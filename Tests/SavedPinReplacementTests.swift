import XCTest
@testable import SessionPresentation

final class SavedPinReplacementTests: XCTestCase {
    func testMovingToNewCoordinateAndEditingSamePinAreAllowed() {
        XCTAssertNil(SavedPinReplacement.validate(sourceID: "home", destinationID: "new", savedIDs: ["home", "school"]))
        XCTAssertNil(SavedPinReplacement.validate(sourceID: "home", destinationID: "home", savedIDs: ["home", "school"]))
    }
    func testMoveCannotOverwriteAnotherPinOrRecreateDeletedSource() {
        XCTAssertEqual(SavedPinReplacement.validate(sourceID: "home", destinationID: "school", savedIDs: ["home", "school"]), .destinationOccupied)
        XCTAssertEqual(SavedPinReplacement.validate(sourceID: "removed", destinationID: "new", savedIDs: ["home"]), .missingSource)
    }
    func testOrdinarySaveKeepsExistingUpsertBehavior() {
        XCTAssertNil(SavedPinReplacement.validate(sourceID: nil, destinationID: "home", savedIDs: ["home"]))
    }
}
