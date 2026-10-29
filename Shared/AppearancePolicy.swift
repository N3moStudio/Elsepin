// Original new Elsepin implementation. See NEW-ADDITIONS-LICENSE.md.
import Foundation

/// Theme presets are presentation only. Never use them to recreate a map, route,
/// session or navigation stack. Stored raw values are part of backup compatibility.
enum AppearanceMaterial: String, Codable, CaseIterable, Sendable { case theme, solid, glass }

/// Font design and text size are fixed for every theme. These types remain so older
/// backups still decode and so exports can state the values older versions expect.
enum AppearanceFont: String, Codable, CaseIterable, Sendable { case theme, system, rounded, serif, monospaced }
enum AppearanceTextSize: String, Codable, CaseIterable, Sendable { case theme, compact, standard, large }

enum AppearanceFixed {
    static let font = AppearanceFont.rounded
    static let textSize = AppearanceTextSize.compact
}

/// The only user-adjustable surface choice is the material. Older stored `font` and
/// `textSize` values are ignored when decoding.
struct AppearanceOverrides: Codable, Equatable, Sendable {
    static let defaultsKey = "shift.appearanceOverrides.v1"
    var material = AppearanceMaterial.theme

    func material(for style: ShiftVisualStyle) -> AppearanceMaterial { material == .theme ? style.defaultMaterial : material }
}

extension ShiftVisualStyle {
    /// A theme selection sets the whole palette, not just a tint. Explicit user
    /// overrides are resolved separately and survive switching themes.
    var defaultAppearance: String {
        switch self {
        case .afterhours, .ion, .ember, .titanium: return "dark"
        case .porcelain, .bloom, .blueprint: return "light"
        case .glacier: return "system"
        }
    }
    var defaultMaterial: AppearanceMaterial { .solid }
}
