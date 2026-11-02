// Original new Elsepin implementation. See NEW-ADDITIONS-LICENSE.md.
import Foundation

/// Theme presets are presentation only. Never use them to recreate a map, route,
/// session or navigation stack. Stored raw values are part of backup compatibility.
enum AppearanceMaterial: String, Codable, CaseIterable, Sendable {
    case solid, glass

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        // All former theme defaults were solid. Normalize old defaults/backups
        // here so the picker and import preview never receive a hidden choice.
        guard let material = raw == "theme" ? Self.solid : Self(rawValue: raw) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown surface")
        }
        self = material
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

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
    var material = AppearanceMaterial.solid

    func material(for style: ShiftVisualStyle) -> AppearanceMaterial { material }
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
}
