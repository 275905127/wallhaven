import SwiftUI

@MainActor
@Observable
final class ImageLoader: @unchecked Sendable {
    private let urlSession: URLSession
    private var cache: NSCache<NSURL, UIImage>
    private var runningTasks: [URL: Task<UIImage?, Never>] = [:]

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
        self.cache = NSCache<NSURL, UIImage>()
        cache.countLimit = 200
        cache.totalCostLimit = 200 * 1024 * 1024
    }

    func loadImage(from url: URL) async -> UIImage? {
        if let cached = cache.object(forKey: url as NSURL) {
            return cached
        }

        if let existingTask = runningTasks[url] {
            return await existingTask.value
        }

        let task = Task<UIImage?, Never> { [urlSession, cache] in
            do {
                let (data, response) = try await urlSession.data(from: url)
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode),
                      let image = UIImage(data: data) else {
                    return nil
                }
                cache.setObject(image, forKey: url as NSURL)
                return image
            } catch {
                return nil
            }
        }

        runningTasks[url] = task
        let result = await task.value
        runningTasks[url] = nil
        return result
    }

    func clearCache() {
        cache.removeAllObjects()
    }
}
