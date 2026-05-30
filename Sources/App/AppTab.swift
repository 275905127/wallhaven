import SwiftUI

enum AppTab: String, Identifiable, Hashable, CaseIterable {
    case browse
    case favorites
    case sources

    var id: String { rawValue }

    @ViewBuilder
    func makeContentView() -> some View {
        switch self {
        case .browse:
            BrowseView()
        case .favorites:
            FavoritesView()
        case .sources:
            SourceListView()
        }
    }

    @ViewBuilder
    var label: some View {
        switch self {
        case .browse:
            Label("Browse", systemImage: "photo.on.rectangle.angled")
        case .favorites:
            Label("Favorites", systemImage: "heart.fill")
        case .sources:
            Label("Sources", systemImage: "link.icloud")
        }
    }
}
