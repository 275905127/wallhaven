import Foundation

@MainActor
@Observable
final class FeedEngine {
    private let repository: WallpaperRepository
    private let prefetchThreshold = 6

    private(set) var wallpapers: [Wallpaper] = []
    private(set) var currentPage = 0
    private(set) var isLoading = false
    private(set) var isRefreshing = false
    private(set) var hasMore = true
    private(set) var error: NetworkError?
    private(set) var currentSorting: WallhavenSorting = .toplist
    private(set) var currentQuery = ""

    private var seenIDs = Set<String>()
    private var isLoadingNextPage = false
    private var currentTask: Task<Void, Never>?

    init(repository: WallpaperRepository = WallpaperRepository()) {
        self.repository = repository
    }

    // MARK: - Public API

    func refresh() async {
        currentTask?.cancel()
        isRefreshing = true
        error = nil
        currentPage = 0
        seenIDs.removeAll()
        hasMore = true

        currentTask = Task { [weak self] in
            guard let self = self else { return }
            do {
                let result = try await self.repository.fetchWallpapers(
                    query: self.currentQuery,
                    page: 1,
                    sorting: self.currentSorting,
                    apiKey: nil
                )
                guard !Task.isCancelled else { return }
                self.currentPage = 1
                self.hasMore = result.hasMore
                self.seenIDs = Set(result.wallpapers.map(\.id))
                self.wallpapers = result.wallpapers
                self.error = nil
            } catch let error as NetworkError {
                guard !Task.isCancelled else { return }
                self.error = error
            } catch {
                guard !Task.isCancelled else { return }
                self.error = .invalidResponse
            }
            self.isRefreshing = false
        }
        await currentTask?.value
    }

    func loadNextPage() async {
        guard !isLoadingNextPage, hasMore, !isRefreshing else { return }
        isLoadingNextPage = true
        isLoading = true
        error = nil

        let nextPage = currentPage + 1
        do {
            let result = try await repository.fetchWallpapers(
                query: currentQuery,
                page: nextPage,
                sorting: currentSorting,
                apiKey: nil
            )
            let newItems = result.wallpapers.filter { !seenIDs.contains($0.id) }
            seenIDs.formUnion(newItems.map(\.id))
            currentPage = nextPage
            hasMore = result.hasMore
            wallpapers.append(contentsOf: newItems)
            error = nil
        } catch let error as NetworkError {
            self.error = error
        } catch {
            self.error = .invalidResponse
        }
        isLoadingNextPage = false
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
        let threshold = wallpapers.count - prefetchThreshold
        guard currentIndex >= threshold, hasMore, !isLoadingNextPage else { return }
        Task { [weak self] in
            await self?.loadNextPage()
        }
    }
}
