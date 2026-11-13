import Foundation

/// Intentionally not Codable: restoring a backup or relaunching cannot grant
/// permission to start another route. A plan contains only one continuation.
struct NextRoutePlan {
    let route: PlannedRoute
    let mode: TravelMode
    let speedMPH: Double
    let smoothMovement: Bool
    let waitSeconds: Double
    let automatically: Bool

    var summary: String {
        let wait = waitSeconds == 0 ? "No wait" : "Wait \(StopDuration.label(waitSeconds))"
        return "\(route.destination.name) · \(wait)"
    }
    var prepared: PreparedRoute {
        PreparedRoute(route: route, mode: mode, speedMPH: speedMPH, smoothMovement: smoothMovement,
            waypoints: [], usesStoredPath: true, sectionChoices: [:])
    }
    func begins(at source: PlannedRoute) -> Bool {
        StopDuration.isValid(waitSeconds) && route.supports(mode) &&
            RoutePoint(route.origin.coordinate).distance(to: source.track.point(at: source.track.length)) <= 5 &&
            route.track.point(at: 0).distance(to: source.track.point(at: source.track.length)) <= 5
    }
}
