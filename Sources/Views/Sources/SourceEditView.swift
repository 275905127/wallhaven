import SwiftUI
import SwiftData

struct SourceEditView: View {
    let source: WallpaperSource?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var urlString: String
    @State private var sourceType: SourceType
    @State private var isEnabled: Bool
    @State private var showValidationError = false
    @State private var validationMessage = ""

    private var isEditing: Bool { source != nil }

    init(source: WallpaperSource?) {
        self.source = source
        _name = State(initialValue: source?.name ?? "")
        _urlString = State(initialValue: source?.urlString ?? "")
        _sourceType = State(initialValue: source?.type ?? .wallhavenAPI)
        _isEnabled = State(initialValue: source?.isEnabled ?? true)
    }

    var body: some View {
        NavigationStack {
            Form {
                sourceInfoSection
                typeSection
                settingsSection
            }
            .navigationTitle(isEditing ? "编辑图源" : "添加图源")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if #available(iOS 26, *) {
                        Button(isEditing ? "保存" : "添加") { saveSource() }
                            .buttonStyle(.glassProminent)
                            .disabled(!isValid)
                    } else {
                        Button(isEditing ? "保存" : "添加") { saveSource() }
                            .disabled(!isValid)
                    }
                }
            }
            .alert("输入错误", isPresented: $showValidationError) {
                Button("OK") {}
            } message: {
                Text(validationMessage)
            }
        }
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !urlString.trimmingCharacters(in: .whitespaces).isEmpty
    }

    @ViewBuilder
    private var sourceInfoSection: some View {
        Section {
            TextField("图源名称", text: $name).textContentType(.name)
            TextField("URL 或 API 端点", text: $urlString)
                .keyboardType(.URL).textContentType(.URL)
                .autocapitalization(.none).disableAutocorrection(true)
        } header: {
            Text("图源信息")
        } footer: {
            Text(sourceType == .directURL
                ? "输入返回壁纸 JSON 数组的 URL 地址"
                : "输入 API 端点地址，如需 API Key 请一并包含")
        }
    }

    @ViewBuilder
    private var typeSection: some View {
        Section("图源类型") {
            Picker("类型", selection: $sourceType) {
                ForEach(SourceType.allCases, id: \.self) { type in
                    HStack {
                        Image(systemName: type.iconName)
                        Text(type.displayName)
                    }.tag(type)
                }
            }
            .pickerStyle(.menu)
        }
    }

    @ViewBuilder
    private var settingsSection: some View {
        Section { Toggle("已启用", isOn: $isEnabled) }
            header: { Text("设置") }
    }

    private func saveSource() {
        guard isValid else {
            validationMessage = "请填写图源名称和 URL"
            showValidationError = true
            return
        }

        if let existingSource = source {
            existingSource.name = name.trimmingCharacters(in: .whitespaces)
            existingSource.urlString = urlString.trimmingCharacters(in: .whitespaces)
            existingSource.sourceType = sourceType.rawValue
            existingSource.isEnabled = isEnabled
        } else {
            let newSource = WallpaperSource(
                name: name.trimmingCharacters(in: .whitespaces),
                urlString: urlString.trimmingCharacters(in: .whitespaces),
                sourceType: sourceType,
                isEnabled: isEnabled,
                sortOrder: (try? modelContext.fetchCount(FetchDescriptor<WallpaperSource>())) ?? 0
            )
            modelContext.insert(newSource)
        }
        dismiss()
    }
}

