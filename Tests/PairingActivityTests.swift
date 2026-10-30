import XCTest
@testable import SessionPresentation

final class PairingActivityTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func request(_ state: PairingActivity, id: UUID = UUID()) -> SessionActivityRequest {
        SessionActivityRequest(id: id, snapshot: SessionSnapshot(phase: .connecting, startedAt: now,
            expiresAt: state.visibleUntil, lowPower: false, pairing: state))
    }

    func testOnlySixASCIIDigitsAreAcceptedAndLeadingZerosSurvive() {
        for invalid in [nil, "", "12345", "1234567", "123 45", "１２３４５６", "abc123"] {
            XCTAssertFalse(PairingActivity.validCode(invalid))
            XCTAssertNil(PairingActivity(stage: .code, code: invalid, now: now).visibleCode(at: now))
        }
        XCTAssertEqual(PairingActivity(stage: .code, code: "001234", now: now).visibleCode(at: now), "001234")
    }

    func testCodeAppearsOnlyAfterNativeCodeStage() {
        for stage in [PairingActivity.Stage.waiting, .connected] {
            let state = PairingActivity(stage: stage, code: "123456", now: now)
            XCTAssertNil(state.code)
            XCTAssertNil(state.visibleCode(at: now))
        }
    }

    func testExpiryStalenessAndClockRollbackHideCodeWithoutHostCleanup() {
        let state = PairingActivity(stage: .code, code: "123456", now: now)
        XCTAssertEqual(state.visibleCode(at: state.visibleUntil.addingTimeInterval(-1)), "123456")
        XCTAssertNil(state.visibleCode(at: state.visibleUntil))
        XCTAssertNil(state.visibleCode(at: now.addingTimeInterval(3600)))
        XCTAssertNil(state.visibleCode(at: now.addingTimeInterval(-1)))
        XCTAssertNil(state.visibleCode(at: now, systemIsStale: true))
    }

    func testOldActivityPayloadStillDecodesAndNewPayloadIsSmall() throws {
        let old = SessionSnapshot(phase: .active, startedAt: now, lastConfirmedAt: now, lowPower: false)
        let data = try JSONEncoder().encode(old)
        XCTAssertNil((try JSONSerialization.jsonObject(with: data) as? [String: Any])?["pairing"])
        XCTAssertNil(try JSONDecoder().decode(SessionSnapshot.self, from: data).pairing)
        let state = try XCTUnwrap(request(PairingActivity(stage: .code, code: "123456", now: now)).snapshot)
        let newData = try JSONEncoder().encode(state)
        XCTAssertEqual(try JSONDecoder().decode(SessionSnapshot.self, from: newData), state)
        XCTAssertLessThan(newData.count, 4096)
    }

    func testIdleSessionUpdatesCannotDismissPairingCode() {
        var selection = SessionActivitySelection()
        let owner = UUID()
        let setup = request(PairingActivity(stage: .waiting, now: now))
        selection.beginPairing(owner: owner, request: setup)
        selection.setSession(SessionActivityRequest(id: UUID(), snapshot: nil))
        XCTAssertTrue(selection.updatePairing(owner: owner, state: PairingActivity(stage: .code, code: "123456", now: now)))
        XCTAssertEqual(selection.current.id, setup.id)
        XCTAssertEqual(selection.current.snapshot?.pairing?.visibleCode(at: now), "123456")
    }

    func testFinishRemovesCodeAndRejectsLateCallback() {
        var selection = SessionActivitySelection()
        let owner = UUID()
        let code = PairingActivity(stage: .code, code: "123456", now: now)
        selection.beginPairing(owner: owner, request: request(code))
        XCTAssertTrue(selection.endPairing(owner: owner))
        XCTAssertNil(selection.current.snapshot)
        XCTAssertNil(selection.pairing)
        XCTAssertNil(selection.pairingOwner)
        XCTAssertFalse(selection.updatePairing(owner: owner, state: code))
        XCTAssertNil(selection.current.snapshot)
    }

    func testOldAttemptCannotUpdateOrEndNewAttempt() {
        var selection = SessionActivitySelection()
        let oldOwner = UUID(), newOwner = UUID()
        selection.beginPairing(owner: oldOwner, request: request(PairingActivity(stage: .waiting, now: now)))
        selection.endPairing(owner: oldOwner)
        let newRequest = request(PairingActivity(stage: .connected, now: now))
        selection.beginPairing(owner: newOwner, request: newRequest)
        XCTAssertFalse(selection.updatePairing(owner: oldOwner, state: PairingActivity(stage: .code, code: "123456", now: now)))
        XCTAssertFalse(selection.endPairing(owner: oldOwner))
        XCTAssertEqual(selection.current, newRequest)
    }

    func testSessionStateIsPreservedWhenPairingEnds() {
        var selection = SessionActivitySelection()
        let owner = UUID()
        let session = SessionActivityRequest(id: UUID(), snapshot: SessionSnapshot(phase: .active,
            startedAt: now, lastConfirmedAt: now, lowPower: false))
        selection.beginPairing(owner: owner, request: request(PairingActivity(stage: .waiting, now: now)))
        selection.setSession(session)
        selection.endPairing(owner: owner)
        XCTAssertEqual(selection.current, session)
    }
}
