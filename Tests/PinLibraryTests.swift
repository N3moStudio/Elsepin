import XCTest
@testable import SessionPresentation

final class PinLibraryTests: XCTestCase {
    func testLegacyPlacesStayFavoritesAndNewPinsRoundTripIndependently() throws {
        let old = Data(#"{"name":"Home","latitude":33.7,"longitude":-117.8}"#.utf8)
        var pin = try JSONDecoder().decode(BackupPlace.self, from: old)
        XCTAssertTrue(pin.isFavorite)
        pin.favorite = false
        let backup = LibraryBackup(places: [pin], trips: [], preferences: nil)
        let restored = try LibraryBackup.decode(backup.encoded())
        XCTAssertFalse(restored.places[0].isFavorite)
        XCTAssertEqual(restored.places[0].id, pin.id)
    }

    func testOlderRoutesAreSavedButNotFavorited() throws {
        var trip = fixtureTrip()
        let legacy = try JSONDecoder().decode(SavedTrip.self, from: JSONEncoder().encode(trip))
        XCTAssertFalse(legacy.isFavorite)
        trip.favorite = true
        let restored = try JSONDecoder().decode(SavedTrip.self, from: JSONEncoder().encode(trip))
        XCTAssertTrue(restored.isFavorite)
        XCTAssertEqual(restored.points, trip.points)
        XCTAssertEqual(restored.stops, trip.stops)
    }

    func testRecentRoutesHonorPrivacyAndDoNotDuplicateAnIdentity() {
        let now = Date()
        let item = RecentRoute(trip: fixtureTrip(), visitedAt: now)
        XCTAssertTrue(RecentRoute.kept([item], retention: .forever, enabled: false, now: now).isEmpty)
        XCTAssertEqual(RecentRoute.kept([item, item], retention: .forever, enabled: true, now: now).count, 1)
        let many = (0..<15).map { _ in RecentRoute(trip: fixtureTrip(), visitedAt: now) }
        XCTAssertEqual(RecentRoute.kept(many, retention: .forever, enabled: true, now: now).count, 10)
        let expired = RecentRoute(trip: fixtureTrip(), visitedAt: now.addingTimeInterval(-172_800))
        XCTAssertTrue(RecentRoute.kept([expired], retention: .oneDay, enabled: true, now: now).isEmpty)
        let future = RecentRoute(trip: fixtureTrip(), visitedAt: now.addingTimeInterval(20))
        XCTAssertTrue(RecentRoute.kept([future], retention: .forever, enabled: true, now: now).isEmpty)
    }
    func testCategorySearchPreservesSpecificAddresses() {
        XCTAssertEqual(PlaceSearchIntent.category(for: "  Fast Foods "), .food)
        XCTAssertEqual(PlaceSearchIntent.query("fast food"), "fast food restaurants")
        XCTAssertNil(PlaceSearchIntent.category(for: "3901 Parkview Lane Irvine"))
        XCTAssertEqual(PlaceSearchIntent.query("3901 Parkview Lane Irvine"), "3901 Parkview Lane Irvine")
    }
    func testEnergyPolicyDoesNotOvershootShortWaits() {
        XCTAssertEqual(DisplayEnergyPolicy.stopWaitInterval(remaining: 0.3, foreground: false, constrained: true), 0.3)
        XCTAssertEqual(DisplayEnergyPolicy.stopWaitInterval(remaining: 3600, foreground: false, constrained: false), 5)
        XCTAssertEqual(DisplayEnergyPolicy.stopWaitInterval(remaining: 3600, foreground: true, constrained: false), 1)
        XCTAssertEqual(DisplayEnergyPolicy.cameraInterval(lowPower: false, thermallyLimited: true), 3)
    }
    func testLongerStopSleepConsumesActualAwakeTimeWithoutStretchingStop() {
        var progress = RouteStopProgress()
        progress.arrive(RouteStop(name: "Wait", metres: 0, waitSeconds: 10))
        progress.tick(5, maximumElapsed: 5.25)
        XCTAssertEqual(progress.remainingSeconds, 5)
        progress.tick(5, maximumElapsed: 5.25)
        XCTAssertNil(progress.currentID)
        XCTAssertEqual(progress.remainingSeconds, 0)
    }
    func testLegacyWaitCapAndInvalidBudgetsRemainSafe() {
        var progress = RouteStopProgress()
        progress.arrive(RouteStop(name: "Wait", metres: 0, waitSeconds: 10))
        progress.tick(300)
        XCTAssertEqual(progress.remainingSeconds, 9.5)
        progress.tick(1, maximumElapsed: .nan)
        XCTAssertEqual(progress.remainingSeconds, 9.5)
    }
}
