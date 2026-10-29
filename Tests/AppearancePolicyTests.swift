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
    func testSurfaceOverrideSurvivesThemeChangesAndSerialization() throws {
        let chosen = AppearanceOverrides(material: .glass)
        let restored = try JSONDecoder().decode(AppearanceOverrides.self, from: JSONEncoder().encode(chosen))
        for style in ShiftVisualStyle.allCases {
            XCTAssertEqual(restored.material(for: style), .glass)
        }
    }
    func testFontAndTextSizeAreFixedForEveryTheme() {
        XCTAssertEqual(AppearanceFixed.font, .rounded)
        XCTAssertEqual(AppearanceFixed.textSize, .compact)
    }
    func testOlderOverridesWithFontAndTextSizeStillDecode() throws {
        let legacy = Data(#"{"material":"glass","font":"serif","textSize":"large"}"#.utf8)
        let decoded = try JSONDecoder().decode(AppearanceOverrides.self, from: legacy)
        XCTAssertEqual(decoded, AppearanceOverrides(material: .glass))
    }
    func testDefaultThemeIsBloomWithThemeDefaultSurface() {
        XCTAssertEqual(ShiftAppearanceSelection().style, .bloom)
        XCTAssertEqual(AppearanceOverrides().material, .theme)
        XCTAssertEqual(AppearanceOverrides().material(for: .bloom), .solid)
    }
    func testRetiredAbyssThemeLoadsAsBloom() throws {
        XCTAssertEqual(ShiftVisualStyle(storedValue: "abyss"), .bloom)
        XCTAssertEqual(try JSONDecoder().decode(ShiftVisualStyle.self, from: Data("\"abyss\"".utf8)), .bloom)
        XCTAssertThrowsError(try JSONDecoder().decode(ShiftVisualStyle.self, from: Data("\"unknown\"".utf8)))
        XCTAssertNil(ShiftVisualStyle.allCases.first { $0.rawValue == "abyss" })
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
        incoming.visualStyle = .ion; incoming.material = .solid
        try BackupSettingKey.material.applying(from: incoming, to: &old)
        XCTAssertEqual(old.material, .solid)
        XCTAssertNil(old.visualStyle)
        XCTAssertNil(old.textSize)
    }
    func testFontAndTextSizeAreNoLongerUserSettings() {
        XCTAssertFalse(BackupSettingKey.allCases.map(\.rawValue).contains("appearance"))
        XCTAssertFalse(BackupSettingKey.allCases.map(\.rawValue).contains("font"))
        XCTAssertFalse(BackupSettingKey.allCases.map(\.rawValue).contains("textSize"))
    }
}
