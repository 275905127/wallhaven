import SwiftUI
import SwiftData

struct SourceListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WallpaperSource.sortOrder) private var sources: [WallpaperSource]

    @State private var showAddSource = false
    @State private var editingSource: WallpaperSource?

    var body: some View {
        Group {
            if sources.isEmpty {
                emptyStateView
            } else {
                sourceList
            }
        }
        .navigationTitle("Sources")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if #available(iOS 26, *) {
                    Button { showAddSource = true } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.glass)
                } else {
                    Button { showAddSource = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showAddSource) {
            SourceEditView(source: nil)
        }
        .sheet(item: $editingSource) { source in
            SourceEditView(source: source)
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Sources",
            systemImage: "link.icloud",
            description: Text("Add wallpaper sources to start browsing.")
        )
        .overlay(alignment: .bottom) {
            if #available(iOS 26, *) {
                Button("Add Source") { showAddSource = true }
                    .buttonStyle(.glassProminent)
                    .padding(.bottom, 32)
            } else {
                Button("Add Source") { showAddSource = true }
                    .buttonStyle(.borderedProminent)
                    .padding(.bottom, 32)
            }
        }
    }

    private var sourceList: some View {
        List {
            ForEach(sources) { source in
                SourceRowView(source: source)
                    .contentShape(Rectangle())
                    .onTapGesture { editingSource = source }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteSource(source)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func deleteSource(_ source: WallpaperSource) {
        modelContext.delete(source)
    }
}

// MARK: - Source Row

struct SourceRowView: View {
    let source: WallpaperSource

    var body: some View {
        HStack(spacing: 12) {
            typeIconView

            VStack(alignment: .leading, spacing: 2) {
                Text(source.name)
                    .font(.body).fontWeight(.medium)
                Text(source.type.displayName)
                    .font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            if !source.isEnabled {
                Text("Disabled")
                    .font(.caption).foregroundStyle(.secondary)
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background(.quaternary, in: Capsule())
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var typeIconView: some View {
        if #available(iOS 26, *) {
            Image(systemName: source.type.iconName)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 36, height: 36)
                .glassEffect(in: .circle)
        } else {
            Image(systemName: source.type.iconName)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 36, height: 36)
                .background(.blue.opacity(0.15), in: Circle())
        }
    }
}
