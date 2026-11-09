import XCTest
@testable import SessionPresentation

final class DeletedItemsSelectionTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private func items() -> [DeletedLibraryItem] {
        let points = [RoutePoint(latitude: 0, longitude: 0), RoutePoint(latitude: 0, longitude: 0.01), RoutePoint(latitude: 0.01, longitude: 0.01)]
        let trip = SavedTrip(name: "Trip", mode: .walk, speedMPH: 3, smoothMovement: false,
            originName: "Start", destinationName: "End", points: points, source: .drawn,
            instructions: [], stops: [], calculatedAt: now)
        return [.init(deletedAt: now, payload: .place(.init(name: "Place", latitude: 0, longitude: 0))),
                .init(deletedAt: now, payload: .trip(trip)),
                .init(deletedAt: now, payload: .area(.init(name: "Area", points: points)))]
    }
    func testSelectingIndividualItemsAndTogglingOff() throws {
        let items = items()
        var selection = DeletedItemsSelection()
        XCTAssertNil(selection.review(items, now: now))
        selection.toggle(items[1].id)
        XCTAssertEqual(try XCTUnwrap(selection.review(items, now: now)).items, [items[1]])
        selection.toggle(items[1].id)
        XCTAssertNil(selection.review(items, now: now))
    }
    func testSweepSelectsSkippedRowsAndReversesWithoutLosingEarlierSelection() throws {
        let ids = (0..<6).map { _ in UUID() }
        let sweep = try XCTUnwrap(DeletedItemsSelectionSweep(anchor: ids[1], orderedIDs: ids, selectedIDs: [ids[5]]))
        XCTAssertEqual(sweep.selection(through: ids[4]), Set([ids[1], ids[2], ids[3], ids[4], ids[5]]))
        XCTAssertEqual(sweep.selection(through: ids[2]), Set([ids[1], ids[2], ids[5]]))
        XCTAssertEqual(sweep.selection(through: ids[0]), Set([ids[0], ids[1], ids[5]]))
        // Repeated samples and revisiting the same range must not invert selection.
        XCTAssertEqual(sweep.selection(through: ids[4]), Set([ids[1], ids[2], ids[3], ids[4], ids[5]]))
        XCTAssertEqual(sweep.selection(through: ids[1]), Set([ids[1], ids[5]]))
    }
    func testSweepStartingOnSelectedRowDeselectsAndRestoresOnReversal() throws {
        let ids = (0..<5).map { _ in UUID() }
        let sweep = try XCTUnwrap(DeletedItemsSelectionSweep(anchor: ids[3], orderedIDs: ids, selectedIDs: Set(ids)))
        XCTAssertEqual(sweep.selection(through: ids[1]), Set([ids[0], ids[4]]))
        XCTAssertEqual(sweep.selection(through: ids[2]), Set([ids[0], ids[1], ids[4]]))
        XCTAssertEqual(sweep.selection(through: ids[4]), Set([ids[0], ids[1], ids[2]]))
    }
    func testSweepRejectsMissingOrAmbiguousAnchorsAndNeverAdoptsNewRows() throws {
        let ids = (0..<3).map { _ in UUID() }
        XCTAssertNil(DeletedItemsSelectionSweep(anchor: UUID(), orderedIDs: ids, selectedIDs: []))
        XCTAssertNil(DeletedItemsSelectionSweep(anchor: ids[0], orderedIDs: [ids[0], ids[0]], selectedIDs: []))
        let stale = UUID()
        let sweep = try XCTUnwrap(DeletedItemsSelectionSweep(anchor: ids[0], orderedIDs: ids, selectedIDs: [stale]))
        XCTAssertNil(sweep.selection(through: UUID()))
        XCTAssertEqual(sweep.selection(through: ids[2]), Set(ids))
    }
    func testNewSweepAfterAnInterruptionStartsFromCurrentSelection() throws {
        let ids = (0..<4).map { _ in UUID() }
        var active: DeletedItemsSelectionSweep? = try XCTUnwrap(DeletedItemsSelectionSweep(anchor: ids[0], orderedIDs: ids, selectedIDs: []))
        let selected = try XCTUnwrap(active?.selection(through: ids[2]))
        active = nil // GestureState cancellation clears only the transient gesture.
        active = try XCTUnwrap(DeletedItemsSelectionSweep(anchor: ids[1], orderedIDs: ids, selectedIDs: selected))
        XCTAssertEqual(active?.selection(through: ids[2]), [ids[0]])
    }
    func testSelectAllIgnoresExpiredAndInvalidEntriesAndDeselectAllIsEmpty() throws {
        let valid = items()
        var expired = valid[0]; expired.id = UUID(); expired.deletedAt = now.addingTimeInterval(-DeletedLibraryItem.lifetime)
        var invalid = valid[0]; invalid.id = UUID(); invalid.payload = .place(.init(name: "Invalid", latitude: 100, longitude: 0))
        var selection = DeletedItemsSelection()
        selection.selectAll(valid + [expired, invalid], now: now)
        XCTAssertEqual(selection.ids, Set(valid.map(\.id)))
        XCTAssertEqual(selection.review(valid, now: now)?.summary, "1 saved place, 1 saved trip, 1 named area")
        selection.ids = []
        XCTAssertNil(selection.review(valid, now: now))
    }
    func testSelectionReconcilesAfterRestoreOrExpiry() {
        let items = items()
        var selection = DeletedItemsSelection(ids: Set(items.map(\.id)))
        selection.reconcile(with: Array(items.dropFirst()), now: now)
        XCTAssertEqual(selection.ids, Set(items.dropFirst().map(\.id)))
        selection.reconcile(with: items, now: now.addingTimeInterval(DeletedLibraryItem.lifetime))
        XCTAssertTrue(selection.ids.isEmpty)
    }
    func testMixedSelectionCommitsWithOneSaveAndPreservesUnselectedItems() throws {
        let current = items()
        let plan = DeletedItemsDeletion(items: [current[0], current[2]])
        var saved: [Data] = []
        let remaining = try plan.commit(current: current, now: now) { saved.append($0) }
        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(remaining, [current[1]])
        XCTAssertEqual(try JSONDecoder().decode([DeletedLibraryItem].self, from: saved[0]), remaining)
    }
    func testSelectAllSnapshotNeverDeletesNewlyAddedRecords() throws {
        let initial = items()
        var selection = DeletedItemsSelection(); selection.selectAll(initial, now: now)
        let plan = try XCTUnwrap(selection.review(initial, now: now))
        let added = items()[0]
        let remaining = try plan.commit(current: initial + [added], now: now) { _ in }
        XCTAssertEqual(remaining, [added])
    }
    func testFailedSaveDoesNotChangeSelectedRecordsOrDisk() throws {
        enum Failure: Error { case storageFull }
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appendingPathComponent("bin.json")
        var current = items()
        let original = current
        let bytes = try JSONEncoder().encode(original)
        try bytes.write(to: file, options: .atomic)
        let plan = DeletedItemsDeletion(items: Array(current.prefix(2)))
        var saves = 0
        XCTAssertThrowsError(try { current = try plan.commit(current: current, now: now) { _ in saves += 1; throw Failure.storageFull } }())
        XCTAssertEqual(current, original); XCTAssertEqual(saves, 1)
        XCTAssertEqual(try Data(contentsOf: file), bytes)
        current = try plan.commit(current: current, now: now) { try $0.write(to: file, options: .atomic) }
        XCTAssertEqual(current, [original[2]])
        XCTAssertEqual(try JSONDecoder().decode([DeletedLibraryItem].self, from: Data(contentsOf: file)), current)
    }
    func testEmptyOrDuplicatedConfirmationNeverWrites() {
        let current = items()
        for selection in [[], [current[0], current[0]]] {
            XCTAssertThrowsError(try DeletedItemsDeletion(items: selection).commit(current: current, now: now) { _ in XCTFail("Must not write") })
        }
    }
    func testChangedRestoredOrExpiredSelectionNeverPartiallyDeletes() {
        let current = items()
        let plan = DeletedItemsDeletion(items: current)
        var changed = current; changed[1].deletedAt = now.addingTimeInterval(1)
        for latest in [Array(current.dropLast()), changed] {
            XCTAssertThrowsError(try plan.commit(current: latest, now: now) { _ in XCTFail("Must not write") })
        }
        XCTAssertThrowsError(try plan.commit(current: current, now: now.addingTimeInterval(DeletedLibraryItem.lifetime)) { _ in XCTFail("Must not write") })
    }
    func testCancellingReviewLeavesOriginalItemsAndSelectionIntact() {
        let original = items()
        var selection = DeletedItemsSelection(); selection.selectAll(original, now: now)
        var review = selection.review(original, now: now)
        XCTAssertNotNil(review)
        review = nil
        XCTAssertNil(review)
        XCTAssertEqual(selection.ids, Set(original.map(\.id)))
    }
}
