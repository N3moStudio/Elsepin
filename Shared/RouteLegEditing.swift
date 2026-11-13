import Foundation

enum RouteLegPathChoice: Equatable { case keepCurrent, recalculate }

enum RouteLegPathPolicy {
    static func needsChoice(from old: TravelMode, to new: TravelMode, exactPath: Bool) -> Bool {
        !exactPath && old.routeNetwork != new.routeNetwork
    }
    static func keepsGeometry(from old: TravelMode, to new: TravelMode, exactPath: Bool, choice: RouteLegPathChoice) -> Bool {
        exactPath || old.routeNetwork == new.routeNetwork || choice == .keepCurrent
    }
}

/// Leg boundaries belong to the destination stop. Editing one leg must not
/// reset speeds outside that interval, including older mixed-mode backups.
enum RouteLegEditing {
    /// Choices describe the segment *arriving at* a stop, not the stop itself.
    /// Reverse the segment order, then re-key it to the reversed destinations.
    /// Missing choices remain implicit defaults; waits and place IDs stay put.
    static func reversed(waypoints: [TripWaypoint], choices: [UUID: RouteLegChoice])
        -> (waypoints: [TripWaypoint], choices: [UUID: RouteLegChoice]) {
        let reversedWaypoints = Array(waypoints.reversed())
        let originalDestinations = waypoints.map(\.id) + [RouteLegChoice.destinationID]
        let reversedDestinations = reversedWaypoints.map(\.id) + [RouteLegChoice.destinationID]
        var reversedChoices: [UUID: RouteLegChoice] = [:]
        for (destination, original) in zip(reversedDestinations, originalDestinations.reversed()) {
            if let choice = choices[original] { reversedChoices[destination] = choice }
        }
        return (reversedWaypoints, reversedChoices)
    }

    static func range(to id: UUID, stops: [RouteStop], length: Double) -> ClosedRange<Double>? {
        guard length.isFinite, length > 0,
              stops.allSatisfy({ $0.metres.isFinite && (0...length).contains($0.metres) }),
              Set(stops.map(\.id)).count == stops.count else { return nil }
        var start = 0.0
        for stop in stops.sorted(by: { $0.metres < $1.metres }) {
            if stop.id == id { return start...stop.metres }
            start = stop.metres
        }
        return id == RouteLegChoice.destinationID ? start...length : nil
    }

    static func replacing(_ sections: [RouteTravelSection], in range: ClosedRange<Double>,
                          length: Double, id: UUID, choice: RouteLegChoice,
                          fallback: RouteLegChoice) -> [RouteTravelSection]? {
        guard choice.isValid, fallback.isValid, length.isFinite, length > 0,
              range.lowerBound.isFinite, range.upperBound.isFinite,
              range.lowerBound >= 0, range.upperBound <= length else { return nil }
        let original = sections.isEmpty
            ? [RouteTravelSection(id: UUID(), startMetres: 0, endMetres: length,
                                  mode: fallback.mode, speedMPH: fallback.speedMPH)] : sections
        guard RouteTravelSection.valid(original, length: length) else { return nil }
        guard range.upperBound > range.lowerBound else { return original }
        var result: [RouteTravelSection] = []
        for section in original {
            if section.endMetres <= range.lowerBound || section.startMetres >= range.upperBound {
                result.append(section)
                continue
            }
            if section.startMetres < range.lowerBound {
                var before = section
                before.endMetres = range.lowerBound
                result.append(before)
            }
            if section.endMetres > range.upperBound {
                var after = section
                after.startMetres = range.upperBound
                after.id = UUID()
                result.append(after)
            }
        }
        // Preserve the edited leg's identity; split fragments get fresh IDs.
        for index in result.indices where result[index].id == id { result[index].id = UUID() }
        result.append(RouteTravelSection(id: id, startMetres: range.lowerBound, endMetres: range.upperBound,
                                        mode: choice.mode, speedMPH: choice.speedMPH))
        result.sort { $0.startMetres < $1.startMetres }
        return RouteTravelSection.valid(result, length: length) ? result : nil
    }
}

enum MapPinPlacement {
    enum SavedPinAction: Equatable { case ignore, revealName, prepareLocation }

    /// Reading a saved pin's label is independent of permission to move the
    /// destination. A route/preview must survive inspecting another pin.
    static func savedPinAction(hasJourney: Bool, hasPreparedRoute: Bool, drawing: Bool, adjusting: Bool) -> SavedPinAction {
        if drawing || adjusting { return .ignore }
        return hasJourney || hasPreparedRoute ? .revealName : .prepareLocation
    }

    /// A staged route is dismissed only with its explicit X, never a map tap.
    static func allowed(hasJourney: Bool, hasPreparedRoute: Bool, drawing: Bool, adjusting: Bool) -> Bool {
        !hasJourney && !hasPreparedRoute && !drawing && !adjusting
    }
}
