import XCTest
@testable import SessionPresentation

final class AppResetTests: XCTestCase {
    private func storage() throws -> UserDefaults {
        let name = "Shift-reset-tests-" + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        addTeardownBlock { defaults.removePersistentDomain(forName: name) }
        return defaults
    }
    @MainActor func testSettingsOnlyPreservesLibrarySetupHelpersAndDailyUpdateGate() async throws {
        let defaults = try storage()
        let kept = Array(AppResetRules.setupKeys) + ["locus.favorites", "locus.recents", "locus.namedAreas", "locus.checkpointAvailable", StableReleaseChecker.defaultsKey, ShiftAppearanceSelection.iconKey, "unrelated.app.setting"]
        for key in kept { defaults.set("keep", forKey: key) }
        for key in AppResetRules.settingKeys { defaults.set("changed", forKey: key) }
        let mapLayerKeys = ["locus.showSavedPinsOnMap", "locus.showNamedAreasOnMap", "locus.mapPinVisibilityMiles"]
        for key in mapLayerKeys { defaults.set(false, forKey: key) }
        AppResetRules.clearPreferences(in: defaults, scope: .settings)
        for key in mapLayerKeys { XCTAssertNil(defaults.object(forKey: key), key) }
        for key in kept { XCTAssertEqual(defaults.string(forKey: key), "keep", key) }
        for key in AppResetRules.settingKeys { XCTAssertNil(defaults.object(forKey: key), key) }
    }
    func testDataWipesPreserveSetupAndIconUntilTheirSeparateFinalStages() throws {
        for scope in [AppResetScope.keepSetup, .full] {
            let defaults = try storage()
            let kept = Array(AppResetRules.setupKeys) + [ShiftAppearanceSelection.iconKey, "NSAppSleepDisabled", "other.preference"]
            let erased = ["locus.favorites", "locus.recents", "locus.namedAreas", "locus.unfinishedSession", "shift.updates.stable.v1", "shift.futureSetting"]
            for key in kept + erased { defaults.set("value", forKey: key) }
            AppResetRules.clearPreferences(in: defaults, scope: scope)
            for key in kept { XCTAssertEqual(defaults.string(forKey: key), "value", key) }
            for key in erased { XCTAssertNil(defaults.object(forKey: key), key) }
        }
    }
    func testSettingsScopeDoesNotDeleteAnyDataOrPairing() {
        XCTAssertEqual(AppResetScope.settings.stages, [.settings, .icon])
        XCTAssertFalse(AppResetScope.keepSetup.stages.contains(.pairingAndSetup))
        XCTAssertEqual(AppResetScope.full.stages.last, .pairingAndSetup)
    }
    func testEveryBusyConditionIndependentlyBlocksReset() {
        XCTAssertTrue(AppResetRules.canReset(hasSession: false, busy: false, setupWorkerRunning: false, iconChanging: false))
        for n in 0..<4 {
            XCTAssertFalse(AppResetRules.canReset(hasSession: n == 0, busy: n == 1, setupWorkerRunning: n == 2, iconChanging: n == 3))
        }
    }
    @MainActor func testEveryFailureStopsLaterStagesAndReportsWhatAlreadyCompleted() async {
        enum Failure: Error { case disk }
        for stage in AppResetScope.full.stages {
            var attempted: [AppResetStage] = []
            let result = await AppResetRules.execute(.full) {
                attempted.append($0)
                if $0 == stage { throw Failure.disk }
            }
            XCTAssertFalse(result.succeeded)
            XCTAssertEqual(result.failed, stage)
            XCTAssertEqual(result.completed, Array(attempted.dropLast()))
            XCTAssertEqual(attempted, Array(AppResetScope.full.stages.prefix(attempted.count)))
            XCTAssertTrue(result.message.contains("may be partly cleared"))
            if stage != .pairingAndSetup { XCTAssertFalse(attempted.contains(.pairingAndSetup)) }
        }
    }
    @MainActor func testSuccessfulResetRunsEachStageOnce() async {
        var stages: [AppResetStage] = []
        let result = await AppResetRules.execute(.full) { stages.append($0) }
        XCTAssertTrue(result.succeeded)
        XCTAssertEqual(stages, AppResetScope.full.stages)
        XCTAssertEqual(result.completed, stages)
    }
    func testNativeWorkerGateRejectsASecondWorkerUntilFirstEnds() {
        let gate = AppResetWorkGate()
        XCTAssertFalse(gate.isBusy)
        XCTAssertTrue(gate.begin()); XCTAssertTrue(gate.isBusy)
        XCTAssertFalse(gate.begin()); XCTAssertTrue(gate.isBusy)
        gate.end(); XCTAssertFalse(gate.isBusy)
        XCTAssertTrue(gate.begin()); gate.end()
    }
    func testResetSearchIsDiscoverable() {
        for query in ["reset", "wipe", "restore defaults", "erase data"] {
            XCTAssertTrue(SettingsDestination.results(for: query).contains(.experimental))
        }
    }
}
