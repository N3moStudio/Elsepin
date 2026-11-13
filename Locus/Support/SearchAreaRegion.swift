import MapKit

extension MKCoordinateRegion {
    var searchBounds: SearchAreaBounds {
        SearchAreaBounds(center: RoutePoint(center), latitudeDelta: span.latitudeDelta, longitudeDelta: span.longitudeDelta)
    }
    func containsPlace(_ coordinate: CLLocationCoordinate2D) -> Bool { searchBounds.contains(RoutePoint(coordinate)) }
}
