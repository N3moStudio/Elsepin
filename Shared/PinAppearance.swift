import Foundation

enum PinAppearance {
    /// Reject invalid edits before the native text field displays them. Choosing
    /// another emoji replaces the current symbol instead of appending a second.
    static func applyingEmojiEdit(to current: String, range: NSRange, replacement: String) -> String? {
        guard let range = Range(range, in: current) else { return nil }
        if replacement.isEmpty { return range.isEmpty ? current : "" }
        let proposed = current.replacingCharacters(in: range, with: replacement)
        if isSingleEmoji(proposed) { return proposed }
        return isSingleEmoji(replacement) ? replacement : nil
    }

    /// A whole extended grapheme preserves flags, ZWJ families and skin tones.
    /// ASCII digits alone have the emoji property, but aren't emoji glyphs.
    static func isSingleEmoji(_ text: String) -> Bool {
        guard text.count == 1, text.unicodeScalars.count <= 32 else { return false }
        return text.unicodeScalars.contains { $0.properties.isEmojiPresentation } ||
            (text.unicodeScalars.contains { $0.properties.isEmoji } &&
             text.unicodeScalars.contains { $0.value == 0xFE0F || $0.value == 0x20E3 })
    }
}
