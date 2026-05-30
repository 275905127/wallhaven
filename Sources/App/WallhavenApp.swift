import SwiftUI
import SwiftData

@main
struct WallhavenApp: App {
    @State private var imageLoader = ImageLoader()
    @State private var wallpaperService = WallpaperService()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([WallpaperSource.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppView()
                .environment(imageLoader)
                .environment(wallpaperService)
        }
        .modelContainer(sharedModelContainer)
    }
}
