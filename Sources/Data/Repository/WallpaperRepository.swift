import Foundation

final class WallpaperRepository: @unchecked Sendable {
    private let api: WallhavenAPI

    init(api: WallhavenAPI = WallhavenAPI()) {
        self.api = api
    }

    func fetchWallpapers(
        query: String,
        page: Int,
        sorting: WallhavenSorting,
        configuration: WallhavenSourceConfiguration
    ) async throws -> (wallpapers: [Wallpaper], hasMore: Bool) {
        let response = try await api.search(
            query: query,
            page: page,
            sorting: sorting,
            configuration: configuration
        )
        let wallpapers = try response.data.map { try $0.toDomain() }
        return (wallpapers, page < response.meta.lastPage)
    }
}

// MARK: - DTO → Domain mapping

extension WallpaperDTO {
    func toDomain() throws -> Wallpaper {
        guard let thumbnailURL = URL(string: thumbs.large) ?? URL(string: thumbs.original),
              let fullImageURL = URL(string: path) else {
            throw NetworkError.invalidURL
        }

        Wallpaper(
            id: id,
            thumbnailURL: thumbnailURL,
            fullImageURL: fullImageURL,
            title: tags?.prefix(3).map(\.name).joined(separator: ", "),
            author: uploader?.username,
            resolution: resolution,
            views: views,
            favorites: favorites,
            category: category,
            purity: purity,
            fileSize: fileSize,
            fileType: fileType,
            createdAt: createdAt,
            colors: colors,
            sourceURL: URL(string: source)
        )
    }
}

