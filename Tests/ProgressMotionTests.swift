import XCTest
@testable import SessionPresentation

final class ProgressMotionTests: XCTestCase {
    func testVisibleForegroundProgressCanAnimate() {
        XCTAssertFalse(ProgressMotion.isPaused(visible: true, active: true, reduceMotion: false, lowPower: false))
    }

    func testReduceMotionKeepsProgressStatic() {
        XCTAssertTrue(ProgressMotion.isPaused(visible: true, active: true, reduceMotion: true, lowPower: false))
    }

    func testLowPowerKeepsProgressStatic() {
        XCTAssertTrue(ProgressMotion.isPaused(visible: true, active: true, reduceMotion: false, lowPower: true))
    }

    func testBackgroundingAndDisappearancePauseUntilBothRecover() {
        XCTAssertTrue(ProgressMotion.isPaused(visible: true, active: false, reduceMotion: false, lowPower: false))
        XCTAssertTrue(ProgressMotion.isPaused(visible: false, active: true, reduceMotion: false, lowPower: false))
        XCTAssertTrue(ProgressMotion.isPaused(visible: false, active: false, reduceMotion: false, lowPower: false))
        XCTAssertFalse(ProgressMotion.isPaused(visible: true, active: true, reduceMotion: false, lowPower: false))
    }
}
