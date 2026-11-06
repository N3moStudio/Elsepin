import XCTest
@testable import SessionPresentation

final class DiagnosticReportTests: XCTestCase {
    func testOSReportSurvivesRealLogFieldLimitsAndUnicode() throws {
        let original = Data(String(repeating: "{\"reason\":\"Crash – café 🔎\"}", count: 150).utf8)
        let parts = try XCTUnwrap(DiagnosticReportChunks.encode(original))
        let stored = parts.map { DeveloperLogEvent(process: "test", event: "system_report_part", details: ["data": $0]).details["data"]! }
        XCTAssertGreaterThan(stored.count, 1)
        XCTAssertEqual(Data(base64Encoded: stored.joined()), original)
    }
    func testOversizedReportIsOmittedInsteadOfSilentlyTruncated() {
        XCTAssertNil(DiagnosticReportChunks.encode(Data(repeating: 0, count: DiagnosticReportChunks.maximumBytes + 1)))
        XCTAssertNil(DiagnosticReportChunks.encode(Data()))
        XCTAssertNotNil(DiagnosticReportChunks.encode(Data(repeating: 1, count: DiagnosticReportChunks.maximumBytes)))
    }
    func testCriticalEvidenceFlushesWhileRoutineObservationsBatch() {
        for event in ["route_plan_started", "route_plan_failed", "route_search_choice", "system_report_end", "touch_cancelled", "clear_result"] {
            XCTAssertFalse(DeveloperLogEvent(process: "test", event: event).canBatch)
        }
        XCTAssertTrue(DeveloperLogEvent(process: "test", event: "touch_began").canBatch)
        XCTAssertTrue(DeveloperLogEvent(process: "test", event: "developer_endpoint_check", details: ["reachable": "true"]).canBatch)
        XCTAssertFalse(DeveloperLogEvent(process: "test", event: "developer_endpoint_check", details: ["reachable": "false"]).canBatch)
        XCTAssertFalse(DeveloperLogEvent(process: "test", event: "energy_snapshot", details: ["reason": "user_reported_heat"]).canBatch)
    }
}
