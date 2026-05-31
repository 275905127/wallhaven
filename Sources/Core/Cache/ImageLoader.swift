import UIKit

@MainActor
final class ImageLoader: @unchecked Sendable {
    private let memoryCache: MemoryImageCache
    private let diskCache: DiskImageCache
    private let urlSession: URLSession
    private var runningTasks: [URL: Task<UIImage?, Never>] = [:]

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
        if let cached = memoryCache.image(for: url) {
            return cached
        }
        if let diskImage = diskCache.image(for: url) {
            memoryCache.setImage(diskImage, for: url)
            return diskImage
        }
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
            if let task = runningTasks[url], memoryCache.image(for: url) == nil {
                task.cancel()
                runningTasks[url] = nil
            }
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
        if let existing = runningTasks[url] {
            return await existing.value
        }

        let task = Task<UIImage?, Never> { [weak self] in
            guard let self = self else { return nil }
            do {
                let (data, response) = try await self.urlSession.data(from: url)
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode),
                      let image = UIImage(data: data) else { return nil }
                self.memoryCache.setImage(image, for: url)
                self.diskCache.storeImage(image, for: url)
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
