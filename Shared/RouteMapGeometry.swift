import Foundation

/// Only geometry changes need new directions. Merely opening/closing a map
/// editor (or changing a label/wait) must preserve an exact saved path.
struct RouteMapGeometry: Equatable {
    struct Stop: Equatable {
        let id: UUID
        let point: RoutePoint
    }
    let origin: RoutePoint
    let destination: RoutePoint
    let stops: [Stop]
}
