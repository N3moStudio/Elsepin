import XCTest
@testable import SessionPresentation

final class WidgetLocationTests: XCTestCase {
    func testEachWidgetCanResolveItsOwnLocationBeyondSharedFour() throws {
        let all = (0..<8).map { WidgetLibraryItem(id: UUID(), title: "Place \($0)", kind: "place") }
        let value = WidgetLibrary(items: Array(all.prefix(4)), availableItems: all)
        XCTAssertTrue(value.valid)
        let a = try XCTUnwrap(WidgetPinDestination(all[1])), b = try XCTUnwrap(WidgetPinDestination(all[6]))
        XCTAssertEqual(value.pinDestination(id: a.id), a)
        XCTAssertEqual(value.pinDestination(id: b.id), b)
        XCTAssertNotEqual(a.url, b.url)
        XCTAssertNil(value.pinDestination(id: "removed"))
        XCTAssertNil(value.pinDestination(id: nil))
    }
    func testRouteStartLinkOnlyPreparesPinAndRejectsAutomaticActions() throws {
        let item = WidgetLibraryItem(id: UUID(), title: "Route", kind: "trip")
        let pin = try XCTUnwrap(WidgetPinDestination(item))
        let link = try XCTUnwrap(LocusShortcut(url: pin.url))
        XCTAssertEqual(link.kind, .tripStart)
        XCTAssertEqual(link.id, item.id)
        for action in ["start=true", "teleport=true", "action=start", "confirm=false"] {
            XCTAssertNil(LocusShortcut(url: URL(string: pin.url.absoluteString + "?" + action)!))
        }
        XCTAssertNil(WidgetPinDestination(WidgetLibraryItem(id: UUID(), title: "Unsafe", kind: "teleport")))
    }
    func testOldSnapshotDecodesAndDeletedTargetsNeverFallBackToAnotherPlace() throws {
        let item = WidgetLibraryItem(id: UUID(), title: "Old favorite", kind: "place")
        let legacy = WidgetLibrary(items: [item])
        let restored = try JSONDecoder().decode(WidgetLibrary.self, from: JSONEncoder().encode(legacy))
        XCTAssertTrue(restored.valid)
        XCTAssertEqual(restored.pinDestinations.count, 1)
        let removedID = try XCTUnwrap(restored.pinDestinations.first).id
        let newSnapshot = WidgetLibrary(items: [item], availableItems: [])
        XCTAssertNil(newSnapshot.pinDestination(id: removedID))
    }
    func testCatalogRejectsUnknownActionsAndUnboundedEntries() {
        let invalid = WidgetLibraryItem(id: UUID(), title: "Bad", kind: "teleport")
        XCTAssertFalse(WidgetLibrary(items: [], availableItems: [invalid]).valid)
        let items = (0..<1051).map { WidgetLibraryItem(id: UUID(), title: "Place \($0)", kind: "place") }
        XCTAssertFalse(WidgetLibrary(items: [], availableItems: items).valid)
    }
    func testWidgetHandlerHasNoLocationCommandOrAutomaticSessionMutation() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appendingPathComponent("Locus/Features/Map/RootView.swift"), encoding: .utf8)
        let handler = try XCTUnwrap(source.components(separatedBy: "private func openShortcutIfAllowed()").dropFirst().first)
            .components(separatedBy: "private func publishWidgets()")[0]
        for call in ["session.teleport(", "session.startPreparedRoute(", "session.startJoystick(", "session.stop(", "session.cancelRoute(", "session.beginSession(", "session.apply("] {
            XCTAssertFalse(handler.contains(call), "Widget handling must require the separate manual control: \(call)")
        }
        let widget = try String(contentsOf: root.appendingPathComponent("LocusActivity/LocusHomeWidgets.swift"), encoding: .utf8)
        XCTAssertFalse(widget.contains("Button(intent:"), "Location widgets only open preview URLs")
    }
}
