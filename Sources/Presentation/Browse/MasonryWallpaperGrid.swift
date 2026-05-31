import SwiftUI

struct MasonryWallpaperGrid: View {
    let wallpapers: [Wallpaper]
    let viewModel: BrowseViewModel
    let onSelect: (Wallpaper) -> Void

    private let spacing: CGFloat = 10
    private let horizontalInset: CGFloat = 10
    private let bottomInset: CGFloat = 18

    var body: some View {
        GeometryReader { proxy in
            let layout = MasonryLayout(
                wallpapers: wallpapers,
                containerWidth: proxy.size.width,
                spacing: spacing,
                horizontalInset: horizontalInset
            )

            ScrollView {
                ZStack(alignment: .topLeading) {
                    ForEach(layout.items) { item in
                        WallpaperCard(
                            wallpaper: item.wallpaper,
                            viewModel: viewModel,
                            height: item.frame.height
                        )
                        .frame(width: item.frame.width, height: item.frame.height)
                        .position(x: item.frame.midX, y: item.frame.midY)
                        .onTapGesture { onSelect(item.wallpaper) }
                    }
                }
                .frame(width: proxy.size.width, height: layout.contentHeight, alignment: .topLeading)
                .padding(.top, 10)
                .padding(.bottom, bottomInset)
            }
            .refreshable { await viewModel.onRefresh() }
            .onScrollGeometryChange(for: Bool.self) { geometry in
                guard !wallpapers.isEmpty else { return false }
                let visibleMaxY = geometry.contentOffset.y + geometry.containerSize.height
                let triggerY = max(0, geometry.contentSize.height - 900)
                return visibleMaxY >= triggerY
            } action: { _, isNearBottom in
                guard isNearBottom else { return }
                Task { @MainActor in
                    viewModel.onItemAppear(index: wallpapers.count - 1)
                }
            }
        }
    }
}

private struct MasonryLayout {
    let items: [MasonryItem]
    let contentHeight: CGFloat

    init(wallpapers: [Wallpaper], containerWidth: CGFloat, spacing: CGFloat, horizontalInset: CGFloat) {
        let columnCount = Self.columnCount(for: containerWidth)
        let contentWidth = max(0, containerWidth - horizontalInset * 2)
        let columnWidth = floor((contentWidth - spacing * CGFloat(columnCount - 1)) / CGFloat(columnCount))
        let safeColumnWidth = max(120, columnWidth)

        var columnHeights = [CGFloat](repeating: 0, count: columnCount)
        var layoutItems: [MasonryItem] = []
        layoutItems.reserveCapacity(wallpapers.count)

        for (index, wallpaper) in wallpapers.enumerated() {
            let targetColumn = columnHeights.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
            let height = Self.estimatedHeight(for: wallpaper, columnWidth: safeColumnWidth)
            let x = horizontalInset + CGFloat(targetColumn) * (safeColumnWidth + spacing)
            let y = columnHeights[targetColumn]
            let frame = CGRect(x: x, y: y, width: safeColumnWidth, height: height)

            layoutItems.append(MasonryItem(index: index, wallpaper: wallpaper, frame: frame))
            columnHeights[targetColumn] = frame.maxY + spacing
        }

        self.items = layoutItems
        self.contentHeight = max(0, (columnHeights.max() ?? 0) - spacing)
    }

    private static func columnCount(for width: CGFloat) -> Int {
        if width >= 900 { return 4 }
        if width >= 680 { return 3 }
        return 2
    }

    private static func estimatedHeight(for wallpaper: Wallpaper, columnWidth: CGFloat) -> CGFloat {
        guard let size = wallpaper.pixelSize, size.width > 0, size.height > 0 else {
            return columnWidth * 1.32
        }

        let ratio = size.height / size.width
        return min(max(columnWidth * ratio, columnWidth * 0.72), columnWidth * 2.15)
    }
}

private struct MasonryItem: Identifiable {
    let index: Int
    let wallpaper: Wallpaper
    let frame: CGRect

    var id: String { wallpaper.id }
}
