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
        apiKey: String?
    ) async throws -> (wallpapers: [Wallpaper], hasMore: Bool) {
        let response = try await api.search(
            query: query,
            page: page,
            sorting: sorting,
            apiKey: apiKey
        )
        let wallpapers = response.data.map { $0.toDomain() }
        return (wallpapers, page < response.meta.lastPage)
    }
}

// MARK: - DTO → Domain mapping

extension WallpaperDTO {
    func toDomain() -> Wallpaper {
        Wallpaper(
            id: id,
            thumbnailURL: URL(string: thumbs.large) ?? URL(string: thumbs.original)!,
            fullImageURL: URL(string: path)!,
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

