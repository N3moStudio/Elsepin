import XCTest
@testable import SessionPresentation

final class NextRouteTimingTests: XCTestCase {
    func testWaitAndSingleScheduledWindow() {
        XCTAssertEqual(NextRouteTiming.decision(now: 99, due: 100, connected: true, sameRoute: true, atOrigin: true), .wait)
        XCTAssertEqual(NextRouteTiming.decision(now: 100, due: 100, connected: true, sameRoute: true, atOrigin: true), .start)
        XCTAssertEqual(NextRouteTiming.decision(now: 131, due: 100, connected: true, sameRoute: true, atOrigin: true), .cancel)
    }
    func testChangedContextOrMissingEvidenceCancels() {
        XCTAssertEqual(NextRouteTiming.decision(now: 100, due: 100, connected: false, sameRoute: true, atOrigin: true), .cancel)
        XCTAssertEqual(NextRouteTiming.decision(now: 100, due: 100, connected: true, sameRoute: false, atOrigin: true), .cancel)
        XCTAssertEqual(NextRouteTiming.decision(now: 100, due: 100, connected: true, sameRoute: true, atOrigin: false), .cancel)
        XCTAssertEqual(NextRouteTiming.decision(now: .nan, due: 100, connected: true, sameRoute: true, atOrigin: true), .cancel)
    }
}
