import XCTest
@testable import SessionPresentation

final class AppDataWorkspaceTests: XCTestCase {
    func testDemoEditsNeverOverwritePersonalDataAndRelaunchKeepsDemo() throws {
        let name = "workspace-test." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        defer { defaults.removePersistentDomain(forName: name); try? FileManager.default.removeItem(at: folder) }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let original = Data("personal routes".utf8)
        try original.write(to: folder.appendingPathComponent("Trips.json"))
        defaults.set("personal pins", forKey: "locus.favorites")
        let workspace = AppDataWorkspace(personal: defaults, directory: folder, suitePrefix: name)
        try workspace.activateDemo { candidate in
            candidate.defaults.set("demo pins", forKey: "locus.favorites")
            try Data("demo routes".utf8).write(to: candidate.file("Trips.json"))
        }
        let demo = workspace.context
        let relaunched = AppDataWorkspace(personal: defaults, directory: folder, suitePrefix: name)
        XCTAssertEqual(relaunched.context.id, demo.id)
        XCTAssertEqual(relaunched.context.defaults.string(forKey: "locus.favorites"), "demo pins")
        demo.defaults.set("edited demo", forKey: "locus.favorites")
        try Data("edited demo".utf8).write(to: demo.file("Trips.json"))
        workspace.deactivateDemo()
        XCTAssertFalse(workspace.isDemo)
        XCTAssertEqual(workspace.context.defaults.string(forKey: "locus.favorites"), "personal pins")
        XCTAssertEqual(try Data(contentsOf: workspace.context.file("Trips.json")), original)
        try workspace.activateDemo { $0.defaults.set("fresh demo", forKey: "locus.favorites") }
        XCTAssertNotEqual(workspace.context.id, demo.id)
        XCTAssertEqual(workspace.context.defaults.string(forKey: "locus.favorites"), "fresh demo")
        workspace.deactivateDemo()
    }

    func testFailedSeedLeavesPersonalWorkspaceActive() throws {
        let name = "workspace-failure." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        defer { defaults.removePersistentDomain(forName: name); try? FileManager.default.removeItem(at: folder) }
        let workspace = AppDataWorkspace(personal: defaults, directory: folder, suitePrefix: name)
        XCTAssertThrowsError(try workspace.activateDemo { _ in throw CocoaError(.fileWriteOutOfSpace) })
        XCTAssertFalse(workspace.isDemo)
        XCTAssertFalse(AppDataWorkspace(personal: defaults, directory: folder, suitePrefix: name).isDemo)
    }
}
