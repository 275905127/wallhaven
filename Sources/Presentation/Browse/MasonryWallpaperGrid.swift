import SwiftUI

struct MasonryWallpaperGrid: View {
    let wallpapers: [Wallpaper]
    let viewModel: BrowseViewModel
    let onSelect: (Wallpaper) -> Void

    private let spacing: CGFloat = 10
    private let horizontalInset: CGFloat = 10
    private let bottomInset: CGFloat = 112

    var body: some View {
        GeometryReader { proxy in
            let columnCount = columnCount(for: proxy.size.width)
            let contentWidth = max(0, proxy.size.width - horizontalInset * 2)
            let columnWidth = max(120, (contentWidth - spacing * CGFloat(columnCount - 1)) / CGFloat(columnCount))
            let masonryColumns = columns(for: wallpapers, columnWidth: columnWidth, columnCount: columnCount)
            ScrollView {
                HStack(alignment: .top, spacing: spacing) {
                    ForEach(masonryColumns.indices, id: \.self) { columnIndex in
                        LazyVStack(spacing: spacing) {
                            ForEach(masonryColumns[columnIndex]) { item in
                                WallpaperCard(
                                    wallpaper: item.wallpaper,
                                    viewModel: viewModel,
                                    height: item.height
                                )
                                .frame(width: columnWidth, height: item.height)
                                .onTapGesture { onSelect(item.wallpaper) }
                                .onAppear { viewModel.onItemAppear(index: item.index) }
                            }
                        }
                        .frame(width: columnWidth, alignment: .top)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .top)
                .padding(.horizontal, horizontalInset)
                .padding(.top, 10)
                .padding(.bottom, bottomInset)
            }
            .refreshable { await viewModel.onRefresh() }
        }
    }

    private func columnCount(for width: CGFloat) -> Int {
        width >= 760 ? 3 : 2
    }

    private func columns(for wallpapers: [Wallpaper], columnWidth: CGFloat, columnCount: Int) -> [[MasonryItem]] {
        var columns = Array(repeating: [MasonryItem](), count: columnCount)
        var columnHeights = [CGFloat](repeating: 0, count: columnCount)

        for (index, wallpaper) in wallpapers.enumerated() {
            let height = estimatedHeight(for: wallpaper, columnWidth: columnWidth)
            let targetColumn = columnHeights.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
            columns[targetColumn].append(MasonryItem(index: index, wallpaper: wallpaper, height: height))
            columnHeights[targetColumn] += height + spacing
        }

        return columns
    }

    private func estimatedHeight(for wallpaper: Wallpaper, columnWidth: CGFloat) -> CGFloat {
        let components = wallpaper.resolution.split(separator: "x").compactMap { Double($0) }
        guard components.count == 2, components[0] > 0, components[1] > 0 else {
            return columnWidth * 1.28
        }

        let ratio = components[1] / components[0]
        return min(max(columnWidth * ratio, columnWidth * 0.72), columnWidth * 1.86)
    }
}

private struct MasonryItem: Identifiable {
    let index: Int
    let wallpaper: Wallpaper
    let height: CGFloat

    var id: String { wallpaper.id }
}
