import SwiftUI
import SwiftData

struct BrowseView: View {
    @Environment(ImageLoader.self) private var imageLoader
    @Environment(WallpaperService.self) private var wallpaperService
    @Query(filter: #Predicate<WallpaperSource> { $0.isEnabled == true },
            sort: \WallpaperSource.sortOrder)
    private var sources: [WallpaperSource]

    @State private var wallpapers: [WallpaperItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedWallpaper: WallpaperItem?
    @State private var searchText = ""

    private let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 12)
    ]

    var body: some View {
        Group {
            if #available(iOS 26, *) {
                content
            } else {
                content
            }
        }
        .navigationTitle("壁纸库")
        .searchable(text: $searchText, prompt: "搜索壁纸")
        .task {
            await loadAllWallpapers()
        }
        .sheet(item: $selectedWallpaper) { wallpaper in
            WallpaperDetailView(wallpaper: wallpaper)
        }
        .overlay {
            if isLoading && wallpapers.isEmpty {
                ProgressView()
                    .scaleEffect(1.5)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if wallpapers.isEmpty && !isLoading {
            emptyStateView
        } else {
            wallpaperGrid
        }
    }

    private var wallpaperGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(filteredWallpapers) { wallpaper in
                    WallpaperCardView(
                        wallpaper: wallpaper,
                        imageLoader: imageLoader
                    )
                    .onTapGesture {
                        selectedWallpaper = wallpaper
                    }
                }
            }
            .padding(12)
        }
        .refreshable {
            await loadAllWallpapers()
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView(
            "暂无壁纸",
            systemImage: "photo.on.rectangle.angled",
            description: Text(sources.isEmpty
                ? "请先添加一个壁纸图源"
                : "下拉刷新或检查你的图源")
        )
    }

    private var filteredWallpapers: [WallpaperItem] {
        if searchText.isEmpty {
            return wallpapers
        }
        return wallpapers.filter { wallpaper in
            wallpaper.title?.localizedCaseInsensitiveContains(searchText) == true ||
            wallpaper.author?.localizedCaseInsensitiveContains(searchText) == true
        }
    }

    private func loadAllWallpapers() async {
        guard !sources.isEmpty else {
            wallpapers = []
            return
        }

        isLoading = true
        errorMessage = nil

        var allWallpapers: [WallpaperItem] = []
        for source in sources {
            do {
                let items = try await wallpaperService.fetchWallpapers(from: source)
                allWallpapers.append(contentsOf: items)
            } catch {
                errorMessage = error.localizedDescription
            }
        }

        wallpapers = allWallpapers
        isLoading = false
    }
}

