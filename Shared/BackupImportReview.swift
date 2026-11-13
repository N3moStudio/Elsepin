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

enum BackupSettingGroup: String, CaseIterable, Identifiable {
    case appearanceAndMap = "Appearance & map"
    case movement = "Movement"
    case liveActivities = "Live Activities"
    case connection = "Connection & reminders"
    case history = "Recent history"
    var id: String { rawValue }
}

enum BackupSettingKey: String, CaseIterable, Identifiable {
    case mapPinSize, mapPinVisibilityMiles
    case visualStyle, material, glassPanel, speedUnit, smoothMovement, preferWalkingPaths, shortcuts, walkSpeed, runSpeed, cycleSpeed, eBikeSpeed, driveSpeed, liveActivities, hideLocation, hideIslandLocation, lockScreenProgress, islandProgress, islandTimer, showFindMyStatus, showLife360Status, connectionAlerts, reminderMinutes, connectionCheckSeconds, saveRecentLocations, recentHistoryRetention, mapStyle, showSavedPinsOnMap, showNamedAreasOnMap
    var id: String { rawValue }
    var group: BackupSettingGroup {
        switch self {
        case .visualStyle, .material, .glassPanel, .mapStyle, .showSavedPinsOnMap, .showNamedAreasOnMap, .mapPinSize, .mapPinVisibilityMiles:
            return .appearanceAndMap
        case .speedUnit, .smoothMovement, .preferWalkingPaths, .shortcuts, .walkSpeed, .runSpeed, .cycleSpeed, .eBikeSpeed, .driveSpeed:
            return .movement
        case .liveActivities, .hideLocation, .hideIslandLocation, .lockScreenProgress, .islandProgress, .islandTimer, .showFindMyStatus, .showLife360Status:
            return .liveActivities
        case .connectionAlerts, .reminderMinutes, .connectionCheckSeconds:
            return .connection
        case .saveRecentLocations, .recentHistoryRetention:
            return .history
        }
    }
    var title: String {
        switch self {
        case .visualStyle: return "Theme"
        case .material: return "Surfaces"
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
        case .showSavedPinsOnMap: return "Pins on map"
        case .showNamedAreasOnMap: return "Areas on map"
        case .mapPinSize: return "Map pin size"
        case .mapPinVisibilityMiles: return "Pin visibility range"
        }
    }
    func value(in p: BackupPreferences) -> BackupSettingValue? {
        switch self {
        case .visualStyle: return p.visualStyle.map { .text($0.title) }
        case .material: return p.material.map { .text($0.rawValue.capitalized) }
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
        case .mapStyle: return p.display.map { .text(["Standard", "Satellite + labels", "Satellite"].indices.contains($0.mapStyle) ? ["Standard", "Satellite + labels", "Satellite"][$0.mapStyle] : "Unknown") }
        case .showSavedPinsOnMap: return (p.display?.showSavedPinsOnMap).map { .boolean($0) }
        case .showNamedAreasOnMap: return (p.display?.showNamedAreasOnMap).map { .boolean($0) }
        case .mapPinSize: return p.display?.mapPinSize.map { .text("\(Int($0)) points") }
        case .mapPinVisibilityMiles: return p.display?.mapPinVisibilityMiles.map { .number($0) }
        }
    }
    private func effectiveValue(in p: BackupPreferences) -> BackupSettingValue? {
        // Old backups use glassPanel; current preferences use material. Compare
        // the legacy option with the actual surface choice, not a missing field.
        if self == .glassPanel, let material = p.material { return .boolean(material == .glass) }
        return value(in: p)
    }
    func matchesCurrentValue(_ incoming: BackupSettingValue, in p: BackupPreferences) -> Bool {
        effectiveValue(in: p).map(incoming.matches) ?? false
    }
    func description(in p: BackupPreferences) -> String {
        switch effectiveValue(in: p) {
        case .boolean(let flag): return flag ? "On" : "Off"
        case .text(let text): return text
        case .number(let speed):
            if self == .mapPinVisibilityMiles { return SavedPinVisibility.label(miles: speed) }
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
            case .showSavedPinsOnMap: target.showSavedPinsOnMap = source.showSavedPinsOnMap
            case .showNamedAreasOnMap: target.showNamedAreasOnMap = source.showNamedAreasOnMap
            case .mapPinSize: target.mapPinSize = source.mapPinSize
            case .mapPinVisibilityMiles: target.mapPinVisibilityMiles = source.mapPinVisibilityMiles
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
        if !places.isEmpty { parts.append("\(places.count) \(places.count == 1 ? "pin" : "pins")") }
        if !trips.isEmpty { parts.append("\(trips.count) \(trips.count == 1 ? "route" : "routes")") }
        if !areas.isEmpty { parts.append("\(areas.count) \(areas.count == 1 ? "area" : "areas")") }
        if !settingKeys.isEmpty { parts.append("\(settingKeys.count) \(settingKeys.count == 1 ? "setting" : "settings")") }
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
    var changes: [BackupSettingChange] {
        guard let source = backup.preferences else { return [] }
        let rows: [BackupSettingChange] = BackupSettingKey.allCases.compactMap { key in
            guard let value = key.value(in: source) else { return nil }
            return BackupSettingChange(key: key, before: key.description(in: current.preferences),
                after: key.description(in: source), changesValue: !key.matchesCurrentValue(value, in: current.preferences))
        }
        return rows.filter(\.changesValue) + rows.filter { !$0.changesValue }
    }
    var changedSettings: Set<BackupSettingKey> { Set(changes.filter(\.changesValue).map(\.key)) }
    /// The selected overview describes the applied values, including units kept on
    /// this device. Neither this comparison nor `changes` compares app defaults.
    func settingChanges(in plan: BackupImportPlan) -> [BackupSettingChange] {
        guard let applied = plan.preferences else { return [] }
        return BackupSettingKey.allCases.filter { plan.settingKeys.contains($0) }.map { key in
            BackupSettingChange(key: key, before: key.description(in: current.preferences),
                after: key.description(in: applied), changesValue: true)
        }
    }
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
