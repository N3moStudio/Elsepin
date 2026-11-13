import XCTest
@testable import SessionPresentation

final class BackupImportReviewTests: XCTestCase {
    func testPinVisibilityRangeRoundTripsAndImportsIndependently() throws {
        var current = try context()
        current.preferences.display?.mapPinVisibilityMiles = 5
        current.preferences.display?.mapPinSize = 34
        var backup = try sample("Shift-Settings-Test")
        backup.preferences?.display?.mapPinVisibilityMiles = 12
        backup.preferences?.display?.mapPinSize = 56
        let decoded = try LibraryBackup.decode(backup.encoded())
        XCTAssertEqual(decoded.preferences?.display?.mapPinVisibilityMiles, 12)
        let review = BackupImportReview(backup: decoded, current: current)
        let selected = try XCTUnwrap(review.plan(BackupImportSelection(settings: [.mapPinVisibilityMiles])).preferences)
        XCTAssertEqual(selected.display?.mapPinVisibilityMiles, 12)
        XCTAssertEqual(selected.display?.mapPinSize, 34)
        let unselected = try XCTUnwrap(review.plan(BackupImportSelection(settings: [.walkSpeed])).preferences)
        XCTAssertEqual(unselected.display?.mapPinVisibilityMiles, 5)
    }

    func testOldBackupsPreservePinVisibilityRange() throws {
        var current = try context()
        current.preferences.display?.mapPinVisibilityMiles = 8.5
        let old = try sample("Shift-Settings-Test")
        XCTAssertNil(old.preferences?.display?.mapPinVisibilityMiles)
        let review = BackupImportReview(backup: old, current: current)
        XCTAssertFalse(review.changes.contains { $0.key == .mapPinVisibilityMiles })
        let result = try XCTUnwrap(review.plan(BackupImportSelection(settings: [.walkSpeed])).preferences)
        XCTAssertEqual(result.display?.mapPinVisibilityMiles, 8.5)
    }

    func testInvalidPinVisibilityRangeRejectedBeforeImport() throws {
        var backup = try sample("Shift-Settings-Test")
        for value in [-1.0, 0, 20.5, .infinity, .nan] {
            backup.preferences?.display?.mapPinVisibilityMiles = value
            XCTAssertFalse(backup.isValid)
        }
    }

    func testPinSizeRoundTripSelectionAndOldBackupPreservation() throws {
        var current = try context()
        current.preferences.display?.mapPinSize = 34
        let old = try sample("Shift-Settings-Test")
        XCTAssertNil(old.preferences?.display?.mapPinSize)
        let oldReview = BackupImportReview(backup: old, current: current)
        XCTAssertFalse(oldReview.changes.contains { $0.key == .mapPinSize })
        let oldResult = try XCTUnwrap(oldReview.plan(BackupImportSelection(settings: [.walkSpeed])).preferences)
        XCTAssertEqual(oldResult.display?.mapPinSize, 34)
        var new = old
        new.preferences?.display?.mapPinSize = 56
        let decoded = try LibraryBackup.decode(new.encoded())
        let review = BackupImportReview(backup: decoded, current: current)
        let changed = try XCTUnwrap(review.plan(BackupImportSelection(settings: [.mapPinSize])).preferences)
        XCTAssertEqual(changed.display?.mapPinSize, 56)
        XCTAssertEqual(changed.display?.mapStyle, current.preferences.display?.mapStyle)
        new.preferences?.display?.mapPinSize = 1_000
        XCTAssertFalse(new.isValid)
    }
    func testMapLayerChoicesRoundTripAndImportIndependently() throws {
        var current = try context()
        current.preferences.display?.showSavedPinsOnMap = true
        current.preferences.display?.showNamedAreasOnMap = false
        var backup = try sample("Shift-Settings-Test")
        backup.preferences?.display?.showSavedPinsOnMap = false
        backup.preferences?.display?.showNamedAreasOnMap = true
        let decoded = try LibraryBackup.decode(backup.encoded())
        XCTAssertEqual(decoded.preferences?.display?.showSavedPinsOnMap, false)
        XCTAssertEqual(decoded.preferences?.display?.showNamedAreasOnMap, true)
        let review = BackupImportReview(backup: decoded, current: current)
        let result = try XCTUnwrap(review.plan(BackupImportSelection(settings: [.showSavedPinsOnMap])).preferences)
        XCTAssertEqual(result.display?.showSavedPinsOnMap, false)
        XCTAssertEqual(result.display?.showNamedAreasOnMap, false)
        XCTAssertEqual(result.display?.mapStyle, current.preferences.display?.mapStyle)
    }

    func testOldBackupOmitsMapLayerChoicesAndKeepsCurrentValues() throws {
        var current = try context()
        current.preferences.display?.showSavedPinsOnMap = false
        current.preferences.display?.showNamedAreasOnMap = true
        let backup = try sample("Shift-Settings-Test")
        XCTAssertNil(backup.preferences?.display?.showSavedPinsOnMap)
        XCTAssertNil(backup.preferences?.display?.showNamedAreasOnMap)
        let review = BackupImportReview(backup: backup, current: current)
        XCTAssertFalse(review.changes.contains { $0.key == .showSavedPinsOnMap || $0.key == .showNamedAreasOnMap })
        let result = try XCTUnwrap(review.plan(BackupImportSelection(settings: [.walkSpeed])).preferences)
        XCTAssertEqual(result.display?.showSavedPinsOnMap, false)
        XCTAssertEqual(result.display?.showNamedAreasOnMap, true)
    }

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
        XCTAssertEqual(review.changes.count, 24)
        XCTAssertEqual(review.changedSettings.count, 19)
        XCTAssertEqual(try review.plan(review.defaultSelection).count, 0)
        XCTAssertNil(try review.plan(review.defaultSelection).preferences)
        let p = try XCTUnwrap(backup.preferences)
        XCTAssertEqual(p.appearance, "light")
        XCTAssertEqual(p.speedUnit, .mph)
        XCTAssertEqual(p.usualSpeeds, ["walk": 4, "run": 6.5, "cycle": 12, "eBike": 18, "drive": 32])
        XCTAssertEqual(p.shortcuts, [.joystick, .saved])
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
    func testOverviewContainsOnlySelectedNewItemsAndSettings() throws {
        var backup = try sample("Shift-Routes-Areas-Test")
        backup.preferences = try sample("Shift-Settings-Test").preferences
        backup.categories = [.settings, .places, .trips]
        var current = try context()
        current.places = [backup.places[0]]
        current.trips = [backup.trips[0]]
        current.areas = [try XCTUnwrap(backup.areas?.first)]
        let review = BackupImportReview(backup: backup, current: current)
        let initial = try review.plan(review.defaultSelection)
        XCTAssertEqual(initial.summary, "1 pin · 1 route · 1 area")
        XCTAssertTrue(review.settingChanges(in: initial).isEmpty)
        var selected = review.defaultSelection
        selected.places = []
        selected.settings = [.smoothMovement, .speedUnit]
        let plan = try review.plan(selected)
        XCTAssertEqual(plan.summary, "1 route · 1 area · 2 settings")
        XCTAssertEqual(Set(review.settingChanges(in: plan).map(\.key)), [.smoothMovement, .speedUnit])
        XCTAssertEqual(review.changes.prefix(19).filter(\.changesValue).count, 19)
        XCTAssertTrue(review.changes.dropFirst(19).allSatisfy { !$0.changesValue })
    }
    func testOverviewUsesAppliedSpeedUnitsAndGroupsEachSelectedSettingOnce() throws {
        let current = try context()
        let review = BackupImportReview(backup: try sample("Shift-Settings-Test"), current: current)
        let plan = try review.plan(BackupImportSelection(settings: [.walkSpeed]))
        let changes = review.settingChanges(in: plan)
        let change = try XCTUnwrap(changes.first)
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(change.key, .walkSpeed)
        XCTAssertEqual(change.key.group, .movement)
        XCTAssertEqual(change.before, BackupSettingKey.walkSpeed.description(in: current.preferences))
        XCTAssertEqual(change.after, "6.4 km/h")
        XCTAssertEqual(plan.summary, "1 setting")
        let withUnits = try review.plan(BackupImportSelection(settings: [.walkSpeed, .speedUnit]))
        XCTAssertEqual(review.settingChanges(in: withUnits).first { $0.key == .walkSpeed }?.after, "4.0 mph")
        let grouped = BackupSettingGroup.allCases.flatMap { group in changes.filter { $0.key.group == group }.map(\.key) }
        XCTAssertEqual(grouped, [.walkSpeed])
    }
    func testOverviewComparesCurrentSettingEvenWhenImportRestoresDefault() throws {
        var backup = try sample("Shift-Settings-Test")
        backup.preferences?.display?.mapPinSize = 34
        var current = try context()
        current.preferences.display?.mapPinSize = 56
        let review = BackupImportReview(backup: backup, current: current)
        let plan = try review.plan(BackupImportSelection(settings: [.mapPinSize]))
        let change = try XCTUnwrap(review.settingChanges(in: plan).first)
        XCTAssertEqual(change.key.group, .appearanceAndMap)
        XCTAssertEqual(change.before, "56 points")
        XCTAssertEqual(change.after, "34 points")
        current.preferences.display?.mapPinSize = 34
        let same = BackupImportReview(backup: backup, current: current)
        XCTAssertTrue(same.settingChanges(in: try same.plan(BackupImportSelection(settings: [.mapPinSize]))).isEmpty)
    }
    func testLegacyGlassFlagComparesActualCurrentSurfaceAndAppliesSelectively() throws {
        var backup = try sample("Shift-Settings-Test")
        backup.preferences?.material = nil
        backup.preferences?.glassPanel = false
        var current = try context()
        current.preferences.material = .solid
        current.preferences.glassPanel = true // Retired stored flag must not override the current surface.
        let same = BackupImportReview(backup: backup, current: current)
        XCTAssertFalse(same.changedSettings.contains(.glassPanel))
        XCTAssertEqual(try same.plan(BackupImportSelection(settings: [.glassPanel])).count, 0)
        current.preferences.material = .glass
        let review = BackupImportReview(backup: backup, current: current)
        let plan = try review.plan(BackupImportSelection(settings: [.glassPanel]))
        XCTAssertEqual(review.settingChanges(in: plan).first?.before, "On")
        XCTAssertEqual(review.settingChanges(in: plan).first?.after, "Off")
        XCTAssertEqual(plan.preferences?.material, .solid)
        XCTAssertEqual(plan.preferences?.speedUnit, current.preferences.speedUnit)
        backup.preferences?.material = .solid
        XCTAssertFalse(BackupImportReview(backup: backup, current: current).changes.contains { $0.key == .glassPanel })
    }
    func testSummaryHandlesPluralAndEmptySelections() throws {
        let review = BackupImportReview(backup: try sample("Shift-Routes-Areas-Test"), current: try context())
        XCTAssertEqual(try review.plan(review.defaultSelection).summary, "2 pins · 2 routes · 2 areas")
        XCTAssertEqual(try review.plan(BackupImportSelection()).summary, "No changes selected")
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
