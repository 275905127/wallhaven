import SwiftUI

struct BrowseView: View {
    @State private var viewModel: BrowseViewModel
    @State private var searchText = ""
    @State private var selectedWallpaper: Wallpaper?
    @State private var searchTask: Task<Void, Never>?
    @State private var presentedSheet: BrowseSheet?
    @State private var isSearchPresented = false

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
            .searchable(
                text: $searchText,
                isPresented: $isSearchPresented,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "搜索壁纸..."
            )
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
            VStack(spacing: 8) {
                BottomSourceMiniBar(
                    sourceName: viewModel.activeSourceEngine.name,
                    systemImage: viewModel.activeSourceEngine.kind.systemImage,
                    isRefreshing: viewModel.isRefreshing
                ) {
                    presentedSheet = .sources
                } onRefresh: {
                    Task { await viewModel.onRefresh() }
                }

                HStack(spacing: 10) {
                    HStack(spacing: 2) {
                        BottomTabButton(title: "主页", systemImage: "house.fill", isSelected: true) { }
                        BottomTabButton(title: "图源", systemImage: "square.grid.2x2.fill", isSelected: false) {
                            presentedSheet = .sources
                        }
                        BottomTabButton(title: "刷新", systemImage: "arrow.clockwise", isSelected: false) {
                            Task { await viewModel.onRefresh() }
                        }
                        BottomTabButton(title: "筛选", systemImage: "slider.horizontal.3", isSelected: false) {
                            presentedSheet = .filters
                        }
                    }
                    .padding(6)
                    .liquidGlassSurface(cornerRadius: 34)

                    Button {
                        isSearchPresented = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 25, weight: .bold))
                            .frame(width: 66, height: 66)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.primary)
                    .liquidGlassSurface(cornerRadius: 33, isInteractive: true)
                }
                .frame(maxWidth: 430)
            }
            .frame(maxWidth: 430)
        }
        .padding(.horizontal, 14)
        .padding(.top, 6)
        .padding(.bottom, 8)
        .background(.clear)
    }
}

private struct BottomSourceMiniBar: View {
    let sourceName: String
    let systemImage: String
    let isRefreshing: Bool
    let onSources: () -> Void
    let onRefresh: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onSources) {
                HStack(spacing: 12) {
                    Image(systemName: systemImage)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 48, height: 48)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(sourceName)
                            .font(.headline.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Text("当前图源")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer(minLength: 8)

            Button(action: onRefresh) {
                Image(systemName: isRefreshing ? "pause.fill" : "play.fill")
                    .font(.system(size: 24, weight: .bold))
                    .frame(width: 42, height: 42)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)

            Button(action: onSources) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 23, weight: .bold))
                    .frame(width: 42, height: 42)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.leading, 12)
        .padding(.trailing, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: 430)
        .liquidGlassSurface(cornerRadius: 28)
    }
}

private struct BottomTabButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .bold))
                Text(title)
                    .font(.caption2.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .padding(.horizontal, 6)
            .foregroundStyle(isSelected ? Color.red : Color.primary)
            .background {
                if isSelected {
                    Capsule(style: .continuous)
                        .fill(.regularMaterial)
                }
            }
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private enum BrowseSheet: Hashable, Identifiable {
    case filters
    case sources

    var id: Self { self }
}
