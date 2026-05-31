import SwiftUI

@MainActor
@Observable
final class BrowseViewModel {
    private let feedEngine: FeedEngine
    let imageLoader: ImageLoader

    var wallpapers: [Wallpaper] { feedEngine.wallpapers }
    var isLoading: Bool { feedEngine.isLoading }
    var isRefreshing: Bool { feedEngine.isRefreshing }
    var error: NetworkError? { feedEngine.error }
    var sortingOptions: [WallhavenSorting] { WallhavenSorting.allCases }
    var currentSorting: WallhavenSorting { feedEngine.currentSorting }
    var currentQuery: String { feedEngine.currentQuery }

    init(feedEngine: FeedEngine, imageLoader: ImageLoader) {
        self.feedEngine = feedEngine
        self.imageLoader = imageLoader
    }

    func onAppear() async {
        await feedEngine.refresh()
    }

    func onRefresh() async {
        await feedEngine.refresh()
    }

    func onItemAppear(index: Int) {
        feedEngine.prefetchIfNeeded(currentIndex: index)
    }

    func onSearchDebounced(query: String, searchTask: inout Task<Void, Never>?) {
        searchTask?.cancel()
        searchTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            await feedEngine.search(query: query)
        }
    }

    func onSortSelected(_ sorting: WallhavenSorting) async {
        await feedEngine.updateSorting(sorting)
    }

    func prefetchImages(for items: [Wallpaper]) {
        let urls = items.map(\.thumbnailURL)
        Task { await imageLoader.prefetchImages(urls: urls) }
    }

    func loadImage(from url: URL) async -> UIImage? {
        await imageLoader.loadImage(from: url)
    }
}
