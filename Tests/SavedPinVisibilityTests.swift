import XCTest
@testable import SessionPresentation

final class SavedPinVisibilityTests: XCTestCase {
    func testDefaultKeepsWiderNeighborhoodOverviewsVisible() {
        // A quarter-mile scale division represents only part of the map.
        // Even a several-mile viewport should keep its saved pins by default.
        for miles in [0.25, 0.75, 2.5, 5] {
            XCTAssertTrue(SavedPinVisibility.isVisible(mapWidthMeters: miles * SavedPinVisibility.metersPerMile,
                maximumMiles: SavedPinVisibility.defaultMiles))
        }
    }

    func testSliderThresholdUsesGroundMilesAndKeepsDistantOverviewsClear() {
        let width = 8 * SavedPinVisibility.metersPerMile
        XCTAssertFalse(SavedPinVisibility.isVisible(mapWidthMeters: width, maximumMiles: 5))
        XCTAssertTrue(SavedPinVisibility.isVisible(mapWidthMeters: width, maximumMiles: 8))
        XCTAssertFalse(SavedPinVisibility.isVisible(mapWidthMeters: width + 1, maximumMiles: 8))
        XCTAssertFalse(SavedPinVisibility.isVisible(mapWidthMeters: 5_000_000, maximumMiles: 20))
    }

    func testPinsHiddenUntilMapSpanIsKnownAndValid() {
        let distances: [Double?] = [nil, .nan, .infinity, -.infinity, 0, -600]
        for distance in distances {
            XCTAssertFalse(SavedPinVisibility.isVisible(mapWidthMeters: distance, maximumMiles: 5))
        }
    }

    func testMapSpanUsesLocalGroundScaleAndRejectsInvalidGeometry() {
        XCTAssertEqual(SavedPinVisibility.mapWidthMeters(mapPoints: 20_000, metersPerMapPoint: 0.2), 4_000)
        XCTAssertEqual(SavedPinVisibility.mapWidthMeters(mapPoints: 20_000, metersPerMapPoint: 0.1), 2_000)
        XCTAssertNil(SavedPinVisibility.mapWidthMeters(mapPoints: .infinity, metersPerMapPoint: 0.2))
        XCTAssertNil(SavedPinVisibility.mapWidthMeters(mapPoints: 0, metersPerMapPoint: 0.2))
        XCTAssertNil(SavedPinVisibility.mapWidthMeters(mapPoints: 100, metersPerMapPoint: -1))
        XCTAssertNil(SavedPinVisibility.mapWidthMeters(mapPoints: .greatestFiniteMagnitude, metersPerMapPoint: 2))
    }

    func testPreferenceBoundsRecoverFromInvalidStoredValues() {
        XCTAssertEqual(SavedPinVisibility.boundedMiles(.nan), 5)
        XCTAssertEqual(SavedPinVisibility.boundedMiles(.infinity), 5)
        XCTAssertEqual(SavedPinVisibility.boundedMiles(-1), 0.5)
        XCTAssertEqual(SavedPinVisibility.boundedMiles(500), 20)
        XCTAssertEqual(SavedPinVisibility.boundedMiles(8.5), 8.5)
    }
}
