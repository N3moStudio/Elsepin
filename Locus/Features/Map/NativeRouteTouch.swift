import MapKit
import UIKit

/// A route touch stays in MapKit's coordinate system for its entire callback.
/// Never capture a SwiftUI MapProxy/CoordinateSpaceConverter in a UIKit delegate:
/// UIKit can deliver a terminal event after SwiftUI has replaced that view graph.
@MainActor
struct NativeRouteTouch {
    let map: MKMapView
    let point: CGPoint

    var coordinate: CLLocationCoordinate2D? {
        guard map.window != nil, point.x.isFinite, point.y.isFinite else { return nil }
        let value = map.convert(point, toCoordinateFrom: map)
        return CLLocationCoordinate2DIsValid(value) ? value : nil
    }

    func project(_ coordinate: CLLocationCoordinate2D) -> CGPoint? {
        guard map.window != nil, CLLocationCoordinate2DIsValid(coordinate) else { return nil }
        let value = map.convert(coordinate, toPointTo: map)
        return value.x.isFinite && value.y.isFinite ? value : nil
    }
}

/// The marker overlay borrows the map that accepted the original route hold.
/// A weak reference cannot keep an obsolete map alive after navigation/recovery.
@MainActor
final class RouteTouchMapReference {
    weak var map: MKMapView?
}
