import XCTest
@testable import SessionPresentation

final class DevModeDatasetTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    func testBackupRoundTripPreservesDemoLibraryWithoutSettings() throws {
        let sample = DevModeDataset.make(at: now)
        XCTAssertTrue(sample.backup.isValid)
        let restored = try LibraryBackup.decode(sample.backup.encoded())
        XCTAssertEqual(restored.places, sample.backup.places)
        XCTAssertEqual(restored.trips, sample.backup.trips)
        XCTAssertEqual(restored.areas, sample.backup.areas)
        XCTAssertEqual(restored.createdAt, now)
        XCTAssertEqual(restored.included, [.places, .trips])
        XCTAssertNil(restored.preferences)
    }

    func testExamplesCoverFavoritesFoldersTravelModesAndStopDurations() {
        let sample = DevModeDataset.make(at: now)
        XCTAssertTrue(sample.backup.places.contains { $0.isFavorite })
        XCTAssertTrue(sample.backup.places.contains { !$0.isFavorite })
        XCTAssertTrue(sample.backup.places.allSatisfy { $0.name.hasPrefix("Demo ") && $0.folder != nil })
        XCTAssertEqual(sample.backup.trips.map(\.mode), [.walk, .cycle, .drive, .eBike, .run, .walk])
        XCTAssertEqual(sample.backup.trips.flatMap(\.stops).map(\.waitSeconds), [15, 45, 7_200, 30, 10, 20, 90])
        XCTAssertTrue(sample.backup.trips.allSatisfy { $0.source == .drawn && $0.instructions.isEmpty })
    }

    func testMixedRouteSectionsCoverTrackAndRemainInRecentHistory() throws {
        let sample = DevModeDataset.make(at: now)
        let mixed = try XCTUnwrap(sample.backup.trips.first { $0.travelSections != nil })
        let track = try XCTUnwrap(RouteTrack(mixed.points))
        let sections = try XCTUnwrap(mixed.travelSections)
        XCTAssertTrue(RouteTravelSection.valid(sections, length: track.length))
        XCTAssertEqual(sections.map(\.mode), [.walk, .cycle, .drive])
        XCTAssertEqual(sections.map(\.id), mixed.stops.map(\.id) + [RouteLegChoice.destinationID])
        XCTAssertEqual(sections[0].endMetres, mixed.stops[0].metres)
        XCTAssertEqual(sections[1].endMetres, mixed.stops[1].metres)
        XCTAssertEqual(RecentRoute.kept(sample.recentRoutes, retention: .forever,
                                       enabled: true, now: now), sample.recentRoutes)
    }

    func testAreasAndTrashCanBeRestoredWithoutConflicts() throws {
        let sample = DevModeDataset.make(at: now)
        let areas = try XCTUnwrap(sample.backup.areas)
        XCTAssertEqual(areas.count, 2)
        XCTAssertNil(NamedArea.newConflict(in: areas, replacing: []))
        XCTAssertEqual(sample.deletedItems.count, 10)
        XCTAssertEqual(Set(sample.deletedItems.map(\.id)).count, 10)
        XCTAssertTrue(sample.deletedItems.allSatisfy { $0.isRetained(at: now) })
        for item in sample.deletedItems {
            switch item.payload {
            case .place(let place): XCTAssertFalse(sample.backup.places.contains { $0.id == place.id })
            case .trip(let trip): XCTAssertFalse(sample.backup.trips.contains { $0.id == trip.id })
            case .area(let area): XCTAssertNil(NamedArea.newConflict(in: areas + [area], replacing: areas))
            }
        }
    }

    func testHistoryTrashAndRepeatedSeedsAreDeterministicAndRoundTrip() throws {
        let sample = DevModeDataset.make(at: now)
        let second = DevModeDataset.make(at: now)
        XCTAssertEqual(sample.backup.places, second.backup.places)
        XCTAssertEqual(sample.backup.areas, second.backup.areas)
        XCTAssertEqual(sample.tripLibrary, second.tripLibrary)
        XCTAssertEqual(sample.recentRoutes, second.recentRoutes)
        XCTAssertEqual(sample.deletedItems, second.deletedItems)
        XCTAssertTrue(sample.tripLibrary.isValid)
        XCTAssertEqual(try TripLibraryDocument.decode(sample.tripLibrary.encoded()), sample.tripLibrary)
        let encoder = JSONEncoder(), decoder = JSONDecoder()
        XCTAssertEqual(try decoder.decode([RecentRoute].self, from: encoder.encode(sample.recentRoutes)), sample.recentRoutes)
        XCTAssertEqual(try decoder.decode([DeletedLibraryItem].self, from: encoder.encode(sample.deletedItems)), sample.deletedItems)
        XCTAssertTrue(sample.recentRoutes.allSatisfy { $0.trip.isValid && $0.visitedAt <= now })
    }
}
