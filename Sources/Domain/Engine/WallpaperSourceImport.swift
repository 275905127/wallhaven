import Foundation

enum WallpaperSourceImportError: LocalizedError {
    case invalidJSON
    case emptyConfiguration
    case unsupportedType(String)
    case missingURL(String)
    case missingMapping(String)

    var errorDescription: String? {
        switch self {
        case .invalidJSON:
            return "配置不是有效 JSON"
        case .emptyConfiguration:
            return "配置里没有可导入的图源"
        case .unsupportedType(let type):
            return "暂不支持的图源类型：\(type)"
        case .missingURL(let name):
            return "\(name) 缺少 url 或 request.url"
        case .missingMapping(let name):
            return "\(name) 缺少 mapping.items、mapping.thumbnail 或 mapping.image"
        }
    }
}

enum WallpaperSourceImporter {
    static func importSources(from jsonText: String) throws -> [WallpaperSourceEngine] {
        guard let data = jsonText.data(using: .utf8) else {
            throw WallpaperSourceImportError.invalidJSON
        }

        let decoder = JSONDecoder()
        let sources: [ImportedSourceConfiguration]
        do {
            sources = try decoder.decode([ImportedSourceConfiguration].self, from: data)
        } catch {
            do {
                sources = [try decoder.decode(ImportedSourceConfiguration.self, from: data)]
            } catch {
                throw WallpaperSourceImportError.invalidJSON
            }
        }

        let enabledSources = sources.filter { $0.enabled ?? true }
        guard !enabledSources.isEmpty else {
            throw WallpaperSourceImportError.emptyConfiguration
        }

        return try enabledSources.map(makeSource)
    }

    private static func makeSource(from configuration: ImportedSourceConfiguration) throws -> WallpaperSourceEngine {
        let name = configuration.normalizedName
        let type = configuration.normalizedType

        switch type {
        case "json", "api", "rss":
            return try makeJSONSource(from: configuration, name: name)
        case "direct":
            return try makeDirectSource(from: configuration, name: name)
        default:
            throw WallpaperSourceImportError.unsupportedType(configuration.type ?? "")
        }
    }

    private static func makeJSONSource(from configuration: ImportedSourceConfiguration, name: String) throws -> WallpaperSourceEngine {
        let rawURL = configuration.request?.url ?? configuration.url
        guard let rawURL, !rawURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw WallpaperSourceImportError.missingURL(name)
        }

        let request = SourceEngineRequest.from(urlString: rawURL)
        let requestParams = (configuration.request?.params ?? configuration.params).stringValues
        let authParams = configuration.authQueryItems
        let staticItems = (request.staticQueryItems + requestParams.queryItems + authParams).deduplicatedByName()
        let mapping = try configuration.resolvedMapping(defaultsFor: rawURL, name: name)
        let pagination = configuration.pagination
        let search = configuration.search
        let defaultPageQueryName = pagination == nil && rawURL.localizedCaseInsensitiveContains("bing.com/HPImageArchive.aspx") ? "" : "page"
        let defaultSearchQueryName = rawURL.localizedCaseInsensitiveContains("bing.com/HPImageArchive.aspx") ? "" : "q"

        return WallpaperSourceEngine(
            name: name,
            kind: .jsonAPI,
            request: SourceEngineRequest(
                baseURL: request.baseURL,
                pathTemplate: request.pathTemplate,
                pageQueryName: pagination?.pageQueryName ?? defaultPageQueryName,
                searchQueryName: search?.enabled == false ? "" : (search?.param ?? defaultSearchQueryName),
                staticQueryItems: staticItems
            ),
            mapping: mapping
        )
    }

    private static func makeDirectSource(from configuration: ImportedSourceConfiguration, name: String) throws -> WallpaperSourceEngine {
        if let urls = configuration.urls, !urls.isEmpty {
            return WallpaperSourceEngine(name: name, kind: .directLinks, directImages: urls)
        }
        guard let url = configuration.request?.url ?? configuration.url else {
            throw WallpaperSourceImportError.missingURL(name)
        }
        return WallpaperSourceEngine(name: name, kind: .directLinks, directImages: [url])
    }
}

private struct ImportedSourceConfiguration: Decodable {
    let name: String?
    let type: String?
    let url: String?
    let urls: [String]?
    let enabled: Bool?
    let params: [String: ImportedJSONValue]?
    let request: ImportedRequest?
    let pagination: ImportedPagination?
    let search: ImportedSearch?
    let mapping: ImportedMapping?
    let transforms: ImportedTransforms?

    var normalizedName: String {
        let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "导入图源" : trimmed
    }

    var normalizedType: String {
        let trimmed = type?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        return trimmed.isEmpty ? "json" : trimmed
    }

    var authQueryItems: [SourceEngineQueryItem] {
        guard let auth = request?.auth,
              auth.type.lowercased() == "query",
              !auth.key.isEmpty,
              !auth.value.isEmpty,
              auth.value != "YOUR_API_KEY" else {
            return []
        }
        return [SourceEngineQueryItem(name: auth.key, value: auth.value)]
    }

    func resolvedMapping(defaultsFor url: String, name: String) throws -> SourceEngineMapping {
        let lastPagePath = pagination?.hasMorePath
        if let mapping {
            return SourceEngineMapping(
                itemsPath: mapping.items ?? "data",
                idPath: mapping.id ?? "id",
                thumbnailURLPath: mapping.thumbnail ?? "thumbnail",
                fullImageURLPath: mapping.image ?? mapping.url ?? "url",
                thumbnailURLPrefix: transforms?.thumbnail?.prefix,
                fullImageURLPrefix: transforms?.image?.prefix,
                titlePath: mapping.title ?? "title",
                authorPath: mapping.author ?? "",
                widthPath: mapping.width ?? "",
                heightPath: mapping.height ?? "",
                viewsPath: mapping.views ?? "",
                favoritesPath: mapping.favorites ?? "",
                categoryPath: mapping.category ?? "",
                purityPath: mapping.purity ?? "",
                fileSizePath: mapping.fileSize ?? "",
                fileTypePath: mapping.fileType ?? "",
                createdAtPath: mapping.createdAt ?? "",
                sourceURLPath: mapping.sourceUrl ?? "",
                colorsPath: mapping.colors ?? "",
                lastPagePath: mapping.lastPage ?? lastPagePath ?? ""
            )
        }

        if url.localizedCaseInsensitiveContains("wallhaven.cc") {
            return WallpaperSourceEngine.wallhavenTemplate.mapping
        }

        if url.localizedCaseInsensitiveContains("bing.com/HPImageArchive.aspx") {
            return SourceEngineMapping(
                itemsPath: "images",
                idPath: "hsh",
                thumbnailURLPath: "url",
                fullImageURLPath: "url",
                thumbnailURLPrefix: "https://www.bing.com",
                fullImageURLPrefix: "https://www.bing.com",
                titlePath: "copyright",
                sourceURLPath: "copyrightlink"
            )
        }

        throw WallpaperSourceImportError.missingMapping(name)
    }
}

private struct ImportedRequest: Decodable {
    let url: String?
    let params: [String: ImportedJSONValue]?
    let auth: ImportedAuth?
}

private struct ImportedAuth: Decodable {
    let type: String
    let key: String
    let value: String
}

private struct ImportedPagination: Decodable {
    let type: String?
    let param: String?
    let hasMorePath: String?

    var pageQueryName: String {
        guard type != "none" else { return "" }
        return param ?? "page"
    }
}

private struct ImportedSearch: Decodable {
    let enabled: Bool?
    let param: String?
}

private struct ImportedMapping: Decodable {
    let items: String?
    let id: String?
    let thumbnail: String?
    let image: String?
    let url: String?
    let title: String?
    let author: String?
    let width: String?
    let height: String?
    let views: String?
    let favorites: String?
    let category: String?
    let purity: String?
    let fileSize: String?
    let fileType: String?
    let createdAt: String?
    let sourceUrl: String?
    let colors: String?
    let lastPage: String?
}

private struct ImportedTransforms: Decodable {
    let thumbnail: ImportedURLTransform?
    let image: ImportedURLTransform?
}

private struct ImportedURLTransform: Decodable {
    let prefix: String?
}

private enum ImportedJSONValue: Decodable {
    case string(String)
    case bool(Bool)
    case number(Double)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else {
            self = .number(try container.decode(Double.self))
        }
    }

    var stringValue: String {
        switch self {
        case .string(let value):
            return value
        case .bool(let value):
            return value ? "true" : "false"
        case .number(let value):
            if value.rounded() == value {
                return String(Int(value))
            }
            return String(value)
        }
    }
}

private extension Optional where Wrapped == [String: ImportedJSONValue] {
    var stringValues: [String: String] {
        self?.mapValues(\.stringValue) ?? [:]
    }
}

private extension Dictionary where Key == String, Value == String {
    var queryItems: [SourceEngineQueryItem] {
        filter { !$0.key.isEmpty && !$0.value.isEmpty && $0.value != "YOUR_API_KEY" }
            .map { SourceEngineQueryItem(name: $0.key, value: $0.value) }
            .sorted { $0.name < $1.name }
    }
}

private extension Array where Element == SourceEngineQueryItem {
    func deduplicatedByName() -> [SourceEngineQueryItem] {
        var seen = Set<String>()
        return filter { item in
            seen.insert(item.name).inserted
        }
    }
}
