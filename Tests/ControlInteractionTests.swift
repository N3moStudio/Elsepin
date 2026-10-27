import XCTest
@testable import SessionPresentation

final class ControlInteractionTests: XCTestCase {
    func testInterruptedTouchRejectsLateChangesAndRelease() {
        var touch = ControlTouchSession()
        XCTAssertTrue(touch.update())
        touch.interrupt(gestureActive: true)
        XCTAssertFalse(touch.update())
        XCTAssertFalse(touch.finish())
        XCTAssertTrue(touch.update()) // A fresh touch works after the gesture reset.
        XCTAssertTrue(touch.finish())
        XCTAssertFalse(touch.finish()) // Cleanup cannot finish the same touch twice.
    }

    func testInterruptionBeforeFirstChangedEventBlocksThatTouch() {
        var touch = ControlTouchSession()
        touch.interrupt(gestureActive: true)
        XCTAssertFalse(touch.update())
        touch.finish()
        XCTAssertTrue(touch.update())
    }

    func testIdleCleanupDoesNotBlockNextTouch() {
        var touch = ControlTouchSession()
        touch.interrupt(gestureActive: false)
        XCTAssertTrue(touch.update())
    }

    func testCanceledTrayDragRestoresBothAnchorsWithoutCommitting() {
        for collapsed in [false, true] {
            var drag = ControlTrayDrag()
            drag.update(x: 0, y: collapsed ? -150 : 150)
            XCTAssertNotEqual(drag.translation, 0)
            drag.gestureDidReset() // Cancellation has no onEnded callback.
            XCTAssertEqual(drag.translation, 0)
            XCTAssertFalse(drag.isTracking)
            XCTAssertEqual(drag.finish(collapsed: collapsed, height: 200, predictedY: -300), collapsed)
        }
    }

    func testResizeOrBackgroundBlocksOldTrayTouchUntilReset() {
        var drag = ControlTrayDrag()
        drag.update(x: 0, y: 70)
        drag.interrupt(gestureActive: true)
        drag.update(x: 0, y: 180)
        XCTAssertEqual(drag.translation, 0)
        XCTAssertFalse(drag.finish(collapsed: false, height: 200, predictedY: 300))
        drag.gestureDidReset()
        drag.update(x: 0, y: 150)
        XCTAssertTrue(drag.finish(collapsed: false, height: 200, predictedY: 150))
    }

    func testHorizontalOwnershipCannotFlipMidGesture() {
        var drag = ControlTrayDrag()
        drag.update(x: 30, y: 12)
        drag.update(x: 30, y: 200)
        XCTAssertEqual(drag.translation, 0)
        XCTAssertFalse(drag.finish(collapsed: false, height: 200, predictedY: 300))
        drag.update(x: 0, y: 40) // Next touch can be vertical.
        drag.update(x: 100, y: 160)
        XCTAssertEqual(drag.translation, 160)
        XCTAssertTrue(drag.finish(collapsed: false, height: 200, predictedY: 160))
    }

    func testReleaseUsesProjectedPositionIncludingReversal() {
        var drag = ControlTrayDrag()
        drag.update(x: 0, y: 150)
        XCTAssertFalse(drag.finish(collapsed: false, height: 200, predictedY: -40))
        drag.update(x: 0, y: -150)
        XCTAssertTrue(drag.finish(collapsed: true, height: 200, predictedY: 40))
        drag.update(x: 0, y: 20)
        XCTAssertTrue(drag.finish(collapsed: false, height: 200, predictedY: 180))
        drag.update(x: 0, y: -20)
        XCTAssertFalse(drag.finish(collapsed: true, height: 200, predictedY: -180))
    }

    func testSmallReleaseAndExactMidpointKeepCurrentAnchor() {
        for collapsed in [false, true] {
            for distance in [20.0, 100.0] {
                var drag = ControlTrayDrag()
                let travel = collapsed ? -distance : distance
                drag.update(x: 0, y: travel)
                XCTAssertEqual(drag.finish(collapsed: collapsed, height: 200, predictedY: travel), collapsed)
            }
        }
    }

    func testInvalidTrayGeometryCannotLeaveOffsetOrCommit() {
        for invalid in [Double.nan, .infinity, -.infinity] {
            var drag = ControlTrayDrag()
            drag.update(x: 0, y: 50)
            drag.update(x: invalid, y: 150)
            XCTAssertEqual(drag.translation, 0)
            XCTAssertFalse(drag.finish(collapsed: false, height: 200, predictedY: 300))
            drag.update(x: 0, y: 150)
            XCTAssertFalse(drag.finish(collapsed: false, height: invalid, predictedY: 300))
            XCTAssertEqual(drag.translation, 0)
        }
        var drag = ControlTrayDrag()
        drag.update(x: 0, y: 150)
        XCTAssertTrue(drag.finish(collapsed: false, height: 200, predictedY: .nan))
    }

    func testJoystickClampsDirectionAndDistance() {
        let vector = JoystickInput.vector(x: 60, y: -80, radius: 32)
        XCTAssertEqual(vector.x, 0.6, accuracy: 0.000001)
        XCTAssertEqual(vector.y, -0.8, accuracy: 0.000001)
        XCTAssertEqual(hypot(vector.x, vector.y), 1, accuracy: 0.000001)
        let small = JoystickInput.vector(x: 8, y: 0, radius: 32)
        XCTAssertEqual(small.x, 0.25)
        XCTAssertEqual(small.y, 0)
    }

    func testInvalidJoystickInputAlwaysProducesZero() {
        for (x, y, radius) in [(Double.nan, 1.0, 32.0), (1, .infinity, 32), (1, 1, .nan),
                               (1, 1, .infinity), (1, 1, 0), (1, 1, -32),
                               (.greatestFiniteMagnitude, .greatestFiniteMagnitude, 32)] {
            let vector = JoystickInput.vector(x: x, y: y, radius: radius)
            XCTAssertEqual(vector.x, 0)
            XCTAssertEqual(vector.y, 0)
        }
    }

    func testCanceledJoystickRequiresFreshTouch() {
        var input = JoystickInput()
        XCTAssertTrue(input.updateTouch())
        XCTAssertTrue(input.hasMovement)
        input.interrupt(gestureActive: true)
        XCTAssertFalse(input.hasMovement)
        XCTAssertFalse(input.updateTouch())
        XCTAssertNil(input.beginNudge())
        XCTAssertFalse(input.finishTouch())
        XCTAssertTrue(input.updateTouch())
        XCTAssertTrue(input.finishTouch())
        XCTAssertFalse(input.hasMovement)
    }

    func testGestureCancellationFinishesMovementOnce() {
        var input = JoystickInput()
        XCTAssertTrue(input.updateTouch())
        XCTAssertTrue(input.finishTouch()) // GestureState reset without onEnded.
        XCTAssertFalse(input.hasMovement)
        XCTAssertFalse(input.finishTouch())
        XCTAssertTrue(input.updateTouch())
    }

    func testOldNudgeCannotStopNewTouchOrNewNudge() throws {
        var input = JoystickInput()
        let first = try XCTUnwrap(input.beginNudge())
        let second = try XCTUnwrap(input.beginNudge())
        XCTAssertFalse(input.finishNudge(first))
        XCTAssertTrue(input.hasMovement)
        XCTAssertTrue(input.updateTouch())
        XCTAssertFalse(input.finishNudge(second))
        XCTAssertTrue(input.isTracking)
        XCTAssertTrue(input.finishTouch())
        let third = try XCTUnwrap(input.beginNudge())
        XCTAssertTrue(input.finishNudge(third))
        XCTAssertFalse(input.finishNudge(third))
        XCTAssertFalse(input.hasMovement)
    }

    func testStopInvalidatesNudgeAndLateTouchResetDoesNotCancelNewNudge() throws {
        var input = JoystickInput()
        let first = try XCTUnwrap(input.beginNudge())
        input.interrupt(gestureActive: false)
        XCTAssertFalse(input.finishNudge(first))
        XCTAssertFalse(input.hasMovement)
        let second = try XCTUnwrap(input.beginNudge())
        XCTAssertFalse(input.finishTouch()) // Delayed reset of an already-ended gesture.
        XCTAssertTrue(input.hasMovement)
        XCTAssertTrue(input.finishNudge(second))
    }

    func testIdleHiddenPadDoesNotOwnVisiblePadsMovement() {
        var hidden = JoystickInput(), visible = JoystickInput()
        XCTAssertTrue(visible.updateTouch())
        XCTAssertFalse(hidden.hasMovement)
        hidden.interrupt(gestureActive: false)
        XCTAssertFalse(hidden.hasMovement) // No zero callback from unrelated layout cleanup.
        XCTAssertTrue(visible.hasMovement)
    }
}
