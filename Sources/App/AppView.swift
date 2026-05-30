import SwiftUI

@MainActor
struct AppView: View {
    @State private var selectedTab: AppTab = .browse

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases) { tab in
                NavigationStack {
                    tab.makeContentView()
                }
                .tabItem { tab.label }
                .tag(tab)
            }
        }
    }
}
