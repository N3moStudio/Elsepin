import MapKit
import SwiftUI

@MainActor final class PinDraft: ObservableObject, Identifiable {
    let id = UUID()
    let existing: SavedPlace?
    let center: CLLocationCoordinate2D?
    @Published var name: String
    @Published var coordinate: CLLocationCoordinate2D?
    @Published var favorite: Bool
    @Published var symbol: SavedPlaceSymbol
    @Published var tint: SavedPlaceTint
    @Published var emoji: String
    @Published var address: String?
    var automaticName: String?
    init(place: SavedPlace?, center: CLLocationCoordinate2D?, selectedCoordinate: CLLocationCoordinate2D? = nil) {
        existing = place; self.center = center; name = place?.name ?? ""
        // Merely centering the map must not create a selected pin.
        coordinate = place?.coordinate ?? selectedCoordinate
        favorite = place?.isFavorite ?? false; symbol = place?.symbol ?? .pin; tint = place?.tint ?? .mint
        emoji = place?.emoji ?? ""; address = place?.address
    }
    var canSave: Bool {
        guard let coordinate, CLLocationCoordinate2DIsValid(coordinate) else { return false }
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            (emoji.isEmpty || PinAppearance.isSingleEmoji(emoji))
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
    @State private var cameraInitialized = false
    @State private var error: String?
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Pin name", text: $draft.name)
                    if let address = draft.address { Text(address).font(.caption).foregroundStyle(.secondary) }
                    Toggle("Favorite", isOn: $draft.favorite)
                }
                Section {
                    if draft.existing == nil {
                        Button("Search for a location", systemImage: "magnifyingglass") { search = true }
                    }
                    Group {
                        if expanded { Color.clear }
                        else { pinMap }
                    }
                    .frame(height: 380)
                    .overlay(alignment: .bottomTrailing) {
                        Button("Expand map", systemImage: "arrow.up.left.and.arrow.down.right") { expanded = true }
                            .labelStyle(.iconOnly).padding(12).background(.regularMaterial, in: Circle()).padding(12)
                    }
                    .listRowInsets(EdgeInsets())
                } footer: {
                    Text(draft.existing == nil ? "Tap to place a pin. Saving never teleports." : "Edit its name and appearance. The saved location stays fixed.")
                }
                Section("Pin appearance") {
                    Picker("Symbol", selection: $draft.symbol) {
                        ForEach(SavedPlaceSymbol.allCases) { symbol in Label(symbol.title, systemImage: symbol.rawValue).tag(symbol) }
                    }
                    .onChange(of: draft.symbol) { _, _ in draft.emoji = "" }
                    TextField("Or choose one emoji", text: $draft.emoji)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    if !draft.emoji.isEmpty, !PinAppearance.isSingleEmoji(draft.emoji) {
                        Text("Choose one emoji using the emoji keyboard.").font(.caption).foregroundStyle(.secondary)
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
                .onAppear {
                    guard !cameraInitialized else { return }
                    cameraInitialized = true
                    if let coordinate = draft.coordinate ?? draft.center { center(coordinate) }
                }
                .sheet(isPresented: Binding(get: { search && !expanded }, set: { if !expanded { search = $0 } })) { searchSheet }
                .fullScreenCover(isPresented: $expanded) {
                    NavigationStack {
                        pinMap
                            .safeAreaInset(edge: .top, spacing: 0) {
                                if draft.existing == nil {
                                    Button("Search for a location", systemImage: "magnifyingglass") { search = true }
                                        .frame(maxWidth: .infinity, minHeight: 44).background(ShiftCanvas())
                                }
                            }
                            .navigationTitle("Place pin").navigationBarTitleDisplayMode(.inline)
                            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { expanded = false } } }
                            .sheet(isPresented: $search) { searchSheet }
                    }
                }
                .task(id: draft.coordinate.map(RoutePoint.init)) { await suggestName() }
        }
    }
    private var searchSheet: some View {
        RoutePlaceSearchSheet(title: "Place pin") { place in
            select(place.coordinate)
            draft.name = place.name; draft.automaticName = nil
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
                        }.font(.title).padding(10).background(.background, in: Circle())
                    }
                }
            }.onTapGesture { location in
                guard draft.existing == nil, let coordinate = proxy.convert(location, from: .local),
                      CLLocationCoordinate2DIsValid(coordinate) else { return }
                select(coordinate)
            }
            .onMapCameraChange(frequency: .onEnd) { visibleMapRect = $0.rect }
        }
    }
    private var visiblePins: [SavedPlace] {
        session.savedPins.filter { pin in
            pin.id != draft.existing?.id && (visibleMapRect?.contains(MKMapPoint(pin.coordinate)) ?? true)
        }
    }
    private func center(_ coordinate: CLLocationCoordinate2D) {
        position = .region(MKCoordinateRegion(center: coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000))
    }
    private func select(_ coordinate: CLLocationCoordinate2D) {
        if draft.name == draft.automaticName { draft.name = "" }
        draft.automaticName = nil; draft.address = nil; draft.coordinate = coordinate
    }
    private func suggestName() async {
        guard draft.existing == nil, let coordinate = draft.coordinate else { return }
        let point = RoutePoint(coordinate)
        let originalName = draft.name
        do { try await Task.sleep(for: .milliseconds(350)) } catch { return }
        let details = await PinLocationLookup.resolve(coordinate)
        guard !Task.isCancelled, draft.coordinate.map(RoutePoint.init) == point else { return }
        draft.address = details?.address
        if draft.name == originalName, originalName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let name = details?.name ?? String(format: "Pin %.4f, %.4f", coordinate.latitude, coordinate.longitude)
            draft.name = name; draft.automaticName = name
        }
    }
    private func save() {
        guard draft.canSave, let coordinate = draft.coordinate else { return }
        if let existing = draft.existing, !session.savedPins.contains(where: { $0.id == existing.id }) {
            error = "This pin was removed. Close the editor and add it again."; return
        }
        guard session.savePin(name: draft.name, coordinate: coordinate, favorite: draft.favorite,
                              icon: draft.symbol, tint: draft.tint, replaceName: true,
                              address: draft.address, emoji: draft.emoji) else {
            error = session.lastError ?? "Couldn't save this pin."; return
        }
        if let existing = draft.existing, existing.name != draft.name { library.renameLinkedPlace(existing, to: draft.name) }
        DeveloperLogObserver.shared.recordMapEnergy(reason: "pin_saved")
        dismiss()
    }
}
