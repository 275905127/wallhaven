import Foundation

@Observable
final class WallpaperService {
    private let urlSession: URLSession
    private let jsonDecoder: JSONDecoder

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
        self.jsonDecoder = JSONDecoder()
    }

    func fetchWallpapers(from source: WallpaperSource) async throws -> [WallpaperItem] {
        switch source.type {
        case .directURL:
            return try await fetchFromDirectURL(source)
        case .wallhavenAPI:
            return try await fetchFromWallhavenAPI(source)
        case .unsplashAPI:
            return try await fetchFromUnsplashAPI(source)
        case .pexelsAPI:
            return try await fetchFromPexelsAPI(source)
        }
    }

    // MARK: - Direct URL (JSON feed)

    private func fetchFromDirectURL(_ source: WallpaperSource) async throws -> [WallpaperItem] {
        guard let url = URL(string: source.urlString) else {
            throw WallpaperError.invalidURL
        }

        let (data, response) = try await urlSession.data(from: url)
        try validateResponse(response)

        let feed = try jsonDecoder.decode(WallpaperFeed.self, from: data)
        return feed.wallpapers.map { item in
            WallpaperItem(
                id: item.id,
                thumbnailURL: item.thumbnailURL,
                fullImageURL: item.fullImageURL,
                title: item.title,
                author: item.author,
                resolution: item.resolution,
                sourceID: source.persistentModelID.hashValue.description,
                sourceName: source.name
            )
        }
    }

    // MARK: - Wallhaven API

    private func fetchFromWallhavenAPI(_ source: WallpaperSource) async throws -> [WallpaperItem] {
        guard let url = URL(string: source.urlString) else {
            throw WallpaperError.invalidURL
        }

        let (data, response) = try await urlSession.data(from: url)
        try validateResponse(response)

        let result = try jsonDecoder.decode(WallhavenResponse.self, from: data)
        return result.data.map { entry in
            WallpaperItem(
                id: entry.id,
                thumbnailURL: URL(string: entry.thumbs.large)!,
                fullImageURL: URL(string: entry.path)!,
                title: nil,
                author: nil,
                resolution: entry.resolution,
                sourceID: source.persistentModelID.hashValue.description,
                sourceName: source.name
            )
        }
    }

    // MARK: - Unsplash API

    private func fetchFromUnsplashAPI(_ source: WallpaperSource) async throws -> [WallpaperItem] {
        guard let url = URL(string: source.urlString) else {
            throw WallpaperError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("v1", forHTTPHeaderField: "Accept-Version")

        let (data, response) = try await urlSession.data(from: url)
        try validateResponse(response)

        let photos = try jsonDecoder.decode([UnsplashPhoto].self, from: data)
        return photos.map { photo in
            WallpaperItem(
                id: photo.id,
                thumbnailURL: photo.urls.thumb,
                fullImageURL: photo.urls.full,
                title: photo.description ?? photo.altDescription,
                author: photo.user.name,
                resolution: "\(photo.width)×\(photo.height)",
                sourceID: source.persistentModelID.hashValue.description,
                sourceName: source.name
            )
        }
    }

    // MARK: - Pexels API

    private func fetchFromPexelsAPI(_ source: WallpaperSource) async throws -> [WallpaperItem] {
        guard let url = URL(string: source.urlString) else {
            throw WallpaperError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await urlSession.data(from: url)
        try validateResponse(response)

        let result = try jsonDecoder.decode(PexelsResponse.self, from: data)
        return result.photos.map { photo in
            WallpaperItem(
                id: String(photo.id),
                thumbnailURL: URL(string: photo.src.medium)!,
                fullImageURL: URL(string: photo.src.original)!,
                title: photo.alt,
                author: photo.photographer,
                resolution: "\(photo.width)×\(photo.height)",
                sourceID: source.persistentModelID.hashValue.description,
                sourceName: source.name
            )
        }
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WallpaperError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw WallpaperError.httpError(httpResponse.statusCode)
        }
    }
}

// MARK: - Error

enum WallpaperError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid source URL"
        case .invalidResponse: return "Invalid server response"
        case .httpError(let code): return "Server error (HTTP \(code))"
        case .decodingFailed(let detail): return "Failed to parse response: \(detail)"
        }
    }
}

// MARK: - Feed models for Direct URL

struct WallpaperFeed: Codable {
    let wallpapers: [FeedWallpaperItem]
}

struct FeedWallpaperItem: Codable {
    let id: String
    let thumbnailURL: URL
    let fullImageURL: URL
    let title: String?
    let author: String?
    let resolution: String?
}

// MARK: - Wallhaven API models

struct WallhavenResponse: Codable {
    let data: [WallhavenEntry]
}

struct WallhavenEntry: Codable {
    let id: String
    let path: String
    let resolution: String
    let thumbs: WallhavenThumbs
}

struct WallhavenThumbs: Codable {
    let large: String
}

// MARK: - Unsplash API models

struct UnsplashPhoto: Codable {
    let id: String
    let width: Int
    let height: Int
    let description: String?
    let altDescription: String?
    let urls: UnsplashURLs
    let user: UnsplashUser
}

struct UnsplashURLs: Codable {
    let thumb: URL
    let full: URL
}

struct UnsplashUser: Codable {
    let name: String
}

// MARK: - Pexels API models

struct PexelsResponse: Codable {
    let photos: [PexelsPhoto]
}

struct PexelsPhoto: Codable {
    let id: Int
    let width: Int
    let height: Int
    let alt: String?
    let photographer: String
    let src: PexelsSource
}

struct PexelsSource: Codable {
    let medium: String
    let original: String
}
