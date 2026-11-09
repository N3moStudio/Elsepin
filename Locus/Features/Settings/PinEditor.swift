import MapKit
import SwiftUI

@MainActor final class PinDraft: ObservableObject, Identifiable {
    let id = UUID()
    let existing: SavedPlace?
    @Published var name: String
    @Published var coordinate: CLLocationCoordinate2D?
    @Published var favorite: Bool
    @Published var symbol: SavedPlaceSymbol
    @Published var tint: SavedPlaceTint
    init(place: SavedPlace?, center: CLLocationCoordinate2D?) {
        existing = place; name = place?.name ?? ""; coordinate = place?.coordinate ?? center
        favorite = place?.isFavorite ?? false; symbol = place?.symbol ?? .pin; tint = place?.tint ?? .mint
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
    @State private var error: String?
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Pin name", text: $draft.name)
                    Toggle("Favorite", isOn: $draft.favorite)
                }
                Section {
                    if draft.existing == nil {
                        Button("Search for a location", systemImage: "magnifyingglass") { search = true }
                    }
                    MapReader { proxy in
                        Map(position: $position, interactionModes: [.pan, .zoom]) {
                            ForEach(visiblePins) { pin in
                                Marker("", systemImage: pin.symbol.rawValue, coordinate: pin.coordinate).tint(pin.tint.swatch)
                            }
                            if let coordinate = draft.coordinate {
                                Marker("", systemImage: draft.symbol.rawValue, coordinate: coordinate).tint(draft.tint.swatch)
                            }
                        }.onTapGesture { location in
                            guard draft.existing == nil, let coordinate = proxy.convert(location, from: .local),
                                  CLLocationCoordinate2DIsValid(coordinate) else { return }
                            draft.coordinate = coordinate
                        }
                        .onMapCameraChange(frequency: .onEnd) { visibleMapRect = $0.rect }
                    }.frame(height: 260).listRowInsets(EdgeInsets())
                } footer: { Text(draft.existing == nil ? "Tap the map to place a pin. Saving never moves your location." : "This is the saved pin’s location. Saving changes its name and appearance only.") }
                Section("Pin appearance") {
                    Picker("Symbol", selection: $draft.symbol) {
                        ForEach(SavedPlaceSymbol.allCases) { symbol in Label(symbol.title, systemImage: symbol.rawValue).tag(symbol) }
                    }
                    Picker("Color", selection: $draft.tint) {
                        ForEach(SavedPlaceTint.allCases) { tint in Text(tint.title).tag(tint) }
                    }
                }
                if let error { Text(error).foregroundStyle(LocusTheme.statusWarn) }
            }.shiftSettingsScreen().loggedNavigationTitle(draft.existing == nil ? "Add pin" : "Edit pin")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save", action: save).disabled(draft.coordinate == nil || draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .onAppear { if let coordinate = draft.coordinate { center(coordinate) } }
                .sheet(isPresented: $search) {
                    RoutePlaceSearchSheet(title: "Place pin") { place in
                        draft.coordinate = place.coordinate
                        if draft.name.isEmpty { draft.name = place.name }
                        center(place.coordinate)
                    }
                }
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
    private func save() {
        guard let coordinate = draft.coordinate else { return }
        if let existing = draft.existing, !session.savedPins.contains(where: { $0.id == existing.id }) {
            error = "This pin was removed. Close the editor and add it again."; return
        }
        guard session.savePin(name: draft.name, coordinate: coordinate, favorite: draft.favorite,
                              icon: draft.symbol, tint: draft.tint, replaceName: true) else {
            error = session.lastError ?? "Couldn't save this pin."; return
        }
        if let existing = draft.existing, existing.name != draft.name { library.renameLinkedPlace(existing, to: draft.name) }
        DeveloperLogObserver.shared.recordMapEnergy(reason: "pin_saved")
        dismiss()
    }
}
