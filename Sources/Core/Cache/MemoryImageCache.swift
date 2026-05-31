import UIKit

final class MemoryImageCache {
    private let cache = NSCache<NSURL, UIImage>()

    init(countLimit: Int = 300, totalCostLimit: Int = 200 * 1024 * 1024) {
        cache.countLimit = countLimit
        cache.totalCostLimit = totalCostLimit
    }

    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func setImage(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }

    func removeImage(for url: URL) {
        cache.removeObject(forKey: url as NSURL)
    }

    func removeAll() {
        cache.removeAllObjects()
    }
}
