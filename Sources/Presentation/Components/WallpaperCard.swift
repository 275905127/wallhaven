import SwiftUI

struct WallpaperCard: View {
    let wallpaper: Wallpaper
    let viewModel: BrowseViewModel
    let width: CGFloat
    let height: CGFloat

    @State private var image: UIImage?

    var body: some View {
        ZStack(alignment: .bottom) {
            imageSection
            infoBar
        }
        .frame(width: width, height: height)
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.14), radius: 6, y: 3)
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
        .frame(width: width, height: height)
        .clipped()
        .task(id: wallpaper.thumbnailURL) {
            image = nil
            image = await viewModel.loadImage(from: wallpaper.thumbnailURL)
        }
    }

    private var infoBar: some View {
        LiquidGlassContainer(spacing: 8) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(wallpaper.title ?? wallpaper.categoryDisplay)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                    Text(wallpaper.resolution)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 4)
                Label(wallpaper.formattedViews, systemImage: "eye")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(width: max(0, width - 16))
            .liquidGlassSurface(cornerRadius: 12)
            .padding(8)
        }
    }
}
