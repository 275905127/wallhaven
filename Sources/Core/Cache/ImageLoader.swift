import UIKit

actor ImageLoader {
    private let memoryCache: MemoryImageCache
    private let diskCache: DiskImageCache
    private let urlSession: URLSession
    private var runningTasks: [URL: Task<UIImage?, Never>] = [:]

    var memoryStats: CacheStats { memoryCache.stats }
    var diskStats: CacheStats { diskCache.stats }

    init(
        memoryCache: MemoryImageCache = MemoryImageCache(),
        diskCache: DiskImageCache = DiskImageCache(),
        urlSession: URLSession = {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 30
            config.urlCache = nil
            return URLSession(configuration: config)
        }()
    ) {
        self.memoryCache = memoryCache
        self.diskCache = diskCache
        self.urlSession = urlSession
    }

    func loadImage(from url: URL) async -> UIImage? {
        // 1. Memory cache (fast path)
        if let cached = memoryCache.image(for: url) {
            return cached
        }
        // 2. Disk cache
        if let diskImage = diskCache.image(for: url) {
            memoryCache.setImage(diskImage, for: url)
            return diskImage
        }
        // 3. Request coalescing: reuse in-flight task
        if let existing = runningTasks[url] {
            return await existing.value
        }
        // 4. Download
        return await downloadImage(from: url)
    }

    func prefetchImages(urls: [URL]) {
        for url in urls {
            Task { [weak self] in
                _ = await self?.loadImage(from: url)
            }
        }
    }

    func cancelPrefetch(for urls: [URL]) {
        for url in urls {
            runningTasks[url]?.cancel()
            runningTasks[url] = nil
        }
    }

    func clearMemoryCache() {
        memoryCache.removeAll()
    }

    func clearAllCache() {
        memoryCache.removeAll()
        diskCache.removeAll()
    }

    // MARK: - Private

    private func downloadImage(from url: URL) async -> UIImage? {
        let task = Task<UIImage?, Never> { [weak self] in
            guard let self = self else { return nil }
            do {
                let (data, response) = try await self.urlSession.data(from: url)
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode),
                      let image = UIImage(data: data) else { return nil }
                await self.memoryCache.setImage(image, for: url)
                await self.diskCache.storeImage(image, for: url)
                return image
            } catch {
                guard !Task.isCancelled else { return nil }
                return nil
            }
        }
        runningTasks[url] = task
        let result = await task.value
        runningTasks[url] = nil
        return result
    }
}

// MARK: - Sendable support for cache classes

extension MemoryImageCache: @unchecked Sendable {}
extension DiskImageCache: @unchecked Sendable {}
