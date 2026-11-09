import Combine
import Foundation

@MainActor
final class DevModeController: ObservableObject {
    static let shared = DevModeController()
    @Published private(set) var enabled = AppDataWorkspace.shared.isDemo
    @Published private(set) var switching = false
    @Published private(set) var revision = UUID()
    @Published var error: String?

    func setEnabled(_ value: Bool, session: SpoofSession, reset: AppResetController) async {
        guard value != enabled, !switching else { return }
        guard canSwitch(session, reset: reset) else {
            error = "Stop spoofing and finish or discard the current route or recovery before changing Dev Mode."
            return
        }
        switching = true
        defer { switching = false }
        // A completed file write is not enough: wait for its availability marker
        // and model callback too, before dropping the old namespace.
        await session.finishWorkspaceWrites()
        guard canSwitch(session, reset: reset) else {
            error = "Finish the current session before changing Dev Mode."
            return
        }
        do {
            if value {
                try AppDataWorkspace.shared.activateDemo { context in
                    let sample = DevModeDataset.make(at: Date())
                    let encoder = JSONEncoder()
                    let files: [(String, Data)] = [
                        ("Trips.json", try encoder.encode(sample.tripLibrary)),
                        ("RecentlyDeleted.json", try encoder.encode(sample.deletedItems))
                    ]
                    for (name, data) in files {
                        try data.write(to: context.file(name), options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
                    }
                    let pins = sample.backup.places.map {
                        SavedPlace(name: $0.name, latitude: $0.latitude, longitude: $0.longitude,
                            folder: $0.folder, icon: $0.icon, color: $0.color, favorite: $0.favorite)
                    }
                    context.defaults.set(try encoder.encode(pins), forKey: "locus.favorites")
                    context.defaults.set(try encoder.encode(Array(pins.prefix(3)).map { pin in
                        var recent = pin; recent.visitedAt = Date(); return recent
                    }), forKey: "locus.recents")
                    context.defaults.set(try encoder.encode(sample.backup.areas ?? []), forKey: "locus.namedAreas")
                    context.defaults.set(try encoder.encode(sample.recentRoutes), forKey: RecentRouteStore.key)
                    context.defaults.set(true, forKey: "locus.recentRoutesAvailable")
                }
            } else { AppDataWorkspace.shared.deactivateDemo() }
            SessionPreferences.shared.reloadAfterReset()
            session.reloadDataWorkspace()
            RecentlyDeletedStore.shared.reloadWorkspace()
            enabled = value
            // Destroy open drafts/planners, not the engine or pairing controller.
            revision = UUID()
            _ = HomeWidgetPublisher.publish(places: session.savedPins, trips: TripLibrary().trips)
            DeveloperLogStore.shared.record("demo_workspace_changed", ["enabled": String(value)])
        } catch {
            self.error = "Couldn't prepare the demo data. Your real data was kept. Free some storage and try again."
        }
    }

    private func canSwitch(_ session: SpoofSession, reset: AppResetController) -> Bool {
        !reset.isResetting && reset.canReset(session) && session.journey == nil
            && session.recovery.checkpoint == nil
    }
}
