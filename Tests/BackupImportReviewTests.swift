import XCTest
@testable import SessionPresentation

final class BackupImportReviewTests: XCTestCase {
    private func sample(_ name: String) throws -> LibraryBackup {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("docs/\(name).json")
        return try BackupImportReader.file(url).backup
    }
    private func context() throws -> BackupImportContext {
        BackupImportContext(preferences: try XCTUnwrap(sample("Shift-Import-Test").preferences), places: [], trips: [], areas: [])
    }
    func testSettingsFileContainsOnlyAll24SupportedPreferencesAndStartsUnchecked() throws {
        let backup = try sample("Shift-Settings-Test")
        let review = BackupImportReview(backup: backup, current: try context())
        XCTAssertEqual(backup.included, [.settings])
        XCTAssertTrue(backup.places.isEmpty && backup.trips.isEmpty && (backup.areas ?? []).isEmpty)
        XCTAssertEqual(review.title, "Settings Import Overview")
        XCTAssertEqual(review.changes.count, 24)
        XCTAssertEqual(review.changedSettings.count, 19)
        XCTAssertEqual(try review.plan(review.defaultSelection).count, 0)
        XCTAssertNil(try review.plan(review.defaultSelection).preferences)
        let p = try XCTUnwrap(backup.preferences)
        XCTAssertEqual(p.appearance, "light")
        XCTAssertEqual(p.speedUnit, .mph)
        XCTAssertEqual(p.usualSpeeds, ["walk": 4, "run": 6.5, "cycle": 12, "eBike": 18, "drive": 32])
        XCTAssertEqual(p.shortcuts, [.joystick, .saved, .settings])
        XCTAssertEqual(p.display?.connectionCheckSeconds, 15)
        XCTAssertEqual(p.display?.reminderMinutes, 60)
        XCTAssertEqual(p.display?.recentHistoryRetention, .forever)
    }
    func testSeparateLibraryFileAndPastedTextKeepExactRoutesStopsAndAreas() throws {
        let backup = try sample("Shift-Routes-Areas-Test")
        let pasted = try BackupImportReader.text(String(decoding: backup.encoded(), as: UTF8.self)).backup
        XCTAssertEqual(backup.included, [.places, .trips])
        XCTAssertNil(backup.preferences)
        XCTAssertEqual(backup.places.count, 2)
        XCTAssertEqual(backup.trips.count, 2)
        XCTAssertEqual(backup.areas?.count, 2)
        XCTAssertEqual(backup.trips[0].stops.map(\.waitSeconds), [15, 90])
        XCTAssertEqual(backup.trips[1].stops.map(\.waitSeconds), [30, 7200])
        XCTAssertEqual(pasted.trips, backup.trips)
        XCTAssertEqual(pasted.areas, backup.areas)
        let review = BackupImportReview(backup: backup, current: try context())
        XCTAssertTrue(review.changes.isEmpty)
        XCTAssertEqual(try review.plan(review.defaultSelection).count, 6)
    }
    func testCanPickOneRouteOneAreaAndOnePlaceIndependently() throws {
        let backup = try sample("Shift-Routes-Areas-Test")
        let areas = try XCTUnwrap(backup.areas)
        let review = BackupImportReview(backup: backup, current: try context())
        let selected = BackupImportSelection(places: [backup.places[1].id], trips: [backup.trips[0].id], areas: [areas[1].id])
        let plan = try review.plan(selected)
        XCTAssertEqual(plan.trips, [backup.trips[0]])
        XCTAssertEqual(plan.places, [backup.places[1]])
        XCTAssertEqual(plan.areas, [areas[1]])
        XCTAssertNil(plan.preferences)
        XCTAssertEqual(try review.plan(BackupImportSelection(areas: [areas[0].id])).count, 1)
        XCTAssertEqual(try review.plan(BackupImportSelection()).count, 0)
    }
    func testSingleSpeedImportPreservesUnitsOtherSpeedsAndEveryOtherPreference() throws {
        let current = try context()
        let review = BackupImportReview(backup: try sample("Shift-Settings-Test"), current: current)
        let result = try review.plan(BackupImportSelection(settings: [.walkSpeed]))
        var expected = current.preferences
        expected.usualSpeeds["walk"] = 4
        XCTAssertEqual(result.preferences, expected)
        XCTAssertEqual(result.settingKeys, [.walkSpeed])
        XCTAssertEqual(result.preferences?.speedUnit, .kilometersPerHour)
        XCTAssertEqual(BackupSettingKey.walkSpeed.description(in: try XCTUnwrap(result.preferences)), "6.4 km/h")
    }
    func testIndividualChangedSettingsNeverTouchUncheckedFields() throws {
        let current = try context()
        let backup = try sample("Shift-Settings-Test")
        let incoming = try XCTUnwrap(backup.preferences)
        let review = BackupImportReview(backup: backup, current: current)
        for key in review.changedSettings {
            let plan = try review.plan(BackupImportSelection(settings: [key]))
            let after = try XCTUnwrap(plan.preferences)
            XCTAssertEqual(plan.settingKeys, [key])
            for other in BackupSettingKey.allCases {
                XCTAssertEqual(other.value(in: after), other.value(in: other == key ? incoming : current.preferences), "\(key) must preserve \(other)")
            }
        }
        let all = try review.plan(BackupImportSelection(settings: Set(BackupSettingKey.allCases)))
        var expected = incoming
        expected.appearance = current.preferences.appearance // Retired color mode is not imported.
        XCTAssertEqual(all.preferences, expected)
        XCTAssertEqual(all.count, review.changedSettings.count)
    }
    func testSameValuesAndUnknownIDsDoNotBecomeChanges() throws {
        let backup = try sample("Shift-Settings-Test")
        var current = try context()
        current.preferences = try XCTUnwrap(backup.preferences)
        let review = BackupImportReview(backup: backup, current: current)
        XCTAssertTrue(review.changes.allSatisfy { !$0.changesValue })
        let plan = try review.plan(BackupImportSelection(places: ["unknown"], trips: [UUID()], areas: [UUID()], settings: Set(BackupSettingKey.allCases)))
        XCTAssertEqual(plan.count, 0)
        XCTAssertNil(plan.preferences)
    }
    func testExistingIdentitiesKeepCurrentEditsEvenIfExplicitlySelected() throws {
        let backup = try sample("Shift-Routes-Areas-Test")
        var current = try context()
        current.trips = backup.trips; current.places = backup.places; current.areas = backup.areas ?? []
        current.trips[0].name = "My edited route"
        current.places[0].name = "My edited place"
        current.areas[0].name = "My edited area"
        let review = BackupImportReview(backup: backup, current: current)
        XCTAssertEqual(try review.plan(review.defaultSelection).count, 0)
        let forced = BackupImportSelection(places: Set(backup.places.map(\.id)), trips: Set(backup.trips.map(\.id)), areas: Set((backup.areas ?? []).map(\.id)))
        XCTAssertEqual(try review.plan(forced).count, 0)
        XCTAssertEqual(review.current, current)
    }
    func testOlderBackupOmitsMissingPreferencesAndDoesNotResetNewControls() throws {
        var backup = try sample("Shift-Settings-Test")
        backup.version = 1; backup.preferences?.speedUnit = nil
        backup.preferences?.display?.connectionCheckSeconds = nil
        backup.preferences?.display?.showFindMyStatus = nil
        backup.preferences?.display?.showLife360Status = nil
        let current = try context()
        let review = BackupImportReview(backup: try LibraryBackup.decode(backup.encoded()), current: current)
        let absent: Set<BackupSettingKey> = [.speedUnit, .connectionCheckSeconds, .showFindMyStatus, .showLife360Status]
        XCTAssertTrue(Set(review.changes.map(\.key)).isDisjoint(with: absent))
        XCTAssertEqual(try review.plan(BackupImportSelection(settings: absent)).count, 0)
        let after = try XCTUnwrap(review.plan(BackupImportSelection(settings: Set(BackupSettingKey.allCases))).preferences)
        for key in absent { XCTAssertEqual(key.value(in: after), key.value(in: current.preferences)) }
        backup.preferences?.display = nil
        let noDisplay = BackupImportReview(backup: try LibraryBackup.decode(backup.encoded()), current: current)
        XCTAssertEqual(noDisplay.changes.count, 9)
        XCTAssertEqual(try noDisplay.plan(BackupImportSelection(settings: noDisplay.changedSettings)).preferences?.display, current.preferences.display)
    }
    func testSparseLegacySpeedDictionaryUsesDefaultOnlyForSelectedPreset() throws {
        var backup = try sample("Shift-Settings-Test")
        backup.preferences?.usualSpeeds = [:]
        let current = try context()
        let review = BackupImportReview(backup: backup, current: current)
        let after = try XCTUnwrap(review.plan(BackupImportSelection(settings: [.walkSpeed])).preferences)
        var expected = current.preferences
        expected.usualSpeeds["walk"] = 3
        XCTAssertEqual(after, expected)
    }
    func testCapacityUsesChosenSubsetSoDeselectingOneRouteAllowsImport() throws {
        let backup = try sample("Shift-Routes-Areas-Test")
        var current = try context()
        current.trips = (0..<49).map { _ in fixtureTrip() }
        let review = BackupImportReview(backup: backup, current: current)
        XCTAssertThrowsError(try review.plan(review.defaultSelection))
        let selected = BackupImportSelection(trips: [backup.trips[0].id])
        XCTAssertEqual(try review.plan(selected).trips, [backup.trips[0]])
        XCTAssertEqual(try review.plan(BackupImportSelection()).count, 0)
    }
    func testContextDetectsChangesMadeAfterConfirmationWasPresented() throws {
        let original = try context()
        var changed = original
        changed.preferences.display?.mapStyle = 2
        XCTAssertNotEqual(original, changed)
        changed = original; changed.trips = [fixtureTrip()]
        XCTAssertNotEqual(original, changed)
        changed = original; changed.places = [BackupPlace(name: "Added", latitude: 1, longitude: 2)]
        XCTAssertNotEqual(original, changed)
        changed = original; changed.areas = try sample("Shift-Routes-Areas-Test").areas ?? []
        XCTAssertNotEqual(original, changed)
    }
    func testOverviewCountsDifferencesAndChangedSettingsComeFirst() throws {
        var backup = try sample("Shift-Routes-Areas-Test")
        backup.preferences = try sample("Shift-Settings-Test").preferences
        backup.categories = [.settings, .places, .trips]
        var current = try context()
        current.places = [backup.places[0]]
        current.trips = [backup.trips[0]]
        current.areas = [try XCTUnwrap(backup.areas?.first)]
        let review = BackupImportReview(backup: backup, current: current)
        XCTAssertEqual(review.title, "Settings & Library Import Overview")
        XCTAssertTrue(review.overview.contains("1 new routes Â· 1 new pins Â· 1 new areas Â· 19 different settings"))
        XCTAssertEqual(review.changes.prefix(19).filter(\.changesValue).count, 19)
        XCTAssertTrue(review.changes.dropFirst(19).allSatisfy { !$0.changesValue })
    }
    func testOnlySelectedSettingsNeedAStoppedSession() throws {
        let library = BackupImportReview(backup: try sample("Shift-Routes-Areas-Test"), current: try context())
        XCTAssertFalse(try library.plan(library.defaultSelection).needsStoppedSession(hasSession: true, isBusy: true))
        let settings = BackupImportReview(backup: try sample("Shift-Settings-Test"), current: try context())
        let plan = try settings.plan(BackupImportSelection(settings: [.smoothMovement]))
        XCTAssertTrue(plan.needsStoppedSession(hasSession: true, isBusy: false))
        XCTAssertTrue(plan.needsStoppedSession(hasSession: false, isBusy: true))
        XCTAssertFalse(plan.needsStoppedSession(hasSession: false, isBusy: false))
        XCTAssertFalse(try settings.plan(BackupImportSelection()).needsStoppedSession(hasSession: true, isBusy: true))
    }
}
