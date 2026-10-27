// Original new Elsepin implementation. See NEW-ADDITIONS-LICENSE.md.
import Foundation

/// Theme presets are presentation only. Never use them to recreate a map, route,
/// session or navigation stack. Stored raw values are part of backup compatibility.
enum AppearanceMaterial: String, Codable, CaseIterable, Sendable { case theme, solid, glass }
enum AppearanceFont: String, Codable, CaseIterable, Sendable { case theme, system, rounded, serif, monospaced }
enum AppearanceTextSize: String, Codable, CaseIterable, Sendable { case theme, compact, standard, large }

struct AppearanceOverrides: Codable, Equatable, Sendable {
    static let defaultsKey = "shift.appearanceOverrides.v1"
    var material = AppearanceMaterial.theme
    var font = AppearanceFont.theme
    var textSize = AppearanceTextSize.theme

    func material(for style: ShiftVisualStyle) -> AppearanceMaterial { material == .theme ? style.defaultMaterial : material }
    func font(for style: ShiftVisualStyle) -> AppearanceFont { font == .theme ? style.defaultFont : font }
    func textSize(for style: ShiftVisualStyle) -> AppearanceTextSize { textSize == .theme ? style.defaultTextSize : textSize }
}

extension ShiftVisualStyle {
    /// A theme selection sets the whole palette, not just a tint. Explicit user
    /// overrides are resolved separately and survive switching themes.
    var defaultAppearance: String {
        switch self {
        case .afterhours, .ion, .ember, .abyss, .titanium: return "dark"
        case .porcelain, .bloom, .blueprint: return "light"
        case .glacier: return "system"
        }
    }
    var defaultMaterial: AppearanceMaterial { .solid }
    var defaultFont: AppearanceFont {
        switch self {
        case .glacier, .bloom: return .rounded
        case .porcelain: return .serif
        case .blueprint: return .monospaced
        default: return .system
        }
    }
    var defaultTextSize: AppearanceTextSize {
        self == .afterhours || self == .bloom ? .large : .standard
    }
}
