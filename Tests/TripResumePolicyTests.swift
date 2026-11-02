import Foundation
import XCTest
@testable import SessionPresentation

final class TripResumePolicyTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suite: String!
    private let now = Date(timeIntervalSince1970: 1000)
    override func setUp() {
        suite = "TripResumePolicyTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)!
    }
    override func tearDown() { defaults.removePersistentDomain(forName: suite) }
    private func checkpoint() -> TripCheckpoint {
        TripCheckpoint(trip: fixtureTrip(), metres: 10, stops: RouteStopProgress(),
                       confirmedAt: now, savedAt: now, arrival: .stay)
    }
    func testLegacyCheckpointDoesNotInventAutomaticPermission() {
        XCTAssertFalse(TripResumePolicy(defaults: defaults).isEligible(checkpoint(), now: now))
    }
    func testRunningRouteCanClaimOnlyOneAttemptAcrossRelaunch() {
        let policy = TripResumePolicy(defaults: defaults)
        policy.setAllowed(true)
        XCTAssertTrue(policy.takeAttempt(checkpoint(), now: now, foreground: true, wifi: true, paired: true, busy: false))
        XCTAssertFalse(TripResumePolicy(defaults: defaults).isEligible(checkpoint(), now: now))
    }
    func testUnavailablePrerequisitesDoNotConsumeSavedIntent() {
        let policy = TripResumePolicy(defaults: defaults)
        policy.setAllowed(true)
        for values in [(false, true, true, false), (true, false, true, false),
                       (true, true, false, false), (true, true, true, true)] {
            XCTAssertFalse(policy.takeAttempt(checkpoint(), now: now, foreground: values.0,
                                             wifi: values.1, paired: values.2, busy: values.3))
            XCTAssertTrue(policy.isEligible(checkpoint(), now: now))
        }
    }
    func testPausedOrExplicitlyStoppedTripCannotResume() {
        let policy = TripResumePolicy(defaults: defaults)
        policy.setAllowed(true)
        policy.setAllowed(false)
        XCTAssertFalse(TripResumePolicy(defaults: defaults).isEligible(checkpoint(), now: now))
    }
    func testMissingInvalidFutureAndStaleCheckpointsCannotResume() {
        let policy = TripResumePolicy(defaults: defaults)
        policy.setAllowed(true)
        XCTAssertFalse(policy.isEligible(nil, now: now))
        var invalid = checkpoint(); invalid.metres = -1
        XCTAssertFalse(policy.isEligible(invalid, now: now))
        XCTAssertFalse(policy.isEligible(checkpoint(), now: now.addingTimeInterval(-1)))
        XCTAssertFalse(policy.isEligible(checkpoint(), now: now.addingTimeInterval(86401)))
    }
    func testConfirmedPlaybackMayCreateNewRecoveryIntentAfterAttempt() {
        let policy = TripResumePolicy(defaults: defaults)
        policy.setAllowed(true)
        XCTAssertTrue(policy.takeAttempt(checkpoint(), now: now, foreground: true, wifi: true, paired: true, busy: false))
        policy.setAllowed(true)
        XCTAssertTrue(TripResumePolicy(defaults: defaults).isEligible(checkpoint(), now: now))
    }
    func testResettingSettingsRevokesAutomaticIntentWithoutErasingCheckpointAvailability() {
        let policy = TripResumePolicy(defaults: defaults)
        policy.setAllowed(true)
        defaults.set(true, forKey: "locus.checkpointAvailable")
        AppResetRules.clearPreferences(in: defaults, scope: .settings)
        XCTAssertFalse(policy.isEligible(checkpoint(), now: now))
        XCTAssertTrue(defaults.bool(forKey: "locus.checkpointAvailable"))
    }
}
