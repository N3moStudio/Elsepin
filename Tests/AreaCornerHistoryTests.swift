import XCTest
@testable import SessionPresentation

final class AreaCornerHistoryTests: XCTestCase {
    private let points = [RoutePoint(latitude: 1, longitude: 1), RoutePoint(latitude: 1, longitude: 2), RoutePoint(latitude: 2, longitude: 2)]

    func testExistingCornersCanBeUndoneAndRedoneInOrder() {
        var history = AreaCornerHistory(points)
        history.undo(); history.undo()
        XCTAssertEqual(history.points, Array(points.prefix(1)))
        history.redo(); history.redo()
        XCTAssertEqual(history.points, points)
        XCTAssertFalse(history.canRedo)
    }

    func testNewCornerOrEditedOutlineDiscardsRedo() {
        var history = AreaCornerHistory(points)
        history.undo()
        let revised = history.points + [RoutePoint(latitude: 3, longitude: 3)]
        history.replace(revised)
        XCTAssertFalse(history.canRedo)
        history.redo()
        XCTAssertEqual(history.points, revised)
    }

    func testReopeningSavedOutlineDoesNotRestorePreviousRedo() {
        var history = AreaCornerHistory(points)
        history.undo()
        let reopened = AreaCornerHistory(history.points)
        XCTAssertFalse(reopened.canRedo)
        XCTAssertTrue(reopened.canUndo)
        var empty = AreaCornerHistory([])
        empty.undo(); empty.redo()
        XCTAssertFalse(empty.canUndo)
        XCTAssertFalse(empty.canRedo)
    }
}
