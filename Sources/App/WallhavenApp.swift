import SwiftUI

@main
struct WallhavenApp: App {
    private let feedEngine: FeedEngine
    private let imageLoader: ImageLoader
    private let viewModel: BrowseViewModel

    init() {
        let engine = FeedEngine()
        let loader = ImageLoader()
        self.feedEngine = engine
        self.imageLoader = loader
        self.viewModel = BrowseViewModel(feedEngine: engine, imageLoader: loader)
    }

    var body: some Scene {
        WindowGroup {
            BrowseView(viewModel: viewModel)
        }
    }
}
