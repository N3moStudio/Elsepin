import MapKit
import SwiftUI

/// Display choices only: never changes saved data, area naming or route movement.
struct MapOptionsMenu: View {
    @EnvironmentObject private var session: SpoofSession
    @EnvironmentObject private var preferences: SessionPreferences

    var body: some View {
        Menu {
            Section("Saved items") {
                Toggle("Pins", isOn: $preferences.showSavedPinsOnMap)
                Toggle("Areas", isOn: $preferences.showNamedAreasOnMap)
            }
            Picker("Map style", selection: $session.mapStyleIndex) {
                Text("Standard").tag(0)
                Text("Satellite").tag(2)
                Text("Satellite + labels").tag(1)
            }
        } label: {
            Image(systemName: "square.3.layers.3d")
                .frame(width: 44, height: 44).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Map options")
        .accessibilityHint("Show pins, area outlines or choose a map style")
    }
}

/// Build polygon geometry only when the saved area list changes, not on route ticks.
/// Let MapKit render the cached overlays in the visible map region.
struct SavedMapArea: Identifiable {
    let id: UUID
    let polygon: MKPolygon

    init(_ area: NamedArea) {
        id = area.id
        let coordinates = area.points.map(\.coordinate)
        polygon = MKPolygon(coordinates: coordinates, count: coordinates.count)
    }
}
