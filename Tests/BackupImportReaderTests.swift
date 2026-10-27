import XCTest
@testable import SessionPresentation

final class BackupImportReaderTests: XCTestCase {
    func testDownloadableSampleImportsAllSettingsWithoutDuplicateRoutes() throws {
        let sample = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("docs/Shift-Import-Test.json")
        let file = try BackupImportReader.file(sample).backup
        let pasted = try BackupImportReader.text(String(contentsOf: sample, encoding: .utf8)).backup
        XCTAssertEqual(file.included, [.places, .trips, .settings])
        let expected = BackupPreferences(
            usualSpeeds: ["walk": 5 / 1.609344, "run": 10 / 1.609344, "cycle": 20 / 1.609344,
                          "eBike": 25 / 1.609344, "drive": 50 / 1.609344],
            glassPanel: false, appearance: "dark", smoothMovement: true,
            preferWalkingPaths: true, shortcuts: [.saved, .speed, .pause],
            display: BackupDisplayPreferences(liveActivities: true, hideLocation: true,
                hideIslandLocation: false, lockScreenProgress: false, islandProgress: true,
                islandTimer: true, connectionAlerts: true, reminderMinutes: 30,
                saveRecentLocations: true, recentHistoryRetention: .forever, mapStyle: 1,
                connectionCheckSeconds: 10, showFindMyStatus: true, showLife360Status: true),
            speedUnit: .kilometersPerHour)
        XCTAssertEqual(file.preferences, expected)
        XCTAssertEqual(pasted.preferences, expected)
        XCTAssertNil(file.selecting([.places, .trips]).preferences)
        XCTAssertEqual(file.selecting([.settings]).preferences, expected)
        XCTAssertEqual(file.places.count, 2)
        XCTAssertEqual(file.trips.count, 1)
        let trip = try XCTUnwrap(file.trips.first)
        XCTAssertEqual(trip.name, "TEST - Park loop")
        XCTAssertEqual(trip.points.count, 5)
        XCTAssertEqual(trip.points.first, trip.points.last)
        XCTAssertEqual(trip.stops.map(\.waitSeconds), [15, 90])
        XCTAssertEqual(pasted.trips, file.trips)
        XCTAssertEqual(try LibraryMerge.trips(local: file.trips, incoming: pasted.trips), file.trips)
        XCTAssertEqual(try LibraryMerge.places(local: file.places, incoming: pasted.places), file.places)
    }

    private func fixture() -> LibraryBackup {
        var trip = fixtureTrip()
        trip.name = "Keep my drawn route"
        trip.stops = [RouteStop(name: "Wait", metres: 100, waitSeconds: 86_400)]
        return LibraryBackup(places: [BackupPlace(name: "Saved place", latitude: 40, longitude: -75)],
            trips: [trip], preferences: BackupPreferences(usualSpeeds: ["eBike": 20], glassPanel: true,
                appearance: "dark", smoothMovement: false, preferWalkingPaths: true, shortcuts: [.saved, .speed, .pause]))
    }

    func testPastedJSONPreservesExactRouteAndMergesWithoutDuplicates() throws {
        let backup = fixture()
        let text = "\n  " + String(decoding: try backup.encoded(), as: UTF8.self) + "\n"
        let preview = try BackupImportReader.text(text).backup
        XCTAssertEqual(preview.trips, backup.trips)
        XCTAssertEqual(preview.places, backup.places)
        XCTAssertEqual(preview.preferences, backup.preferences)
        XCTAssertEqual(try LibraryMerge.trips(local: backup.trips, incoming: preview.trips), backup.trips)
    }

    func testLegacyLocusVersionOnePastesWithoutFormatMigration() throws {
        var backup = fixture()
        backup.format = "Locus library"
        backup.version = 1
        let text = String(decoding: try backup.encoded(), as: UTF8.self)
        XCTAssertEqual(try BackupImportReader.text(text).backup.trips, backup.trips)
    }

    func testRenamedFileIsCheckedByContentsAndOriginalIsUntouched() throws {
        let folder = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appendingPathComponent("backup-without-json-extension.dat")
        let data = try fixture().encoded()
        try data.write(to: file)
        let preview = try BackupImportReader.file(file).backup
        XCTAssertEqual(preview.trips, try LibraryBackup.decode(data).trips)
        XCTAssertEqual(try Data(contentsOf: file), data)
    }

    func testRejectsPartialTextLinksOtherJSONAndInvalidRoutes() throws {
        for text in ["", "   ", "https://example.com/backup.json", "file:///backup.json", "{\"format\":", "{\"helperKey\":\"example\"}"] {
            XCTAssertThrowsError(try BackupImportReader.text(text))
        }
        var backup = fixture()
        backup.trips[0].points[0] = RoutePoint(latitude: 100, longitude: 0)
        XCTAssertThrowsError(try BackupImportReader.text(String(decoding: JSONEncoder().encode(backup), as: UTF8.self)))
    }

    func testRejectsFoldersAndRemoteURLsWithoutTryingToDownload() throws {
        let folder = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        XCTAssertThrowsError(try BackupImportReader.file(folder))
        XCTAssertThrowsError(try BackupImportReader.file(URL(string: "https://example.com/backup.json")!))
    }

    func testFileLimitIsCheckedBeforeReadingOversizedFile() throws {
        let folder = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appendingPathComponent("large.json")
        try Data().write(to: file)
        let handle = try FileHandle(forWritingTo: file)
        try handle.truncate(atOffset: UInt64(LibraryBackup.maximumBytes + 1))
        try handle.close()
        XCTAssertThrowsError(try BackupImportReader.file(file)) { error in
            guard case BackupError.tooLarge = error else { return XCTFail("Expected size error, got \(error)") }
        }
    }

    func testPastedLimitUsesUTF8BytesRatherThanCharacterCount() {
        let text = String(repeating: "😀", count: LibraryBackup.maximumBytes / 4 + 1)
        XCTAssertThrowsError(try BackupImportReader.text(text)) { error in
            guard case BackupError.tooLarge = error else { return XCTFail("Expected size error") }
        }
    }

    func testFailedAndCanceledAttemptsKeepPreviousPreview() throws {
        var state = BackupImportState()
        let value = try BackupImportReader.text(String(decoding: fixture().encoded(), as: UTF8.self))
        state.finish(try XCTUnwrap(state.begin()), result: .success(value))
        let failing = try XCTUnwrap(state.begin())
        state.finish(failing, result: .failure(BackupImportError.invalidContent))
        XCTAssertEqual(state.preview?.id, value.id)
        XCTAssertNotNil(state.message)
        _ = state.begin()
        state.cancel()
        XCTAssertEqual(state.preview?.id, value.id)
        XCTAssertFalse(state.isLoading)
    }

    func testCanceledLateResultCannotReplaceNewerPreview() throws {
        var state = BackupImportState()
        let old = try XCTUnwrap(state.begin())
        XCTAssertNil(state.begin())
        state.cancel()
        let current = try XCTUnwrap(state.begin())
        let value = try BackupImportReader.text(String(decoding: fixture().encoded(), as: UTF8.self))
        state.finish(old, result: .failure(BackupImportError.invalidContent))
        XCTAssertEqual(state.operation, current)
        XCTAssertNil(state.message)
        state.finish(current, result: .success(value))
        state.finish(old, result: .success(try BackupImportReader.text(String(decoding: fixture().encoded(), as: UTF8.self))))
        XCTAssertEqual(state.preview?.id, value.id)
    }

    func testCanceledReaderDoesNotProducePreview() async {
        let worker = Task {
            while !Task.isCancelled { await Task.yield() }
            return try BackupImportReader.text("{}")
        }
        worker.cancel()
        do { _ = try await worker.value; XCTFail("Canceled read must not complete") }
        catch { XCTAssertTrue(error is CancellationError) }
    }

    private func temporaryFolder() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
