import XCTest
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import SessionPresentation

final class StableReleaseUpdatesTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let endpoint = URL(string: "https://api.github.com/repos/N3moStudio/Elsepin-Releases/releases/latest")!

    private func release(_ tag: String = "v2.6.0", id: Int64 = 1) -> StableRelease {
        StableRelease(id: id, tag: tag, url: URL(string: "https://github.com/N3moStudio/Elsepin-Releases/releases/tag/\(tag)")!)
    }
    private func payload(tag: String = "v2.6.0", id: Int = 1, draft: Bool = false, prerelease: Bool = false,
                         url: String? = nil, published: Any = "2026-10-24T10:00:00Z") -> Data {
        try! JSONSerialization.data(withJSONObject: ["id": id, "tag_name": tag,
            "html_url": url ?? "https://github.com/N3moStudio/Elsepin-Releases/releases/tag/\(tag)",
            "draft": draft, "prerelease": prerelease, "published_at": published])
    }
    private func response(_ code: Int = 200, headers: [String: String] = [:]) -> HTTPURLResponse {
        HTTPURLResponse(url: endpoint, statusCode: code, httpVersion: "HTTP/1.1", headerFields: headers)!
    }
    private func storage() -> (UserDefaults, String) {
        let name = "StableReleaseTests.\(UUID().uuidString)"
        return (UserDefaults(suiteName: name)!, name)
    }

    func testNumericVersionsAndPrereleaseTagRejection() {
        XCTAssertLessThan(ReleaseVersion("v2.9")!, ReleaseVersion("2.10.0")!)
        XCTAssertEqual(ReleaseVersion("V2.5"), ReleaseVersion("2.5.0"))
        for tag in ["", "v", " 2.5", "2.5 ", "2..5", "2.5.4.1", "2.6.0-beta.1", "2.6-rc", "2.6+test", "latest", "2.5x", "-2.6", String(repeating: "9", count: 40)] {
            XCTAssertNil(ReleaseVersion(tag), tag)
        }
    }

    @MainActor func testManualCheckBypassesDailyGateButNotServerBackoff() async {
        let (defaults, name) = storage(); defer { defaults.removePersistentDomain(forName: name) }
        let stub = ReleaseStub([(payload(), response()), (Data(), response(429, headers: ["Retry-After": "120"])), (payload(), response())])
        let checker = StableReleaseChecker(defaults: defaults, fetch: { try await stub.send($0) })
        await checker.checkIfDue(at: now)
        await checker.checkIfDue(at: now.addingTimeInterval(1), force: true)
        var count = await stub.count; XCTAssertEqual(count, 2)
        XCTAssertTrue(checker.state.lastCheckFailed)
        await checker.checkIfDue(at: now.addingTimeInterval(2), force: true)
        count = await stub.count; XCTAssertEqual(count, 2)
        await checker.checkIfDue(at: now.addingTimeInterval(121), force: true)
        count = await stub.count; XCTAssertEqual(count, 3)
        XCTAssertFalse(checker.state.lastCheckFailed)
    }

    func testManualClockRollbackCannotClearServerBackoff() {
        var state = ReleaseUpdateState(lastAttempt: now, retryAfter: now.addingTimeInterval(120))
        XCTAssertFalse(state.beginAttempt(at: now.addingTimeInterval(-30), force: true))
        XCTAssertEqual(state.retryAfter, now.addingTimeInterval(120))
    }

    @MainActor func testUnspecifiedRateLimitHasManualCooldown() async {
        let (defaults, name) = storage(); defer { defaults.removePersistentDomain(forName: name) }
        let stub = ReleaseStub([(Data(), response(403))])
        let checker = StableReleaseChecker(defaults: defaults, fetch: { try await stub.send($0) })
        await checker.checkIfDue(at: now, force: true)
        await checker.checkIfDue(at: now.addingTimeInterval(1), force: true)
        let count = await stub.count; XCTAssertEqual(count, 1)
        XCTAssertEqual(checker.state.retryAfter, now.addingTimeInterval(60))
    }

    func testOnlyNewerOfficialVersionsOrSameVersionBetaPromotion() {
        XCTAssertTrue(release().isUpdate(for: "2.5.4", isPrerelease: false))
        XCTAssertFalse(release().isUpdate(for: "2.6.0", isPrerelease: false))
        XCTAssertTrue(release().isUpdate(for: "2.6.0", isPrerelease: true))
        XCTAssertFalse(release("v2.4.4").isUpdate(for: "2.5.4", isPrerelease: true))
        XCTAssertFalse(release().isUpdate(for: "broken", isPrerelease: true))
    }

    func testReleaseLinksAreRestrictedToTheExactRepositoryAndTag() {
        XCTAssertTrue(release().isValid)
        for url in ["http://github.com/N3moStudio/Elsepin-Releases/releases/tag/v2.6.0",
                    "https://github.com.evil.test/N3moStudio/Elsepin-Releases/releases/tag/v2.6.0",
                    "https://github.com/Other/Shift/releases/tag/v2.6.0",
                    "https://github.com/N3moStudio/Elsepin-Releases/releases/latest",
                    "https://github.com/N3moStudio/Elsepin-Releases/releases/tag/v9.0.0",
                    "https://github.com/N3moStudio/Elsepin-Releases/releases/tag/v2.6.0?redirect=elsewhere",
                    "https://user@github.com/N3moStudio/Elsepin-Releases/releases/tag/v2.6.0",
                    "https://github.com:8443/N3moStudio/Elsepin-Releases/releases/tag/v2.6.0"] {
            XCTAssertFalse(StableRelease(id: 1, tag: "v2.6.0", url: URL(string: url)!).isValid, url)
        }
    }

    @MainActor func testDailyAttemptPersistsAcrossRelaunchAndRepeatedAppearances() async {
        let (defaults, name) = storage(); defer { defaults.removePersistentDomain(forName: name) }
        let stub = ReleaseStub([(payload(), response())])
        let first = StableReleaseChecker(defaults: defaults, fetch: { try await stub.send($0) })
        await first.checkIfDue(at: now)
        for seconds in [0.0, 1, 60, 86_399] { await first.checkIfDue(at: now.addingTimeInterval(seconds)) }
        let restarted = StableReleaseChecker(defaults: defaults, fetch: { try await stub.send($0) })
        await restarted.checkIfDue(at: now.addingTimeInterval(86_399))
        var count = await stub.count; XCTAssertEqual(count, 1)
        await restarted.checkIfDue(at: now.addingTimeInterval(86_400))
        count = await stub.count; XCTAssertEqual(count, 2)
        XCTAssertNotNil(restarted.state.update(for: "2.5.4", isPrerelease: false, at: now.addingTimeInterval(86_400)))
    }

    @MainActor func testOfflineAttemptDoesNotRetryOnEveryOpen() async {
        let (defaults, name) = storage(); defer { defaults.removePersistentDomain(forName: name) }
        let checker = StableReleaseChecker(defaults: defaults) { _ in throw URLError(.notConnectedToInternet) }
        await checker.checkIfDue(at: now)
        XCTAssertTrue(checker.state.lastCheckFailed)
        XCTAssertNil(checker.state.lastChecked)
        let stub = ReleaseStub([(payload(), response())])
        let restarted = StableReleaseChecker(defaults: defaults, fetch: { try await stub.send($0) })
        await restarted.checkIfDue(at: now.addingTimeInterval(60))
        let count = await stub.count; XCTAssertEqual(count, 0)
    }

    @MainActor func testConcurrentTriggersShareOneInFlightAttempt() async {
        let (defaults, name) = storage(); defer { defaults.removePersistentDomain(forName: name) }
        let began = expectation(description: "request started")
        let gate = ReleaseGate()
        let result = (payload(), response())
        let checker = StableReleaseChecker(defaults: defaults) { _ in began.fulfill(); await gate.wait(); return result }
        let task = Task { await checker.checkIfDue(at: now) }
        await fulfillment(of: [began], timeout: 2)
        await checker.checkIfDue(at: now.addingTimeInterval(86_400))
        XCTAssertEqual(checker.state.lastAttempt, now)
        XCTAssertTrue(checker.isChecking)
        await gate.open(); await task.value
        XCTAssertFalse(checker.isChecking)
    }

    @MainActor func testCancellationDiscardsLateResponseAndKeepsDailyGate() async {
        let (defaults, name) = storage(); defer { defaults.removePersistentDomain(forName: name) }
        let began = expectation(description: "request started")
        let gate = ReleaseGate(); let result = (payload(), response())
        let checker = StableReleaseChecker(defaults: defaults) { _ in began.fulfill(); await gate.wait(); return result }
        let task = Task { await checker.checkIfDue(at: now) }
        await fulfillment(of: [began], timeout: 2)
        task.cancel(); await gate.open(); await task.value
        XCTAssertNil(checker.state.release)
        XCTAssertNil(checker.state.lastChecked)
        XCTAssertEqual(checker.state.lastAttempt, now)
        XCTAssertFalse(checker.isChecking)
    }

    @MainActor func testConditionalRequestRetainsCachedReleaseAndDismissal() async {
        let (defaults, name) = storage(); defer { defaults.removePersistentDomain(forName: name) }
        let stub = ReleaseStub([(payload(), response(headers: ["ETag": "\"abc\""])), (Data(), response(304))])
        let checker = StableReleaseChecker(defaults: defaults, fetch: { try await stub.send($0) })
        await checker.checkIfDue(at: now); checker.dismiss(release())
        await checker.checkIfDue(at: now.addingTimeInterval(86_400))
        let requests = await stub.requests
        XCTAssertNil(requests[0].value(forHTTPHeaderField: "If-None-Match"))
        XCTAssertEqual(requests[1].value(forHTTPHeaderField: "If-None-Match"), "\"abc\"")
        XCTAssertEqual(requests[0].httpMethod, "GET")
        XCTAssertNil(requests[0].httpBody)
        XCTAssertNil(requests[0].value(forHTTPHeaderField: "Authorization"))
        XCTAssertEqual(requests[0].timeoutInterval, 10)
        XCTAssertEqual(requests[0].url, endpoint)
        XCTAssertEqual(checker.state.release, release())
        XCTAssertNil(checker.state.update(for: "2.5.4", isPrerelease: false, at: now.addingTimeInterval(86_400)))
        XCTAssertNotNil(checker.state.update(for: "2.5.4", isPrerelease: false, at: now.addingTimeInterval(86_400), includeDismissed: true))
    }

    @MainActor func testUnexpectedNotModifiedIsNotSuccessfulCheck() async {
        let (defaults, name) = storage(); defer { defaults.removePersistentDomain(forName: name) }
        let result = (Data(), response(304))
        let checker = StableReleaseChecker(defaults: defaults) { _ in result }
        await checker.checkIfDue(at: now)
        XCTAssertTrue(checker.state.lastCheckFailed)
        XCTAssertNil(checker.state.lastChecked)
    }

    @MainActor func testDraftPrereleaseUnpublishedAndMislabelledTagsNeverProduceNotice() async {
        for data in [payload(draft: true), payload(prerelease: true), payload(tag: "v2.6.0-beta.1"),
                     payload(published: NSNull()), payload(published: "not a date"), payload(id: 0),
                     payload(url: "https://example.com/release")] {
            let (defaults, name) = storage(); defer { defaults.removePersistentDomain(forName: name) }
            let response = response()
            let checker = StableReleaseChecker(defaults: defaults) { _ in (data, response) }
            await checker.checkIfDue(at: now)
            XCTAssertNil(checker.state.release)
            XCTAssertNil(checker.state.update(for: "2.5.4", isPrerelease: true, at: now))
        }
    }

    @MainActor func testMalformedOversizedAndFailedResponsesDoNotClaimUpToDate() async {
        for result in [(Data("{}".utf8), response()), (Data(repeating: 32, count: 262_145), response()),
                       (payload(), response(500))] {
            let (defaults, name) = storage(); defer { defaults.removePersistentDomain(forName: name) }
            let checker = StableReleaseChecker(defaults: defaults) { _ in result }
            await checker.checkIfDue(at: now)
            XCTAssertTrue(checker.state.lastCheckFailed)
            XCTAssertNil(checker.state.lastChecked)
        }
    }

    @MainActor func testDismissalSurvivesRestartAndOnlyNewTagReturns() async {
        let (defaults, name) = storage(); defer { defaults.removePersistentDomain(forName: name) }
        let stub = ReleaseStub([(payload(), response()), (payload(tag: "v2.7.0", id: 2), response())])
        let checker = StableReleaseChecker(defaults: defaults, fetch: { try await stub.send($0) })
        await checker.checkIfDue(at: now); checker.dismiss(release())
        let restarted = StableReleaseChecker(defaults: defaults, fetch: { try await stub.send($0) })
        XCTAssertNil(restarted.state.update(for: "2.5.4", isPrerelease: false, at: now))
        await restarted.checkIfDue(at: now.addingTimeInterval(86_400))
        XCTAssertEqual(restarted.state.update(for: "2.5.4", isPrerelease: false, at: now.addingTimeInterval(86_400))?.tag, "v2.7.0")
    }

    func testCachedNoticeExpiresAndInstalledUpdateHidesIt() {
        var state = ReleaseUpdateState(); state.lastChecked = now; state.release = release()
        XCTAssertNotNil(state.update(for: "2.5.4", isPrerelease: false, at: now))
        XCTAssertNil(state.update(for: "2.6.0", isPrerelease: false, at: now))
        XCTAssertNil(state.update(for: "2.5.4", isPrerelease: false, at: now.addingTimeInterval(7 * 86_400 + 1)))
        XCTAssertNil(state.update(for: "2.5.4", isPrerelease: false, at: now.addingTimeInterval(-1)))
    }

    func testClockRollbackDoesNotRepeatedlyCheckOrWaitForYears() {
        var state = ReleaseUpdateState(); state.lastAttempt = now.addingTimeInterval(10 * 86_400)
        XCTAssertFalse(state.beginAttempt(at: now))
        XCTAssertEqual(state.lastAttempt, now)
        XCTAssertFalse(state.beginAttempt(at: now.addingTimeInterval(100)))
        XCTAssertTrue(state.beginAttempt(at: now.addingTimeInterval(86_400)))
    }

    @MainActor func testRateLimitCanExtendButNeverShortenDailyWait() async {
        let (defaults, name) = storage(); defer { defaults.removePersistentDomain(forName: name) }
        let stub = ReleaseStub([(Data(), response(429, headers: ["Retry-After": "172800"])), (payload(), response())])
        let checker = StableReleaseChecker(defaults: defaults, fetch: { try await stub.send($0) })
        await checker.checkIfDue(at: now)
        await checker.checkIfDue(at: now.addingTimeInterval(86_400))
        var count = await stub.count; XCTAssertEqual(count, 1)
        await checker.checkIfDue(at: now.addingTimeInterval(172_800))
        count = await stub.count; XCTAssertEqual(count, 2)
        XCTAssertFalse(checker.state.lastCheckFailed)
    }

    @MainActor func testWithdrawnReleaseClearsNoticeAndETag() async {
        let (defaults, name) = storage(); defer { defaults.removePersistentDomain(forName: name) }
        let stub = ReleaseStub([(payload(), response(headers: ["ETag": "\"abc\""])), (Data(), response(404))])
        let checker = StableReleaseChecker(defaults: defaults, fetch: { try await stub.send($0) })
        await checker.checkIfDue(at: now)
        await checker.checkIfDue(at: now.addingTimeInterval(86_400))
        XCTAssertNil(checker.state.release); XCTAssertNil(checker.state.etag)
        XCTAssertFalse(checker.state.lastCheckFailed)
    }

    @MainActor func testBrokenStoredStateRecoversWithoutCrashing() async {
        let (defaults, name) = storage(); defer { defaults.removePersistentDomain(forName: name) }
        defaults.set(Data("broken".utf8), forKey: StableReleaseChecker.defaultsKey)
        let stub = ReleaseStub([(payload(), response())])
        let checker = StableReleaseChecker(defaults: defaults, fetch: { try await stub.send($0) })
        await checker.checkIfDue(at: now)
        XCTAssertEqual(checker.state.release, release())
    }

    @MainActor func testResetDiscardsAnInFlightReleaseResponseAndStoredDismissal() async {
        let (defaults, name) = storage(); defer { defaults.removePersistentDomain(forName: name) }
        let gate = ReleaseGate()
        let data = payload(), reply = response()
        let checker = StableReleaseChecker(defaults: defaults, fetch: { _ in await gate.wait(); return (data, reply) })
        checker.dismiss(release())
        let request = Task { await checker.checkIfDue(at: now) }
        while !checker.isChecking { await Task.yield() }
        checker.reset()
        await gate.open(); await request.value
        XCTAssertEqual(checker.state, ReleaseUpdateState())
        XCTAssertNil(defaults.object(forKey: StableReleaseChecker.defaultsKey))
        XCTAssertFalse(checker.isChecking)
    }

    func testUpdateSearchLeadsToAbout() {
        for query in ["updates", "software update", "official releases"] {
            XCTAssertTrue(SettingsDestination.results(for: query).contains(.about))
        }
    }
}

private actor ReleaseStub {
    private var replies: [(Data, HTTPURLResponse)]
    private(set) var requests: [URLRequest] = []
    var count: Int { requests.count }
    init(_ replies: [(Data, HTTPURLResponse)]) { self.replies = replies }
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requests.append(request)
        return replies.count > 1 ? replies.removeFirst() : replies[0]
    }
}

private actor ReleaseGate {
    private var continuation: CheckedContinuation<Void, Never>?
    private var opened = false
    func wait() async {
        if opened { return }
        await withCheckedContinuation { continuation = $0 }
    }
    func open() { opened = true; continuation?.resume(); continuation = nil }
}
