// Original new Elsepin implementation. See NEW-ADDITIONS-LICENSE.md.
import SwiftUI

/// Apply presentation without changing view identity: active touches, navigation,
/// route drafts and the native map must survive a theme change.
struct AppearancePresentation: ViewModifier {
    @EnvironmentObject private var preferences: SessionPreferences
    @Environment(\.dynamicTypeSize) private var systemSize

    private var font: Font.Design {
        switch preferences.appearanceOverrides.font(for: preferences.visualStyle) {
        case .rounded: return .rounded
        case .serif: return .serif
        case .monospaced: return .monospaced
        default: return .default
        }
    }
    private var textSize: DynamicTypeSize {
        // Never shrink accessibility categories or cap the user's system size.
        guard !systemSize.isAccessibilitySize else { return systemSize }
        let sizes: [DynamicTypeSize] = [.xSmall, .small, .medium, .large, .xLarge, .xxLarge, .xxxLarge]
        guard let index = sizes.firstIndex(of: systemSize) else { return systemSize }
        let option = preferences.appearanceOverrides.textSize(for: preferences.visualStyle)
        let offset = option == .large ? 1 : option == .compact ? -1 : 0
        return sizes[min(sizes.count - 1, max(0, index + offset))]
    }
    func body(content: Content) -> some View {
        content.fontDesign(font).dynamicTypeSize(textSize)
            .foregroundStyle(ShiftPalette.color(.text, style: preferences.visualStyle))
    }
}

struct AppearanceNavigationSurface: ViewModifier {
    @EnvironmentObject private var preferences: SessionPreferences
    func body(content: Content) -> some View {
        content
            .toolbarBackground(ShiftPalette.color(.surface, style: preferences.visualStyle), for: .navigationBar)
            .toolbarBackground(preferences.glassPanel ? .automatic : .visible, for: .navigationBar)
    }
}
