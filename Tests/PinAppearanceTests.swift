import XCTest
@testable import SessionPresentation

final class PinAppearanceTests: XCTestCase {
    func testNativeEmojiVariantsAndSequencesRemainWhole() {
        for emoji in ["🙂", "👍🏽", "🇺🇸", "👨‍👩‍👧‍👦", "❤️", "1️⃣"] {
            XCTAssertTrue(PinAppearance.isSingleEmoji(emoji), emoji)
        }
        for text in ["", "1", "#", "a", "hello", "🙂🙂"] {
            XCTAssertFalse(PinAppearance.isSingleEmoji(text), text)
        }
    }
    func testLegacyAndExtendedBackupPinsRoundTrip() throws {
        let old = Data(#"{"name":"Home","latitude":1,"longitude":2}"#.utf8)
        let legacy = try JSONDecoder().decode(BackupPlace.self, from: old)
        XCTAssertTrue(legacy.isValid)
        XCTAssertNil(legacy.address)
        XCTAssertNil(legacy.emoji)
        XCTAssertTrue(legacy.isFavorite)
        var current = legacy
        current.address = "123 Example Street"
        current.emoji = "🏡"
        current.color = "blue"
        XCTAssertTrue(current.isValid)
        XCTAssertEqual(try JSONDecoder().decode(BackupPlace.self, from: JSONEncoder().encode(current)), current)
        current.color = SavedPlaceTint.mint.rawValue
        XCTAssertEqual(SavedPlaceTint.mint.title, "Follow theme")
        XCTAssertEqual(try JSONDecoder().decode(BackupPlace.self, from: JSONEncoder().encode(current)).color, "mint")
        current.emoji = "bad"
        XCTAssertFalse(current.isValid)
    }
}
