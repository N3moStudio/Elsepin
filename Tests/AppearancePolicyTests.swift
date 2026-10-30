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
    func testDefaultThemeIsBloomWithSolidSurface() {
        XCTAssertEqual(ShiftAppearanceSelection().style, .bloom)
        XCTAssertEqual(AppearanceOverrides().material, .solid)
        XCTAssertEqual(AppearanceOverrides().material(for: .bloom), .solid)
    }
    func testOnlyConcreteSurfacesAreOfferedInOrder() {
        XCTAssertEqual(AppearanceMaterial.allCases, [.solid, .glass])
    }
    func testLegacyThemeSurfaceMigratesAndExportsAsSolid() throws {
        let legacy = Data(#"{"material":"theme","font":"serif","textSize":"large"}"#.utf8)
        let restored = try JSONDecoder().decode(AppearanceOverrides.self, from: legacy)
        XCTAssertEqual(restored.material, .solid)
        for style in ShiftVisualStyle.allCases {
            XCTAssertEqual(restored.material(for: style), .solid)
        }
        let encoded = try JSONEncoder().encode(restored)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        XCTAssertEqual(object["material"] as? String, "solid")
    }
    func testUnknownSurfaceIsRejectedAndExplicitChoicesRoundTrip() throws {
        XCTAssertThrowsError(try JSONDecoder().decode(AppearanceMaterial.self, from: Data(#""unknown""#.utf8)))
        for material in AppearanceMaterial.allCases {
            XCTAssertEqual(try JSONDecoder().decode(AppearanceMaterial.self, from: JSONEncoder().encode(material)), material)
        }
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
