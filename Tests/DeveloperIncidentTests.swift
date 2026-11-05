import Foundation
import XCTest
@testable import SessionPresentation

final class DeveloperIncidentTests: XCTestCase {
    private let moment = Date(timeIntervalSince1970: 1_790_000_000)

    private func folder() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }
    private func rows(_ data: Data) throws -> [[String: Any]] {
        try data.split(separator: 10).map { try XCTUnwrap(JSONSerialization.jsonObject(with: Data($0)) as? [String: Any]) }
    }
    private func line(_ event: String, offset: Double, details: [String: String] = [:]) throws -> Data {
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        var data = try encoder.encode(DeveloperLogEvent(time: moment.addingTimeInterval(offset), process: "test", event: event, details: details))
        data.append(10); return data
    }

    func testWindowIncludesEdgesAndOwnLaterNoteButNotUnrelatedHistory() throws {
        let url = try folder().appendingPathComponent("events.jsonl")
        var input = Data()
        for offset in [-301.0, -300, 0, 300, 301] { input.append(try line("event_\(offset)", offset: offset)) }
        input.append(try line("problem_note", offset: 400, details: ["marker": "mine", "note": "afterwards"]))
        input.append(try line("problem_note", offset: 401, details: ["marker": "another"]))
        try input.write(to: url)
        let slice = try DeveloperIncident.read(from: url, around: moment, marker: "mine")
        XCTAssertEqual(slice.events, 4)
        XCTAssertEqual(try rows(slice.data).compactMap { $0["event"] as? String }, ["event_-300.0", "event_0.0", "event_300.0", "problem_note"])
        XCTAssertFalse(slice.truncated)
        XCTAssertEqual(slice.malformedLines, 0)
        XCTAssertEqual(try Data(contentsOf: url), input)
    }

    func testBoundedExportKeepsWholeRecordsAndReportsOmissions() throws {
        let url = try folder().appendingPathComponent("events.jsonl")
        let first = try line("first", offset: 0), second = try line("second", offset: 1)
        try (first + second).write(to: url)
        let slice = try DeveloperIncident.read(from: url, around: moment, marker: "mine", maximumBytes: first.count)
        XCTAssertEqual(slice.data, first)
        XCTAssertEqual(slice.events, 1)
        XCTAssertTrue(slice.truncated)
    }

    func testStreamingAcrossChunksAndMalformedTailAreExplicit() throws {
        let url = try folder().appendingPathComponent("events.jsonl")
        var input = Data("not-json\n".utf8)
        for n in 0..<450 { input.append(try line("event_\(n)", offset: 0, details: ["value": String(repeating: "z", count: 300)])) }
        input.append(Data("unfinished".utf8))
        try input.write(to: url)
        let slice = try DeveloperIncident.read(from: url, around: moment, marker: "mine")
        XCTAssertEqual(slice.events, 450)
        XCTAssertEqual(slice.malformedLines, 2)
        XCTAssertEqual(try rows(slice.data).count, 450)
    }

    func testOversizedCorruptRecordFailsWithoutModifyingSource() throws {
        let url = try folder().appendingPathComponent("events.jsonl")
        let input = Data(repeating: 65, count: 200 * 1024)
        try input.write(to: url)
        XCTAssertThrowsError(try DeveloperIncident.read(from: url, around: moment, marker: "mine"))
        XCTAssertEqual(try Data(contentsOf: url), input)
    }

    func testStoreExportsRetainedMarkerWhileRecordingOffAndRejectsAfterClear() async throws {
        let name = "incident-test-" + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        addTeardownBlock { UserDefaults(suiteName: name)?.removePersistentDomain(forName: name) }
        defaults.set(true, forKey: DeveloperLogStore.enabledKey)
        let time = moment
        let store = DeveloperLogStore(folder: try folder(), defaults: defaults, now: { time })
        let marker = UUID()
        try await store.markProblem(id: marker, at: time)
        store.record("route_interaction", ["attempt": "test", "stage": "hold_began"])
        try await store.addProblemNote("drag stopped", marker: marker)
        store.setEnabled(false)
        let data = try await store.exportIncident(marker: marker.uuidString)
        let entries = try rows(data)
        XCTAssertEqual(entries.first?["event"] as? String, "incident_export_information")
        XCTAssertTrue(entries.contains { $0["event"] as? String == "problem_note" })
        XCTAssertTrue(entries.contains { $0["event"] as? String == "route_interaction" })
        XCTAssertFalse(store.enabled)
        await store.clear()
        do { _ = try await store.exportIncident(marker: marker.uuidString); XCTFail("Expired marker exported") }
        catch { XCTAssertTrue(error is IncidentExportError) }
    }

    func testAttemptKeepsIdentityAcrossStagesAndDistinctAttemptsDoNotCollide() {
        let route = UUID(), attempt = RouteDiagnosticAttempt(kind: .marker, routeID: route)
        let first = attempt.fields(stage: "hold_began"), second = attempt.fields(stage: "completed", details: ["attempt": "wrong", "result": "accepted"])
        XCTAssertEqual(first["attempt"], second["attempt"])
        XCTAssertEqual(second["route"], route.uuidString)
        XCTAssertEqual(second["result"], "accepted")
        XCTAssertNotEqual(first["attempt"], RouteDiagnosticAttempt(kind: .retry, routeID: route).fields(stage: "requested")["attempt"])
    }

    func testTimelineOnlySummarizesUserActionsAndDoesNotCallRequestsConfirmed() {
        var timeline = SessionTimelineArchive(windowStart: moment)
        let attempt = RouteDiagnosticAttempt(kind: .retry, routeID: UUID())
        for stage in ["requested", "write_requested", "write_result", "completed"] {
            timeline.include(DeveloperLogEvent(time: moment, process: "test", event: "route_interaction", details: attempt.fields(stage: stage)))
        }
        XCTAssertEqual(timeline.entries.map(\.title), ["Route retry requested", "Route retry confirmed"])
        XCTAssertTrue(timeline.entries.last?.detail.contains("other apps haven't been checked") == true)
    }
}
