import SwiftUI
import PhotosUI

struct DetailView: View {
    let wallpaper: Wallpaper
    let imageLoader: ImageLoader

    @Environment(\.dismiss) private var dismiss
    @State private var fullImage: UIImage?
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if let image = fullImage {
                    ZoomableScrollView {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                    .overlay(alignment: .bottom) { infoOverlay }
                } else if isLoading {
                    ProgressView().tint(.white)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2).foregroundStyle(.white)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        ShareLink(item: wallpaper.fullImageURL) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title2).foregroundStyle(.white)
                        }
                        Button {
                            Task { await saveToPhotos() }
                        } label: {
                            Image(systemName: "square.and.arrow.down")
                                .font(.title2).foregroundStyle(.white)
                        }
                    }
                }
            }
            .task {
                fullImage = await imageLoader.loadImage(from: wallpaper.fullImageURL)
                isLoading = false
            }
        }
    }

    private var infoOverlay: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                if let title = wallpaper.title {
                    Text(title).font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(.white).lineLimit(1)
                }
                Text("\(wallpaper.resolution) · \(wallpaper.formattedFileSize)")
                    .font(.caption).foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
            HStack(spacing: 12) {
                Label(wallpaper.formattedViews, systemImage: "eye")
                Label("\(wallpaper.favorites)", systemImage: "heart.fill")
            }
            .font(.caption).foregroundStyle(.white.opacity(0.7))
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 16).padding(.bottom, 32)
    }

    private func saveToPhotos() async {
        guard let image = fullImage else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
}

struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    @ViewBuilder let content: () -> Content

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.maximumZoomScale = 5.0
        scrollView.minimumZoomScale = 1.0
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bouncesZoom = true

        let hosting = UIHostingController(rootView: content())
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        hosting.view.backgroundColor = .clear
        scrollView.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            hosting.view.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            hosting.view.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
        ])
        context.coordinator.hostingController = hosting
        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        context.coordinator.hostingController?.rootView = content()
    }

    func makeCoordinator() -> Coordinator { Coordinator() }
    class Coordinator: NSObject, UIScrollViewDelegate {
        var hostingController: UIHostingController<Content>?
        func viewForZooming(in scrollView: UIScrollView) -> UIView? { hostingController?.view }
    }
}
