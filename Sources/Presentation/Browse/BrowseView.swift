import SwiftUI

struct BrowseView: View {
    @State private var viewModel: BrowseViewModel
    @State private var selectedTab: BrowseTab = .home
    @State private var searchText = ""
    @State private var selectedWallpaper: Wallpaper?
    @State private var searchTask: Task<Void, Never>?

    init(viewModel: BrowseViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("主页", systemImage: "photo.on.rectangle", value: BrowseTab.home) {
                browseNavigation
            }

            Tab("图源", systemImage: "square.grid.2x2", value: BrowseTab.sources) {
                SourceEngineSheet(viewModel: viewModel, showsDoneButton: false)
            }

            Tab("筛选", systemImage: "slider.horizontal.3", value: BrowseTab.filters) {
                FilterSheet(viewModel: viewModel, showsDoneButton: false)
            }

            Tab(value: BrowseTab.search, role: .search) {
                searchNavigation
            }
        }
        .searchable(text: $searchText, prompt: "搜索壁纸")
        .tabViewSearchActivation(.searchTabSelection)
        .onChange(of: searchText) { _, newValue in
            viewModel.onSearchDebounced(query: newValue, searchTask: &searchTask)
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .sheet(item: $selectedWallpaper) { wallpaper in
            DetailView(wallpaper: wallpaper, imageLoader: viewModel.imageLoader)
        }
        .task {
            await viewModel.onAppear()
        }
    }

    private var browseNavigation: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                wallpaperGrid
            }
            .navigationTitle("Wallhaven")
        }
    }

    private var searchNavigation: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                wallpaperGrid
            }
            .navigationTitle("搜索")
        }
    }

    @ViewBuilder
    private var wallpaperGrid: some View {
        if viewModel.wallpapers.isEmpty && viewModel.isRefreshing {
            loadingStateView
        } else if viewModel.wallpapers.isEmpty && !viewModel.isRefreshing {
            if let error = viewModel.error {
                errorStateView(error)
            } else {
                emptyStateView
            }
        } else {
            MasonryWallpaperGrid(wallpapers: viewModel.wallpapers, viewModel: viewModel) { wallpaper in
                selectedWallpaper = wallpaper
            }
            .overlay(alignment: .bottom) {
                if let error = viewModel.error {
                    errorBanner(error)
                } else if viewModel.isLoading {
                    ProgressView()
                        .padding(12)
                        .glassEffect(.regular, in: .rect(cornerRadius: 14))
                        .padding(.bottom, 12)
                }
            }
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView(
            viewModel.currentQuery.isEmpty ? "探索壁纸" : "未找到",
            systemImage: viewModel.currentQuery.isEmpty ? "photo.on.rectangle.angled" : "magnifyingglass",
            description: Text(viewModel.currentQuery.isEmpty ? "下拉刷新开始浏览壁纸" : "未找到相关壁纸")
        )
    }

    private func errorStateView(_ error: NetworkError) -> some View {
        ContentUnavailableView {
            Label("加载失败", systemImage: "wifi.exclamationmark")
        } description: {
            Text(error.localizedDescription)
        } actions: {
            Button("重试") {
                Task { await viewModel.onRefresh() }
            }
            .buttonStyle(.glassProminent)
        }
    }

    private var loadingStateView: some View {
        ProgressView()
            .controlSize(.large)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorBanner(_ error: NetworkError) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(error.localizedDescription)
                .font(.footnote)
                .lineLimit(2)
            Spacer(minLength: 8)
            Button("重试") {
                Task { await viewModel.onRefresh() }
            }
            .font(.footnote.weight(.semibold))
            .buttonStyle(.glass)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .glassEffect(.regular.tint(.red.opacity(0.18)), in: .rect(cornerRadius: 16))
        .padding(.horizontal)
        .padding(.bottom, 12)
    }
}

private enum BrowseTab: Hashable {
    case home
    case sources
    case filters
    case search
}
