import XCTest
@testable import SessionPresentation

final class RouteLegEditingTests: XCTestCase {
    func testDifferentNetworksOfferBothDirectionsOfModeChange() {
        let changes: [(TravelMode, TravelMode)] = [(.drive, .eBike), (.walk, .drive), (.cycle, .walk), (.walk, .cycle)]
        for pair in changes {
            XCTAssertTrue(RouteLegPathPolicy.needsChoice(from: pair.0, to: pair.1, exactPath: false))
            XCTAssertTrue(RouteLegPathPolicy.keepsGeometry(from: pair.0, to: pair.1, exactPath: false, choice: .keepCurrent))
            XCTAssertFalse(RouteLegPathPolicy.keepsGeometry(from: pair.0, to: pair.1, exactPath: false, choice: .recalculate))
        }
    }
    func testExactAndSameNetworkPathsDoNotNeedRecalculation() {
        XCTAssertFalse(RouteLegPathPolicy.needsChoice(from: .drive, to: .walk, exactPath: true))
        XCTAssertTrue(RouteLegPathPolicy.keepsGeometry(from: .drive, to: .walk, exactPath: true, choice: .recalculate))
        XCTAssertFalse(RouteLegPathPolicy.needsChoice(from: .eBike, to: .cycle, exactPath: false))
        XCTAssertTrue(RouteLegPathPolicy.keepsGeometry(from: .walk, to: .run, exactPath: false, choice: .recalculate))
    }
    func testKeepingCarPathChangesLegMotionWithoutChangingBoundaries() throws {
        let id = UUID()
        let old = [RouteTravelSection(id: id, startMetres: 0, endMetres: 100, mode: .drive, speedMPH: 30),
                   RouteTravelSection(id: UUID(), startMetres: 100, endMetres: 300, mode: .drive, speedMPH: 40)]
        let changed = try XCTUnwrap(RouteLegEditing.replacing(old, in: 0...100, length: 300, id: id,
            choice: .init(mode: .eBike, speedMPH: 10), fallback: .init(mode: .drive, speedMPH: 30)))
        XCTAssertEqual(changed.map(\.startMetres), old.map(\.startMetres))
        XCTAssertEqual(changed.map(\.endMetres), old.map(\.endMetres))
        XCTAssertEqual(changed.map(\.mode), [.eBike, .drive])
        XCTAssertEqual(changed.map(\.speedMPH), [10, 40])
    }
    private let walk = RouteLegChoice(mode: .walk, speedMPH: 3)
    private let bike = RouteLegChoice(mode: .eBike, speedMPH: 10)

    func testEditingMiddleLegKeepsBothNeighborsAndCorrectETA() throws {
        let id = UUID()
        let updated = try XCTUnwrap(RouteLegEditing.replacing([], in: 100...200, length: 300,
            id: id, choice: bike, fallback: walk))
        XCTAssertEqual(updated.map(\.mode), [.walk, .eBike, .walk])
        XCTAssertEqual(updated.map(\.speedMPH), [3, 10, 3])
        XCTAssertEqual(updated[1].id, id)
        XCTAssertTrue(RouteTravelSection.valid(updated, length: 300))
        XCTAssertEqual(RouteTravelSection.remainingSeconds(updated, from: 0),
            200 / SpeedConversion.metresPerSecond(mph: 3) + 100 / SpeedConversion.metresPerSecond(mph: 10), accuracy: 0.001)
    }

    func testEditingAnotherLegPreservesEarlierChoiceAndRoundTrips() throws {
        let first = try XCTUnwrap(RouteLegEditing.replacing([], in: 0...100, length: 300,
            id: UUID(), choice: bike, fallback: walk))
        let updated = try XCTUnwrap(RouteLegEditing.replacing(first, in: 100...300, length: 300,
            id: RouteLegChoice.destinationID, choice: .init(mode: .drive, speedMPH: 25), fallback: walk))
        XCTAssertEqual(updated.map(\.mode), [.eBike, .drive])
        XCTAssertEqual(updated.map(\.speedMPH), [10, 25])
        let decoded = try JSONDecoder().decode([RouteTravelSection].self, from: JSONEncoder().encode(updated))
        XCTAssertEqual(decoded, updated)
    }

    func testOverlappingLegacySectionsKeepUneditedSpeeds() throws {
        let target = UUID()
        let old = [RouteTravelSection(id: target, startMetres: 0, endMetres: 150, mode: .run, speedMPH: 6),
                   RouteTravelSection(id: UUID(), startMetres: 150, endMetres: 300, mode: .cycle, speedMPH: 12)]
        let updated = try XCTUnwrap(RouteLegEditing.replacing(old, in: 100...200, length: 300,
            id: target, choice: bike, fallback: walk))
        XCTAssertEqual(updated.map(\.speedMPH), [6, 10, 12])
        XCTAssertEqual(Set(updated.map(\.id)).count, 3)
        XCTAssertTrue(RouteTravelSection.valid(updated, length: 300))
    }

    func testStopBoundariesIncludeDestinationAndCoLocatedStops() {
        let a = RouteStop(name: "A", metres: 100, waitSeconds: 0)
        let b = RouteStop(name: "B", metres: 100, waitSeconds: 15)
        XCTAssertEqual(RouteLegEditing.range(to: a.id, stops: [a, b], length: 300), 0...100)
        XCTAssertEqual(RouteLegEditing.range(to: b.id, stops: [a, b], length: 300), 100...100)
        XCTAssertEqual(RouteLegEditing.range(to: RouteLegChoice.destinationID, stops: [a, b], length: 300), 100...300)
        XCTAssertNil(RouteLegEditing.range(to: UUID(), stops: [a], length: 300))
    }

    func testInvalidEditsCannotDamageExistingRoute() {
        XCTAssertNil(RouteLegEditing.replacing([], in: 0...400, length: 300, id: UUID(), choice: bike, fallback: walk))
        XCTAssertNil(RouteLegEditing.replacing([], in: 0...100, length: 300, id: UUID(),
            choice: .init(mode: .walk, speedMPH: .nan), fallback: walk))
        let invalid = [RouteTravelSection(id: UUID(), startMetres: 10, endMetres: 300, mode: .walk, speedMPH: 3)]
        XCTAssertNil(RouteLegEditing.replacing(invalid, in: 100...200, length: 300, id: UUID(), choice: bike, fallback: walk))
    }

    func testCoLocatedLegDoesNotInventTravelAndSectionLimitRemainsValid() throws {
        let old = [RouteTravelSection(id: UUID(), startMetres: 0, endMetres: 300, mode: .walk, speedMPH: 3)]
        let unchanged = try XCTUnwrap(RouteLegEditing.replacing(old, in: 100...100, length: 300,
            id: UUID(), choice: bike, fallback: walk))
        XCTAssertEqual(unchanged, old)
        let full = (0..<21).map { index in
            RouteTravelSection(id: UUID(), startMetres: Double(index * 10), endMetres: Double((index + 1) * 10), mode: .walk, speedMPH: 3)
        }
        XCTAssertNil(RouteLegEditing.replacing(full, in: 5...15, length: 210, id: UUID(), choice: bike, fallback: walk))
        XCTAssertTrue(RouteTravelSection.valid(full, length: 210))
    }

    func testMapTapsWaitForExplicitPreparedRouteDismissal() {
        XCTAssertFalse(MapPinPlacement.allowed(hasJourney: false, hasPreparedRoute: true, drawing: false, adjusting: false))
        XCTAssertFalse(MapPinPlacement.allowed(hasJourney: true, hasPreparedRoute: false, drawing: false, adjusting: false))
        XCTAssertFalse(MapPinPlacement.allowed(hasJourney: false, hasPreparedRoute: false, drawing: true, adjusting: false))
        XCTAssertTrue(MapPinPlacement.allowed(hasJourney: false, hasPreparedRoute: false, drawing: false, adjusting: false))
    }
}
