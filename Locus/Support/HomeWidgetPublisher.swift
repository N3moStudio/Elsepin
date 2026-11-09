import Foundation
import WidgetKit

@MainActor
enum HomeWidgetPublisher {
    static let unavailableMessage = "Saved-location widgets need shared App Group access. This installation doesn't provide it. Check your signer's app-extension and App Group support."
    private static var reportedMissingAccess = false
    static var available: Bool { container != nil }
    private static var container: URL? { WidgetLibrary.containerURL }
    static func resetSharedData() throws {
        // A build without an accessible app group cannot have written this data.
        guard let container else { return }
        let file = container.appendingPathComponent(WidgetLibrary.filename)
        if FileManager.default.fileExists(atPath: file.path) { try FileManager.default.removeItem(at: file) }
        WidgetCenter.shared.reloadAllTimelines()
    }
    static func placeID(_ place: SavedPlace) -> UUID {
        var ids = AppDataWorkspace.defaults.dictionary(forKey: "locus.widget.placeIDs") as? [String: String] ?? [:]
        if let stored = ids[place.id], let id = UUID(uuidString: stored) { return id }
        let id = UUID(); ids[place.id] = id.uuidString
        AppDataWorkspace.defaults.set(ids, forKey: "locus.widget.placeIDs")
        return id
    }
    static func place(for id: UUID, among places: [SavedPlace]) -> SavedPlace? {
        let ids = AppDataWorkspace.defaults.dictionary(forKey: "locus.widget.placeIDs") as? [String: String] ?? [:]
        return places.first { ids[$0.id] == id.uuidString }
    }
    static func choices(places: [SavedPlace], trips: [SavedTrip]) -> [WidgetLibraryItem] {
        places.map { WidgetLibraryItem(id: placeID($0), title: $0.displayName, kind: "place") } +
            trips.map { WidgetLibraryItem(id: $0.id, title: $0.name, kind: "trip") }
    }
    @discardableResult
    static func publish(places: [SavedPlace], trips: [SavedTrip]) -> String? {
        let ids = AppDataWorkspace.defaults.dictionary(forKey: "locus.widget.placeIDs") as? [String: String] ?? [:]
        let retained = Set(places.map(\.id))
        let trimmed = ids.filter { retained.contains($0.key) }
        if trimmed != ids { AppDataWorkspace.defaults.set(trimmed, forKey: "locus.widget.placeIDs") }
        guard let container else {
            if !reportedMissingAccess {
                reportedMissingAccess = true
                DeveloperLogStore.shared.record("widget_storage_unavailable", ["shared_container": "missing"])
            }
            return unavailableMessage
        }
        let all = choices(places: places, trips: trips)
        let selected = AppDataWorkspace.defaults.stringArray(forKey: "locus.widget.selected")
        let items = selected.map { ids in ids.compactMap { id in all.first { $0.id.uuidString == id } } } ?? Array(all.prefix(4))
        let primary = AppDataWorkspace.defaults.string(forKey: "locus.widget.primary").flatMap(UUID.init(uuidString:))
        let snapshot = WidgetLibrary(items: Array(items.prefix(4)), primaryID: primary, availableItems: all)
        guard snapshot.valid else { return "Couldn't prepare the widget's saved items." }
        do {
            let data = try JSONEncoder().encode(snapshot)
            let file = container.appendingPathComponent(WidgetLibrary.filename)
            if (try? Data(contentsOf: file)) == data { return nil }
            try data.write(to: file, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            WidgetCenter.shared.reloadTimelines(ofKind: "LocusFavorite")
            WidgetCenter.shared.reloadTimelines(ofKind: "LocusLibrary")
            WidgetCenter.shared.reloadTimelines(ofKind: "ShiftLocation")
            return nil
        } catch { return "Couldn't update the Home Screen widgets. Open Elsepin and try again." }
    }
}
