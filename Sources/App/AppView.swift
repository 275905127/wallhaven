import SwiftUI

@MainActor
struct AppView: View {
    @State private var selectedTab: AppTab = .browse

    var body: some View {
        if #available(iOS 26, *) {
            TabView(selection: $selectedTab) {
                ForEach(AppTab.allCases) { tab in
                    NavigationStack {
                        tab.makeContentView()
                    }
                    .tabItem { tab.label }
                    .tag(tab)
                }
            }
        } else {
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
}
