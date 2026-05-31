import SwiftUI

@MainActor
@Observable
final class BrowseViewModel {
    let feedEngine: FeedEngine
    let imageLoader: ImageLoader

    var wallpapers: [Wallpaper] { feedEngine.wallpapers }
    var isLoading: Bool { feedEngine.isLoading }
    var isRefreshing: Bool { feedEngine.isRefreshing }
    var hasMore: Bool { feedEngine.hasMore }
    var error: NetworkError? { feedEngine.error }
    var sortingOptions: [WallhavenSorting] { WallhavenSorting.allCases }
    var currentSorting: WallhavenSorting { feedEngine.currentSorting }
    var currentQuery: String { feedEngine.currentQuery }

    init(feedEngine: FeedEngine, imageLoader: ImageLoader) {
        self.feedEngine = feedEngine
        self.imageLoader = imageLoader
    }

    func refresh() async {
        await feedEngine.refresh()
    }

    func loadNextPageIfNeeded(currentItem: Wallpaper) async {
        guard let index = wallpapers.firstIndex(where: { $0.id == currentItem.id }) else { return }
        feedEngine.prefetchIfNeeded(currentIndex: index)
    }

    func search(query: String) async {
        await feedEngine.search(query: query)
    }

    func selectSorting(_ sorting: WallhavenSorting) async {
        await feedEngine.updateSorting(sorting)
    }

    func prefetchImages(for items: [Wallpaper]) {
        let urls = items.map(\.thumbnailURL)
        imageLoader.prefetchImages(urls: urls)
    }
}
