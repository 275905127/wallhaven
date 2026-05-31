import SwiftUI

struct FilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: BrowseViewModel
    let showsDoneButton: Bool

    @State private var apiKey: String

    init(viewModel: BrowseViewModel, showsDoneButton: Bool = true) {
        self.viewModel = viewModel
        self.showsDoneButton = showsDoneButton
        _apiKey = State(initialValue: viewModel.sourceConfiguration.apiKey)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("排序") {
                    Picker("排序方式", selection: Binding(
                        get: { viewModel.currentSorting },
                        set: { sorting in Task { await viewModel.onSortSelected(sorting) } }
                    )) {
                        ForEach(viewModel.sortingOptions, id: \.self) { sorting in
                            Text(sorting.displayName).tag(sorting)
                        }
                    }

                    Picker("顺序", selection: Binding(
                        get: { viewModel.sourceConfiguration.order },
                        set: { order in Task { await viewModel.onOrderSelected(order) } }
                    )) {
                        ForEach(viewModel.orderOptions) { order in
                            Text(order.displayName).tag(order)
                        }
                    }

                    if viewModel.currentSorting == .toplist {
                        Picker("榜单范围", selection: Binding(
                            get: { viewModel.sourceConfiguration.topRange },
                            set: { range in Task { await viewModel.onTopRangeSelected(range) } }
                        )) {
                            ForEach(viewModel.topRangeOptions) { range in
                                Text(range.displayName).tag(range)
                            }
                        }
                    }
                }

                Section("分类") {
                    ForEach(viewModel.categoryOptions) { category in
                        Toggle(isOn: Binding(
                            get: { viewModel.sourceConfiguration.categories.contains(category) },
                            set: { _ in Task { await viewModel.onCategoryToggled(category) } }
                        )) {
                            Label(category.displayName, systemImage: category.systemImage)
                        }
                    }
                }

                Section("分级") {
                    ForEach(viewModel.purityOptions) { purity in
                        Toggle(isOn: Binding(
                            get: { viewModel.sourceConfiguration.purities.contains(purity) },
                            set: { _ in Task { await viewModel.onPurityToggled(purity) } }
                        )) {
                            Label(purity.displayName, systemImage: purity.systemImage)
                        }
                        .disabled(purity == .nsfw && !viewModel.sourceConfiguration.hasAPIKey && !viewModel.activeSourceEngine.hasAPIKey)
                    }
                }

                Section("Wallhaven API Key") {
                    SecureField("API Key", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("保存密钥") {
                        Task { await viewModel.onAPIKeyChanged(apiKey) }
                    }
                }
            }
            .navigationTitle("筛选")
            .toolbar {
                if showsDoneButton {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("完成") { dismiss() }
                    }
                }
            }
            .presentationDetents([.large])
        }
    }
}
