import XCTest
@testable import SessionPresentation

final class RouteSearchCorridorTests: XCTestCase {
    func testBentRouteFiltersByPathRatherThanItsBoundingBox() throws {
        let track = try XCTUnwrap(RouteTrack([
            RoutePoint(latitude: 33.7, longitude: -117.9),
            RoutePoint(latitude: 33.8, longitude: -117.9),
            RoutePoint(latitude: 33.8, longitude: -117.7)
        ]))
        let corridor = RouteSearchCorridor(track: track, width: 500)
        XCTAssertNotNil(corridor.match(RoutePoint(latitude: 33.801, longitude: -117.8)))
        XCTAssertNil(corridor.match(RoutePoint(latitude: 33.71, longitude: -117.71)))
        XCTAssertNil(corridor.match(RoutePoint(latitude: .nan, longitude: 0)))
    }

    func testSearchRegionsAreBoundedAndCoverShortAndLongPaths() throws {
        for end in [0.001, 0.2, 2.0] {
            let track = try XCTUnwrap(RouteTrack([RoutePoint(latitude: 0, longitude: 0), RoutePoint(latitude: 0, longitude: end)]))
            let corridor = RouteSearchCorridor(track: track)
            XCTAssertTrue((1...4).contains(corridor.regions.count))
            XCTAssertTrue(corridor.regions.allSatisfy { $0.center.isValid && $0.diameter.isFinite && $0.diameter > 0 })
            for fraction in [0.0, 0.25, 0.5, 0.75, 1.0] {
                let point = track.point(at: track.length * fraction)
                XCTAssertTrue(corridor.regions.contains { $0.center.distance(to: point) <= $0.diameter / 2 })
            }
        }
    }

    func testVeryLongRouteUsesSafeSizedSamplingRegions() throws {
        let track = try XCTUnwrap(RouteTrack([RoutePoint(latitude: 0, longitude: 0), RoutePoint(latitude: 0, longitude: 20)]))
        let corridor = RouteSearchCorridor(track: track)
        XCTAssertTrue(corridor.samplesLongRoute)
        XCTAssertEqual(corridor.regions.count, 4)
        XCTAssertTrue(corridor.regions.allSatisfy { $0.diameter <= 200_000 })
    }

    func testDateLineResultsAndInsertionKeepExistingStopOrder() throws {
        let track = try XCTUnwrap(RouteTrack([RoutePoint(latitude: 0, longitude: 179.9), RoutePoint(latitude: 0, longitude: -179.9)]))
        let corridor = RouteSearchCorridor(track: track)
        let middle = track.point(at: track.length / 2)
        XCTAssertEqual(try XCTUnwrap(corridor.match(middle)).metresAlong, track.length / 2, accuracy: 1)
        XCTAssertEqual(corridor.insertionIndex(for: middle, stopMetres: [track.length * 0.2, track.length * 0.8]), 1)
        XCTAssertEqual(corridor.insertionIndex(for: RoutePoint(latitude: 5, longitude: 0), stopMetres: [100, 200]), 2)
    }

    func testDuplicateRuleRetainsDifferentNearbyBusinessesAndSeparateBranches() {
        let point = RoutePoint(latitude: 33.7, longitude: -117.8)
        XCTAssertTrue(RouteSearchCorridor.isDuplicate(name: "Café", point: point, ofName: "CAFE", point: point))
        XCTAssertFalse(RouteSearchCorridor.isDuplicate(name: "Cafe", point: point, ofName: "Grocery", point: point))
        XCTAssertFalse(RouteSearchCorridor.isDuplicate(name: "Cafe", point: point, ofName: "Cafe", point: RoutePoint(latitude: 33.72, longitude: -117.8)))
    }
}
