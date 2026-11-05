import SwiftUI
import WidgetKit

@MainActor
final class SessionPreferences: ObservableObject {
    static let shared = SessionPreferences()
    @Published var speedUnit: SpeedUnit { didSet { defaults.set(speedUnit.rawValue, forKey: "shift.speedUnit") } }
    @Published var liveActivities: Bool { didSet { save(liveActivities, "liveActivities") } }
    @Published var hideLocation: Bool { didSet { save(hideLocation, "hideLocation") } }
    @Published var hideIslandLocation: Bool { didSet { save(hideIslandLocation, "hideIslandLocation") } }
    @Published var lockScreenProgress: Bool { didSet { save(lockScreenProgress, "lockScreenProgress") } }
    @Published var islandProgress: Bool { didSet { save(islandProgress, "islandProgress") } }
    @Published var islandTimer: Bool { didSet { save(islandTimer, "islandTimer") } }
    @Published var showFindMyStatus: Bool { didSet { save(showFindMyStatus, "showFindMyStatus") } }
    @Published var showLife360Status: Bool { didSet { save(showLife360Status, "showLife360Status") } }
    @Published var showSavedPinsOnMap: Bool { didSet { save(showSavedPinsOnMap, "showSavedPinsOnMap") } }
    @Published var showNamedAreasOnMap: Bool { didSet { save(showNamedAreasOnMap, "showNamedAreasOnMap") } }
    // Legacy backup field remains writable; all surfaces now use one policy.
    var glassPanel: Bool {
        get { appearanceOverrides.material(for: visualStyle) == .glass }
        set { appearanceOverrides.material = newValue ? .glass : .solid }
    }
    @Published var appearanceOverrides: AppearanceOverrides {
        didSet {
            if let data = try? JSONEncoder().encode(appearanceOverrides) {
                defaults.set(data, forKey: AppearanceOverrides.defaultsKey)
            }
        }
    }
    @Published var connectionAlerts: Bool { didSet { save(connectionAlerts, "connectionAlerts") } }
    @Published var connectionCheckSeconds: Int {
        didSet {
            let bounded = SessionTiming.checkSeconds(connectionCheckSeconds)
            if bounded != connectionCheckSeconds { connectionCheckSeconds = bounded }
            defaults.set(bounded, forKey: "shift.connectionCheckSeconds")
        }
    }
    @Published var reminderMinutes: Int { didSet { save(reminderMinutes, "reminderMinutes") } }
    @Published var appearance: String { didSet { save(appearance, "appearance") } }
    @Published var appLockEnabled: Bool { didSet { save(appLockEnabled, "appLockEnabled") } }
    @Published var hideInAppSwitcher: Bool { didSet { save(hideInAppSwitcher, "hideInAppSwitcher") } }
    @Published var saveRecentLocations: Bool { didSet { save(saveRecentLocations, "saveRecentLocations") } }
    @Published var recentHistoryRetention: RecentHistoryRetention { didSet { save(recentHistoryRetention.rawValue, "recentHistoryRetention") } }
    @Published var panelShortcuts: [PanelShortcut] {
        didSet {
            let normalized = PanelShortcut.normalized(panelShortcuts)
            if panelShortcuts != normalized { panelShortcuts = normalized }
            save(normalized.map(\.rawValue), "panelShortcuts")
        }
    }
    @Published var visualStyle: ShiftVisualStyle {
        didSet {
            guard visualStyle != oldValue else { return }
            defaults.set(visualStyle.rawValue, forKey: ShiftAppearanceSelection.styleKey)
            publishAppearance()
        }
    }
    @Published private(set) var iconSelection: ShiftIconSelection
    private let defaults: UserDefaults

    func confirmIcon(_ selection: ShiftIconSelection) {
        guard iconSelection != selection else { return }
        iconSelection = selection
        defaults.set(selection.id, forKey: ShiftAppearanceSelection.iconKey)
        publishAppearance()
    }

    func publishAppearance() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let container = WidgetLibrary.containerURL,
              let data = try? encoder.encode(ShiftAppearanceSelection(style: visualStyle, icon: iconSelection)) else { return }
        let destination = container.appendingPathComponent("ShiftAppearance.json")
        guard (try? Data(contentsOf: destination)) != data else { return }
        do {
            try data.write(to: destination, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            WidgetCenter.shared.reloadAllTimelines()
        } catch { /* In-app choices still persist when shared widget storage is unavailable. */ }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        speedUnit = SpeedUnit(rawValue: defaults.string(forKey: "shift.speedUnit") ?? "") ?? .mph
        let branding = ShiftAppearanceSelection(defaults: defaults)
        visualStyle = branding.style
        iconSelection = branding.icon
        appearanceOverrides = defaults.data(forKey: AppearanceOverrides.defaultsKey)
            .flatMap { try? JSONDecoder().decode(AppearanceOverrides.self, from: $0) } ?? AppearanceOverrides()
        connectionCheckSeconds = SessionTiming.checkSeconds(defaults.object(forKey: "shift.connectionCheckSeconds") as? Int ?? SessionTiming.defaultCheckSeconds)
        panelShortcuts = PanelShortcut.normalized((defaults.stringArray(forKey: "locus.panelShortcuts") ?? []).compactMap(PanelShortcut.init(rawValue:)))
        defaults.register(defaults: [
            "locus.liveActivities": true, "locus.hideLocation": false,
            "locus.hideIslandLocation": false,
            "locus.connectionAlerts": true, "locus.reminderMinutes": 0,
            "locus.appearance": "theme", "locus.lockScreenProgress": true,
            "locus.islandProgress": true, "locus.islandTimer": true, "locus.glassPanel": true,
            "locus.showFindMyStatus": true, "locus.showLife360Status": true,
            "locus.showSavedPinsOnMap": true, "locus.showNamedAreasOnMap": true,
            "locus.appLockEnabled": false, "locus.hideInAppSwitcher": false,
            "locus.saveRecentLocations": true, "locus.recentHistoryRetention": RecentHistoryRetention.forever.rawValue
        ])
        liveActivities = defaults.bool(forKey: "locus.liveActivities")
        hideLocation = defaults.bool(forKey: "locus.hideLocation")
        hideIslandLocation = defaults.bool(forKey: "locus.hideIslandLocation")
        lockScreenProgress = defaults.bool(forKey: "locus.lockScreenProgress")
        islandProgress = defaults.bool(forKey: "locus.islandProgress")
        islandTimer = defaults.bool(forKey: "locus.islandTimer")
        showFindMyStatus = defaults.bool(forKey: "locus.showFindMyStatus")
        showLife360Status = defaults.bool(forKey: "locus.showLife360Status")
        showSavedPinsOnMap = defaults.bool(forKey: "locus.showSavedPinsOnMap")
        showNamedAreasOnMap = defaults.bool(forKey: "locus.showNamedAreasOnMap")
        connectionAlerts = defaults.bool(forKey: "locus.connectionAlerts")
        reminderMinutes = defaults.integer(forKey: "locus.reminderMinutes")
        // Legacy color preferences remain readable in backups; themes now own color mode.
        appearance = "theme"
        appLockEnabled = defaults.bool(forKey: "locus.appLockEnabled")
        hideInAppSwitcher = defaults.bool(forKey: "locus.hideInAppSwitcher")
        saveRecentLocations = defaults.bool(forKey: "locus.saveRecentLocations")
        recentHistoryRetention = RecentHistoryRetention(rawValue: defaults.string(forKey: "locus.recentHistoryRetention") ?? "") ?? .forever
    }

    var colorScheme: ColorScheme? {
        let resolved = visualStyle.defaultAppearance
        return resolved == "dark" ? .dark : resolved == "light" ? .light : nil
    }

    /// Rehydrate the live object after the reset policy removes preference keys.
    func reloadAfterReset() {
        let fresh = SessionPreferences(defaults: defaults)
        speedUnit = fresh.speedUnit
        liveActivities = fresh.liveActivities; hideLocation = fresh.hideLocation
        hideIslandLocation = fresh.hideIslandLocation; lockScreenProgress = fresh.lockScreenProgress
        islandProgress = fresh.islandProgress; islandTimer = fresh.islandTimer
        showFindMyStatus = fresh.showFindMyStatus; showLife360Status = fresh.showLife360Status
        showSavedPinsOnMap = fresh.showSavedPinsOnMap; showNamedAreasOnMap = fresh.showNamedAreasOnMap
        appearanceOverrides = fresh.appearanceOverrides; connectionAlerts = fresh.connectionAlerts
        connectionCheckSeconds = fresh.connectionCheckSeconds; reminderMinutes = fresh.reminderMinutes
        appearance = fresh.appearance; appLockEnabled = fresh.appLockEnabled
        hideInAppSwitcher = fresh.hideInAppSwitcher; saveRecentLocations = fresh.saveRecentLocations
        recentHistoryRetention = fresh.recentHistoryRetention; panelShortcuts = fresh.panelShortcuts
        visualStyle = fresh.visualStyle
        publishAppearance()
    }

    private func save(_ value: Any, _ key: String) {
        DeveloperLogStore.shared.record("preference_changed", ["preference": key, "value": String(describing: value)])
        defaults.set(value, forKey: "locus.\(key)")
    }
}
