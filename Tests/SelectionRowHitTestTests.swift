import XCTest
@testable import SessionPresentation

final class SelectionRowHitTestTests: XCTestCase {
    func testTallRowWinsOverCloserAdjacentCenter() {
        let frames = [1: CGRect(x: 0, y: 200, width: 200, height: 200),
                      2: CGRect(x: 0, y: 410, width: 200, height: 40)]
        XCTAssertEqual(SelectionRowHitTest.target(y: 395, frames: frames), 1)
        XCTAssertEqual(SelectionRowHitTest.target(y: 408, frames: frames), 2)
        XCTAssertEqual(SelectionRowHitTest.target(y: 405, frames: frames), 1)
    }

    func testScrollAndScreenOffsetsDoNotChangeTarget() {
        for offset in [-300.0, 0, 180, 500] {
            let frames = [1: CGRect(x: 0, y: 100 + offset, width: 200, height: 60),
                          2: CGRect(x: 0, y: 180 + offset, width: 200, height: 60)]
            XCTAssertEqual(SelectionRowHitTest.target(y: 210 + offset, frames: frames), 2)
        }
    }

    func testMissingOrInvalidGeometryDoesNotSelect() {
        XCTAssertNil(SelectionRowHitTest.target(y: 10, frames: [Int: CGRect]()))
        XCTAssertNil(SelectionRowHitTest.target(y: .nan, frames: [1: CGRect(x: 0, y: 0, width: 100, height: 50)]))
        XCTAssertNil(SelectionRowHitTest.target(y: 10, frames: [1: .zero]))
    }
}
