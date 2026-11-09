import XCTest
@testable import SessionPresentation

final class DiagnosticNumberTests: XCTestCase {
    func testNonfiniteAndOutOfRangeValuesCannotTrap() {
        for value in [Double.nan, .infinity, -.infinity] {
            XCTAssertEqual(DiagnosticNumber.rounded(value), "unavailable")
        }
        XCTAssertEqual(DiagnosticNumber.rounded(.greatestFiniteMagnitude), "out_of_range")
        XCTAssertEqual(DiagnosticNumber.rounded(42.9), "42")
        XCTAssertEqual(DiagnosticNumber.rounded(-12.8), "-12")
    }
}
