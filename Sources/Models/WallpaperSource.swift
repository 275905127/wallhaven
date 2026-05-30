import Foundation
import SwiftData

@Model
final class WallpaperSource {
    var name: String
    var urlString: String
    var sourceType: SourceType.RawValue
    var isEnabled: Bool
    var createdAt: Date
    var sortOrder: Int

    init(name: String, urlString: String, sourceType: SourceType = .directURL, isEnabled: Bool = true, sortOrder: Int = 0) {
        self.name = name
        self.urlString = urlString
        self.sourceType = sourceType.rawValue
        self.isEnabled = isEnabled
        self.createdAt = Date()
        self.sortOrder = sortOrder
    }

    var type: SourceType {
        SourceType(rawValue: sourceType) ?? .directURL
    }
}

enum SourceType: String, CaseIterable, Codable {
    case directURL = "directURL"
    case wallhavenAPI = "wallhavenAPI"
    case unsplashAPI = "unsplashAPI"
    case pexelsAPI = "pexelsAPI"

    var displayName: String {
        switch self {
        case .directURL: return "直链URL"
        case .wallhavenAPI: return "Wallhaven API"
        case .unsplashAPI: return "Unsplash API"
        case .pexelsAPI: return "Pexels API"
        }
    }

    var iconName: String {
        switch self {
        case .directURL: return "link"
        case .wallhavenAPI: return "photo.on.rectangle"
        case .unsplashAPI: return "camera.aperture"
        case .pexelsAPI: return "square.grid.3x3"
        }
    }
}
