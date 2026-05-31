import UIKit

struct CacheStats {
    var hits: Int = 0
    var misses: Int = 0

    var hitRate: Double {
        let total = hits + misses
        return total > 0 ? Double(hits) / Double(total) : 0
    }
}

final class MemoryImageCache {
    private let cache = NSCache<NSURL, CacheEntry>()
    private var accessOrder: [NSURL] = []
    private let maxCount: Int
    let ttl: TimeInterval
    private(set) var stats = CacheStats()

    init(countLimit: Int = 300, totalCostLimit: Int = 200 * 1024 * 1024, ttl: TimeInterval = 600) {
        self.maxCount = countLimit
        self.ttl = ttl
        cache.countLimit = countLimit
        cache.totalCostLimit = totalCostLimit
    }

    func image(for url: URL) -> UIImage? {
        let key = url as NSURL
        guard let entry = cache.object(forKey: key) else {
            stats.misses += 1
            return nil
        }
        if Date().timeIntervalSince(entry.createdAt) > ttl {
            removeImage(for: url)
            stats.misses += 1
            return nil
        }
        stats.hits += 1
        touchAccessOrder(key)
        return entry.image
    }

    func setImage(_ image: UIImage, for url: URL) {
        let key = url as NSURL
        let entry = CacheEntry(image: image, createdAt: Date())
        cache.setObject(entry, forKey: key)
        touchAccessOrder(key)
        evictIfNeeded()
    }

    func removeImage(for url: URL) {
        let key = url as NSURL
        cache.removeObject(forKey: key)
        accessOrder.removeAll { $0 == key }
    }

    func removeAll() {
        cache.removeAllObjects()
        accessOrder.removeAll()
    }

    // MARK: Private

    private func touchAccessOrder(_ key: NSURL) {
        accessOrder.removeAll { $0 == key }
        accessOrder.append(key)
    }

    private func evictIfNeeded() {
        while accessOrder.count > maxCount {
            let oldest = accessOrder.removeFirst()
            cache.removeObject(forKey: oldest)
        }
    }
}

private final class CacheEntry {
    let image: UIImage
    let createdAt: Date

    init(image: UIImage, createdAt: Date) {
        self.image = image
        self.createdAt = createdAt
    }
}
