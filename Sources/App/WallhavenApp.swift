import SwiftUI

@main
struct WallhavenApp: App {
    private let viewModel: BrowseViewModel

    init() {
        let engine = FeedEngine()
        let loader = ImageLoader()
        self.viewModel = BrowseViewModel(feedEngine: engine, imageLoader: loader)
    }

    var body: some Scene {
        WindowGroup {
            BrowseView(viewModel: viewModel)
        }
    }
}
