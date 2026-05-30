import SwiftUI

@MainActor
enum AppTab: String, Identifiable, Hashable, CaseIterable {
    case browse
    case favorites
    case sources

    nonisolated var id: String { rawValue }

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
            Label("浏览", systemImage: "photo.on.rectangle.angled")
        case .favorites:
            Label("收藏", systemImage: "heart.fill")
        case .sources:
            Label("图源", systemImage: "link.icloud")
        }
    }
}
