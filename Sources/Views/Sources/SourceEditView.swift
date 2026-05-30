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
            .navigationTitle(isEditing ? "Edit Source" : "Add Source")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if #available(iOS 26, *) {
                        Button(isEditing ? "Save" : "Add") { saveSource() }
                            .buttonStyle(.glassProminent)
                            .disabled(!isValid)
                    } else {
                        Button(isEditing ? "Save" : "Add") { saveSource() }
                            .disabled(!isValid)
                    }
                }
            }
            .alert("Validation Error", isPresented: $showValidationError) {
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
            TextField("Source Name", text: $name).textContentType(.name)
            TextField("URL or API Endpoint", text: $urlString)
                .keyboardType(.URL).textContentType(.URL)
                .autocapitalization(.none).disableAutocorrection(true)
        } header: {
            Text("Source Info")
        } footer: {
            Text(sourceType == .directURL
                ? "Enter a URL that returns JSON with an array of wallpaper objects."
                : "Enter the API endpoint URL including your API key if needed.")
        }
    }

    @ViewBuilder
    private var typeSection: some View {
        Section("Source Type") {
            Picker("Type", selection: $sourceType) {
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
        Section { Toggle("Enabled", isOn: $isEnabled) }
            header: { Text("Settings") }
    }

    private func saveSource() {
        guard isValid else {
            validationMessage = "Please fill in both name and URL."
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
