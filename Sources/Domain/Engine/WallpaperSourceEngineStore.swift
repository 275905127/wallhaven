import Foundation

struct WallpaperSourceEngineStore {
    private let defaults: UserDefaults
    private let enginesKey = "wallpaper.sourceEngines"
    private let activeEngineIDKey = "wallpaper.sourceEngines.active"
    private let didSeedDefaultEngineKey = "wallpaper.sourceEngines.didSeedDefault"
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadEngines() -> [WallpaperSourceEngine] {
        guard let data = defaults.data(forKey: enginesKey),
              let engines = try? decoder.decode([WallpaperSourceEngine].self, from: data),
              !engines.isEmpty else {
            defaults.set(true, forKey: didSeedDefaultEngineKey)
            return [.wallhavenTemplate]
        }
        return engines
    }

    func loadActiveEngineID(engines: [WallpaperSourceEngine]) -> UUID {
        if let rawValue = defaults.string(forKey: activeEngineIDKey),
           let id = UUID(uuidString: rawValue),
           engines.contains(where: { $0.id == id }) {
            return id
        }
        return engines.first?.id ?? WallpaperSourceEngine.wallhavenTemplateID
    }

    func save(engines: [WallpaperSourceEngine], activeEngineID: UUID) {
        let safeEngines = engines.isEmpty ? [WallpaperSourceEngine.wallhavenTemplate] : engines
        if let data = try? encoder.encode(safeEngines) {
            defaults.set(data, forKey: enginesKey)
        }
        defaults.set(activeEngineID.uuidString, forKey: activeEngineIDKey)
        defaults.set(true, forKey: didSeedDefaultEngineKey)
    }
}
