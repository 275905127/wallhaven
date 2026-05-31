import SwiftUI

struct BrowseView: View {
    @State private var viewModel: BrowseViewModel
    @State private var searchText = ""
    @State private var selectedWallpaper: Wallpaper?
    @State private var searchTask: Task<Void, Never>?
    @State private var presentedSheet: BrowseSheet?

    init(viewModel: BrowseViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                wallpaperGrid
                bottomFloatingBar
            }
            .navigationTitle("Wallhaven")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        presentedSheet = .filters
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                    .liquidGlassButtonStyle()
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索壁纸...")
            .onChange(of: searchText) { _, newValue in
                viewModel.onSearchDebounced(query: newValue, searchTask: &searchTask)
            }
            .sheet(item: $selectedWallpaper) { wallpaper in
                DetailView(wallpaper: wallpaper, imageLoader: viewModel.imageLoader)
            }
            .sheet(item: $presentedSheet) { sheet in
                switch sheet {
                case .filters:
                    FilterSheet(viewModel: viewModel)
                case .sources:
                    SourceEngineSheet(viewModel: viewModel)
                }
            }
            .task {
                await viewModel.onAppear()
            }
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
                        .liquidGlassSurface(cornerRadius: 14)
                        .padding(.bottom, 86)
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
            .liquidGlassButtonStyle(prominent: true)
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
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .liquidGlassSurface(cornerRadius: 16, tint: .red.opacity(0.18))
        .padding(.horizontal)
        .padding(.bottom, 86)
    }

    private var bottomFloatingBar: some View {
        VStack {
            Spacer()
            LiquidGlassContainer(spacing: 18) {
                HStack(spacing: 18) {
                    Button {
                        Task { await viewModel.onRefresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .frame(width: 42, height: 42)
                    }
                    .liquidGlassButtonStyle()

                    Button {
                        presentedSheet = .sources
                    } label: {
                        Label(viewModel.activeSourceEngine.name, systemImage: viewModel.activeSourceEngine.kind.systemImage)
                            .lineLimit(1)
                            .frame(maxWidth: 168)
                    }
                    .liquidGlassButtonStyle(prominent: true)

                    Button {
                        presentedSheet = .filters
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .frame(width: 42, height: 42)
                    }
                    .liquidGlassButtonStyle()
                }
                .font(.headline)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .liquidGlassSurface(cornerRadius: 28)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 16)
        }
        .ignoresSafeArea(.keyboard)
    }
}

private enum BrowseSheet: Hashable, Identifiable {
    case filters
    case sources

    var id: Self { self }
}
