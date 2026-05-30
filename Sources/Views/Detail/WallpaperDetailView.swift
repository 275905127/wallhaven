import SwiftUI
import PhotosUI

struct WallpaperDetailView: View {
    let wallpaper: WallpaperItem

    @Environment(ImageLoader.self) private var imageLoader
    @Environment(\.dismiss) private var dismiss

    @State private var fullImage: UIImage?
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var isFavorite = false
    @State private var showSavedAlert = false

    var body: some View {
        NavigationStack {
            detailContent
                .toolbar { toolbarContent }
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let image = fullImage {
                ZoomableScrollView {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                .overlay(alignment: .bottom) {
                    actionBar
                }
            } else if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            } else if let error = loadError {
                ContentUnavailableView(
                    "Failed to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            }
        }
        .task {
            fullImage = await imageLoader.loadImage(from: wallpaper.fullImageURL)
            isLoading = false
            if fullImage == nil {
                loadError = "Could not load image"
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if #available(iOS 26, *) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.glass)
            } else {
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: 12) {
                if #available(iOS 26, *) {
                    Button { isFavorite.toggle() } label: {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                    }
                    .buttonStyle(.glass)
                    .tint(isFavorite ? .red : nil)
                } else {
                    Button { isFavorite.toggle() } label: {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.title2)
                            .foregroundStyle(isFavorite ? .red : .white)
                    }
                }

                Menu {
                    Button { Task { await saveToPhotos() } } label: {
                        Label("Save to Photos", systemImage: "square.and.arrow.down")
                    }
                    Button { Task { await setAsWallpaper() } } label: {
                        Label("Set as Wallpaper", systemImage: "house")
                    }
                    ShareLink(item: wallpaper.fullImageURL) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    if #available(iOS 26, *) {
                        Image(systemName: "ellipsis.circle")
                    } else {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.glass)
            }
        }
    }

    @ViewBuilder
    private var actionBar: some View {
        if #available(iOS 26, *) {
            GlassEffectContainer(spacing: 16) {
                HStack(spacing: 16) {
                    metadataSection
                    actionButtons
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .padding(.bottom, 32)
        } else {
            HStack(spacing: 16) {
                metadataSection
                Spacer()
                actionButtons
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
    }

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let title = wallpaper.title {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            HStack(spacing: 8) {
                if let resolution = wallpaper.resolution {
                    Text(resolution)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                Text("·").foregroundStyle(.white.opacity(0.5))
                Text(wallpaper.sourceName)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: 12) {
            if #available(iOS 26, *) {
                Button { Task { await saveToPhotos() } } label: {
                    Image(systemName: "square.and.arrow.down")
                }
                .buttonStyle(.glass)

                Button { Task { await setAsWallpaper() } } label: {
                    Image(systemName: "house")
                }
                .buttonStyle(.glassProminent)
            } else {
                Button { Task { await saveToPhotos() } } label: {
                    Image(systemName: "square.and.arrow.down")
                        .font(.title3).foregroundStyle(.white)
                        .padding(10).background(.ultraThinMaterial, in: Circle())
                }
                Button { Task { await setAsWallpaper() } } label: {
                    Image(systemName: "house")
                        .font(.title3).foregroundStyle(.white)
                        .padding(10).background(.white.opacity(0.3), in: Circle())
                }
            }
        }
    }

    private func saveToPhotos() async {
        guard let image = fullImage else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        showSavedAlert = true
    }

    private func setAsWallpaper() async {
        guard let image = fullImage else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        showSavedAlert = true
    }
}

// MARK: - ZoomableScrollView

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

// MARK: - View Extension

extension View {
    @ViewBuilder
    func ifAvailable<A: View>(iOS26 transform: (Self) -> A, fallback: ((Self) -> A)? = nil) -> some View {
        if #available(iOS 26, *) {
            transform(self)
        } else if let fallback {
            fallback(self)
        } else {
            self
        }
    }
}

