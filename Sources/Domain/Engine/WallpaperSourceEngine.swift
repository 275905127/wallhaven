import Foundation

struct WallpaperSourceEngine: Identifiable, Codable, Equatable, Sendable {
    static let wallhavenTemplateID = UUID(uuidString: "8E7788CB-0AF9-4F97-8C9B-0C898AC7E601")!

    var id: UUID
    var name: String
    var kind: WallpaperSourceEngineKind
    var request: SourceEngineRequest
    var mapping: SourceEngineMapping
    var directImages: [String]
    var apiKey: String

    init(
        id: UUID = UUID(),
        name: String,
        kind: WallpaperSourceEngineKind,
        request: SourceEngineRequest = SourceEngineRequest(),
        mapping: SourceEngineMapping = SourceEngineMapping(),
        directImages: [String] = [],
        apiKey: String = ""
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.request = request
        self.mapping = mapping
        self.directImages = directImages
        self.apiKey = apiKey
    }

    static var wallhavenTemplate: WallpaperSourceEngine {
        WallpaperSourceEngine(
            id: wallhavenTemplateID,
            name: "Wallhaven",
            kind: .wallhaven,
            request: SourceEngineRequest(
                baseURL: "https://wallhaven.cc/api/v1",
                pathTemplate: "/search",
                pageQueryName: "page",
                searchQueryName: "q"
            ),
            mapping: SourceEngineMapping(
                itemsPath: "data",
                idPath: "id",
                thumbnailURLPath: "thumbs.large",
                fullImageURLPath: "path",
                titlePath: "tags.0.name",
                authorPath: "uploader.username",
                widthPath: "dimension_x",
                heightPath: "dimension_y",
                viewsPath: "views",
                favoritesPath: "favorites",
                categoryPath: "category",
                purityPath: "purity",
                fileSizePath: "file_size",
                fileTypePath: "file_type",
                createdAtPath: "created_at",
                sourceURLPath: "url",
                colorsPath: "colors",
                lastPagePath: "meta.last_page"
            )
        )
    }

    var trimmedAPIKey: String {
        apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var hasAPIKey: Bool {
        !trimmedAPIKey.isEmpty
    }
}

enum WallpaperSourceEngineKind: String, CaseIterable, Codable, Identifiable, Sendable {
    case wallhaven
    case jsonAPI
    case directLinks

    var id: Self { self }

    var displayName: String {
        switch self {
        case .wallhaven: return "Wallhaven 模板"
        case .jsonAPI: return "JSON API 引擎"
        case .directLinks: return "图片直链引擎"
        }
    }

    var systemImage: String {
        switch self {
        case .wallhaven: return "network"
        case .jsonAPI: return "curlybraces"
        case .directLinks: return "link"
        }
    }
}

struct SourceEngineRequest: Codable, Equatable, Sendable {
    var baseURL: String = ""
    var pathTemplate: String = ""
    var pageQueryName: String = "page"
    var searchQueryName: String = "q"
    var staticQueryItems: [SourceEngineQueryItem] = []

    var normalizedBaseURL: String {
        let trimmed = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        let withScheme = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
        return withScheme.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    static func from(urlString: String) -> SourceEngineRequest {
        guard let components = URLComponents(string: urlString.withHTTPSIfNeeded),
              let host = components.host else {
            return SourceEngineRequest(baseURL: urlString, pathTemplate: "")
        }

        let scheme = components.scheme ?? "https"
        return SourceEngineRequest(
            baseURL: "\(scheme)://\(host)",
            pathTemplate: components.path,
            pageQueryName: "page",
            searchQueryName: "q",
            staticQueryItems: components.queryItems?.map {
                SourceEngineQueryItem(name: $0.name, value: $0.value ?? "")
            } ?? []
        )
    }

    static func wallhavenCompatible(from urlString: String) -> SourceEngineRequest {
        var request = SourceEngineRequest.from(urlString: urlString)
        request.baseURL = "https://wallhaven.cc/api/v1"
        request.pathTemplate = request.pathTemplate.isEmpty ? "/search" : request.pathTemplate
        return request
    }
}

struct SourceEngineQueryItem: Identifiable, Codable, Equatable, Sendable {
    var id = UUID()
    var name: String
    var value: String
}

struct SourceEngineMapping: Codable, Equatable, Sendable {
    var itemsPath: String = "data"
    var idPath: String = "id"
    var thumbnailURLPath: String = "thumbnail"
    var fullImageURLPath: String = "url"
    var titlePath: String = "title"
    var authorPath: String = ""
    var widthPath: String = ""
    var heightPath: String = ""
    var viewsPath: String = ""
    var favoritesPath: String = ""
    var categoryPath: String = ""
    var purityPath: String = ""
    var fileSizePath: String = ""
    var fileTypePath: String = ""
    var createdAtPath: String = ""
    var sourceURLPath: String = ""
    var colorsPath: String = ""
    var lastPagePath: String = ""
}

private extension String {
    var withHTTPSIfNeeded: String {
        contains("://") ? self : "https://\(self)"
    }

    var isImageURL: Bool {
        guard let url = URL(string: withHTTPSIfNeeded) else { return false }
        let imageExtensions = ["jpg", "jpeg", "png", "webp", "gif", "heic", "avif"]
        return imageExtensions.contains(url.pathExtension.lowercased())
    }
}

extension WallpaperSourceEngine {
    static func smartSource(name: String, input: String) -> WallpaperSourceEngine {
        let links = input
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackName = trimmedName.isEmpty ? "自定义图源" : trimmedName

        if links.count > 1 || links.first?.isImageURL == true {
            return WallpaperSourceEngine(
                name: trimmedName.isEmpty ? "图片直链" : trimmedName,
                kind: .directLinks,
                directImages: links
            )
        }

        guard let first = links.first else {
            return newDirectLinksSource()
        }

        if first.localizedCaseInsensitiveContains("wallhaven.cc") {
            var source = newWallhavenCompatibleSource()
            source.name = fallbackName == "自定义图源" ? "Wallhaven" : fallbackName
            source.request = SourceEngineRequest.wallhavenCompatible(from: first)
            return source
        }

        var source = newJSONAPISource()
        source.name = fallbackName == "自定义图源" ? "JSON API 图源" : fallbackName
        source.request = SourceEngineRequest.from(urlString: first)
        return source
    }

    static func newDirectLinksSource() -> WallpaperSourceEngine {
        WallpaperSourceEngine(name: "图片直链", kind: .directLinks)
    }

    static func newJSONAPISource() -> WallpaperSourceEngine {
        WallpaperSourceEngine(
            name: "JSON API 图源",
            kind: .jsonAPI,
            request: SourceEngineRequest(
                baseURL: "",
                pathTemplate: "",
                pageQueryName: "page",
                searchQueryName: "q"
            )
        )
    }

    static func newWallhavenCompatibleSource() -> WallpaperSourceEngine {
        var source = wallhavenTemplate
        source.id = UUID()
        source.name = "Wallhaven 兼容图源"
        source.apiKey = ""
        return source
    }

    func endpoint(query: String, page: Int) throws -> Endpoint {
        let baseURL = request.normalizedBaseURL
        guard !baseURL.isEmpty else { throw NetworkError.invalidURL }
        var items = request.staticQueryItems.map { URLQueryItem(name: $0.name, value: $0.value) }
        if !request.pageQueryName.isEmpty {
            items.append(URLQueryItem(name: request.pageQueryName, value: String(page)))
        }
        if !request.searchQueryName.isEmpty, !query.isEmpty {
            items.append(URLQueryItem(name: request.searchQueryName, value: query))
        }
        if hasAPIKey {
            items.append(URLQueryItem(name: "apikey", value: trimmedAPIKey))
        }
        return Endpoint(baseURL: baseURL, path: request.pathTemplate, queryItems: items)
    }

    func decodeWallpapers(from root: Any, page: Int) throws -> (wallpapers: [Wallpaper], hasMore: Bool) {
        let itemsValue = value(in: root, at: mapping.itemsPath)
        guard let items = itemsValue as? [Any] else {
            throw NetworkError.invalidResponse
        }

        let wallpapers = items.compactMap { item -> Wallpaper? in
            guard let thumbnailURL = stringValue(in: item, at: mapping.thumbnailURLPath).flatMap(URL.init(string:)),
                  let fullImageURL = stringValue(in: item, at: mapping.fullImageURLPath).flatMap(URL.init(string:)) else {
                return nil
            }
            let width = intValue(in: item, at: mapping.widthPath)
            let height = intValue(in: item, at: mapping.heightPath)
            let resolution: String
            if let width, let height {
                resolution = "\(width)x\(height)"
            } else {
                resolution = "自定义"
            }
            return Wallpaper(
                id: stringValue(in: item, at: mapping.idPath) ?? fullImageURL.absoluteString,
                thumbnailURL: thumbnailURL,
                fullImageURL: fullImageURL,
                title: stringValue(in: item, at: mapping.titlePath),
                author: stringValue(in: item, at: mapping.authorPath),
                resolution: resolution,
                views: intValue(in: item, at: mapping.viewsPath) ?? 0,
                favorites: intValue(in: item, at: mapping.favoritesPath) ?? 0,
                category: stringValue(in: item, at: mapping.categoryPath) ?? "custom",
                purity: stringValue(in: item, at: mapping.purityPath) ?? "sfw",
                fileSize: intValue(in: item, at: mapping.fileSizePath) ?? 0,
                fileType: stringValue(in: item, at: mapping.fileTypePath) ?? fullImageURL.pathExtension,
                createdAt: stringValue(in: item, at: mapping.createdAtPath) ?? "",
                colors: stringArrayValue(in: item, at: mapping.colorsPath),
                sourceURL: stringValue(in: item, at: mapping.sourceURLPath).flatMap(URL.init(string:))
            )
        }

        guard !wallpapers.isEmpty || items.isEmpty else {
            throw NetworkError.invalidResponse
        }

        let lastPage = intValue(in: root, at: mapping.lastPagePath)
        return (wallpapers, lastPage.map { page < $0 } ?? !items.isEmpty)
    }

    private func value(in root: Any, at path: String) -> Any? {
        guard !path.isEmpty else { return nil }
        var current: Any? = root
        for component in path.split(separator: ".") {
            guard let unwrapped = current else { return nil }
            if let dictionary = unwrapped as? [String: Any] {
                current = dictionary[String(component)]
                continue
            }
            if let array = unwrapped as? [Any], let index = Int(component), array.indices.contains(index) {
                current = array[index]
                continue
            }
            return nil
        }
        return current
    }

    private func stringValue(in root: Any, at path: String) -> String? {
        guard let rawValue = value(in: root, at: path) else { return nil }
        if let string = rawValue as? String { return string }
        if let number = rawValue as? NSNumber { return number.stringValue }
        return nil
    }

    private func intValue(in root: Any, at path: String) -> Int? {
        guard let rawValue = value(in: root, at: path) else { return nil }
        if let int = rawValue as? Int { return int }
        if let number = rawValue as? NSNumber { return number.intValue }
        if let string = rawValue as? String { return Int(string) }
        return nil
    }

    private func stringArrayValue(in root: Any, at path: String) -> [String] {
        guard let rawValue = value(in: root, at: path) else { return [] }
        if let strings = rawValue as? [String] { return strings }
        if let values = rawValue as? [Any] {
            return values.compactMap {
                if let string = $0 as? String { return string }
                if let number = $0 as? NSNumber { return number.stringValue }
                return nil
            }
        }
        return []
    }
}
