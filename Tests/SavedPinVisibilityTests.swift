import XCTest
@testable import SessionPresentation

final class SavedPinVisibilityTests: XCTestCase {
    func testPinsVisibleAtNeighborhoodScale() {
        XCTAssertTrue(SavedPinVisibility.isVisible(cameraDistance: 600))
        XCTAssertTrue(SavedPinVisibility.isVisible(cameraDistance: SavedPinVisibility.maximumCameraDistance))
    }

    func testPinsHiddenAtCityAndCountryScale() {
        XCTAssertFalse(SavedPinVisibility.isVisible(cameraDistance: SavedPinVisibility.maximumCameraDistance + 1))
        XCTAssertFalse(SavedPinVisibility.isVisible(cameraDistance: 20_000))
        XCTAssertFalse(SavedPinVisibility.isVisible(cameraDistance: 5_000_000))
    }

    func testPinsHiddenUntilCameraIsKnownAndValid() {
        let distances: [Double?] = [nil, .nan, .infinity, -.infinity, 0, -600]
        for distance in distances {
            XCTAssertFalse(SavedPinVisibility.isVisible(cameraDistance: distance))
        }
    }
}
