import Foundation

enum PinAppearance {
    /// A whole extended grapheme preserves flags, ZWJ families and skin tones.
    /// ASCII digits alone have the emoji property, but aren't emoji glyphs.
    static func isSingleEmoji(_ text: String) -> Bool {
        guard text.count == 1, text.unicodeScalars.count <= 32 else { return false }
        return text.unicodeScalars.contains { $0.properties.isEmojiPresentation } ||
            (text.unicodeScalars.contains { $0.properties.isEmoji } &&
             text.unicodeScalars.contains { $0.value == 0xFE0F || $0.value == 0x20E3 })
    }
}
