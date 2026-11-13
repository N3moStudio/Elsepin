import XCTest
@testable import SessionPresentation

final class SearchAreaBoundsTests: XCTestCase {
    func testChosenCityRejectsDeviceAreaAndKeepsBoundary() {
        let region = SearchAreaBounds(center: RoutePoint(latitude: 40.7, longitude: -74), latitudeDelta: 0.2, longitudeDelta: 0.2)
        XCTAssertTrue(region.contains(RoutePoint(latitude: 40.7, longitude: -74)))
        XCTAssertFalse(region.contains(RoutePoint(latitude: 33.68, longitude: -117.83)))
        XCTAssertFalse(region.contains(RoutePoint(latitude: 41, longitude: -74)))
    }
    func testDatelineAndInvalidRegions() {
        let region = SearchAreaBounds(center: RoutePoint(latitude: 0, longitude: 179.9), latitudeDelta: 1, longitudeDelta: 1)
        XCTAssertTrue(region.contains(RoutePoint(latitude: 0, longitude: -179.9)))
        XCTAssertFalse(region.contains(RoutePoint(latitude: 0, longitude: 178)))
        XCTAssertFalse(SearchAreaBounds(center: region.center, latitudeDelta: .nan, longitudeDelta: 1).isValid)
        XCTAssertFalse(SearchAreaBounds(center: region.center, latitudeDelta: 1, longitudeDelta: 0).isValid)
    }
}
