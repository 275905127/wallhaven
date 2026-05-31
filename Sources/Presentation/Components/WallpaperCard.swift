import SwiftUI

struct WallpaperCard: View {
    let wallpaper: Wallpaper
    let imageLoader: ImageLoader

    @State private var image: UIImage?

    var body: some View {
        VStack(spacing: 0) {
            imageSection
            infoBar
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }

    @ViewBuilder
    private var imageSection: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(.quaternary)
                    .overlay { ProgressView().scaleEffect(0.8) }
            }
        }
        .frame(minHeight: 180)
        .clipped()
        .task {
            image = await imageLoader.loadImage(from: wallpaper.thumbnailURL)
        }
    }

    private var infoBar: some View {
        HStack(spacing: 4) {
            if let title = wallpaper.title {
                Text(title)
                    .font(.caption2)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "eye")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
            Text(wallpaper.formattedViews)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
    }
}
