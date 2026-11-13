import Foundation

/// User-selected search regions remain authoritative, even for POI fallbacks.
struct SearchAreaBounds {
    let center: RoutePoint
    let latitudeDelta: Double
    let longitudeDelta: Double
    var isValid: Bool {
        center.isValid && latitudeDelta.isFinite && longitudeDelta.isFinite &&
            latitudeDelta > 0 && latitudeDelta <= 180 && longitudeDelta > 0 && longitudeDelta <= 360
    }
    func contains(_ point: RoutePoint) -> Bool {
        isValid && point.isValid && abs(point.latitude - center.latitude) <= latitudeDelta / 2 &&
            abs(RoutePoint.longitudeDelta(point.longitude - center.longitude)) <= longitudeDelta / 2
    }
}
