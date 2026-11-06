import XCTest
@testable import SessionPresentation

final class MapPinSizeTests: XCTestCase {
    func testPinSizeBoundsAndLargerDefault() {
        XCTAssertEqual(MapPinSize.bounded(0), 22)
        XCTAssertEqual(MapPinSize.bounded(500), 64)
        XCTAssertEqual(MapPinSize.bounded(.nan), 34)
        XCTAssertEqual(MapPinSize.bounded(.infinity), 34)
        XCTAssertEqual(MapPinSize.bounded(45), 45)
        XCTAssertGreaterThan(MapPinSize.defaultValue, MapPinSize.range.lowerBound)
    }
}
