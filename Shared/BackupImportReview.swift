import Foundation

/// A backup stays compatible with Locus/Shift v1/v2. Selection is a separate,
/// temporary plan; unselected preferences are copied from the current device.
enum BackupSettingValue: Equatable {
    case boolean(Bool), text(String), number(Double)
    func matches(_ other: Self) -> Bool {
        if case .number(let a) = self, case .number(let b) = other { return abs(a - b) < 0.000000001 }
        return self == other
    }
}

enum BackupSettingKey: String, CaseIterable, Identifiable {
    case visualStyle, material, appearance, glassPanel, speedUnit, smoothMovement, preferWalkingPaths, shortcuts, walkSpeed, runSpeed, cycleSpeed, eBikeSpeed, driveSpeed, liveActivities, hideLocation, hideIslandLocation, lockScreenProgress, islandProgress, islandTimer, showFindMyStatus, showLife360Status, connectionAlerts, reminderMinutes, connectionCheckSeconds, saveRecentLocations, recentHistoryRetention, mapStyle
    var id: String { rawValue }
    var title: String {
        switch self {
        case .visualStyle: return "Theme"
        case .material: return "Surfaces"
        case .appearance: return "Color mode"
        case .glassPanel: return "Liquid Glass (legacy setting)"
        case .speedUnit: return "Speed units"
        case .smoothMovement: return "Smooth movement"
        case .preferWalkingPaths: return "Prefer walking paths"
        case .shortcuts: return "Panel shortcuts"
        case .walkSpeed: return "Walk preset"
        case .runSpeed: return "Run preset"
        case .cycleSpeed: return "Cycle preset"
        case .eBikeSpeed: return "E-bike preset"
        case .driveSpeed: return "Drive preset"
        case .liveActivities: return "Live Activities"
        case .hideLocation: return "Lock Screen: hide location name"
        case .hideIslandLocation: return "Dynamic Island: hide location name"
        case .lockScreenProgress: return "Lock Screen: route progress"
        case .islandProgress: return "Dynamic Island: route progress"
        case .islandTimer: return "Dynamic Island: update timer"
        case .showFindMyStatus: return "Find My iPhone status"
        case .showLife360Status: return "Life360 status"
        case .connectionAlerts: return "Connection warnings"
        case .reminderMinutes: return "Session reminder"
        case .connectionCheckSeconds: return "Connection check interval"
        case .saveRecentLocations: return "Save recent locations"
        case .recentHistoryRetention: return "History retention"
        case .mapStyle: return "Map style"
        }
    }
    func value(in p: BackupPreferences) -> BackupSettingValue? {
        switch self {
        case .visualStyle: return p.visualStyle.map { .text($0.title) }
        case .material: return p.material.map { .text($0.rawValue.capitalized) }
        case .appearance: return .text(p.appearance)
        case .glassPanel: return p.material == nil ? .boolean(p.glassPanel) : nil
        case .speedUnit: return p.speedUnit.map { .text($0.title) }
        case .smoothMovement: return .boolean(p.smoothMovement)
        case .preferWalkingPaths: return .boolean(p.preferWalkingPaths)
        case .shortcuts: return .text(p.shortcuts.map(\.title).joined(separator: ", "))
        case .walkSpeed: return .number(UsualSpeedRules.value(for: .walk, stored: p.usualSpeeds))
        case .runSpeed: return .number(UsualSpeedRules.value(for: .run, stored: p.usualSpeeds))
        case .cycleSpeed: return .number(UsualSpeedRules.value(for: .cycle, stored: p.usualSpeeds))
        case .eBikeSpeed: return .number(UsualSpeedRules.value(for: .eBike, stored: p.usualSpeeds))
        case .driveSpeed: return .number(UsualSpeedRules.value(for: .drive, stored: p.usualSpeeds))
        case .liveActivities: return (p.display?.liveActivities).map { .boolean($0) }
        case .hideLocation: return (p.display?.hideLocation).map { .boolean($0) }
        case .hideIslandLocation: return (p.display?.hideIslandLocation).map { .boolean($0) }
        case .lockScreenProgress: return (p.display?.lockScreenProgress).map { .boolean($0) }
        case .islandProgress: return (p.display?.islandProgress).map { .boolean($0) }
        case .islandTimer: return (p.display?.islandTimer).map { .boolean($0) }
        case .showFindMyStatus: return (p.display?.showFindMyStatus).map { .boolean($0) }
        case .showLife360Status: return (p.display?.showLife360Status).map { .boolean($0) }
        case .connectionAlerts: return (p.display?.connectionAlerts).map { .boolean($0) }
        case .reminderMinutes: return p.display.map { .text($0.reminderMinutes == 0 ? "Off" : "\($0.reminderMinutes) minutes") }
        case .connectionCheckSeconds: return (p.display?.connectionCheckSeconds).map { .text("\($0) seconds") }
        case .saveRecentLocations: return (p.display?.saveRecentLocations).map { .boolean($0) }
        case .recentHistoryRetention: return p.display.map { .text($0.recentHistoryRetention.title) }
        case .mapStyle: return p.display.map { .text(["Standard", "Hybrid", "Satellite"].indices.contains($0.mapStyle) ? ["Standard", "Hybrid", "Satellite"][$0.mapStyle] : "Unknown") }
        }
    }
    func description(in p: BackupPreferences) -> String {
        switch value(in: p) {
        case .boolean(let flag): return flag ? "On" : "Off"
        case .text(let text): return self == .appearance ? text.capitalized : text
        case .number(let speed):
            let unit = p.speedUnit ?? .mph
            return unit.formatted(mph: speed)
        case nil: return "Not included"
        }
    }
    func applying(from incoming: BackupPreferences, to current: inout BackupPreferences) throws {
        guard value(in: incoming) != nil else { return }
        switch self {
        case .visualStyle: current.visualStyle = incoming.visualStyle
        case .material: current.material = incoming.material
        case .appearance: current.appearance = incoming.appearance
        case .glassPanel:
            current.glassPanel = incoming.glassPanel
            if current.material != nil { current.material = incoming.glassPanel ? .glass : .solid }
        case .speedUnit: current.speedUnit = incoming.speedUnit
        case .smoothMovement: current.smoothMovement = incoming.smoothMovement
        case .preferWalkingPaths: current.preferWalkingPaths = incoming.preferWalkingPaths
        case .shortcuts: current.shortcuts = incoming.shortcuts
        case .walkSpeed: current.usualSpeeds["walk"] = UsualSpeedRules.value(for: .walk, stored: incoming.usualSpeeds)
        case .runSpeed: current.usualSpeeds["run"] = UsualSpeedRules.value(for: .run, stored: incoming.usualSpeeds)
        case .cycleSpeed: current.usualSpeeds["cycle"] = UsualSpeedRules.value(for: .cycle, stored: incoming.usualSpeeds)
        case .eBikeSpeed: current.usualSpeeds["eBike"] = UsualSpeedRules.value(for: .eBike, stored: incoming.usualSpeeds)
        case .driveSpeed: current.usualSpeeds["drive"] = UsualSpeedRules.value(for: .drive, stored: incoming.usualSpeeds)
        default:
            guard let source = incoming.display, var target = current.display else { throw BackupError.invalid }
            switch self {
            case .liveActivities: target.liveActivities = source.liveActivities
            case .hideLocation: target.hideLocation = source.hideLocation
            case .hideIslandLocation: target.hideIslandLocation = source.hideIslandLocation
            case .lockScreenProgress: target.lockScreenProgress = source.lockScreenProgress
            case .islandProgress: target.islandProgress = source.islandProgress
            case .islandTimer: target.islandTimer = source.islandTimer
            case .showFindMyStatus: target.showFindMyStatus = source.showFindMyStatus
            case .showLife360Status: target.showLife360Status = source.showLife360Status
            case .connectionAlerts: target.connectionAlerts = source.connectionAlerts
            case .reminderMinutes: target.reminderMinutes = source.reminderMinutes
            case .connectionCheckSeconds: target.connectionCheckSeconds = source.connectionCheckSeconds
            case .saveRecentLocations: target.saveRecentLocations = source.saveRecentLocations
            case .recentHistoryRetention: target.recentHistoryRetention = source.recentHistoryRetention
            case .mapStyle: target.mapStyle = source.mapStyle
            default: break
            }
            current.display = target
        }
    }
}

struct BackupSettingChange: Identifiable {
    let key: BackupSettingKey
    let before: String
    let after: String
    let changesValue: Bool
    var id: BackupSettingKey { key }
}

struct BackupImportContext: Equatable {
    var preferences: BackupPreferences
    var places: [BackupPlace]
    var trips: [SavedTrip]
    var areas: [NamedArea]
}

struct BackupImportSelection {
    var places: Set<String> = []
    var trips: Set<UUID> = []
    var areas: Set<UUID> = []
    var settings: Set<BackupSettingKey> = []
}

struct BackupImportPlan {
    var places: [BackupPlace]
    var trips: [SavedTrip]
    var areas: [NamedArea]
    var preferences: BackupPreferences?
    var settingKeys: Set<BackupSettingKey>
    var count: Int { places.count + trips.count + areas.count + settingKeys.count }
    func needsStoppedSession(hasSession: Bool, isBusy: Bool) -> Bool {
        !settingKeys.isEmpty && (hasSession || isBusy)
    }
    var summary: String {
        var parts: [String] = []
        if !trips.isEmpty { parts.append("Add \(trips.count) route(s)") }
        if !places.isEmpty { parts.append("Add \(places.count) saved place(s)") }
        if !areas.isEmpty { parts.append("Add \(areas.count) named area(s)") }
        if !settingKeys.isEmpty { parts.append("Change \(settingKeys.count) setting(s)") }
        return parts.isEmpty ? "No changes selected" : parts.joined(separator: " · ")
    }
}

struct BackupImportReview {
    let backup: LibraryBackup
    let current: BackupImportContext
    let existingPlaces: Set<String>
    let existingTrips: Set<UUID>
    let existingAreas: Set<UUID>
    init(backup: LibraryBackup, current: BackupImportContext) {
        self.backup = backup; self.current = current
        existingPlaces = Set(current.places.map(\.id))
        existingTrips = Set(current.trips.map(\.id))
        existingAreas = Set(current.areas.map(\.id))
    }
    var title: String {
        let hasLibrary = !backup.places.isEmpty || !backup.trips.isEmpty || !(backup.areas ?? []).isEmpty
        if backup.preferences != nil { return hasLibrary ? "Settings & Library Import Overview" : "Settings Import Overview" }
        return "Library Import Overview"
    }
    var overview: String {
        let newItems = defaultSelection
        return "Compared with your current data: \(newItems.trips.count) new routes · \(newItems.places.count) new saved places · \(newItems.areas.count) new areas · \(changedSettings.count) different settings. Counts include all available changes, before your selections."
    }
    var changes: [BackupSettingChange] {
        guard let source = backup.preferences else { return [] }
        let rows: [BackupSettingChange] = BackupSettingKey.allCases.compactMap { key in
            guard let value = key.value(in: source) else { return nil }
            return BackupSettingChange(key: key, before: key.description(in: current.preferences),
                after: key.description(in: source), changesValue: !(key.value(in: current.preferences).map(value.matches) ?? false))
        }
        return rows.filter(\.changesValue) + rows.filter { !$0.changesValue }
    }
    var changedSettings: Set<BackupSettingKey> { Set(changes.filter(\.changesValue).map(\.key)) }
    var defaultSelection: BackupImportSelection {
        BackupImportSelection(places: Set(backup.places.map(\.id)).subtracting(existingPlaces),
            trips: Set(backup.trips.map(\.id)).subtracting(existingTrips),
            areas: Set((backup.areas ?? []).map(\.id)).subtracting(existingAreas))
    }
    func plan(_ selected: BackupImportSelection) throws -> BackupImportPlan {
        // The immutable document was validated by BackupImportReader. Do not rebuild
        // route geometry on every checkbox change; validate persisted merges at commit.
        let places = backup.places.filter { selected.places.contains($0.id) && !existingPlaces.contains($0.id) }
        let trips = backup.trips.filter { selected.trips.contains($0.id) && !existingTrips.contains($0.id) }
        let areas = (backup.areas ?? []).filter { selected.areas.contains($0.id) && !existingAreas.contains($0.id) }
        let keys = selected.settings.intersection(changedSettings)
        var preferences: BackupPreferences?
        if !keys.isEmpty, let source = backup.preferences {
            var merged = current.preferences
            for key in keys { try key.applying(from: source, to: &merged) }
            guard merged.isValid else { throw BackupError.invalid }
            preferences = merged
        }
        // Validate capacity for the selected subset, never the entire unselected file.
        guard current.places.count + places.count <= 1000,
              current.trips.count + trips.count <= 50,
              current.areas.count + areas.count <= 100,
              current.trips.reduce(0, { $0 + $1.points.count }) + trips.reduce(0, { $0 + $1.points.count }) <= 500_000
        else { throw BackupError.capacity }
        return BackupImportPlan(places: places, trips: trips, areas: areas,
                                preferences: preferences, settingKeys: keys)
    }
}
