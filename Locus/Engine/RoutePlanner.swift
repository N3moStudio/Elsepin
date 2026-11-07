import Combine
import MapKit

struct PreparedRoute: Identifiable {
    let route: PlannedRoute
    let mode: TravelMode
    let speedMPH: Double
    let smoothMovement: Bool
    var arrival: ArrivalChoice = .stay
    var editingTripID: UUID? = nil
    var continuationNote: String? = nil
    var historyID: UUID? = nil
    let waypoints: [TripWaypoint]
    let usesStoredPath: Bool
    let sectionChoices: [UUID: RouteLegChoice]
    var id: UUID { route.id }
}

@MainActor
final class RoutePlanner: ObservableObject {
    @Published private(set) var preparedRoute: PreparedRoute?
    @Published var editingTripID: UUID?
    private var draftContinuationNote: String?
    @Published var draftArrival: ArrivalChoice = .stay
    @Published private(set) var continuationLoading = false
    @Published var draftMode: TravelMode = .walk
    @Published var draftSpeedMPH = 3.0
    @Published var draftSmoothMovement = false
    private var draftSettingsInitialized = false
    private var draftHistoryID = UUID()
    private var draftName: String?
    @Published private(set) var origin: RoutePlace?
    @Published private(set) var destination: RoutePlace?
    @Published private(set) var alternatives: [PlannedRoute] = []
    @Published private(set) var selectedID: UUID?
    @Published private(set) var isLoading = false
    @Published var error: String?
    @Published var cyclingUnavailable = false
    @Published var isPresented = false
    @Published var isDrawing = false
    @Published private(set) var waypoints: [TripWaypoint] = []
    @Published private(set) var usesStoredPath = false
    @Published private(set) var sectionChoices: [UUID: RouteLegChoice] = [:]
    @Published var preferWalkingPaths = UserDefaults.standard.bool(forKey: "locus.preferWalkingPaths") {
        didSet { UserDefaults.standard.set(preferWalkingPaths, forKey: "locus.preferWalkingPaths") }
    }
    private var generation = UUID()
    private var task: Task<Void, Never>?

    var selectedRoute: PlannedRoute? { alternatives.first { $0.id == selectedID } }

    func initializeDraftIfNeeded(mode: TravelMode, speedMPH: Double, smoothMovement: Bool) {
        guard !draftSettingsInitialized else { return }
        draftMode = mode
        draftSpeedMPH = mode.clampedSpeedMPH(speedMPH)
        draftSmoothMovement = smoothMovement
        draftSettingsInitialized = true
    }
    @discardableResult
    func prepareSelectedRoute(mode: TravelMode, speedMPH: Double, smoothMovement: Bool) -> Bool {
        guard !isLoading, let route = selectedRoute, route.supports(mode) else { return false }
        preparedRoute = PreparedRoute(route: route, mode: mode, speedMPH: mode.clampedSpeedMPH(speedMPH), smoothMovement: smoothMovement,
            arrival: draftArrival, editingTripID: editingTripID, continuationNote: draftContinuationNote, historyID: draftHistoryID,
            waypoints: waypoints, usesStoredPath: usesStoredPath, sectionChoices: sectionChoices)
        return true
    }
    func discardPreparedRoute() { preparedRoute = nil }
    func rememberSavedTrip(_ id: UUID, routeID: UUID) {
        guard preparedRoute?.id == routeID else { return }
        preparedRoute?.editingTripID = id
        editingTripID = id
    }
    func previewContinuation(choice: ArrivalChoice, session: SpoofSession) {
        guard choice != .stay, !continuationLoading, session.journey?.state == .arrived,
              let original = session.activeRoute, let coordinate = session.simulated else { return }
        cancel()
        continuationLoading = true
        error = nil
        let token = generation
        let mode = session.travelMode
        let speed = session.speedMPH(for: mode)
        let smooth = session.smoothMovement
        let preferWalking = preferWalkingPaths
        task = Task { [weak self, weak session] in
            do {
                let route = try await RouteContinuation.make(original: original, from: coordinate,
                    choice: choice, mode: mode, speed: speed, preferWalking: preferWalking)
                guard let self, let session, !Task.isCancelled, generation == token,
                      session.activeRoute?.id == original.id, session.journey?.state == .arrived else {
                    if let self, self.generation == token { self.continuationLoading = false; self.task = nil }
                    return
                }
                session.stopRoute()
                guard session.journey == nil else { self.continuationLoading = false; self.task = nil; return }
                preparedRoute = PreparedRoute(route: route, mode: mode, speedMPH: speed, smoothMovement: smooth,
                    continuationNote: choice == .repeatTrip ? "Includes the path back to the start, then one repeat. Review the map before starting." : "New directions back to the start. Review the map before starting.",
                    waypoints: [], usesStoredPath: true, sectionChoices: [:])
                continuationLoading = false
                task = nil
                isPresented = false
            } catch {
                guard let self, !Task.isCancelled, self.generation == token else { return }
                self.continuationLoading = false
                self.task = nil
                self.error = error.localizedDescription
            }
        }
    }
    func editPreparedRoute() {
        guard let preparedRoute else { return }
        cancel()
        let route = preparedRoute.route
        origin = route.origin
        destination = route.destination
        alternatives = [route]
        selectedID = route.id
        waypoints = preparedRoute.waypoints
        sectionChoices = preparedRoute.sectionChoices
        usesStoredPath = preparedRoute.usesStoredPath
        editingTripID = preparedRoute.editingTripID
        draftHistoryID = preparedRoute.historyID ?? route.id
        draftName = route.name
        draftContinuationNote = preparedRoute.continuationNote
        draftArrival = preparedRoute.arrival
        draftMode = preparedRoute.mode
        draftSpeedMPH = preparedRoute.speedMPH
        draftSmoothMovement = preparedRoute.smoothMovement
        draftSettingsInitialized = true
        error = nil
        isPresented = true
    }

    func plan(to place: RoutePlace, defaultOrigin: RoutePlace?, mode: TravelMode) {
        destination = place
        origin = defaultOrigin ?? origin
        isPresented = true
        rebuild(mode: mode)
    }
    func setOrigin(_ place: RoutePlace, mode: TravelMode) {
        origin = place
        rebuild(mode: mode)
    }
    func setDestination(_ place: RoutePlace, defaultOrigin: RoutePlace?, mode: TravelMode) {
        destination = place
        if origin == nil { origin = defaultOrigin }
        rebuild(mode: mode)
    }
    func swap(mode: TravelMode) {
        syncPathStops()
        usesStoredPath = false
        waypoints.reverse()
        let previous = origin
        origin = destination
        destination = previous
        rebuild(mode: mode)
    }
    func modeChanged(_ mode: TravelMode) {
        guard isPresented else { return }
        if usesStoredPath {
            if hasSectionSettings { return }
            for index in alternatives.indices { alternatives[index].storedMode = mode }
            return
        }
        if selectedRoute?.source.isAutomatic == false { return }
        rebuild(mode: mode)
    }
    func choose(_ route: PlannedRoute) {
        selectedID = route.id
    }

    /// Dismissing an unaccepted draft clears only that draft. A route explicitly
    /// staged with Show route stays on the map until Start or Discard.
    func discardDraft() {
        cancel()
        origin = nil
        destination = nil
        alternatives = []
        selectedID = nil
        error = nil
        waypoints = []
        sectionChoices = [:]
        usesStoredPath = false
        draftSettingsInitialized = false
        draftArrival = .stay
        editingTripID = nil
        draftContinuationNote = nil
        draftHistoryID = UUID()
        draftName = nil
    }
    func cancel() {
        generation = UUID()
        task?.cancel()
        task = nil
        isLoading = false
        continuationLoading = false
    }
    func rebuild(mode: TravelMode) {
        cancel()
        syncPathStops()
        usesStoredPath = false
        error = nil
        cyclingUnavailable = false
        alternatives = []
        selectedID = nil
        guard let origin, let destination else { return }
        let token = generation
        let stops = waypoints
        let preferWalking = preferWalkingPaths
        let choices = sectionChoices
        let defaultSpeed = mode.clampedSpeedMPH(draftSpeedMPH)
        isLoading = true
        let started = ProcessInfo.processInfo.systemUptime
        DeveloperLogStore.shared.record("route_plan_started", ["attempt": token.uuidString,
            "mode": mode.rawValue, "stops": String(stops.count), "walking_selected": String(preferWalking),
            "origin_latitude": String(origin.coordinate.latitude), "origin_longitude": String(origin.coordinate.longitude),
            "destination_latitude": String(destination.coordinate.latitude), "destination_longitude": String(destination.coordinate.longitude)])
        task = Task { [weak self] in
            do {
                let routes = try await RouteBuilder.itinerary(from: origin, to: destination, via: stops,
                                                              mode: mode, preferWalkingPaths: preferWalking, legChoices: choices, defaultSpeedMPH: defaultSpeed)
                DeveloperLogStore.shared.record("route_plan_finished", ["attempt": token.uuidString,
                    "routes": String(routes.count), "duration_ms": String(Int((ProcessInfo.processInfo.systemUptime - started) * 1000))])
                guard let self, !Task.isCancelled, self.generation == token else { return }
                self.alternatives = routes.map { route in
                    var named = route
                    if let name = self.draftName { named.name = name }
                    return named
                }
                self.selectedID = routes.first?.id
                self.isLoading = false
                self.task = nil
            } catch {
                DeveloperLogStore.shared.record("route_plan_failed", ["attempt": token.uuidString,
                    "domain": (error as NSError).domain, "code": String((error as NSError).code),
                    "cancelled": String(Task.isCancelled), "duration_ms": String(Int((ProcessInfo.processInfo.systemUptime - started) * 1000))])
                guard let self, !Task.isCancelled, self.generation == token else { return }
                self.error = error.localizedDescription
                self.cyclingUnavailable = error is RouteBuilder.CyclingUnavailable
                self.isLoading = false
                self.task = nil
            }
        }
    }
    func useCustom(_ coordinates: [CLLocationCoordinate2D], source: RoutePathSource) {
        guard let route = RouteBuilder.customRoute(coordinates, source: source) else {
            error = "Choose at least two different, valid points for the path."
            return
        }
        cancel()
        waypoints = []
        editingTripID = nil
        draftHistoryID = route.id
        draftName = nil
        sectionChoices = [:]
        usesStoredPath = true
        origin = route.origin
        destination = route.destination
        alternatives = [route]
        selectedID = route.id
        error = nil
        isPresented = true
    }

    func useSaved(_ trip: SavedTrip) {
        guard let route = trip.plannedRoute else { error = "The saved trip is invalid."; return }
        cancel()
        editingTripID = trip.id
        draftHistoryID = trip.id
        draftName = trip.name
        draftArrival = trip.arrival ?? .stay
        draftMode = trip.mode
        draftSpeedMPH = trip.speedMPH
        draftSmoothMovement = trip.smoothMovement
        draftSettingsInitialized = true
        origin = route.origin
        destination = route.destination
        alternatives = [route]
        selectedID = route.id
        waypoints = route.stops.map { TripWaypoint(id: $0.id, name: $0.name, point: route.track.point(at: $0.metres), waitSeconds: $0.waitSeconds) }
        usesStoredPath = true
        sectionChoices = Dictionary(uniqueKeysWithValues: route.travelSections.map { ($0.id, RouteLegChoice(mode: $0.mode, speedMPH: $0.speedMPH)) })
        error = nil
        isPresented = true
    }

    func useRecent(_ trip: SavedTrip) {
        useSaved(trip)
        // A history entry is not a saved Library item until the user saves it.
        editingTripID = nil
    }

    func rememberDraft(in session: SpoofSession) {
        guard !isLoading, let route = selectedRoute, route.supports(draftMode) else { return }
        var trip = route.savedTrip(name: route.name, mode: draftMode, speed: draftSpeedMPH,
                                  smooth: draftSmoothMovement, arrival: draftArrival)
        trip.id = editingTripID ?? draftHistoryID
        session.rememberPlannedRoute(trip)
    }

    func addWaypoint(_ place: RoutePlace, mode: TravelMode, speedMPH: Double? = nil, insertAlongRoute: Bool = false) {
        syncPathStops()
        guard waypoints.count < 8, CLLocationCoordinate2DIsValid(place.coordinate) else { return }
        DeveloperLogStore.shared.record("route_stop_inserting", ["count_before": String(waypoints.count),
            "mode": mode.rawValue, "along_route": String(insertAlongRoute)])
        usesStoredPath = false
        let waypoint = TripWaypoint(name: place.name, point: RoutePoint(place.coordinate))
        if hasSectionSettings { sectionChoices[waypoint.id] = RouteLegChoice(mode: mode, speedMPH: mode.clampedSpeedMPH(speedMPH ?? mode.defaultSpeedMPH)) }
        var insertion = waypoints.count
        if insertAlongRoute, let route = selectedRoute {
            let positions = waypoints.compactMap { stop in route.stops.first { $0.id == stop.id }?.metres }
            if positions.count == waypoints.count {
                insertion = RouteSearchCorridor(track: route.track).insertionIndex(for: waypoint.point, stopMetres: positions)
            }
        }
        waypoints.insert(waypoint, at: insertion)
        rebuild(mode: mode)
    }
    func removeWaypoint(_ id: UUID, mode: TravelMode) {
        waypoints.removeAll { $0.id == id }
        sectionChoices.removeValue(forKey: id)
        rebuild(mode: mode)
    }
    func moveWaypoint(_ id: UUID, offset: Int, mode: TravelMode) {
        guard let index = waypoints.firstIndex(where: { $0.id == id }), waypoints.indices.contains(index + offset) else { return }
        waypoints.swapAt(index, index + offset)
        rebuild(mode: mode)
    }
    func setWait(_ id: UUID, seconds: Double) {
        guard seconds.isFinite else { return }
        let value = StopDuration.normalized(seconds)
        if let index = waypoints.firstIndex(where: { $0.id == id }) { waypoints[index].waitSeconds = value }
        for index in alternatives.indices {
            if let stop = alternatives[index].stops.firstIndex(where: { $0.id == id }) { alternatives[index].stops[stop].waitSeconds = value }
        }
    }
    func setAllWaits(seconds: Double) {
        guard !isLoading, seconds.isFinite else { return }
        let value = StopDuration.normalized(seconds)
        waypoints = waypoints.map { var stop = $0; stop.waitSeconds = value; return stop }
        alternatives = alternatives.map { route in
            var updated = route
            updated.stops = route.stops.map { var stop = $0; stop.waitSeconds = value; return stop }
            return updated
        }
    }
    func addPathStop(name: String, fraction: Double, wait: Double) {
        guard let route = selectedRoute, route.stops.count < 20, fraction.isFinite, wait.isFinite else { return }
        let title = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(120))
        let stop = RouteStop(name: title.isEmpty ? "Stop \(route.stops.count + 1)" : title,
            metres: min(1, max(0, fraction)) * route.track.length, waitSeconds: StopDuration.normalized(wait))
        guard let index = alternatives.firstIndex(where: { $0.id == route.id }) else { return }
        alternatives[index].stops.append(stop)
        alternatives[index].stops.sort { $0.metres < $1.metres }
        usesStoredPath = true
    }
    func removePathStop(_ id: UUID) {
        guard let index = alternatives.firstIndex(where: { $0.id == selectedID }) else { return }
        alternatives[index].stops.removeAll { $0.id == id }
        waypoints.removeAll { $0.id == id }
    }

    var hasSectionSettings: Bool { !sectionChoices.isEmpty }

    func renameRoute(_ value: String) {
        let name = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let clipped = String(name.prefix(120))
        draftName = clipped
        for index in alternatives.indices { alternatives[index].name = clipped }
    }

    func replaceWaypoint(_ id: UUID, with place: RoutePlace, mode: TravelMode) {
        syncPathStops()
        guard let index = waypoints.firstIndex(where: { $0.id == id }) else { return }
        waypoints[index].name = place.name
        waypoints[index].point = RoutePoint(place.coordinate)
        usesStoredPath = false
        rebuild(mode: mode)
    }

    func setSectionChoice(_ choice: RouteLegChoice, for id: UUID, defaultMode: TravelMode,
                          pathChoice: RouteLegPathChoice = .recalculate) {
        guard !isLoading, choice.isValid else { return }
        syncPathStops()
        let targets = waypoints.map(\.id) + [RouteLegChoice.destinationID]
        guard targets.contains(id) else { return }
        let fallback = RouteLegChoice(mode: defaultMode, speedMPH: defaultMode.clampedSpeedMPH(draftSpeedMPH))
        var choices = sectionChoices
        for target in targets where choices[target] == nil {
            if let route = selectedRoute,
               let range = RouteLegEditing.range(to: target, stops: route.stops, length: route.track.length),
               let section = RouteTravelSection.current(in: route.travelSections, at: range.lowerBound) {
                choices[target] = RouteLegChoice(mode: section.mode, speedMPH: section.speedMPH)
            } else { choices[target] = fallback }
        }
        let previous = choices[id] ?? fallback
        choices[id] = choice
        let keepsExactPath = selectedRoute?.source.isAutomatic == false
        // Speed changes (and Walk/Run or Cycle/E-bike switches) don't require
        // MapKit. Preserve the path, other legs and old mixed-section backups.
        if let route = selectedRoute,
           RouteLegPathPolicy.keepsGeometry(from: previous.mode, to: choice.mode, exactPath: keepsExactPath, choice: pathChoice) {
            var updated = alternatives
            for index in updated.indices {
                guard let range = RouteLegEditing.range(to: id, stops: updated[index].stops, length: updated[index].track.length),
                      let sections = RouteLegEditing.replacing(updated[index].travelSections, in: range,
                        length: updated[index].track.length, id: id, choice: choice, fallback: fallback) else {
                    error = "This change exceeds the movement-section limit. Your existing legs are unchanged."
                    return
                }
                updated[index].travelSections = sections
            }
            alternatives = updated
            sectionChoices = choices
            error = nil
            DeveloperLogStore.shared.record("route_leg_updated", ["leg": id.uuidString, "mode": choice.mode.rawValue,
                "speed_mph": String(choice.speedMPH), "directions_requested": "false", "route": route.id.uuidString])
        } else {
            sectionChoices = choices
            rebuild(mode: defaultMode)
        }
    }
    func applyMapEdit(origin start: RoutePoint, destination end: RoutePoint, stops: [TripWaypoint], mode: TravelMode, speedMPH: Double? = nil) {
        guard start.isValid, end.isValid, stops.count <= 20, stops.allSatisfy({ $0.point.isValid }),
              Set(stops.map(\.id)).count == stops.count else { return }
        cancel()
        let oldStart = origin, oldEnd = destination
        origin = RoutePlace(name: oldStart.map { RoutePoint($0.coordinate) == start ? $0.name : "Edited start" } ?? "Start", coordinate: start.coordinate)
        destination = RoutePlace(name: oldEnd.map { RoutePoint($0.coordinate) == end ? $0.name : "Edited destination" } ?? "Destination", coordinate: end.coordinate)
        waypoints = stops
        usesStoredPath = false
        let allowed = Set(stops.map(\.id) + [RouteLegChoice.destinationID])
        sectionChoices = sectionChoices.filter { allowed.contains($0.key) }
        if hasSectionSettings {
            for id in allowed where sectionChoices[id] == nil {
                sectionChoices[id] = RouteLegChoice(mode: mode, speedMPH: mode.clampedSpeedMPH(speedMPH ?? mode.defaultSpeedMPH))
            }
        }
        rebuild(mode: mode)
    }

    var editableWaypoints: [TripWaypoint] {
        if usesStoredPath, let route = selectedRoute {
            return route.stops.map { TripWaypoint(id: $0.id, name: $0.name, point: route.track.point(at: $0.metres), waitSeconds: $0.waitSeconds) }
        }
        return waypoints
    }

    func applyPlaceEdits(_ places: [TripWaypoint], mode: TravelMode) {
        guard places.count >= 2, places.count <= 22, let start = places.first, let end = places.last,
              places.allSatisfy({ $0.point.isValid && !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.name.count <= 120 && StopDuration.isValid($0.waitSeconds) }),
              let route = selectedRoute else { return }
        let stops = Array(places.dropFirst().dropLast())
        let old = editableWaypoints
        let sameGeometry = RoutePoint(route.origin.coordinate) == start.point && RoutePoint(route.destination.coordinate) == end.point &&
            old.map(\.id) == stops.map(\.id) && zip(old, stops).allSatisfy { pair in pair.0.point == pair.1.point }
        origin = RoutePlace(name: start.name, coordinate: start.point.coordinate)
        destination = RoutePlace(name: end.name, coordinate: end.point.coordinate)
        if sameGeometry {
            waypoints = stops
            for index in alternatives.indices {
                alternatives[index].origin = RoutePlace(name: start.name, coordinate: start.point.coordinate)
                alternatives[index].destination = RoutePlace(name: end.name, coordinate: end.point.coordinate)
                for j in alternatives[index].stops.indices {
                    if let value = stops.first(where: { $0.id == alternatives[index].stops[j].id }) {
                        alternatives[index].stops[j].name = value.name
                        alternatives[index].stops[j].waitSeconds = value.waitSeconds
                    }
                }
            }
        } else {
            // Prevent syncPathStops from bringing the old positions back.
            usesStoredPath = false
            waypoints = stops
            let allowed = Set(stops.map(\.id) + [RouteLegChoice.destinationID])
            sectionChoices = sectionChoices.filter { allowed.contains($0.key) }
            rebuild(mode: mode)
        }
    }

    private func syncPathStops() {
        guard usesStoredPath, let route = selectedRoute else { return }
        waypoints = route.stops.map { TripWaypoint(id: $0.id, name: $0.name, point: route.track.point(at: $0.metres), waitSeconds: $0.waitSeconds) }
    }
}

extension Notification.Name {
    static let locusDrawRoute = Notification.Name("locus.drawRoute")
}
