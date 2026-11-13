import Foundation

enum AppResetScope: String, CaseIterable, Identifiable {
    case settings, keepSetup, full
    var id: String { rawValue }
    var wipesData: Bool { self != .settings }
    var title: String {
        switch self {
        case .settings: return "Restore default settings"
        case .keepSetup: return "Wipe data, keep setup"
        case .full: return "Wipe everything & restart setup"
        }
    }
    var detail: String {
        let settings = "Restores appearance, icon, speeds, controls, privacy, notifications, widgets and experimental settings to their defaults. App lock turns off; enabled app lock requires device authentication first."
        let limits = "Exports in Files, accounts on your helper server, installed Home Screen widgets, iOS permissions, Developer Mode, host trust and LocalDevVPN are not removed."
        switch self {
        case .settings:
            return settings + " Keeps saved places, routes, areas, history, recovery, helper connections, pairing and setup. " + limits
        case .keepSetup:
            return settings + " Permanently deletes saved places, routes, areas, edit history, Recently Deleted, recents, recovery, diagnostics and this app's helper credentials. Keeps this iPhone's pairing file, tunnel address and current setup progress. " + limits
        case .full:
            return settings + " Permanently deletes all of the same local data and helper credentials, then removes Elsepin's pairing file and opens the initial setup checklist. You must pair again or import a pairing file. " + limits
        }
    }
    var stages: [AppResetStage] {
        let data: [AppResetStage] = wipesData ? [.trips, .deletedItems, .places, .recovery, .diagnostics, .cloudLink, .computerLink, .widgetData] : []
        return data + [.settings, .icon] + (self == .full ? [.pairingAndSetup] : [])
    }
}

enum AppResetStage: String, Equatable {
    case trips = "Saved routes and edit history"
    case deletedItems = "Recently Deleted"
    case places = "Saved places, areas and recent locations"
    case recovery = "Trip recovery"
    case diagnostics = "Diagnostics and reliability history"
    case cloudLink = "Cloud helper connection"
    case computerLink = "Windows helper connection"
    case widgetData = "Shared widget data"
    case settings = "App settings"
    case icon = "Home Screen icon"
    case pairingAndSetup = "Pairing and initial setup"
}

struct AppResetResult: Identifiable {
    let id = UUID()
    let completed: [AppResetStage]
    let failed: AppResetStage?
    var succeeded: Bool { failed == nil }
    var title: String { succeeded ? "Reset complete" : "Reset incomplete" }
    var message: String {
        guard let failed else { return "Your chosen reset is complete. Nothing starts spoofing automatically." }
        let done = completed.isEmpty ? "No reset step completed." : "Already reset: " + completed.map(\.rawValue).joined(separator: ", ") + "."
        return done + " Could not finish: \(failed.rawValue). That step may be partly cleared. Later steps were not run. Earlier deletions cannot be undone. Reopen this screen and retry."
    }
}

/// A cancelled setup screen can still have native pairing work writing to disk.
/// Track the worker lifetime, independently of its screen or presentation state.
final class AppResetWorkGate: @unchecked Sendable {
    private let lock = NSLock()
    private var running = false
    var isBusy: Bool { lock.lock(); defer { lock.unlock() }; return running }
    func begin() -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard !running else { return false }
        running = true
        return true
    }
    func end() { lock.lock(); running = false; lock.unlock() }
}

enum AppResetRules {
    static let setupKeys: Set<String> = ["locus.setupComplete", "locus.setupDeferred", "locus.setupInProgress", "shift.setup.lastStep", "locus.targetDeviceIP"]
    // Settings reset never removes saved data, pairing or update-network throttles.
    static let settingKeys: Set<String> = Set([
        "liveActivities", "hideLocation", "hideIslandLocation", "lockScreenProgress", "islandProgress", "islandTimer",
        "showFindMyStatus", "showLife360Status", "glassPanel", "connectionAlerts", "reminderMinutes", "appearance",
        "showSavedPinsOnMap", "showNamedAreasOnMap", "mapPinSize", "mapPinVisibilityMiles",
        "appLockEnabled", "hideInAppSwitcher", "saveRecentLocations", "recentHistoryRetention", "panelShortcuts",
        "modeSpeeds", "usualSpeeds", "eBikeSpeedMPH", "smoothMovement", "preferWalkingPaths", "tripRecovery", "tripRecoveryAutoResume",
        "keepTroubleshootingEvents", "developerLogEnabled", "widget.selected", "widget.primary", "remoteFindMy.enabled", "remoteFindMy.alerts"
    ].map { "locus." + $0 } + ["shift.speedUnit", "shift.connectionCheckSeconds", "shift.visualStyle", AppearanceOverrides.defaultsKey, "shift.appearancePresetMigration.v1", "shift.cloud.findMy", "shift.cloud.life360", "shift.computerChecks.enabled"])

    static func canReset(hasSession: Bool, busy: Bool, setupWorkerRunning: Bool, iconChanging: Bool) -> Bool {
        !hasSession && !busy && !setupWorkerRunning && !iconChanging
    }

    static func clearPreferences(in defaults: UserDefaults, scope: AppResetScope) {
        // Pairing/setup are the last stage, after every fallible local-data stage.
        let preserved = setupKeys.union([ShiftAppearanceSelection.iconKey])
        for key in defaults.dictionaryRepresentation().keys {
            let owned = key.hasPrefix("locus.") || key.hasPrefix("shift.")
            if scope.wipesData ? (owned && !preserved.contains(key)) : settingKeys.contains(key) {
                defaults.removeObject(forKey: key)
            }
        }
    }

    @MainActor static func execute(_ scope: AppResetScope,
        perform: (AppResetStage) async throws -> Void) async -> AppResetResult {
        var completed: [AppResetStage] = []
        for stage in scope.stages {
            do { try await perform(stage); completed.append(stage) }
            catch { return AppResetResult(completed: completed, failed: stage) }
        }
        return AppResetResult(completed: completed, failed: nil)
    }
}
