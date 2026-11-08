import XCTest
@testable import SessionPresentation

final class MapViewportSafetyTests: XCTestCase {
    func testWorldAndStreetZoomSamplesRemainValid() {
        for distance in [10.0, 1_000, 40_000_000] {
            XCTAssertTrue(MapViewportSafety.validCamera(latitude: 33.7, longitude: -117.8,
                distance: distance, pitch: 0, heading: 359.9))
        }
    }
    func testInvalidTransientCameraSamplesCannotReachNativeCameraConstruction() {
        for invalid in [Double.nan, .infinity, -.infinity] {
            XCTAssertFalse(MapViewportSafety.validCamera(latitude: invalid, longitude: 0, distance: 100, pitch: 0, heading: 0))
            XCTAssertFalse(MapViewportSafety.validCamera(latitude: 0, longitude: invalid, distance: 100, pitch: 0, heading: 0))
            XCTAssertFalse(MapViewportSafety.validCamera(latitude: 0, longitude: 0, distance: invalid, pitch: 0, heading: 0))
            XCTAssertFalse(MapViewportSafety.validCamera(latitude: 0, longitude: 0, distance: 100, pitch: invalid, heading: 0))
            XCTAssertFalse(MapViewportSafety.validCamera(latitude: 0, longitude: 0, distance: 100, pitch: 0, heading: invalid))
        }
        XCTAssertFalse(MapViewportSafety.validCamera(latitude: 91, longitude: 0, distance: 100, pitch: 0, heading: 0))
        XCTAssertFalse(MapViewportSafety.validCamera(latitude: 0, longitude: 181, distance: 100, pitch: 0, heading: 0))
        XCTAssertFalse(MapViewportSafety.validCamera(latitude: 0, longitude: 0, distance: 0, pitch: 0, heading: 0))
    }
}
