import SwiftUI

struct BrowseView: View {
    @State private var viewModel: BrowseViewModel
    @State private var searchText = ""
    @State private var selectedWallpaper: Wallpaper?
    @State private var searchTask: Task<Void, Never>?
    @State private var isAPIKeyPresented = false

    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 240), spacing: 10)
    ]

    init(viewModel: BrowseViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                VStack(spacing: 0) {
                    sourceControls
                    wallpaperGrid
                }
            }
            .navigationTitle("Wallhaven")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isAPIKeyPresented = true
                    } label: {
                        Image(systemName: viewModel.sourceConfiguration.hasAPIKey ? "key.fill" : "key")
                    }
                    .liquidGlassButtonStyle()
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索壁纸...")
            .onChange(of: searchText) { _, newValue in
                viewModel.onSearchDebounced(query: newValue, searchTask: &searchTask)
            }
            .sheet(item: $selectedWallpaper) { wallpaper in
                DetailView(wallpaper: wallpaper, imageLoader: viewModel.imageLoader)
            }
            .sheet(isPresented: $isAPIKeyPresented) {
                APIKeySheet(apiKey: viewModel.sourceConfiguration.apiKey) { apiKey in
                    Task { await viewModel.onAPIKeyChanged(apiKey) }
                }
            }
            .task {
                await viewModel.onAppear()
            }
        }
    }

    @ViewBuilder
    private var sourceControls: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LiquidGlassContainer(spacing: 10) {
                HStack(spacing: 8) {
                    sortingMenu
                    if viewModel.currentSorting == .toplist {
                        topRangeMenu
                    }
                    orderMenu
                    ForEach(viewModel.categoryOptions) { category in
                        SourceToggleChip(
                            title: category.displayName,
                            systemImage: category.systemImage,
                            isSelected: viewModel.sourceConfiguration.categories.contains(category),
                            isEnabled: true
                        ) {
                            Task { await viewModel.onCategoryToggled(category) }
                        }
                    }
                    ForEach(viewModel.purityOptions) { purity in
                        SourceToggleChip(
                            title: purity.displayName,
                            systemImage: purity.systemImage,
                            isSelected: viewModel.sourceConfiguration.purities.contains(purity),
                            isEnabled: purity != .nsfw || viewModel.sourceConfiguration.hasAPIKey
                        ) {
                            Task { await viewModel.onPurityToggled(purity) }
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
        }
        .background(.bar)
    }

    private var sortingMenu: some View {
        Menu {
            ForEach(viewModel.sortingOptions, id: \.self) { option in
                Button {
                    Task { await viewModel.onSortSelected(option) }
                } label: {
                    Label(option.displayName, systemImage: viewModel.currentSorting == option ? "checkmark" : "arrow.up.arrow.down")
                }
            }
        } label: {
            SourceMenuLabel(title: viewModel.currentSorting.displayName, systemImage: "arrow.up.arrow.down.circle")
        }
    }

    private var topRangeMenu: some View {
        Menu {
            ForEach(viewModel.topRangeOptions) { range in
                Button {
                    Task { await viewModel.onTopRangeSelected(range) }
                } label: {
                    Label(range.displayName, systemImage: viewModel.sourceConfiguration.topRange == range ? "checkmark" : "calendar")
                }
            }
        } label: {
            SourceMenuLabel(title: viewModel.sourceConfiguration.topRange.displayName, systemImage: "calendar")
        }
    }

    private var orderMenu: some View {
        Menu {
            ForEach(viewModel.orderOptions) { order in
                Button {
                    Task { await viewModel.onOrderSelected(order) }
                } label: {
                    Label(order.displayName, systemImage: viewModel.sourceConfiguration.order == order ? "checkmark" : "arrow.up.arrow.down")
                }
            }
        } label: {
            SourceMenuLabel(
                title: viewModel.sourceConfiguration.order.displayName,
                systemImage: viewModel.sourceConfiguration.order == .descending ? "arrow.down" : "arrow.up"
            )
        }
    }

    @ViewBuilder
    private var wallpaperGrid: some View {
        if viewModel.wallpapers.isEmpty && viewModel.isRefreshing {
            loadingStateView
        } else if viewModel.wallpapers.isEmpty && !viewModel.isRefreshing {
            if let error = viewModel.error {
                errorStateView(error)
            } else {
                emptyStateView
            }
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(Array(viewModel.wallpapers.enumerated()), id: \.element.id) { index, wallpaper in
                        WallpaperCard(wallpaper: wallpaper, viewModel: viewModel)
                            .onTapGesture { selectedWallpaper = wallpaper }
                            .onAppear { viewModel.onItemAppear(index: index) }
                    }
                    if viewModel.isLoading {
                        ProgressView().frame(maxWidth: .infinity).padding().gridCellColumns(columns.count)
                    }
                }
                .padding(10)
            }
            .refreshable { await viewModel.onRefresh() }
            .overlay(alignment: .bottom) {
                if let error = viewModel.error {
                    errorBanner(error)
                }
            }
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView(
            viewModel.currentQuery.isEmpty ? "探索壁纸" : "未找到",
            systemImage: viewModel.currentQuery.isEmpty ? "photo.on.rectangle.angled" : "magnifyingglass",
            description: Text(viewModel.currentQuery.isEmpty ? "下拉刷新开始浏览壁纸" : "未找到相关壁纸")
        )
    }

    private func errorStateView(_ error: NetworkError) -> some View {
        ContentUnavailableView {
            Label("加载失败", systemImage: "wifi.exclamationmark")
        } description: {
            Text(error.localizedDescription)
        } actions: {
            Button("重试") {
                Task { await viewModel.onRefresh() }
            }
            .liquidGlassButtonStyle(prominent: true)
        }
    }

    private var loadingStateView: some View {
        ProgressView()
            .controlSize(.large)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorBanner(_ error: NetworkError) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(error.localizedDescription)
                .font(.footnote)
                .lineLimit(2)
            Spacer(minLength: 8)
            Button("重试") {
                Task { await viewModel.onRefresh() }
            }
            .font(.footnote.weight(.semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .liquidGlassSurface(cornerRadius: 16, tint: .red.opacity(0.18))
        .padding()
    }
}

private struct SourceMenuLabel: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.semibold))
            .labelStyle(.titleAndIcon)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .liquidGlassCapsule(isInteractive: true)
    }
}

private struct SourceToggleChip: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : systemImage)
                    .font(.caption)
                Text(title)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(isEnabled ? .primary : .secondary)
            .liquidGlassCapsule(tint: isSelected ? .accentColor.opacity(0.22) : nil, isInteractive: isEnabled)
            .opacity(isEnabled ? 1 : 0.45)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

private struct APIKeySheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey: String
    let onSave: (String) -> Void

    init(apiKey: String, onSave: @escaping (String) -> Void) {
        _apiKey = State(initialValue: apiKey)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Wallhaven") {
                    SecureField("API Key", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button(role: .destructive) {
                        apiKey = ""
                    } label: {
                        Label("清除", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("图源密钥")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(apiKey)
                        dismiss()
                    }
                }
            }
            .presentationDetents([.medium])
            .presentationBackground(.thinMaterial)
        }
    }
}
