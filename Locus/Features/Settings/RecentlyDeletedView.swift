import SwiftUI

struct RecentlyDeletedView: View {
    @ObservedObject private var bin = RecentlyDeletedStore.shared
    @EnvironmentObject private var library: TripLibrary
    @EnvironmentObject private var session: SpoofSession
    @State private var selecting = false
    @State private var selection = DeletedItemsSelection()
    @State private var deleting: DeletedItemsDeletion?
    @State private var message: String?
    @State private var messageTitle = "Couldn't restore"
    private var visibleItems: [DeletedLibraryItem] { bin.items.filter { $0.isRetained(at: Date()) } }
    var body: some View {
        List {
            if selecting {
                Section {
                    HStack {
                        Button("Select All") { selection.selectAll(visibleItems, now: Date()) }
                            .disabled(visibleItems.isEmpty || selection.ids.count == visibleItems.count)
                        Spacer()
                        Button("Deselect All") { selection.ids = [] }.disabled(selection.ids.isEmpty)
                    }.buttonStyle(.borderless).frame(minHeight: 44)
                    Button("Permanently delete selected (\(selection.ids.count))", role: .destructive) {
                        deleting = selection.review(bin.items, now: Date())
                    }.frame(minHeight: 44).disabled(selection.ids.isEmpty || !bin.canEdit)
                }
            }
            Section {
                if visibleItems.isEmpty { Text("Nothing recently deleted").foregroundStyle(.secondary) }
                ForEach(visibleItems) { item in
                    if selecting {
                        Button { selection.toggle(item.id) } label: {
                            HStack(spacing: 12) {
                                Image(systemName: selection.ids.contains(item.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selection.ids.contains(item.id) ? LocusTheme.accent : .secondary)
                                    .accessibilityHidden(true)
                                itemLabel(item)
                            }.frame(maxWidth: .infinity, minHeight: 52, alignment: .leading).contentShape(Rectangle())
                        }.buttonStyle(.plain)
                            .accessibilityValue(selection.ids.contains(item.id) ? "Selected" : "Not selected")
                            .accessibilityAddTraits(selection.ids.contains(item.id) ? .isSelected : [])
                    } else {
                    VStack(alignment: .leading, spacing: 8) {
                        itemLabel(item)
                        HStack {
                            Button("Restore") { restore(item) }.frame(minHeight: 44)
                            Spacer()
                            Button("Delete permanently", role: .destructive) { deleting = DeletedItemsDeletion(items: [item]) }.frame(minHeight: 44)
                        }.buttonStyle(.borderless)
                    }
                    }
                }
                if let error = bin.error { Text(error).foregroundStyle(LocusTheme.statusWarn) }
            } footer: { Text("Deleted places, trips, and areas stay here for 30 days. Restoring never starts spoofing. These items are not included in exports.") }
        }
        .shiftScreen().loggedNavigationTitle("Recently Deleted").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(selecting ? "Done" : "Select") {
                    selecting.toggle(); selection.ids = []
                }.disabled(!selecting && visibleItems.isEmpty)
            }
        }
        .onAppear { bin.prune() }
        .onChange(of: bin.items) { _, items in selection.reconcile(with: items, now: Date()) }
        .loggedAlert("Permanently delete \(deleting?.items.count ?? 0) \(deleting?.items.count == 1 ? "item" : "items")?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })) {
            Button("Cancel", role: .cancel) { deleting = nil }
            if let plan = deleting {
                Button("Permanently delete", role: .destructive) {
                    if bin.permanentlyDelete(plan) { selection.ids.subtract(plan.items.map(\.id)) }
                    else { messageTitle = "Couldn't delete selection"; message = bin.error }
                    deleting = nil
                }
            }
        } message: { Text("From Recently Deleted: \(deleting?.summary ?? ""). This cannot be undone. Items still in your saved library and any active route are kept.") }
        .loggedAlert(messageTitle, isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("OK", role: .cancel) { message = nil }
        } message: { Text(message ?? "") }
    }
    private func itemLabel(_ item: DeletedLibraryItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(PlaceLabel.readable(item.payload.name)).font(.headline).foregroundStyle(.primary)
            Text("\(item.payload.kind) · Expires \(item.expiresAt.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
    private func restore(_ item: DeletedLibraryItem) {
        messageTitle = "Couldn't restore"
        guard item.isRetained(at: Date()) else { bin.prune(); return }
        do {
            switch item.payload {
            case .trip(let trip):
                guard !library.trips.contains(where: { $0.id == trip.id }) else { throw RestoreError.exists }
                guard try library.merge([trip]) else { message = library.error; return }
            case .place(let place):
                guard !session.favorites.contains(where: { $0.id == place.id }) else { throw RestoreError.exists }
                guard session.restoreFavorite(place) else { message = session.lastError; return }
            case .area(let area):
                guard !session.namedAreas.contains(where: { $0.id == area.id }) else { throw RestoreError.exists }
                guard session.replaceNamedAreas(session.namedAreas + [area]) else { message = session.lastError; return }
            }
            if !bin.remove(item.id) { message = "Restored. The old entry couldn't be removed from Recently Deleted; it is safe to delete that entry later." }
        } catch { message = error.localizedDescription }
    }
    private enum RestoreError: LocalizedError {
        case exists
        var errorDescription: String? { "An item with this identity is already saved. Keep it, or delete it before restoring the older version." }
    }
}
