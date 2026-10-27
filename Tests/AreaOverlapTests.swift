import XCTest
@testable import SessionPresentation

final class AreaOverlapTests: XCTestCase {
    private func polygon(_ points: [(Double, Double)], name: String = "Area") -> NamedArea {
        NamedArea(name: name, points: points.map { RoutePoint(latitude: $0.1, longitude: $0.0) })
    }
    private func box(_ x: Double = 0, _ y: Double = 0, _ width: Double = 1, _ height: Double = 1) -> NamedArea {
        polygon([(x,y),(x+width,y),(x+width,y+height),(x,y+height)])
    }
    private func assertOverlap(_ a: NamedArea, _ b: NamedArea, _ expected: Bool, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(a.isValid, file: file, line: line); XCTAssertTrue(b.isValid, file: file, line: line)
        XCTAssertEqual(a.overlaps(b), expected, file: file, line: line)
        XCTAssertEqual(b.overlaps(a), expected, file: file, line: line)
        var reversed = b; reversed.points.reverse()
        XCTAssertEqual(a.overlaps(reversed), expected, file: file, line: line)
    }
    func testDisjointEdgesAndCornersCanMeet() {
        assertOverlap(box(), box(2,2), false)
        assertOverlap(box(), box(1,0), false)
        assertOverlap(box(), box(1,1), false)
        assertOverlap(box(), box(1,0.25,1,0.5), false)
    }
    func testPartialContainmentIdenticalAndCrossedInteriorsAreRejected() {
        assertOverlap(box(), box(0.5,0.5), true)
        assertOverlap(box(), box(0.2,0.2,0.4,0.4), true)
        assertOverlap(box(), box(), true)
        assertOverlap(box(0,0,3,1), box(1,-1,1,3), true)
        assertOverlap(box(), box(0,0,0.5,1), true)
    }
    func testConcaveCutoutIsAvailableButItsEdgesCannotBeCrossed() {
        let l = polygon([(0,0),(3,0),(3,1),(1,1),(1,3),(0,3)])
        assertOverlap(l, box(1.2,1.2,0.5,0.5), false)
        assertOverlap(l, box(0.8,0.8,0.5,0.5), true)
        assertOverlap(l, box(1,1,1,1), false)
    }
    func testDateLineOverlapAndNearbyNonOverlap() {
        let across = polygon([(179.99,0),(-179.99,0),(-179.99,0.02),(179.99,0.02)])
        assertOverlap(across, box(179.995,0.005,0.003,0.003), true)
        assertOverlap(across, box(-179.998,0.005,0.003,0.003), true)
        assertOverlap(across, box(-179.98,0,0.005,0.005), false)
        assertOverlap(across, box(0,0,0.01,0.01), false)
    }
    func testSameNameCanBeUsedForSeparatePiecesAndEditingExcludesSelf() throws {
        let a = box(), b = box(2,0)
        XCTAssertEqual(a.name, b.name)
        XCTAssertNil(a.conflictingArea(in: [a,b]))
        XCTAssertEqual(try LibraryMerge.areas(local: [a], incoming: [b]), [a,b])
        XCTAssertThrowsError(try LibraryMerge.areas(local: [a], incoming: [box(0.5,0.5)]))
        XCTAssertThrowsError(try LibraryMerge.areas(local: [], incoming: [a,box(0.5,0.5)]))
    }
    func testLegacyOverlapRemainsReadableWithoutAllowingNewConflicts() throws {
        let old = [box(),box(0.5,0.5)]
        XCTAssertNil(NamedArea.newConflict(in: old, replacing: old))
        var renamed = old; renamed[0].name = "Renamed"
        XCTAssertNil(NamedArea.newConflict(in: renamed, replacing: old))
        XCTAssertEqual(try LibraryMerge.areas(local: old, incoming: old), old)
        XCTAssertNotNil(NamedArea.newConflict(in: old+[box(0.7,0.7)], replacing: old))
        XCTAssertNil(NamedArea.newConflict(in: [old[0]], replacing: old))
    }
}
