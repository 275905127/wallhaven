import SwiftUI

struct WallpaperCard: View {
    let wallpaper: Wallpaper
    let viewModel: BrowseViewModel
    let width: CGFloat
    let height: CGFloat

    @State private var image: UIImage?

    var body: some View {
        imageSection
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
}
