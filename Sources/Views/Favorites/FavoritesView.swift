import SwiftUI

struct FavoritesView: View {
    @Environment(ImageLoader.self) private var imageLoader
    @State private var favoriteWallpapers: [WallpaperItem] = []
    @State private var selectedWallpaper: WallpaperItem?

    private let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 12)
    ]

    var body: some View {
        Group {
            if favoriteWallpapers.isEmpty {
                ContentUnavailableView(
                    "暂无收藏",
                    systemImage: "heart",
                    description: Text("你收藏的壁纸会显示在这里")
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(favoriteWallpapers) { wallpaper in
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
            }
        }
        .navigationTitle("收藏")
        .sheet(item: $selectedWallpaper) { wallpaper in
            WallpaperDetailView(wallpaper: wallpaper)
        }
    }
}


