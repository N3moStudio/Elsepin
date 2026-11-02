import MapKit
import SwiftUI

struct NamedAreasSection: View {
    var search = ""
    var onEdit: (NamedArea?) -> Void
    @EnvironmentObject private var session: SpoofSession
    var body: some View {
        Section {
            Button { onEdit(nil) } label: { Label("Draw a named area", systemImage: "plus").frame(minHeight: 44) }
                .disabled(session.namedAreas.count >= 100)
            if session.namedAreas.isEmpty {
                Text("Make Home a whole area. Draw its outline and Elsepin uses the name while your sent location is inside.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            ForEach(session.namedAreas.filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) }) { area in
                Button { onEdit(area) } label: {
                    HStack(spacing: 12) {
                        ShiftRowIcon(symbol: "square.dashed")
                        VStack(alignment: .leading, spacing: 4) {
                            Text(area.name).foregroundStyle(.primary)
                            Text("\(area.points.count) corners").font(.footnote).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right").font(.footnote).foregroundStyle(.tertiary)
                    }.frame(maxWidth: .infinity, minHeight: 52, alignment: .leading).contentShape(Rectangle())
                }
                .swipeActions { Button("Delete", role: .destructive) { session.deleteNamedArea(area) } }
            }
        } footer: {
            Text("Separate areas can share the same name. Their borders can touch, but their interiors cannot overlap. Names change labels in Elsepin, including its Live Activity; they don’t rename places in Find My.")
        }
    }
}

/// Owned by the screen outside List's reusable sections. Session publications
/// can rebuild rows without replacing the presentation, draft, or camera.
@MainActor final class NamedAreaDraft: ObservableObject, Identifiable {
    let id: UUID
    @Published var name: String
    @Published var points: [RoutePoint]
    let center: CLLocationCoordinate2D?
    let viewport = SketchMapViewport()
    init(area: NamedArea?, center: CLLocationCoordinate2D?) {
        id = area?.id ?? UUID()
        name = area?.name ?? ""
        points = area?.points ?? []
        self.center = center
    }
    var area: NamedArea {
        NamedArea(id: id, name: String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(120)), points: points)
    }
}

struct NamedAreaEditor: View {
    @ObservedObject var draft: NamedAreaDraft
    @EnvironmentObject private var session: SpoofSession
    let onSave: (NamedArea) -> Bool
    @Environment(\.dismiss) private var dismiss
    @State private var editingCorners = false
    @State private var confirmDiscard = false
    @State private var error: String?
    private var otherAreas: [NamedArea] { session.namedAreas.filter { $0.id != draft.id } }
    var body: some View {
        NavigationStack {
            ScrollView {
            VStack(spacing: 12) {
                TextField("Area name, like School", text: $draft.name).textFieldStyle(.roundedBorder).padding(.horizontal)
                Text("Map").font(.headline).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal)
                Text("Tap corners around the edge. Use two fingers to move or zoom. Add at least 3 corners without crossing the outline.")
                    .font(.subheadline).foregroundStyle(.secondary).padding(.horizontal)
                SketchMapView(points: draft.points, outline: .area,
                              referenceAreas: otherAreas,
                              initialCamera: draft.viewport.camera, initialCenter: draft.center,
                              onPoint: { coordinate in
                    guard draft.points.count < 200 else { return }
                    let point = RoutePoint(coordinate)
                    if point.isValid, draft.points.last.map({ $0.distance(to: point) > 0.2 }) ?? true { draft.points.append(point) }
                }, onCameraChanged: { draft.viewport.camera = $0.copy() as? MKMapCamera })
                .frame(height: 300).clipShape(RoundedRectangle(cornerRadius: 20)).padding(.horizontal)
                Text("Saved areas are outlined in gray. Separate areas may use the same name; borders can touch without overlapping.")
                    .font(.footnote).foregroundStyle(.secondary).padding(.horizontal)
                if let error { Text(error).font(.footnote).foregroundStyle(LocusTheme.statusWarn).padding(.horizontal) }
                HStack {
                    Button("Edit corners") { editingCorners = true }.frame(minHeight: 44).disabled(draft.points.count < 3)
                    Button { if !draft.points.isEmpty { draft.points.removeLast() } } label: {
                        Label("Undo corner", systemImage: "arrow.uturn.backward").frame(maxWidth: .infinity, minHeight: 44).contentShape(Rectangle())
                    }.disabled(draft.points.isEmpty)
                    Text("\(draft.points.count) corners").font(.caption).foregroundStyle(.secondary)
                }.buttonStyle(.borderless).padding(.horizontal)
                Text("Preview only. Drawing here never moves your spoofed location.").font(.caption).foregroundStyle(.secondary)
            }.padding(.vertical)
            }
            .sheet(isPresented: $editingCorners) {
                PathEditorSheet(title: "Edit area", points: draft.points, area: true, referenceAreas: otherAreas) { edited in
                    var area = draft.area; area.points = edited
                    if let conflict = area.conflictingArea(in: otherAreas) { return NamedArea.overlapMessage(conflict.name) }
                    draft.points = edited; return nil
                }
            }
            .shiftScreen().loggedNavigationTitle("Name an area").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { if draft.points.isEmpty && draft.name.isEmpty { dismiss() } else { confirmDiscard = true } }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let conflict = draft.area.conflictingArea(in: otherAreas),
                           session.namedAreas.first(where: { $0.id == draft.id })?.points != draft.points {
                            error = NamedArea.overlapMessage(conflict.name)
                        } else if onSave(draft.area) { dismiss() }
                        else { error = session.lastError ?? "This area could not be saved. Try again." }
                    }.disabled(!draft.area.isValid)
                }
            }
        }
        .interactiveDismissDisabled()
        .onChange(of: draft.points) { _, _ in error = nil }
        .confirmationDialog("Discard this area edit?", isPresented: $confirmDiscard, titleVisibility: .visible) {
            Button("Discard changes", role: .destructive) { dismiss() }
            Button("Keep drawing", role: .cancel) { }
        }
    }
}
