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

    func testEmojiFieldRejectsLettersNumbersAndMixedPaste() {
        for rejected in ["1", "#", "abc", "🙂🙂", "🙂 home", " 🙂", "\n"] {
            XCTAssertNil(PinAppearance.applyingEmojiEdit(to: "", range: NSRange(location: 0, length: 0), replacement: rejected))
            XCTAssertNil(PinAppearance.applyingEmojiEdit(to: "🏡", range: NSRange(location: 2, length: 0), replacement: rejected))
        }
    }

    func testEmojiFieldAcceptsWholeVariantsAndReplacesPreviousSymbol() {
        for emoji in ["🙂", "👍🏽", "🇺🇸", "👨‍👩‍👧‍👦", "❤️", "1️⃣"] {
            XCTAssertEqual(PinAppearance.applyingEmojiEdit(to: "", range: NSRange(location: 0, length: 0), replacement: emoji), emoji)
            XCTAssertEqual(PinAppearance.applyingEmojiEdit(to: "🏡", range: NSRange(location: 2, length: 0), replacement: emoji), emoji)
            XCTAssertEqual(PinAppearance.applyingEmojiEdit(to: "🏡", range: NSRange(location: 0, length: 2), replacement: emoji), emoji)
        }
    }

    func testEmojiFieldCanClearComplexEmojiAndRejectsStaleRanges() {
        let family = "👨‍👩‍👧‍👦"
        XCTAssertEqual(PinAppearance.applyingEmojiEdit(to: family, range: NSRange(location: 0, length: family.utf16.count), replacement: ""), "")
        XCTAssertEqual(PinAppearance.applyingEmojiEdit(to: "🏡", range: NSRange(location: 2, length: 0), replacement: ""), "🏡")
        XCTAssertNil(PinAppearance.applyingEmojiEdit(to: "🏡", range: NSRange(location: 20, length: 1), replacement: "🙂"))
    }
}
