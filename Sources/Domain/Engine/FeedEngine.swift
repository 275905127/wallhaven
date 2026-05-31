import Foundation

@MainActor
@Observable
final class FeedEngine {
    private let repository: WallpaperRepository
    private let pagination: PaginationController
    private let prefetchController: PrefetchController
    private let dedup: DeduplicationStore

    private(set) var wallpapers: [Wallpaper] = []
    private(set) var isLoading = false
    private(set) var isRefreshing = false
    private(set) var error: NetworkError?
    private(set) var currentSorting: WallhavenSorting = .toplist
    private(set) var currentQuery = ""

    var hasMore: Bool { pagination.hasMore }
    private var currentTask: Task<Void, Never>?

    init(repository: WallpaperRepository = WallpaperRepository()) {
        self.repository = repository
        self.pagination = PaginationController()
        self.prefetchController = PrefetchController(threshold: 6)
        self.dedup = DeduplicationStore()
    }

    // MARK: - Public API

    func refresh() async {
        currentTask?.cancel()
        isRefreshing = true
        error = nil
        resetState()

        currentTask = Task { [weak self] in
            guard let self = self else { return }
            await self.executeFetch(page: 1)
            self.isRefreshing = false
        }
        await currentTask?.value
    }

    func loadNextPage() async {
        guard pagination.hasMore, !isLoading, !isRefreshing else { return }
        isLoading = true
        error = nil
        await executeFetch(page: pagination.nextPage)
        isLoading = false
    }

    func search(query: String) async {
        currentQuery = query
        await refresh()
    }

    func updateSorting(_ sorting: WallhavenSorting) async {
        guard sorting != currentSorting else { return }
        currentSorting = sorting
        await refresh()
    }

    func prefetchIfNeeded(currentIndex: Int) {
        guard prefetchController.shouldPrefetch(currentIndex: currentIndex, totalCount: wallpapers.count) else { return }
        Task { [weak self] in
            await self?.loadNextPage()
            await self?.prefetchController.prefetchCompleted()
        }
    }

    func prefetchImages(for urls: [URL], using loader: ImageLoader) {
        Task { await loader.prefetchImages(urls: urls) }
    }

    // MARK: - Private

    private func resetState() {
        pagination.reset()
        prefetchController.reset()
        dedup.reset()
    }

    private func executeFetch(page: Int) async {
        do {
            let result = try await repository.fetchWallpapers(
                query: currentQuery, page: page,
                sorting: currentSorting, apiKey: nil
            )
            guard !Task.isCancelled else { return }

            let newItems = dedup.filterNew(from: result.wallpapers)
            dedup.insertBatch(newItems.map(\.id))
            pagination.markPageLoaded(page: page, hasMore: result.hasMore)

            if page == 1 {
                wallpapers = newItems
            } else {
                wallpapers.append(contentsOf: newItems)
            }
            error = nil
        } catch let error as NetworkError {
            guard !Task.isCancelled else { return }
            self.error = error
        } catch {
            guard !Task.isCancelled else { return }
            self.error = .invalidResponse
        }
    }
}
