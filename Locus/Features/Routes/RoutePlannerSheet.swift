import CoreLocation
import MapKit
import SwiftUI
import UniformTypeIdentifiers

struct RoutePlannerSheet: View {
    var onDraw: () -> Void = {}
    @EnvironmentObject private var session: SpoofSession
    @EnvironmentObject private var preferences: SessionPreferences
    @EnvironmentObject private var planner: RoutePlanner
    @EnvironmentObject private var library: TripLibrary
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var searchEndpoint: Endpoint?
    @State private var stopSearchRoute: PlannedRoute?
    @State private var pendingSearchChoice: (endpoint: Endpoint, place: RoutePlace, alongRoute: Bool)?
    @State private var showImporter = false
    @State private var showExporter = false
    @State private var exportDocument = GPXRouteDocument(text: "")
    @State private var showPathStop = false
    @State private var showSaveTrip = false
    @State private var tripName = ""
    @State private var savedNotice: String?
    @State private var showPractice = false
    @State private var showMapEditor = false
    @State private var showPlaceEditor = false
    @State private var confirmLiveEdit = false
    @State private var pendingEdit: SavedTrip?
    @State private var pendingEditID: UUID?
    @State private var editingSection: SectionEdit?
    @State private var pendingSectionChoice: (id: UUID, choice: RouteLegChoice)?
    @State private var pendingLiveSection: SectionEdit?
    @State private var liveMovementExpanded = false
    @State private var draftMovementExpanded = false
    @State private var editingStop: StopEdit?
    @State private var advancedExpanded = false
    @State private var previewLine: (id: UUID, line: MKPolyline)?
    private struct SectionEdit: Identifiable, Hashable {
        let id: UUID; let title: String; let choice: RouteLegChoice
        static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
        func hash(into hasher: inout Hasher) { hasher.combine(id) }
    }
    private struct StopEdit: Identifiable {
        let id: UUID
        let name: String
        let seconds: Double
    }
    private struct TimelinePlace: Identifiable {
        let id: UUID
        let name: String
        let wait: Double?
        let metres: Double?
    }

    private enum Endpoint: String, Identifiable, Hashable {
        case origin, destination, stop
        var id: String { rawValue }
    }
    private var hasJourney: Bool { session.journey != nil }
    private var route: PlannedRoute? { hasJourney ? session.activeRoute : planner.selectedRoute }
    private var displayMode: TravelMode { hasJourney ? session.travelMode : planner.draftMode }
    private var displaySpeed: Double { hasJourney ? session.speedMPH(for: session.travelMode) : planner.draftSpeedMPH }
    private var displaySmooth: Bool { hasJourney ? session.smoothMovement : planner.draftSmoothMovement }

    var body: some View {
        NavigationStack {
            List {
                if let route { routePreview(route) }
                routeTimeline.shiftSettingsRows()
                movement.shiftSettingsRows()
                if planner.isLoading {
                    Section { ProgressView("Finding route…").frame(maxWidth: .infinity, minHeight: 44, alignment: .leading) }
                        .listRowBackground(Color.clear)
                }
                if !hasJourney && planner.alternatives.count > 1 { alternatives.shiftSettingsRows() }
                if let route { routeSummary(route).shiftSettingsRows() }
                routeOptions
            }
            .shiftSettingsScreen().textCase(nil)
            .loggedNavigationTitle(hasJourney ? "Your route" : "Plan a route")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button(hasJourney ? "Done" : "Cancel") {
                if !hasJourney { planner.rememberDraft(in: session) }
                dismiss()
            } } }
            .safeAreaInset(edge: .bottom, spacing: 0) { routeActions }
            .onAppear {
                applyPendingSearchChoice()
                applyPendingSectionChoice()
                if !hasJourney {
                    planner.initializeDraftIfNeeded(mode: session.travelMode, speedMPH: session.speedMPH(for: session.travelMode), smoothMovement: session.smoothMovement)
                }
                if !hasJourney, planner.origin == nil, let current = session.defaultRouteOrigin {
                    planner.setOrigin(current, mode: displayMode)
                }
                if !hasJourney { planner.rememberDraft(in: session) }
            }
            .onChange(of: planner.selectedID) { _, _ in
                if !hasJourney { planner.rememberDraft(in: session) }
            }
            .navigationDestination(item: $searchEndpoint) { endpoint in
                // Freeze the route for this navigation visit. Rebuilding the
                // parent must not replace a mounted search screen's identity.
                if endpoint == .stop, let route = stopSearchRoute {
                    RouteStopSearchSheet(route: route) { place, alongRoute in
                        pendingSearchChoice = (endpoint, place, alongRoute)
                    }
                } else {
                    RoutePlaceSearchSheet(title: endpoint == .origin ? "Starting point" : endpoint == .stop ? "Add stop" : "Destination",
                                          allowsDeviceOrigin: endpoint == .origin) { place in
                        pendingSearchChoice = (endpoint, place, false)
                    }
                }
            }
            .onChange(of: searchEndpoint) { _, endpoint in
                if endpoint == nil { applyPendingSearchChoice() }
            }
            .navigationDestination(isPresented: $showPractice) {
                if let route { RoutePracticeSheet(route: route, mode: displayMode, speed: SpeedConversion.metresPerSecond(mph: displaySpeed)) }
            }
            .sheet(item: $editingStop) { item in
                StopDurationSheet(name: item.name, seconds: item.seconds, stopCount: timelineStops.count) { seconds, all in
                    guard !hasJourney, !planner.isLoading else { return }
                    if all { planner.setAllWaits(seconds: seconds) }
                    else { planner.setWait(item.id, seconds: seconds) }
                }
            }
            .loggedConfirmationDialog("Edit this route?", isPresented: $confirmLiveEdit, titleVisibility: .visible) {
                Button("Hold location and edit") {
                    guard let route, !session.isBusy else { return }
                    pendingEditID = session.activeSavedTripID
                    pendingEdit = route.savedTrip(name: route.name, mode: displayMode, speed: displaySpeed, smooth: displaySmooth, arrival: session.arrivalChoice)
                    session.stopRoute()
                    finishLiveEditIfReady()
                }
                Button("Cancel", role: .cancel) { pendingLiveSection = nil }
            } message: {
                Text("This ends travel and holds your last sent location while you edit. Show route previews the changes. Start route begins again at the chosen start.")
            }
            .onChange(of: hasJourney) { _, active in if !active { finishLiveEditIfReady() } }
            .navigationDestination(isPresented: $showPlaceEditor) {
                if let route {
                    RoutePlacesEditor(route: route, waypoints: planner.editableWaypoints) { places, savePlaces in
                        planner.applyPlaceEdits(places, mode: displayMode)
                        if savePlaces {
                            for place in places { session.addFavorite(name: place.name, coordinate: place.point.coordinate) }
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $showMapEditor) {
                if let route {
                    RouteWaypointEditor(route: route, stops: planner.editableWaypoints) { start, end, stops in
                        planner.applyMapEdit(origin: start, destination: end, stops: stops, mode: displayMode, speedMPH: displaySpeed)
                    }
                }
            }
            .navigationDestination(item: $editingSection) { item in
                RouteSectionChoiceSheet(title: item.title, choice: item.choice,
                                        keepsExactPath: route?.source.isAutomatic == false) { choice in
                    pendingSectionChoice = (item.id, choice)
                }
            }
            .onChange(of: editingSection) { _, item in
                if item == nil { applyPendingSectionChoice() }
            }
            .navigationDestination(isPresented: $showPathStop) {
                if let route {
                    AddPathStopSheet(route: route, liveRoute: hasJourney) { name, fraction, wait in
                        if hasJourney { return session.addRouteStop(routeID: route.id, name: name, fraction: fraction, wait: wait) }
                        planner.addPathStop(name: name, fraction: fraction, wait: wait)
                        return nil
                    }
                }
            }
            .loggedAlert("Save trip", isPresented: $showSaveTrip) {
                TextField("Trip name", text: $tripName)
                Button("Cancel", role: .cancel) { }
                Button("Save") {
                    if let route, library.save(route: route, name: tripName, mode: displayMode,
                        speed: displaySpeed, smooth: displaySmooth, arrival: hasJourney ? session.arrivalChoice : planner.draftArrival, replacingID: hasJourney ? session.activeSavedTripID : planner.editingTripID) {
                        if let id = library.lastSavedID {
                            if hasJourney { session.rememberSavedTrip(id, routeID: route.id) }
                            else { planner.editingTripID = id }
                        }
                        savedNotice = "Trip saved with its place names and stops."
                    }
                }
            } message: { Text("Saves the whole path from its start, travel mode, target speed, and all stops.") }
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.xml, .data]) { result in
                do {
                    let coordinates = try GPXCodec.parse(result.get())
                    planner.useCustom(coordinates, source: .gpx)
                } catch { planner.error = error.localizedDescription }
            }
            .fileExporter(isPresented: $showExporter, document: exportDocument, contentType: .xml,
                          defaultFilename: "Elsepin-Route.gpx") { result in
                if case .failure(let error) = result { planner.error = error.localizedDescription }
            }
        }
    }

    private func finishLiveEditIfReady() {
        guard !hasJourney, let trip = pendingEdit else { return }
        pendingEdit = nil
        planner.useSaved(trip)
        planner.editingTripID = pendingEditID
        pendingEditID = nil
        if let section = pendingLiveSection {
            pendingLiveSection = nil
            editingSection = section
        } else { showPlaceEditor = true }
    }

    private var timelineStops: [TripWaypoint] {
        if hasJourney, let route {
            return route.stops.map { TripWaypoint(id: $0.id, name: $0.name, point: route.track.point(at: $0.metres), waitSeconds: $0.waitSeconds) }
        }
        return planner.editableWaypoints
    }

    private var timelinePlaces: [TimelinePlace] {
        [TimelinePlace(id: RoutePlacesEditor.startID,
            name: (hasJourney ? route?.origin.name : planner.origin?.name) ?? "Choose starting point", wait: nil, metres: 0)] +
        timelineStops.map { stop in
            TimelinePlace(id: stop.id, name: stop.name, wait: stop.waitSeconds,
                metres: route?.stops.first(where: { $0.id == stop.id })?.metres)
        } +
        [TimelinePlace(id: RouteLegChoice.destinationID,
            name: (hasJourney ? route?.destination.name : planner.destination?.name) ?? "Choose destination", wait: nil, metres: route?.track.length)]
    }

    private var routeTimeline: some View {
        // Every row and its previous leg use the SAME immutable collection.
        // Lazy rows can outlive a later stop edit; never index a newly read list.
        let places = timelinePlaces
        return Section {
            ForEach(Array(places.enumerated()), id: \.element.id) { index, place in
                VStack(alignment: .leading, spacing: 4) {
                    if index > 0 { timelineLeg(to: place, previousMetres: places[index - 1].metres) }
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)").font(.subheadline.weight(.semibold)).monospacedDigit()
                            .foregroundStyle(LocusTheme.onAccent)
                            .frame(width: 28, height: 28).background(LocusTheme.accent, in: Circle())
                            .padding(.top, 8).accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Button { editTimelinePlace(place) } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(index == 0 ? "Start" : place.wait == nil ? "Destination" : "Stop \(index)")
                                        .font(.caption).foregroundStyle(.secondary)
                                    Text(place.name).font(.body.weight(.semibold)).foregroundStyle(.primary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading).contentShape(Rectangle())
                            }
                            .disabled(hasJourney && (session.isBusy || session.routeStopping))
                            if let seconds = place.wait {
                                if hasJourney {
                                    Label(StopDuration.label(seconds), systemImage: "clock")
                                        .font(.subheadline).foregroundStyle(.secondary).padding(.vertical, 6)
                                } else {
                                    Button { editingStop = StopEdit(id: place.id, name: place.name, seconds: seconds) } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "clock")
                                            Text(seconds == 0 ? "Pass through" : "Wait \(StopDuration.label(seconds))")
                                            Image(systemName: "chevron.right").font(.caption2)
                                        }.font(.subheadline).frame(minHeight: 44).contentShape(Rectangle())
                                    }.accessibilityLabel("Wait at \(place.name), \(StopDuration.label(seconds))")
                                }
                            }
                        }
                        if place.wait != nil && !hasJourney { timelineStopMenu(place) }
                    }
                }
                .listRowSeparator(.hidden)
            }
            HStack {
                Button {
                    if hasJourney || planner.usesStoredPath { showPathStop = true }
                    else { stopSearchRoute = planner.selectedRoute; searchEndpoint = .stop }
                } label: {
                    Label(hasJourney ? "Add a stop ahead" : "Add stop", systemImage: "plus.circle")
                        .frame(minHeight: 44)
                }
                .disabled(hasJourney ? !session.canAddRouteStop || timelineStops.count >= 20 : timelineStops.count >= (planner.usesStoredPath ? 20 : 8))
                Spacer()
                Menu {
                    if hasJourney {
                        Button("Edit places & stops", systemImage: "pencil") { confirmLiveEdit = true }
                            .disabled(session.isBusy || session.routeStopping)
                    } else {
                        Button("Edit names & places", systemImage: "pencil") { showPlaceEditor = true }.disabled(route == nil)
                        Button("Swap start and destination", systemImage: "arrow.up.arrow.down") { planner.swap(mode: displayMode) }
                            .disabled(planner.origin == nil || planner.destination == nil)
                        Button("Refresh directions", systemImage: "arrow.clockwise") { planner.rebuild(mode: displayMode) }
                            .disabled(planner.origin == nil || planner.destination == nil)
                    }
                } label: {
                    Image(systemName: "ellipsis").frame(width: 44, height: 44).contentShape(Rectangle())
                }.accessibilityLabel("Route place options")
            }
        } header: { Text("Stops") }
        .buttonStyle(.borderless)
        .disabled(!hasJourney && planner.isLoading)
    }

    private func editTimelinePlace(_ place: TimelinePlace) {
        if hasJourney { confirmLiveEdit = true }
        else if place.id == RoutePlacesEditor.startID { searchEndpoint = .origin }
        else if place.id == RouteLegChoice.destinationID { searchEndpoint = .destination }
        else if route != nil { showPlaceEditor = true }
        else if let seconds = place.wait { editingStop = StopEdit(id: place.id, name: place.name, seconds: seconds) }
    }

    private func timelineStopMenu(_ place: TimelinePlace) -> some View {
        Menu {
            if !planner.usesStoredPath {
                Button("Move earlier") { planner.moveWaypoint(place.id, offset: -1, mode: displayMode) }
                    .disabled(planner.waypoints.first?.id == place.id)
                Button("Move later") { planner.moveWaypoint(place.id, offset: 1, mode: displayMode) }
                    .disabled(planner.waypoints.last?.id == place.id)
            }
            Button("Remove stop", role: .destructive) {
                if planner.usesStoredPath { planner.removePathStop(place.id) }
                else { planner.removeWaypoint(place.id, mode: displayMode) }
            }
        } label: {
            Image(systemName: "ellipsis").frame(width: 44, height: 44).contentShape(Rectangle())
        }.accessibilityLabel("Options for \(place.name)")
    }

    private func timelineLeg(to place: TimelinePlace, previousMetres: Double?) -> some View {
        let choices = timelineLegChoices(to: place, previousMetres: previousMetres)
        return HStack(spacing: 12) {
            Rectangle().fill(LocusTheme.accent.opacity(0.3)).frame(width: 2).frame(width: 28)
            Button {
                if !hasJourney, let choice = choices.first {
                    editingSection = SectionEdit(id: place.id, title: "To \(place.name)", choice: choice)
                } else if hasJourney, let choice = choices.first {
                    pendingLiveSection = SectionEdit(id: place.id, title: "To \(place.name)", choice: choice)
                    confirmLiveEdit = true
                }
            } label: {
                HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    if choices.count > 1 {
                        Label("Mixed travel · \(choices.count) sections", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                            .font(.subheadline).foregroundStyle(.secondary)
                    } else if let choice = choices.first {
                        Label("\(choice.mode.title) · \(preferences.speedUnit.formatted(mph: choice.speedMPH))", systemImage: choice.mode.icon)
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.tertiary)
                }.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading).contentShape(Rectangle())
            }.accessibilityLabel("Movement to \(place.name)")
                .accessibilityHint(hasJourney ? "Hold the current location before editing this leg" : "Change only this leg's mode and speed")
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func timelineLegChoices(to place: TimelinePlace, previousMetres: Double?) -> [RouteLegChoice] {
        if !hasJourney, !planner.usesStoredPath, let choice = planner.sectionChoices[place.id] { return [choice] }
        if !hasJourney, place.metres == previousMetres, let choice = planner.sectionChoices[place.id] { return [choice] }
        if let route, let end = place.metres, let start = previousMetres {
            let sections = route.travelSections.filter { $0.endMetres > start && $0.startMetres < end }
            if !sections.isEmpty {
                return sections.map { RouteLegChoice(mode: $0.mode, speedMPH: $0.speedMPH) }
            }
        }
        return [RouteLegChoice(mode: displayMode, speedMPH: displaySpeed)]
    }

    private var planningCycling: Bool {
        planner.hasSectionSettings ? planner.sectionChoices.values.contains { $0.mode.routeNetwork == .cycling }
            : displayMode.routeNetwork == .cycling
    }

    @ViewBuilder private var movement: some View {
        if hasJourney {
            Section {
                DisclosureGroup("Mode & speed", isExpanded: $liveMovementExpanded) {
                    RouteModeMenu()
                    MovementSpeedControl()
                }
            }
        } else {
            Section {
                DisclosureGroup("Whole route", isExpanded: $draftMovementExpanded) {
                if planner.hasSectionSettings {
                    Label("Individual leg settings", systemImage: "slider.horizontal.3")
                        .font(.subheadline.weight(.semibold))
                        Button {
                            planner.useSingleMovement(mode: displayMode)
                        } label: {
                            Text("Use one mode & speed").frame(maxWidth: .infinity, minHeight: 44, alignment: .leading).contentShape(Rectangle())
                        }.buttonStyle(.borderless)
                } else {
                    // Keep every mode discoverable without a hidden horizontal
                    // scroll. Accessibility text gets full-width wrapping rows.
                    LazyVGrid(columns: modeColumns, alignment: .leading, spacing: 8) {
                            ForEach(TravelMode.allCases) { mode in
                                Button {
                                    planner.draftMode = mode
                                    planner.draftSpeedMPH = session.speedMPH(for: mode)
                                    planner.modeChanged(mode)
                                } label: {
                                    Label(mode.title, systemImage: mode.icon).font(.subheadline.weight(.semibold))
                                        .fixedSize(horizontal: false, vertical: true)
                                        .padding(.horizontal, 12).padding(.vertical, 8)
                                        .frame(maxWidth: .infinity, minHeight: 44)
                                        .foregroundStyle(planner.draftMode == mode ? LocusTheme.onAccent : Color.primary)
                                        .background(planner.draftMode == mode ? LocusTheme.accent : Color.primary.opacity(0.055), in: Capsule())
                                        .contentShape(Capsule())
                                }.buttonStyle(.plain)
                                    .accessibilityLabel(mode.title)
                                    .accessibilityAddTraits(planner.draftMode == mode ? .isSelected : [])
                            }
                    }.padding(.vertical, 4).accessibilityLabel("Travel mode")
                    draftSpeedControl
                }
                }
            }
        }
    }

    private var modeColumns: [GridItem] {
        typeSize.isAccessibilitySize
            ? [GridItem(.flexible(minimum: 0))]
            : [GridItem(.adaptive(minimum: 110), spacing: 8)]
    }

    private var draftSpeedControl: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Speed").font(.subheadline).foregroundStyle(.secondary)
                Spacer()
                Text(preferences.speedUnit.formatted(mph: displaySpeed)).font(.title2.weight(.semibold)).monospacedDigit()
            }
            SpeedSlider(mph: $planner.draftSpeedMPH, mode: displayMode)
            Button { planner.draftSpeedMPH = session.usualSpeedMPH(for: displayMode) } label: {
                Label("Use usual speed · \(preferences.speedUnit.formatted(mph: session.usualSpeedMPH(for: displayMode)))", systemImage: "arrow.counterclockwise")
                    .font(.caption).frame(maxWidth: .infinity, minHeight: 44, alignment: .leading).contentShape(Rectangle())
            }.buttonStyle(.borderless)
        }
    }

    private var arrivalPicker: some View {
        Picker("At destination", selection: Binding(get: { hasJourney ? session.arrivalChoice : planner.draftArrival },
            set: { if hasJourney { session.arrivalChoice = $0 } else { planner.draftArrival = $0 } })) {
            ForEach(ArrivalChoice.allCases) { choice in Text(choice.title).tag(choice) }
        }
    }
    @ViewBuilder private var routeOptions: some View {
        Section {
            Button {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { advancedExpanded.toggle() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "slider.horizontal.3").foregroundStyle(LocusTheme.accent)
                    Text("Options").font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: advancedExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                }.frame(maxWidth: .infinity, minHeight: 44).contentShape(Rectangle())
            }.buttonStyle(.plain)
                .accessibilityValue(advancedExpanded ? "Expanded" : "Collapsed")
        }.shiftSettingsRows()
        if advancedExpanded {
            Section {
                arrivalPicker
                if !hasJourney {
                    Toggle("Smooth route movement", isOn: $planner.draftSmoothMovement)
                    if !planner.usesStoredPath && planningCycling {
                        Toggle("Use walking paths", isOn: Binding(get: { planner.preferWalkingPaths }, set: {
                            planner.preferWalkingPaths = $0
                            planner.rebuild(mode: displayMode)
                        }))
                    }
                }
            } header: { Text("Behavior").padding(.leading, 16) }
                .shiftSettingsRows().modifier(RouteNestedOptions()).disabled(planner.isLoading)
            Section {
                Button {
                    if hasJourney { confirmLiveEdit = true }
                    else { showPlaceEditor = true }
                } label: { Label("Edit names & places", systemImage: "pencil").frame(minHeight: 44) }
                    .disabled(route == nil || session.isBusy || session.routeStopping)
                if !hasJourney && !planner.usesStoredPath {
                    Button { showMapEditor = true } label: {
                        Label("Move places on map", systemImage: "hand.draw").frame(minHeight: 44)
                    }.disabled(route == nil)
                }
            } header: { Text("Edit route").padding(.leading, 16) }
                .shiftSettingsRows().modifier(RouteNestedOptions()).buttonStyle(.borderless).disabled(planner.isLoading)
            routeFiles
                .shiftSettingsRows().modifier(RouteNestedOptions()).buttonStyle(.borderless)
        }
    }

    private var alternatives: some View {
        Section("Route choices") {
            ForEach(planner.alternatives) { option in
                Button { planner.choose(option) } label: {
                    HStack(spacing: 12) {
                        Image(systemName: option.id == planner.selectedID ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(LocusTheme.accent)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(option.name).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                            Text("\(JourneyText.distance(option.distance)) · \(JourneyText.duration(option.estimate(mode: displayMode, speed: SpeedConversion.metresPerSecond(mph: displaySpeed), smooth: displaySmooth))) simulated")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 4).frame(minHeight: 44).contentShape(Rectangle())
                }
            }
        }
    }

    private func routePreview(_ route: PlannedRoute) -> some View {
        Section {
            Map(initialPosition: .automatic, interactionModes: [.pan, .zoom]) {
                if let previewLine, previewLine.id == route.id {
                    MapPolyline(previewLine.line).stroke(LocusTheme.accent, lineWidth: 5)
                }
                ForEach(Array(route.stops.enumerated()), id: \.element.id) { index, stop in
                    Annotation(stop.name, coordinate: route.track.point(at: stop.metres).coordinate) {
                        Text("\(index + 2)").font(.caption.weight(.bold)).foregroundStyle(LocusTheme.onAccent)
                            .frame(width: 28, height: 28).background(LocusTheme.accent, in: Circle())
                            .overlay(Circle().stroke(.background, lineWidth: 2))
                            .accessibilityLabel("Stop \(index + 1), \(stop.name)")
                    }
                }
                Marker("Start", systemImage: "circle.fill", coordinate: route.origin.coordinate).tint(.secondary)
                Marker("Finish", systemImage: "flag.checkered", coordinate: route.destination.coordinate).tint(LocusTheme.accent)
                if hasJourney, let coordinate = session.simulated {
                    Marker("Spoofed location", systemImage: displayMode.icon, coordinate: coordinate).tint(LocusTheme.accentSecondary)
                }
            }
            .mapStyle(.standard(elevation: .flat))
            .mapControlVisibility(.hidden)
            .id(route.id)
            .frame(height: typeSize.isAccessibilitySize ? 170 : 140)
            .overlay(alignment: .topTrailing) {
                Button { showPractice = true } label: {
                    Label("Preview", systemImage: "play.fill").font(.caption.weight(.semibold))
                        .padding(.horizontal, 12).frame(minHeight: 44).contentShape(Capsule())
                }.buttonStyle(.plain).locusGlass(.regular, in: Capsule())
                    .padding(10).accessibilityLabel("Preview without changing location")
            }
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .accessibilityLabel("Simulated route preview")
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .onAppear { updatePreviewLine(route) }
        .onChange(of: route.id) { _, _ in updatePreviewLine(route) }
    }

    private func updatePreviewLine(_ route: PlannedRoute) {
        guard previewLine?.id != route.id else { return }
        previewLine = (route.id, MKPolyline(coordinates: route.coordinates, count: route.coordinates.count))
    }

    // Outside the scrolling list so choosing a mode never hides Show route.
    private var routeActions: some View {
        VStack(spacing: 6) {
            if hasJourney {
                RoutePlaybackControls(onStop: { dismiss() })
            } else {
                if let error = planner.error {
                    Text(error).font(.caption).foregroundStyle(LocusTheme.statusWarn)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(4)
                    if planner.cyclingUnavailable {
                        Button("Use a walking path instead") {
                            planner.preferWalkingPaths = true
                            planner.rebuild(mode: displayMode)
                        }.font(.subheadline.weight(.semibold)).frame(minHeight: 44)
                    }
                }
                if let route {
                    if let note = route.source.playbackNote(mode: route.travelSections.first?.mode ?? displayMode) {
                        Text(note).font(.caption.weight(.medium)).foregroundStyle(LocusTheme.statusWarn)
                    }
                }
                Button(action: showRoute) {
                    Label(planner.isLoading ? "Finding route…" : "Show route", systemImage: "map")
                        .font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 44).contentShape(Rectangle())
                }
                .buttonStyle(ShiftActionStyle(compact: true))
                .disabled(!canShowRoute)
                Text(planner.isLoading ? "Building your preview. No movement has started."
                     : planner.cyclingUnavailable ? "Choose Walking path above or change your endpoints."
                     : route == nil ? "Choose a start and destination." : "Next: tap Start route on the map.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(12).frame(maxWidth: .infinity)
        .locusGlass(.regular, in: RoundedRectangle(cornerRadius: 22))
        .padding(.horizontal, 16).padding(.vertical, 8)
    }

    private var canShowRoute: Bool {
        guard let route else { return false }
        return !hasJourney && !planner.isLoading && route.supports(displayMode)
    }

    private func applyPendingSearchChoice() {
        guard let choice = pendingSearchChoice else { return }
        pendingSearchChoice = nil
        searchEndpoint = nil
        stopSearchRoute = nil
        DeveloperLogStore.shared.record("route_search_choice_applied", ["endpoint": choice.endpoint.rawValue])
        // Run after the navigation update that removed the search destination.
        Task { @MainActor in
            await Task.yield()
            guard planner.isPresented, !hasJourney else { return }
            switch choice.endpoint {
            case .origin: planner.setOrigin(choice.place, mode: displayMode)
            case .stop: planner.addWaypoint(choice.place, mode: displayMode, speedMPH: displaySpeed, insertAlongRoute: choice.alongRoute)
            case .destination: planner.setDestination(choice.place, defaultOrigin: session.defaultRouteOrigin, mode: displayMode)
            }
        }
    }

    private func showRoute() {
        guard canShowRoute else { return }
        if planner.prepareSelectedRoute(mode: displayMode, speedMPH: displaySpeed, smoothMovement: displaySmooth) {
            planner.rememberDraft(in: session)
            dismiss()
        }
    }

    private func applyPendingSectionChoice() {
        guard let pending = pendingSectionChoice else { return }
        pendingSectionChoice = nil
        editingSection = nil
        Task { @MainActor in
            await Task.yield()
            guard planner.isPresented, !hasJourney else { return }
            planner.setSectionChoice(pending.choice, for: pending.id, defaultMode: displayMode)
            planner.rememberDraft(in: session)
        }
    }

    private func routeSummary(_ route: PlannedRoute) -> some View {
        Section {
            HStack(alignment: .top, spacing: 20) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Distance").font(.caption).foregroundStyle(.secondary)
                    Text(JourneyText.distance(route.distance)).font(.title3.weight(.semibold))
                }.frame(maxWidth: .infinity, alignment: .leading)
                Divider().frame(height: 42)
                VStack(alignment: .leading, spacing: 5) {
                    Text("Elsepin time").font(.caption).foregroundStyle(.secondary)
                    Text(JourneyText.duration(route.estimate(mode: displayMode, speed: SpeedConversion.metresPerSecond(mph: displaySpeed), smooth: displaySmooth))).font(.title3.weight(.semibold))
                }.frame(maxWidth: .infinity, alignment: .leading)
            }.padding(.vertical, 5)
            Button {
                tripName = library.trips.first(where: { $0.id == (hasJourney ? session.activeSavedTripID : planner.editingTripID) })?.name ?? route.name
                showSaveTrip = true
            } label: {
                Label((hasJourney ? session.activeSavedTripID : planner.editingTripID) != nil ? "Save changes" : "Save route", systemImage: "star")
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading).contentShape(Rectangle())
            }.buttonStyle(.borderless)
            if let savedNotice { Text(savedNotice).font(.caption).foregroundStyle(.secondary) }
            if let error = library.error { Text(error).font(.caption).foregroundStyle(LocusTheme.statusWarn) }
            if !route.notices.isEmpty {
                DisclosureGroup("Route notes") {
                    ForEach(Array(route.notices.enumerated()), id: \.offset) { notice in
                        Text(notice.element).font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
        } header: { Text("Summary") }
    }

    private var routeFiles: some View {
        Section {
            Button {
                onDraw()
                dismiss()
            } label: { Label("Draw an exact path", systemImage: "pencil.tip").frame(minHeight: 44) }
                .disabled(hasJourney)
            Button { showImporter = true } label: {
                Label("Import GPX", systemImage: "square.and.arrow.down").frame(minHeight: 44)
            }.disabled(hasJourney)
            Button {
                guard let route else { return }
                exportDocument = GPXRouteDocument(text: GPXCodec.export(route.coordinates, name: route.name))
                showExporter = true
            } label: { Label("Export route", systemImage: "square.and.arrow.up").frame(minHeight: 44) }
                .disabled(route == nil)
        } header: { Text("Files & drawing").padding(.leading, 16) }
    }

}

private struct GPXRouteDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.xml] }
    let text: String
    init(text: String) { self.text = text }
    init(configuration: ReadConfiguration) throws {
        text = String(decoding: configuration.file.regularFileContents ?? Data(), as: UTF8.self)
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}

/// A narrow inset/rail makes disclosed settings read as children, retaining
/// native row sizing, separators and accessibility instead of shrinking text.
private struct RouteNestedOptions: ViewModifier {
    @Environment(\.shiftVisualStyle) private var style
    func body(content: Content) -> some View {
        content.listRowInsets(EdgeInsets(top: 10, leading: 32, bottom: 10, trailing: 16))
            .listRowBackground(
                HStack(spacing: 0) {
                    Rectangle().fill(LocusTheme.accent.opacity(0.4)).frame(width: 2)
                    Color.clear
                }.padding(.leading, 12)
                    .background(ShiftPalette.color(style == .porcelain ? .canvas : .surface, style: style))
            )
    }
}
