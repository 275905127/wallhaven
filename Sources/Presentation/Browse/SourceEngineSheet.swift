import SwiftUI

struct SourceEngineSheet: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: BrowseViewModel

    @State private var editingSource: WallpaperSourceEngine?
    @State private var isQuickAddPresented = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        isQuickAddPresented = true
                    } label: {
                        Label("傻瓜式添加图源", systemImage: "wand.and.stars")
                    }
                } footer: {
                    Text("粘贴图片直链、Wallhaven API 或普通 JSON API 地址，应用会自动选择合适的图源类型。")
                }

                Section("当前图源") {
                    ForEach(viewModel.sourceEngines) { source in
                        SourceEngineRow(
                            source: source,
                            isSelected: source.id == viewModel.activeSourceEngine.id
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            Task { await viewModel.onSourceSelected(source) }
                        }
                        .swipeActions(edge: .trailing) {
                            Button {
                                editingSource = source
                            } label: {
                                Label("编辑", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                Task { await viewModel.onSourceDeleted(source) }
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                            .disabled(viewModel.sourceEngines.count == 1)
                        }
                    }
                }

                Section {
                    Button {
                        editingSource = WallpaperSourceEngine.newDirectLinksSource()
                    } label: {
                        Label("添加图片直链图源", systemImage: WallpaperSourceEngineKind.directLinks.systemImage)
                    }

                    Button {
                        editingSource = WallpaperSourceEngine.newJSONAPISource()
                    } label: {
                        Label("添加 JSON API 图源", systemImage: WallpaperSourceEngineKind.jsonAPI.systemImage)
                    }

                    Button {
                        editingSource = WallpaperSourceEngine.newWallhavenCompatibleSource()
                    } label: {
                        Label("添加 Wallhaven 兼容图源", systemImage: WallpaperSourceEngineKind.wallhaven.systemImage)
                    }
                }
            }
            .navigationTitle("图源")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .sheet(item: $editingSource) { source in
                SourceEngineEditor(source: source) { updatedSource in
                    Task { await viewModel.onSourceSaved(updatedSource) }
                }
            }
            .sheet(isPresented: $isQuickAddPresented) {
                QuickSourceAddSheet { source in
                    Task { await viewModel.onSourceSaved(source) }
                }
            }
            .presentationDetents([.large])
            .presentationBackground(.thinMaterial)
        }
    }
}

private struct SourceEngineRow: View {
    let source: WallpaperSourceEngine
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: source.kind.systemImage)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(source.name)
                    .font(.body.weight(.medium))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.tint)
            }
        }
        .padding(.vertical, 4)
    }

    private var subtitle: String {
        switch source.kind {
        case .wallhaven:
            return source.request.normalizedBaseURL
        case .jsonAPI:
            return source.request.normalizedBaseURL.isEmpty ? "未配置 API 地址" : source.request.normalizedBaseURL
        case .directLinks:
            return "\(source.directImages.count) 张图片"
        }
    }
}

private struct QuickSourceAddSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var input = ""

    let onSave: (WallpaperSourceEngine) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("图源名称") {
                    TextField("可不填，自动命名", text: $name)
                }

                Section {
                    TextEditor(text: $input)
                        .font(.body.monospaced())
                        .frame(minHeight: 220)
                } header: {
                    Text("粘贴地址")
                } footer: {
                    Text("多行图片地址会生成直链图源；Wallhaven API 会生成兼容图源；其他地址会生成 JSON API 图源。")
                }

                Section("会自动识别") {
                    Label("图片直链列表", systemImage: WallpaperSourceEngineKind.directLinks.systemImage)
                    Label("Wallhaven 兼容 API", systemImage: WallpaperSourceEngineKind.wallhaven.systemImage)
                    Label("普通 JSON API", systemImage: WallpaperSourceEngineKind.jsonAPI.systemImage)
                }
            }
            .navigationTitle("添加图源")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        onSave(WallpaperSourceEngine.smartSource(name: name, input: input))
                        dismiss()
                    }
                    .disabled(input.lines().isEmpty)
                }
            }
        }
        .presentationDetents([.large])
        .presentationBackground(.thinMaterial)
    }
}

private struct SourceEngineEditor: View {
    @Environment(\.dismiss) private var dismiss

    @State private var draft: WallpaperSourceEngine
    @State private var directImagesText: String
    @State private var staticQueryText: String

    let onSave: (WallpaperSourceEngine) -> Void

    init(source: WallpaperSourceEngine, onSave: @escaping (WallpaperSourceEngine) -> Void) {
        _draft = State(initialValue: source)
        _directImagesText = State(initialValue: source.directImages.joined(separator: "\n"))
        _staticQueryText = State(initialValue: source.request.staticQueryItems.map { "\($0.name)=\($0.value)" }.joined(separator: "\n"))
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("名称", text: $draft.name)
                    Picker("类型", selection: $draft.kind) {
                        ForEach(WallpaperSourceEngineKind.allCases) { kind in
                            Label(kind.displayName, systemImage: kind.systemImage).tag(kind)
                        }
                    }
                }

                if draft.kind == .directLinks {
                    Section {
                        TextEditor(text: $directImagesText)
                            .font(.body.monospaced())
                            .frame(minHeight: 220)
                    } header: {
                        Text("图片 URL")
                    } footer: {
                        Text("每行一个图片地址。直链图源不依赖内置 API，搜索会按 URL 文本过滤。")
                    }
                } else {
                    requestSection
                }

                if draft.kind == .jsonAPI {
                    mappingSection
                }
            }
            .navigationTitle("编辑图源")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        draft.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
                        draft.directImages = directImagesText.lines()
                        draft.request.staticQueryItems = staticQueryText.queryItems()
                        onSave(draft)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private var requestSection: some View {
        Section {
            TextField("Base URL", text: $draft.request.baseURL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            TextField("Path", text: $draft.request.pathTemplate)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            TextField("分页参数名", text: $draft.request.pageQueryName)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            TextField("搜索参数名", text: $draft.request.searchQueryName)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            SecureField("API Key", text: $draft.apiKey)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            TextEditor(text: $staticQueryText)
                .font(.body.monospaced())
                .frame(minHeight: 88)
        } header: {
            Text("请求")
        } footer: {
            Text("固定查询参数每行一个，例如 categories=111。API Key 会作为 apikey 参数发送。")
        }
    }

    private var mappingSection: some View {
        Section {
            TextField("列表路径", text: $draft.mapping.itemsPath)
            TextField("ID 路径", text: $draft.mapping.idPath)
            TextField("缩略图 URL 路径", text: $draft.mapping.thumbnailURLPath)
            TextField("原图 URL 路径", text: $draft.mapping.fullImageURLPath)
            TextField("标题路径", text: $draft.mapping.titlePath)
            TextField("作者路径", text: $draft.mapping.authorPath)
            TextField("宽度路径", text: $draft.mapping.widthPath)
            TextField("高度路径", text: $draft.mapping.heightPath)
            TextField("最后一页路径", text: $draft.mapping.lastPagePath)
        } header: {
            Text("JSON 映射")
        } footer: {
            Text("路径使用点号访问嵌套字段，数组下标也可作为路径段，例如 data.0.url。")
        }
    }

    private var canSave: Bool {
        let hasName = !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        switch draft.kind {
        case .directLinks:
            return hasName && !directImagesText.lines().isEmpty
        case .wallhaven, .jsonAPI:
            return hasName && !draft.request.normalizedBaseURL.isEmpty
        }
    }
}

private extension String {
    func lines() -> [String] {
        split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    func queryItems() -> [SourceEngineQueryItem] {
        lines().compactMap { line in
            let parts = line.split(separator: "=", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { return nil }
            let name = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let value = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return nil }
            return SourceEngineQueryItem(name: name, value: value)
        }
    }
}
