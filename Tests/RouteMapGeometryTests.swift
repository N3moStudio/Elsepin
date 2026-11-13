import XCTest
@testable import SessionPresentation

final class RouteMapGeometryTests: XCTestCase {
    private let start = RoutePoint(latitude: 40, longitude: -74)
    private let finish = RoutePoint(latitude: 40.01, longitude: -74.01)
    private let midpoint = RoutePoint(latitude: 40.005, longitude: -74.005)

    func testOpeningAndAcceptingMapWithoutEditsKeepsGeometry() {
        let geometry = RouteMapGeometry(origin: start, destination: finish, stops: [])
        XCTAssertEqual(geometry, RouteMapGeometry(origin: start, destination: finish, stops: []))
    }

    func testUnchangedSavedStopIdentitiesAndPointsDoNotRequireDirections() {
        let id = UUID()
        let geometry = RouteMapGeometry(origin: start, destination: finish, stops: [.init(id: id, point: midpoint)])
        XCTAssertEqual(geometry, RouteMapGeometry(origin: start, destination: finish, stops: [.init(id: id, point: midpoint)]))
    }

    func testMovedEndpointsAndReorderedOrInsertedStopsRequireDirections() {
        let a = RouteMapGeometry.Stop(id: UUID(), point: midpoint)
        let b = RouteMapGeometry.Stop(id: UUID(), point: finish)
        let geometry = RouteMapGeometry(origin: start, destination: finish, stops: [a, b])
        XCTAssertNotEqual(geometry, RouteMapGeometry(origin: midpoint, destination: finish, stops: [a, b]))
        XCTAssertNotEqual(geometry, RouteMapGeometry(origin: start, destination: midpoint, stops: [a, b]))
        XCTAssertNotEqual(geometry, RouteMapGeometry(origin: start, destination: finish, stops: [b, a]))
        XCTAssertNotEqual(geometry, RouteMapGeometry(origin: start, destination: finish, stops: [a]))
        XCTAssertNotEqual(geometry, RouteMapGeometry(origin: start, destination: finish, stops: [a, b, .init(id: UUID(), point: midpoint)]))
    }

    func testMovingAStopOrReplacingItsIdentityRequiresDirections() {
        let id = UUID()
        let geometry = RouteMapGeometry(origin: start, destination: finish, stops: [.init(id: id, point: midpoint)])
        XCTAssertNotEqual(geometry, RouteMapGeometry(origin: start, destination: finish, stops: [.init(id: id, point: start)]))
        XCTAssertNotEqual(geometry, RouteMapGeometry(origin: start, destination: finish, stops: [.init(id: UUID(), point: midpoint)]))
    }
}
