import Foundation

struct WallpaperItem: Identifiable, Hashable, Sendable {
    let id: String
    let thumbnailURL: URL
    let fullImageURL: URL
    let title: String?
    let author: String?
    let resolution: String?
    let sourceID: String
    let sourceName: String

    init(
        id: String,
        thumbnailURL: URL,
        fullImageURL: URL,
        title: String? = nil,
        author: String? = nil,
        resolution: String? = nil,
        sourceID: String,
        sourceName: String
    ) {
        self.id = id
        self.thumbnailURL = thumbnailURL
        self.fullImageURL = fullImageURL
        self.title = title
        self.author = author
        self.resolution = resolution
        self.sourceID = sourceID
        self.sourceName = sourceName
    }

    static func == (lhs: WallpaperItem, rhs: WallpaperItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
