import XCTest
@testable import SessionPresentation

final class AppearancePolicyTests: XCTestCase {
    func testIonStartsDarkAndSolidWithTheReferencePalette() {
        XCTAssertEqual(ShiftVisualStyle.ion.defaultAppearance, "dark")
        XCTAssertEqual(AppearanceOverrides().material(for: .ion), .solid)
        XCTAssertEqual(ShiftVisualStyle.ion.hex(.canvas, dark: true), 0x10170D)
        XCTAssertEqual(ShiftVisualStyle.ion.hex(.surface, dark: true), 0x20291C)
        XCTAssertEqual(ShiftVisualStyle.ion.hex(.accent, dark: true), 0xD7FF4F)
    }
    func testOverridesSurviveThemeChangesAndSerialization() throws {
        let chosen = AppearanceOverrides(material: .glass, font: .serif, textSize: .large)
        let restored = try JSONDecoder().decode(AppearanceOverrides.self, from: JSONEncoder().encode(chosen))
        for style in ShiftVisualStyle.allCases {
            XCTAssertEqual(restored.material(for: style), .glass)
            XCTAssertEqual(restored.font(for: style), .serif)
            XCTAssertEqual(restored.textSize(for: style), .large)
        }
        XCTAssertEqual(AppearanceOverrides().font(for: .blueprint), .monospaced)
        XCTAssertEqual(AppearanceOverrides().font(for: .bloom), .rounded)
        XCTAssertEqual(AppearanceOverrides().font(for: .porcelain), .serif)
    }
    func testResetIncludesOverridesWithoutClearingNetworkBackoff() {
        XCTAssertTrue(AppResetRules.settingKeys.contains(AppearanceOverrides.defaultsKey))
        XCTAssertFalse(AppResetRules.settingKeys.contains("shift.updates.stable.v1"))
    }
    func testNewAppearanceFieldsAreOptionalForOldBackupsAndSelectable() throws {
        var old = BackupPreferences(usualSpeeds: [:], glassPanel: true, appearance: "system",
                                   smoothMovement: true, preferWalkingPaths: false, shortcuts: PanelShortcut.normalized([]))
        XCTAssertTrue(old.isValid)
        let data = try JSONEncoder().encode(old)
        let decoded = try JSONDecoder().decode(BackupPreferences.self, from: data)
        XCTAssertNil(decoded.visualStyle)
        XCTAssertNil(decoded.material)
        var incoming = old
        incoming.visualStyle = .ion; incoming.material = .solid; incoming.font = .serif; incoming.textSize = .large
        try BackupSettingKey.font.applying(from: incoming, to: &old)
        XCTAssertEqual(old.font, .serif)
        XCTAssertNil(old.material)
        XCTAssertNil(old.visualStyle)
        XCTAssertNil(old.textSize)
    }
}
