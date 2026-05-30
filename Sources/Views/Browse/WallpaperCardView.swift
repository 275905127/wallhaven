import SwiftUI

struct WallpaperCardView: View {
    let wallpaper: WallpaperItem
    let imageLoader: ImageLoader

    @State private var loadedImage: UIImage?
    @State private var loadFailed = false

    var body: some View {
        cardContent
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var cardContent: some View {
        VStack(spacing: 0) {
            imageSection
            infoSection
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    }

    @ViewBuilder
    private var imageSection: some View {
        Group {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if loadFailed {
                fallbackImage
            } else {
                loadingPlaceholder
            }
        }
        .frame(height: 240)
        .clipped()
        .task {
            loadedImage = await imageLoader.loadImage(from: wallpaper.thumbnailURL)
            loadFailed = loadedImage == nil
        }
    }

    private var loadingPlaceholder: some View {
        ZStack {
            Rectangle()
                .fill(.quaternary)
            ProgressView()
        }
    }

    private var fallbackImage: some View {
        ZStack {
            Rectangle()
                .fill(.quaternary)
            Image(systemName: "photo.badge.exclamationmark")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let title = wallpaper.title {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
            HStack {
                if let resolution = wallpaper.resolution {
                    Text(resolution)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(wallpaper.sourceName)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
    }
}
