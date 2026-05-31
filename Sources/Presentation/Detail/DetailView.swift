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
            Group {
                if let image = fullImage {
                    ZoomableScrollView {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                } else if isLoading {
                    ProgressView()
                } else if didFailLoading {
                    ContentUnavailableView {
                        Label("图片加载失败", systemImage: "photo.badge.exclamationmark")
                    } description: {
                        Text("请检查网络后重试")
                    } actions: {
                        Button("重试") {
                            Task { await loadFullImage() }
                        }
                        .buttonStyle(.glassProminent)
                    }
                }
            }
            .navigationTitle(wallpaper.title ?? wallpaper.categoryDisplay)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.glass)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        ShareLink(item: wallpaper.fullImageURL) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .buttonStyle(.glass)

                        Button {
                            Task { await saveToPhotos() }
                        } label: {
                            Image(systemName: "square.and.arrow.down")
                        }
                        .buttonStyle(.glass)
                    }
                }
            }
            .task(id: wallpaper.fullImageURL) {
                await loadFullImage()
            }
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
