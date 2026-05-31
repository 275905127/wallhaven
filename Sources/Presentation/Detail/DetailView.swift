import SwiftUI

struct DetailView: View {
    let wallpaper: Wallpaper
    let imageLoader: ImageLoader

    @Environment(\.dismiss) private var dismiss
    @State private var fullImage: UIImage?
    @State private var isLoading = true
    @State private var didFailLoading = false

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
                } else if didFailLoading {
                    ContentUnavailableView {
                        Label("图片加载失败", systemImage: "photo.badge.exclamationmark")
                    } description: {
                        Text("请检查网络后重试")
                    } actions: {
                        Button("重试") {
                            Task { await loadFullImage() }
                        }
                        .liquidGlassButtonStyle(prominent: true)
                    }
                    .foregroundStyle(.white)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    detailToolbarButton(systemImage: "xmark") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        ShareLink(item: wallpaper.fullImageURL) {
                            Image(systemName: "square.and.arrow.up")
                                .frame(width: 36, height: 36)
                        }
                        .liquidGlassSurface(cornerRadius: 18, isInteractive: true)
                        detailToolbarButton(systemImage: "square.and.arrow.down") {
                            Task { await saveToPhotos() }
                        }
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                }
            }
            .task(id: wallpaper.fullImageURL) {
                await loadFullImage()
            }
        }
    }

    private var infoOverlay: some View {
        LiquidGlassContainer(spacing: 14) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(wallpaper.title ?? wallpaper.categoryDisplay)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text("\(wallpaper.resolution) · \(wallpaper.formattedFileSize) · \(wallpaper.purityDisplay)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                HStack(spacing: 10) {
                    Label(wallpaper.formattedViews, systemImage: "eye")
                    Label("\(wallpaper.favorites)", systemImage: "heart.fill")
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.76))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .liquidGlassSurface(cornerRadius: 20)
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
    }

    private func saveToPhotos() async {
        guard let image = fullImage else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }

    private func loadFullImage() async {
        isLoading = true
        didFailLoading = false
        fullImage = await imageLoader.loadImage(from: wallpaper.fullImageURL)
        didFailLoading = fullImage == nil
        isLoading = false
    }

    private func detailToolbarButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .frame(width: 36, height: 36)
        }
        .font(.headline)
        .foregroundStyle(.white)
        .liquidGlassSurface(cornerRadius: 18, isInteractive: true)
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
