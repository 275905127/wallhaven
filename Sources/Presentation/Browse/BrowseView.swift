import SwiftUI

struct BrowseView: View {
    @State private var viewModel: BrowseViewModel
    @State private var searchText = ""
    @State private var selectedWallpaper: Wallpaper?
    @State private var searchTask: Task<Void, Never>?
    @State private var presentedSheet: BrowseSheet?
    @State private var isSearchPresented = false
    @State private var selectedBottomTab: BottomTab = .home
    @Namespace private var bottomBarNamespace

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
            .onChange(of: presentedSheet) { _, sheet in
                guard sheet == nil else { return }
                selectBottomTab(.home)
            }
            .onChange(of: isSearchPresented) { _, isPresented in
                if isPresented {
                    selectBottomTab(.search)
                } else if selectedBottomTab == .search {
                    selectBottomTab(.home)
                }
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
                    presentSheet(.sources)
                } onRefresh: {
                    refreshFromBottomBar()
                }

                HStack(spacing: 10) {
                    BottomTabCluster(selectedTab: selectedBottomTab, namespace: bottomBarNamespace) { tab in
                        switch tab {
                        case .home:
                            selectBottomTab(.home)
                        case .sources:
                            presentSheet(.sources)
                        case .refresh:
                            refreshFromBottomBar()
                        case .filters:
                            presentSheet(.filters)
                        case .search:
                            isSearchPresented = true
                        }
                    }

                    Button {
                        selectBottomTab(.search)
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

    private func presentSheet(_ sheet: BrowseSheet) {
        switch sheet {
        case .filters:
            selectBottomTab(.filters)
        case .sources:
            selectBottomTab(.sources)
        }
        presentedSheet = sheet
    }

    private func refreshFromBottomBar() {
        selectBottomTab(.refresh)
        Task {
            await viewModel.onRefresh()
            try? await Task.sleep(nanoseconds: 240_000_000)
            await MainActor.run {
                guard presentedSheet == nil, !isSearchPresented else { return }
                selectBottomTab(.home)
            }
        }
    }

    private func selectBottomTab(_ tab: BottomTab) {
        withAnimation(.smooth(duration: 0.34, extraBounce: 0.12)) {
            selectedBottomTab = tab
        }
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

private struct BottomTabCluster: View {
    let selectedTab: BottomTab
    let namespace: Namespace.ID
    let onSelect: (BottomTab) -> Void

    var body: some View {
        HStack(spacing: 2) {
            ForEach(BottomTab.primaryTabs) { tab in
                BottomTabButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    namespace: namespace
                ) {
                    onSelect(tab)
                }
            }
        }
        .padding(6)
        .liquidGlassSurface(cornerRadius: 34)
    }
}

private struct BottomTabButton: View {
    let tab: BottomTab
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                if isSelected {
                    Capsule(style: .continuous)
                        .fill(.regularMaterial)
                        .matchedGeometryEffect(id: "bottom-tab-selection", in: namespace)
                        .liquidGlassSelection(id: "bottom-tab-selection", namespace: namespace)
                }

                VStack(spacing: 4) {
                    Image(systemName: tab.systemImage)
                        .font(.system(size: 22, weight: .bold))
                    Text(tab.title)
                        .font(.caption2.weight(.medium))
                }
                .foregroundStyle(isSelected ? Color.red : Color.primary)
                .scaleEffect(isSelected ? 1.04 : 0.94)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .padding(.horizontal, 6)
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
        .animation(.smooth(duration: 0.28, extraBounce: 0.12), value: isSelected)
    }
}

private enum BottomTab: String, CaseIterable, Identifiable {
    case home
    case sources
    case refresh
    case filters
    case search

    static let primaryTabs: [BottomTab] = [.home, .sources, .refresh, .filters]

    var id: Self { self }

    var title: String {
        switch self {
        case .home: return "主页"
        case .sources: return "图源"
        case .refresh: return "刷新"
        case .filters: return "筛选"
        case .search: return "搜索"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .sources: return "square.grid.2x2.fill"
        case .refresh: return "arrow.clockwise"
        case .filters: return "slider.horizontal.3"
        case .search: return "magnifyingglass"
        }
    }
}

private extension View {
    @ViewBuilder
    func liquidGlassSelection(id: String, namespace: Namespace.ID) -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(.regular.interactive(), in: .capsule)
                .glassEffectID(id, in: namespace)
        } else {
            self
        }
    }
}

private enum BrowseSheet: Hashable, Identifiable {
    case filters
    case sources

    var id: Self { self }
}
