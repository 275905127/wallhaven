import SwiftUI

struct BrowseView: View {
    @State private var viewModel: BrowseViewModel
    @State private var searchText = ""
    @State private var selectedWallpaper: Wallpaper?
    @State private var searchTask: Task<Void, Never>?

    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 240), spacing: 10)
    ]

    init(viewModel: BrowseViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                sortingBar
                wallpaperGrid
            }
            .navigationTitle("壁纸库")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索壁纸...")
            .onChange(of: searchText) { _, newValue in
                debounceSearch(query: newValue)
            }
            .sheet(item: $selectedWallpaper) { wallpaper in
                DetailView(wallpaper: wallpaper, imageLoader: viewModel.imageLoader)
            }
            .task {
                await viewModel.refresh()
            }
        }
    }

    // MARK: - Sorting Bar

    @ViewBuilder
    private var sortingBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.sortingOptions, id: \.self) { option in
                    SortChip(
                        title: option.displayName,
                        isSelected: viewModel.currentSorting == option
                    )
                    .onTapGesture {
                        Task { await viewModel.selectSorting(option) }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(.bar)
    }

    // MARK: - Wallpaper Grid

    @ViewBuilder
    private var wallpaperGrid: some View {
        Group {
            if viewModel.wallpapers.isEmpty && !viewModel.isRefreshing {
                emptyStateView
            } else {
                scrollContent
            }
        }
    }

    private var scrollContent: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(viewModel.wallpapers) { wallpaper in
                    WallpaperCard(wallpaper: wallpaper, imageLoader: viewModel.imageLoader)
                        .onTapGesture { selectedWallpaper = wallpaper }
                        .onAppear {
                            Task { await viewModel.loadNextPageIfNeeded(currentItem: wallpaper) }
                        }
                }

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .gridCellColumns(columns.count)
                }
            }
            .padding(10)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView(
            viewModel.currentQuery.isEmpty ? "探索壁纸" : "未找到",
            systemImage: viewModel.currentQuery.isEmpty ? "photo.on.rectangle.angled" : "magnifyingglass",
            description: Text(viewModel.currentQuery.isEmpty
                ? "下拉刷新开始浏览壁纸"
                : "未找到「\(viewModel.currentQuery)」相关壁纸")
        )
    }

    private func debounceSearch(query: String) {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            await viewModel.search(query: query)
        }
    }
}

// MARK: - Sort Chip

struct SortChip: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(isSelected ? .semibold : .regular)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.quaternary))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
            .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
