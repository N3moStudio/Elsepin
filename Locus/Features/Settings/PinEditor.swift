import MapKit
import SwiftUI
import UIKit

@MainActor final class PinDraft: ObservableObject, Identifiable {
    let id = UUID()
    let existing: SavedPlace?
    let center: CLLocationCoordinate2D?
    let workspaceGeneration = AppDataWorkspace.shared.context.generation
    @Published var name: String
    @Published var coordinate: CLLocationCoordinate2D?
    @Published var favorite: Bool
    @Published var symbol: SavedPlaceSymbol
    @Published var tint: SavedPlaceTint
    @Published var emoji: String
    @Published var usesCustomEmoji: Bool
    @Published var address: String?
    init(place: SavedPlace?, center: CLLocationCoordinate2D?, selectedCoordinate: CLLocationCoordinate2D? = nil) {
        existing = place; self.center = center; name = place?.name ?? ""
        // Merely centering the map must not create a selected pin.
        coordinate = place?.coordinate ?? selectedCoordinate
        favorite = place?.isFavorite ?? false; symbol = place?.symbol ?? .pin; tint = place?.tint ?? .mint
        emoji = place?.emoji ?? ""; address = place?.address
        usesCustomEmoji = place?.emoji != nil
    }
    var canSave: Bool {
        guard let coordinate, CLLocationCoordinate2DIsValid(coordinate) else { return false }
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            (!usesCustomEmoji || PinAppearance.isSingleEmoji(emoji))
    }
}

struct PinEditor: View {
    @ObservedObject var draft: PinDraft
    @EnvironmentObject private var session: SpoofSession
    @EnvironmentObject private var library: TripLibrary
    @Environment(\.dismiss) private var dismiss
    @State private var position: MapCameraPosition = .automatic
    @State private var visibleMapRect: MKMapRect?
    @State private var search = false
    @State private var expanded = false
    @State private var retainedCamera: MapCamera?
    @State private var error: String?
    init(draft: PinDraft) {
        self.draft = draft
        let location = draft.coordinate ?? draft.center
        _position = State(initialValue: location.map {
            .region(MKCoordinateRegion(center: $0, latitudinalMeters: 600, longitudinalMeters: 600))
        } ?? .automatic)
    }
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Pin name", text: $draft.name)
                    Toggle("Favorite", isOn: $draft.favorite)
                }
                Section {
                    HStack {
                        Button("Search for a location", systemImage: "magnifyingglass") { search = true }
                            .frame(minHeight: 44)
                        Spacer()
                        Button("Expand map", systemImage: "arrow.up.left.and.arrow.down.right") {
                            preserveCamera(); expanded = true
                        }.labelStyle(.iconOnly).frame(width: 44, height: 44).contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless)
                    Group {
                        if expanded { Color.clear }
                        else { pinMap }
                    }
                    .frame(height: 380)
                    .listRowInsets(EdgeInsets())
                } footer: {
                    Text("Tap to place or move the pin. Saving never teleports.")
                }
                Section("Pin appearance") {
                    Picker("Symbol", selection: symbolChoice) {
                        ForEach(SavedPlaceSymbol.allCases) { symbol in
                            Label(symbol.title, systemImage: symbol.rawValue).tag(Optional(symbol))
                        }
                        Label("Custom emoji", systemImage: "face.smiling").tag(nil as SavedPlaceSymbol?)
                    }
                    if draft.usesCustomEmoji {
                        SingleEmojiField(text: $draft.emoji)
                            .frame(minHeight: 44)
                    }
                    Picker("Color", selection: $draft.tint) {
                        ForEach(SavedPlaceTint.allCases) { tint in Text(tint.title).tag(tint) }
                    }
                }
                if let error { Text(error).foregroundStyle(LocusTheme.statusWarn) }
            }.shiftSettingsScreen().loggedNavigationTitle(draft.existing == nil ? "Save pin" : "Edit pin")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save", action: save).disabled(!draft.canSave)
                            .opacity(draft.canSave ? 1 : 0.4)
                    }
                }
                .sheet(isPresented: Binding(get: { search && !expanded }, set: { if !expanded { search = $0 } })) { searchSheet }
                .fullScreenCover(isPresented: $expanded) {
                    NavigationStack {
                        pinMap
                            .safeAreaInset(edge: .top, spacing: 0) {
                                Button("Search for a location", systemImage: "magnifyingglass") { search = true }
                                    .buttonStyle(.plain)
                                    .frame(maxWidth: .infinity, minHeight: 44).background(ShiftCanvas())
                            }
                            .navigationTitle("Place pin").navigationBarTitleDisplayMode(.inline)
                            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { preserveCamera(); expanded = false } } }
                            .sheet(isPresented: $search) { searchSheet }
                    }
                }
        }
    }
    private var symbolChoice: Binding<SavedPlaceSymbol?> {
        Binding(get: { draft.usesCustomEmoji ? nil : draft.symbol }, set: { symbol in
            draft.usesCustomEmoji = symbol == nil
            if let symbol { draft.symbol = symbol; draft.emoji = "" }
        })
    }
    private var searchSheet: some View {
        RoutePlaceSearchSheet(title: "Place pin") { place in
            select(place.coordinate)
            // A search suggestion may fill a blank name, never replace a custom one.
            if draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { draft.name = place.name }
            center(place.coordinate)
        }
    }
    private var pinMap: some View {
        MapReader { proxy in
            Map(position: $position, interactionModes: [.pan, .zoom]) {
                ForEach(visiblePins) { pin in
                    Marker("", systemImage: pin.symbol.rawValue, coordinate: pin.coordinate).tint(pin.tint.swatch)
                }
                if let coordinate = draft.coordinate {
                    Annotation("", coordinate: coordinate) {
                        Group {
                            if PinAppearance.isSingleEmoji(draft.emoji) { Text(draft.emoji) }
                            else { Image(systemName: draft.symbol.rawValue).foregroundStyle(draft.tint.swatch) }
                        }.font(.title)
                    }
                }
            }.onTapGesture { location in
                guard let coordinate = proxy.convert(location, from: .local),
                      CLLocationCoordinate2DIsValid(coordinate) else { return }
                select(coordinate)
            }
            .onMapCameraChange(frequency: .onEnd) { visibleMapRect = $0.rect; retainedCamera = $0.camera }
        }
    }
    private var visiblePins: [SavedPlace] {
        guard SavedPinVisibility.isVisible(cameraDistance: retainedCamera?.distance) else { return [] }
        return session.savedPins.filter { pin in
            pin.id != draft.existing?.id && (visibleMapRect?.contains(MKMapPoint(pin.coordinate)) ?? true)
        }
    }
    private func center(_ coordinate: CLLocationCoordinate2D) {
        retainedCamera = nil
        position = .region(MKCoordinateRegion(center: coordinate, latitudinalMeters: 600, longitudinalMeters: 600))
    }
    private func preserveCamera() {
        if let retainedCamera { position = .camera(retainedCamera) }
    }
    private func select(_ coordinate: CLLocationCoordinate2D) {
        draft.address = nil; draft.coordinate = coordinate
    }
    private func save() {
        guard draft.canSave, let coordinate = draft.coordinate else { return }
        guard draft.workspaceGeneration == AppDataWorkspace.shared.context.generation else {
            error = "Your library changed. Close this editor and reopen the pin."; return
        }
        if let existing = draft.existing, !session.savedPins.contains(existing) {
            error = "This pin changed or was removed. Close the editor and reopen it."; return
        }
        guard session.savePin(name: draft.name, coordinate: coordinate, favorite: draft.favorite,
                              icon: draft.symbol, tint: draft.tint, replaceName: true,
                              address: draft.address, emoji: draft.emoji, replacingID: draft.existing?.id) else {
            error = session.lastError ?? "Couldn't save this pin."; return
        }
        if let existing = draft.existing, existing.name != draft.name,
           RoutePoint(existing.coordinate) == RoutePoint(coordinate) {
            library.renameLinkedPlace(existing, to: draft.name)
        }
        DeveloperLogObserver.shared.recordMapEnergy(reason: "pin_saved")
        dismiss()
    }
}

/// A native field lets us reject invalid input before it appears, including paste.
/// Updating a SwiftUI binding alone can leave rejected text in the backing field.
private struct SingleEmojiField: UIViewRepresentable {
    @Binding var text: String
    @ScaledMetric(relativeTo: .body) private var fontSize: CGFloat = 17

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.placeholder = "Choose an emoji"
        field.accessibilityLabel = "Custom emoji"
        field.accessibilityHint = "Use the emoji keyboard to choose one symbol."
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.spellCheckingType = .no
        field.returnKeyType = .done
        field.delegate = context.coordinator
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return field
    }

    func updateUIView(_ field: UITextField, context: Context) {
        context.coordinator.text = $text
        if field.text != text { field.text = text }
        let descriptor = UIFont.systemFont(ofSize: fontSize).fontDescriptor
        field.font = UIFont(descriptor: descriptor.withDesign(.rounded) ?? descriptor, size: fontSize)
    }

    func makeCoordinator() -> Coordinator { Coordinator(text: $text) }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var text: Binding<String>
        init(text: Binding<String>) { self.text = text }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            guard let accepted = PinAppearance.applyingEmojiEdit(to: textField.text ?? "", range: range, replacement: string) else {
                return false
            }
            textField.text = accepted
            text.wrappedValue = accepted
            return false
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
    }
}
