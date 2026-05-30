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
                    "No Favorites",
                    systemImage: "heart",
                    description: Text("Your favorite wallpapers will appear here.")
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
        .navigationTitle("Favorites")
        .sheet(item: $selectedWallpaper) { wallpaper in
            WallpaperDetailView(wallpaper: wallpaper)
        }
    }
}

