import Foundation
import XCTest
@testable import SessionPresentation

final class SessionLifetimeTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suite: String!

    override func setUp() {
        suite = "SessionLifetimeTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)!
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
    }

    func testReadsLegacyUnfinishedMarkerWithoutTreatingItAsAnActiveProcess() {
        defaults.set(true, forKey: "locus.unfinishedSession")
        let lifetime = SessionLifetime(defaults: defaults)
        XCTAssertTrue(lifetime.previousLocationMayRemain)
        XCTAssertTrue(lifetime.acceptsCommands)
    }

    func testTerminationClosesCommandGateOnceWithoutClaimingClearSucceeded() {
        let lifetime = SessionLifetime(defaults: defaults)
        lifetime.locationMayRemain()
        XCTAssertTrue(lifetime.beginTermination())
        XCTAssertFalse(lifetime.beginTermination())
        XCTAssertFalse(lifetime.acceptsCommands)
        XCTAssertTrue(lifetime.previousLocationMayRemain)
    }

    func testSuccessfulClearRemovesMarkerButCannotReopenTerminatingProcess() {
        let lifetime = SessionLifetime(defaults: defaults)
        lifetime.locationMayRemain()
        _ = lifetime.beginTermination()
        lifetime.locationCleared()
        XCTAssertFalse(lifetime.previousLocationMayRemain)
        XCTAssertFalse(lifetime.acceptsCommands)
    }

    func testAbruptExitWithNoCallbackRetainsUnknownLocationOnNextLaunch() {
        let oldProcess = SessionLifetime(defaults: defaults)
        oldProcess.locationMayRemain()
        let newProcess = SessionLifetime(defaults: defaults)
        XCTAssertTrue(newProcess.previousLocationMayRemain)
        XCTAssertTrue(newProcess.acceptsCommands)
    }

    func testCleanExitDoesNotInventUnfinishedSession() {
        let lifetime = SessionLifetime(defaults: defaults)
        _ = lifetime.beginTermination()
        XCTAssertFalse(lifetime.previousLocationMayRemain)
        XCTAssertFalse(SessionLifetime(defaults: defaults).previousLocationMayRemain)
    }

    func testReadingEvidenceDoesNotCloseCommandGate() {
        let lifetime = SessionLifetime(defaults: defaults)
        lifetime.locationMayRemain()
        // Reading launch evidence is not a termination signal.
        for _ in 0..<10 { XCTAssertTrue(lifetime.previousLocationMayRemain) }
        XCTAssertTrue(lifetime.acceptsCommands)
        lifetime.locationCleared()
        XCTAssertFalse(SessionLifetime(defaults: defaults).previousLocationMayRemain)
    }

    func testNativeWriteMarkerSurvivesUnflushedDefaultsAndIsRemovedOnlyByClear() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let marker = folder.appendingPathComponent("location-may-remain")
        let lifetime = SessionLifetime(defaults: defaults, markerURL: marker)
        XCTAssertTrue(lifetime.locationMayRemain())
        defaults.removeObject(forKey: "locus.unfinishedSession") // simulate lost asynchronous preference write
        let restarted = SessionLifetime(defaults: defaults, markerURL: marker)
        XCTAssertTrue(restarted.previousLocationMayRemain)
        restarted.locationCleared()
        XCTAssertFalse(FileManager.default.fileExists(atPath: marker.path))
        XCTAssertFalse(SessionLifetime(defaults: defaults, markerURL: marker).previousLocationMayRemain)
    }

    func testNativeWriteMustNotProceedWhenRecoveryStateCannotBeSaved() throws {
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try Data([1]).write(to: path)
        defer { try? FileManager.default.removeItem(at: path) }
        let lifetime = SessionLifetime(defaults: defaults, markerURL: path.appendingPathComponent("impossible"))
        XCTAssertFalse(lifetime.locationMayRemain())
        XCTAssertTrue(lifetime.previousLocationMayRemain)
    }

    func testCommandQueuedBeforeShutdownCannotStartAfterGateCloses() {
        let lifetime = SessionLifetime(defaults: defaults)
        let queue = DispatchQueue(label: "session-lifetime-test")
        let finished = expectation(description: "queued command drained")
        queue.suspend()
        queue.async {
            XCTAssertFalse(lifetime.acceptsCommands, "A queued write must check the gate at execution time")
            finished.fulfill()
        }
        XCTAssertTrue(lifetime.beginTermination())
        queue.resume()
        wait(for: [finished], timeout: 2)
    }
}
