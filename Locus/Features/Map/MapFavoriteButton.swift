import SwiftUI
import CoreLocation

/// Stars the current route, otherwise the selected pin. Naming is a separate action.
struct MapFavoriteButton: View {
    @EnvironmentObject private var session: SpoofSession
    @EnvironmentObject private var planner: RoutePlanner
    @EnvironmentObject private var library: TripLibrary

    private var route: PlannedRoute? { session.activeRoute ?? planner.preparedRoute?.route }
    private var coordinate: CLLocationCoordinate2D? { session.pinIsPreview ? session.pin : session.simulated ?? session.pin }
    private var savedRoute: SavedTrip? {
        let id = session.activeRoute == nil ? planner.preparedRoute?.editingTripID : session.activeSavedTripID
        return library.trips.first { $0.id == id }
    }
    private var isFavorite: Bool {
        if route != nil { return savedRoute?.isFavorite == true }
        return coordinate.flatMap { session.savedPin(at: $0) }?.isFavorite == true
    }
    var body: some View {
        if route != nil || coordinate != nil {
            Button(action: toggle) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundStyle(.primary).frame(width: 44, height: 44).contentShape(Rectangle())
            }.buttonStyle(.plain)
                .accessibilityLabel((isFavorite ? "Unfavorite " : "Favorite ") + (route == nil ? "pin" : "route"))
                .accessibilityValue(isFavorite ? "Favorited" : "Not favorited")
        }
    }
    private func toggle() {
        if let route {
            if let savedRoute { library.toggleFavorite(savedRoute); return }
            let active = session.activeRoute != nil
            let mode = active ? session.travelMode : planner.preparedRoute?.mode ?? .walk
            guard library.save(route: route, name: route.name, mode: mode,
                speed: active ? session.speedMPH(for: mode) : planner.preparedRoute?.speedMPH ?? 3,
                smooth: active ? session.currentSmoothMovement : planner.preparedRoute?.smoothMovement ?? false,
                arrival: active ? session.arrivalChoice : planner.preparedRoute?.arrival ?? .stay, favorite: true),
                let id = library.lastSavedID else { session.lastError = library.error; return }
            if active { session.rememberSavedTrip(id, routeID: route.id) }
            else { planner.rememberSavedTrip(id, routeID: route.id) }
        } else if let coordinate { session.toggleFavorite(at: coordinate) }
    }
}
