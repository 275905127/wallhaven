import SwiftUI

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
                        Image(uiImage: image).resizable().aspectRatio(contentMode: .fit)
                    }
                    .overlay(alignment: .bottom) { infoOverlay }
                } else if isLoading {
                    ProgressView().tint(.white)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill").font(.title2).foregroundStyle(.white)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        ShareLink(item: wallpaper.fullImageURL) {
                            Image(systemName: "square.and.arrow.up").font(.title2).foregroundStyle(.white)
                        }
                        Button { Task { await saveToPhotos() } } label: {
                            Image(systemName: "square.and.arrow.down").font(.title2).foregroundStyle(.white)
                        }
                    }
                }
            }
            .task { fullImage = await imageLoader.loadImage(from: wallpaper.fullImageURL); isLoading = false }
        }
    }

    private var infoOverlay: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                if let title = wallpaper.title {
                    Text(title).font(.subheadline).fontWeight(.semibold).foregroundStyle(.white).lineLimit(1)
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
        .background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 20))
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
        let sv = UIScrollView(); sv.delegate = context.coordinator
        sv.maximumZoomScale = 5; sv.minimumZoomScale = 1
        sv.showsHorizontalScrollIndicator = false; sv.showsVerticalScrollIndicator = false
        sv.bouncesZoom = true
        let host = UIHostingController(rootView: content())
        host.view.translatesAutoresizingMaskIntoConstraints = false; host.view.backgroundColor = .clear
        sv.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: sv.contentLayoutGuide.topAnchor),
            host.view.leadingAnchor.constraint(equalTo: sv.contentLayoutGuide.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: sv.contentLayoutGuide.trailingAnchor),
            host.view.bottomAnchor.constraint(equalTo: sv.contentLayoutGuide.bottomAnchor),
            host.view.widthAnchor.constraint(equalTo: sv.frameLayoutGuide.widthAnchor),
            host.view.heightAnchor.constraint(equalTo: sv.frameLayoutGuide.heightAnchor),
        ])
        context.coordinator.hostingController = host; return sv
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
