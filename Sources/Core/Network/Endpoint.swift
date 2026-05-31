import Foundation

struct Endpoint {
    let path: String
    let queryItems: [URLQueryItem]
    let baseURL: String

    init(baseURL: String = "https://wallhaven.cc/api/v1", path: String, queryItems: [URLQueryItem] = []) {
        self.baseURL = baseURL
        self.path = path
        self.queryItems = queryItems
    }

    func buildURLRequest() throws -> URLRequest {
        guard var components = URLComponents(string: baseURL + path) else {
            throw NetworkError.invalidURL
        }
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        request.cachePolicy = .reloadIgnoringLocalCacheData
        return request
    }
}

extension Endpoint {
    static func search(
        query: String = "",
        page: Int = 1,
        sorting: WallhavenSorting = .toplist,
        categories: String = "111",
        purity: String = "100",
        apiKey: String? = nil
    ) -> Endpoint {
        var items: [URLQueryItem] = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "sorting", value: sorting.rawValue),
            URLQueryItem(name: "categories", value: categories),
            URLQueryItem(name: "purity", value: purity),
        ]
        if let key = apiKey, !key.isEmpty {
            items.append(URLQueryItem(name: "apikey", value: key))
        }
        return Endpoint(path: "/search", queryItems: items)
    }

    static func wallpaperDetail(id: String, apiKey: String? = nil) -> Endpoint {
        var items: [URLQueryItem] = []
        if let key = apiKey, !key.isEmpty {
            items.append(URLQueryItem(name: "apikey", value: key))
        }
        return Endpoint(path: "/w/\(id)", queryItems: items)
    }
}

enum WallhavenSorting: String, CaseIterable {
    case toplist = "toplist"
    case hot = "views"
    case random = "random"
    case dateAdded = "date_added"
    case relevance = "relevance"

    var displayName: String {
        switch self {
        case .toplist: return "热门推荐"
        case .hot: return "最多浏览"
        case .random: return "随机发现"
        case .dateAdded: return "最新上传"
        case .relevance: return "最相关"
        }
    }
}
