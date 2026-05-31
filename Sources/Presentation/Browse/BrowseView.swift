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
            }
            .navigationTitle("Wallhaven")
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bottomFloatingBar
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
        .padding(.bottom, 12)
    }

    private var bottomFloatingBar: some View {
        LiquidGlassContainer(spacing: 10) {
            HStack(spacing: 6) {
                BottomBarButton(title: "刷新", systemImage: "arrow.clockwise") {
                    Task { await viewModel.onRefresh() }
                }

                BottomSourceButton(
                    sourceName: viewModel.activeSourceEngine.name,
                    systemImage: viewModel.activeSourceEngine.kind.systemImage
                ) {
                    presentedSheet = .sources
                }

                BottomBarButton(title: "筛选", systemImage: "slider.horizontal.3") {
                    presentedSheet = .filters
                }
            }
            .padding(6)
            .frame(maxWidth: 430)
            .liquidGlassSurface(cornerRadius: 32)
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
        .padding(.bottom, 8)
        .background(.clear)
    }
}

private struct BottomBarButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: systemImage)
                    .font(.system(size: 19, weight: .semibold))
                Text(title)
                    .font(.caption2.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .foregroundStyle(.secondary)
            .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .buttonStyle(.plain)
        .liquidGlassSurface(cornerRadius: 26, isInteractive: true)
    }
}

private struct BottomSourceButton: View {
    let sourceName: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: systemImage)
                    .font(.system(size: 19, weight: .semibold))
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 1) {
                    Text("图源")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text(sourceName)
                        .font(.footnote.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .padding(.horizontal, 12)
            .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .liquidGlassSurface(cornerRadius: 26, tint: .accentColor.opacity(0.18), isInteractive: true)
    }
}

private enum BrowseSheet: Hashable, Identifiable {
    case filters
    case sources

    var id: Self { self }
}
