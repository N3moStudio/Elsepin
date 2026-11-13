import MapKit
import SwiftUI

struct RoutePlaceSearchSheet: View {
    let title: String
    let onChoose: (RoutePlace) -> Void
    let onPreviewTeleport: ((RoutePlace) -> Void)?
    let allowsDeviceOrigin: Bool
    let onChooseTrip: ((SavedTrip) -> Void)?
    @EnvironmentObject private var library: TripLibrary
    @EnvironmentObject private var session: SpoofSession
    @Environment(\.dismiss) private var dismiss
    @Environment(\.shiftEditorEmbedded) private var embedded
    @StateObject private var completer = PlaceSearchCompleter()
    @State private var query = ""
    @State private var isResolving = false
    @State private var error: String?
    @State private var searchTask: Task<Void, Never>?
    @State private var activeSearch: PlaceSearchRequest?
    @State private var searchGeneration = UUID()
    @State private var pinEditor: PinDraft?
    @State private var selectedTrip: SavedTrip?
    @State private var renameTrip = false
    @State private var tripName = ""
    @State private var resultNote: String?
    @State private var selectedPlace: RoutePlace?
    @State private var showPlaceActions = false
    @State private var showDeviceLocation = false
    @State private var pendingDeviceOrigin: RoutePlace?
    @State private var searchResults: [PlaceSearchResult] = []
    @State private var submittedQuery: String?
    @FocusState private var searchFocused: Bool

    init(title: String, onPreviewTeleport: ((RoutePlace) -> Void)? = nil, allowsDeviceOrigin: Bool = false,
         onChooseTrip: ((SavedTrip) -> Void)? = nil, onChoose: @escaping (RoutePlace) -> Void) {
        self.title = title
        self.onChooseTrip = onChooseTrip
        self.onPreviewTeleport = onPreviewTeleport
        self.allowsDeviceOrigin = allowsDeviceOrigin
        self.onChoose = onChoose
    }

    var body: some View {
        ShiftEditorContainer {
            List {
                if isResolving {
                    HStack {
                        ElsepinProgressLabel("Finding place…", lowPower: session.lowPower)
                        Spacer()
                        Button("Cancel search") { cancelSearch() }.buttonStyle(.borderless)
                    }
                }
                if let error { Text(error).foregroundStyle(LocusTheme.statusWarn) }
                if let resultNote { Text(resultNote).font(.caption).foregroundStyle(.secondary) }
                if query.isEmpty {
                    ShiftScreenHeading(eyebrow: "Places", title: "Where to?", detail: "Find a place or return to a favorite.")
                    Section("Use a location") {
                        if allowsDeviceOrigin {
                            Button {
                                showDeviceLocation = true
                            } label: { Label("Use device location", systemImage: "location.fill") }
                        }
                        if let current = session.defaultRouteOrigin, !allowsDeviceOrigin || session.hasSession {
                            Button { choose(current) } label: { Label(current.name, systemImage: "location") }
                        }
                        if let pin = session.pin {
                            Button { choose(RoutePlace(name: session.suggestedFavoriteName(for: pin), coordinate: pin)) } label: {
                                Label("Currently dropped pin", systemImage: "mappin")
                            }
                        }
                    }
                    Section("Recent pins & routes") {
                        ForEach(session.recents.prefix(8)) { place in
                            let current = session.savedPin(at: place.coordinate) ?? place
                            Button { choose(RoutePlace(name: current.displayName, coordinate: current.coordinate)) } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "mappin")
                                    placeRow(current.displayName, subtitle: current.address ?? "")
                                    if current.isFavorite && session.savedPin(at: current.coordinate) != nil {
                                        Image(systemName: "star.fill").font(.caption)
                                    }
                                }
                            }
                        }
                        if onChooseTrip != nil {
                            ForEach(session.recentRoutes.prefix(8)) { recent in
                                Button { chooseTrip(recent.trip) } label: {
                                    let current = library.trips.first { $0.id == recent.trip.id } ?? recent.trip
                                    HStack(spacing: 10) {
                                        Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                                        placeRow(current.name, subtitle: "\(current.originName) → \(current.destinationName)")
                                        if current.isFavorite { Image(systemName: "star.fill").font(.caption) }
                                    }
                                }
                                .disabled(session.journey != nil || session.isBusy)
                                .contextMenu {
                                    Button("Name route", systemImage: "pencil") {
                                        selectedTrip = recent.trip
                                        tripName = recent.trip.name
                                        renameTrip = true
                                    }
                                }
                            }
                        }
                    }
                } else {
                    savedMatches
                    if submittedQuery != nil {
                        Section("Search results") {
                            ForEach(searchResults) { result in
                                Button { choose(result.place) } label: {
                                    placeRow(result.place.name, subtitle: result.address)
                                }
                            }
                        }
                    } else {
                        ForEach(completer.results, id: \.self) { completion in
                            Button {
                                resolve(MKLocalSearch.Request(completion: completion), chooseSingleResult: true)
                            } label: {
                                placeRow(completion.title, subtitle: completion.subtitle)
                            }
                        }
                    }
                    Button("Search for “\(query)”", action: searchAll)
                        .disabled(isResolving || query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                RouteSearchField(query: $query, focused: $searchFocused,
                                 prompt: "Saved name, address, or place", submit: searchAll)
            }
            .onChange(of: query) { _, value in
                cancelSearch()
                searchResults = []
                submittedQuery = nil
                selectedPlace = nil
                showPlaceActions = false
                completer.query = value
                resultNote = nil
                error = nil
            }
            .shiftSettingsScreen().loggedNavigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { if !embedded { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { cancelSearch(); dismiss() } } } }
            .loggedConfirmationDialog(selectedPlace?.name ?? "Selected place", isPresented: $showPlaceActions, titleVisibility: .visible) {
                if let place = selectedPlace, let onPreviewTeleport {
                    Button("Teleport here") {
                        session.pushNamedRecent(name: place.name, coordinate: place.coordinate)
                        onPreviewTeleport(place)
                        selectedPlace = nil
                        dismiss()
                    }
                    Button("Plan a route") { openPlanner(place) }
                    Button(session.savedPin(at: place.coordinate) == nil ? "Save pin" : "Rename pin") {
                        let saved = session.savedPins.first { $0.id == "\(place.coordinate.latitude),\(place.coordinate.longitude)" }
                        let draft = PinDraft(place: saved, center: place.coordinate, selectedCoordinate: place.coordinate)
                        draft.name = saved?.name ?? place.name
                        pinEditor = draft
                    }
                }
                Button("Cancel", role: .cancel) { selectedPlace = nil }
            } message: { Text("Teleport shows a pin first. Confirm on the map when you're ready.") }
            .sheet(item: $pinEditor) { draft in PinEditor(draft: draft) }
            .alert("Name route", isPresented: $renameTrip) {
                TextField("Route name", text: $tripName)
                Button("Save") {
                    if let trip = selectedTrip, !library.saveRecent(trip, name: tripName) { error = library.error }
                }
                Button("Cancel", role: .cancel) { }
            } message: { Text("Saves this route to Library. You can favorite it there.") }
            .sheet(isPresented: $showDeviceLocation, onDismiss: {
                if let place = pendingDeviceOrigin { pendingDeviceOrigin = nil; choose(place) }
            }) {
                DeviceOriginSheet { place in pendingDeviceOrigin = place; showDeviceLocation = false }
                    .presentationDetents([.medium])
            }
            .onDisappear { searchFocused = false; cancelSearch() }
        }
    }

    private func placeRow(_ name: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ShiftRowIcon(symbol: "mappin.and.ellipse")
            VStack(alignment: .leading, spacing: 4) {
                Text(name).font(.body.weight(.medium)).foregroundStyle(.primary)
                if !subtitle.isEmpty { Text(subtitle).font(.caption).foregroundStyle(.secondary) }
            }
        }.frame(maxWidth: .infinity, minHeight: 52, alignment: .leading).contentShape(Rectangle())
    }

    private func searchAll() {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        // Keyboard Search and the list button share one path. A general query
        // never opens a dialog or picks the first business/address implicitly.
        searchFocused = false
        let request = MKLocalSearch.Request()
        PlaceSearchRequest.configure(request, query: text)
        if let center = session.pin ?? session.defaultRouteOrigin?.coordinate ?? session.realCoordinate,
           CLLocationCoordinate2DIsValid(center) {
            request.region = MKCoordinateRegion(center: center, latitudinalMeters: 12_000, longitudinalMeters: 12_000)
        }
        resolve(request, chooseSingleResult: false)
    }

    @ViewBuilder private var savedMatches: some View {
        let places = session.savedPins.filter { SavedNameSearch.matches(query, fields: [$0.displayName, $0.folder ?? ""]) }
        if !places.isEmpty {
            Section("Pins") {
                ForEach(places.prefix(20)) { place in
                    Button { choose(RoutePlace(name: place.displayName, coordinate: place.coordinate)) } label: {
                        Label(place.displayName, systemImage: "star")
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading).contentShape(Rectangle())
                    }
                }
                if places.count > 20 { Text("More matches are available in Saved.").font(.caption).foregroundStyle(.secondary) }
            }
        }
        if onChooseTrip != nil {
            let trips = library.trips.filter { SavedNameSearch.matches(query, trip: $0) }
            if !trips.isEmpty {
                Section {
                    ForEach(trips) { trip in
                        Button { chooseTrip(trip) } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Label(trip.name, systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                                Text("\(trip.originName) → \(trip.destinationName)").font(.caption).foregroundStyle(.secondary)
                            }.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading).contentShape(Rectangle())
                        }.disabled(session.journey != nil || session.isBusy)
                    }
                } header: { Text("Your saved trips") } footer: {
                    Text(session.journey != nil ? "Stop your current route before opening a saved trip."
                         : "Opens the saved trip in the planner. Tap Show Route, then Start Route on the map when you're ready.")
                }
            }
        }
    }

    private func chooseTrip(_ trip: SavedTrip) {
        guard session.journey == nil, !session.isBusy, let onChooseTrip else { return }
        cancelSearch(); searchFocused = false
        DeveloperLogStore.shared.record("recent_route_opened", ["route": trip.id.uuidString])
        onChooseTrip(library.trips.first(where: { $0.id == trip.id }) ?? trip)
        dismiss()
    }

    private func choose(_ place: RoutePlace) {
        DeveloperLogStore.shared.record("route_search_choice", ["screen": title, "place": place.name,
            "latitude": String(place.coordinate.latitude), "longitude": String(place.coordinate.longitude)])
        cancelSearch()
        searchFocused = false
        if onPreviewTeleport != nil {
            selectedPlace = place
            showPlaceActions = true
        } else { openPlanner(place) }
    }

    private func openPlanner(_ place: RoutePlace) {
        DeveloperLogStore.shared.record("route_search_handoff", ["screen": title])
        session.pushNamedRecent(name: place.name, coordinate: place.coordinate)
        onChoose(place)
        selectedPlace = nil
        dismiss()
    }

    private func cancelSearch() {
        searchGeneration = UUID()
        activeSearch?.cancel()
        activeSearch = nil
        searchTask?.cancel()
        searchTask = nil
        isResolving = false
    }

    /// Broad categories use a short nearby query first, then Apple's POI index.
    /// The fallback explicitly labels broader results instead of claiming every restaurant is fast food.
    @MainActor private func response(_ operation: PlaceSearchRequest, request: MKLocalSearch.Request, general: Bool) async throws -> MKLocalSearch.Response {
        var firstError: Error?
        do {
            let result = try await operation.start()
            if !general || !result.mapItems.isEmpty { return result }
        } catch { firstError = error }
        try Task.checkCancellation()
        guard general else { throw firstError ?? NSError(domain: MKErrorDomain, code: Int(MKError.Code.placemarkNotFound.rawValue)) }
        let fallback: PlaceSearchRequest
        if let category = PlaceSearchIntent.category(for: query), request.region.span.latitudeDelta > 0 {
            let nearby = MKLocalPointsOfInterestRequest(center: request.region.center, radius: 12_000)
            nearby.pointOfInterestFilter = MKPointOfInterestFilter(including: category.mapCategories)
            fallback = PlaceSearchRequest(pointsOfInterest: nearby)
            resultNote = category == .food ? "Nearby restaurants. Check each place for its menu and opening hours." : "Nearby places in this category."
        } else {
            let wider = MKLocalSearch.Request()
            PlaceSearchRequest.configure(wider, query: query)
            if request.region.span.latitudeDelta > 0 {
                wider.region = MKCoordinateRegion(center: request.region.center, latitudinalMeters: 40_000, longitudinalMeters: 40_000)
            }
            fallback = PlaceSearchRequest(wider)
        }
        activeSearch = fallback
        return try await fallback.start()
    }

    private func resolve(_ request: MKLocalSearch.Request, chooseSingleResult: Bool) {
        cancelSearch()
        let generation = searchGeneration
        let fallbackName = query
        let search = PlaceSearchRequest(request)
        activeSearch = search
        isResolving = true
        error = nil
        DeveloperLogStore.shared.record("place_search_started", ["kind": chooseSingleResult ? "suggestion" : "general"])
        searchTask = Task { @MainActor in
            do {
                let response = try await self.response(search, request: request, general: !chooseSingleResult)
                guard !Task.isCancelled, generation == searchGeneration else { return }
                isResolving = false
                activeSearch = nil
                // Clear the completed task before user selection can cancel it.
                searchTask = nil
                let matches = response.mapItems.compactMap { item -> PlaceSearchResult? in
                    let coordinate = item.placemark.coordinate
                    guard CLLocationCoordinate2DIsValid(coordinate) else { return nil }
                    let saved = session.savedPins.first { RoutePoint($0.coordinate).distance(to: RoutePoint(coordinate)) <= 5 && !PlaceLabel.isCoordinate($0.name) }
                    let street = [item.placemark.subThoroughfare, item.placemark.thoroughfare].compactMap { $0 }.joined(separator: " ")
                    let address = [street, item.placemark.locality, item.placemark.administrativeArea]
                        .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
                    return PlaceSearchResult(place: RoutePlace(name: saved?.name ?? item.name ?? fallbackName, coordinate: coordinate), address: address)
                }
                DeveloperLogStore.shared.record("place_search_finished", ["results": String(matches.count)])
                guard !matches.isEmpty else {
                    searchResults = []; submittedQuery = fallbackName
                    error = "No matching places found. Try adding a city or a more specific address."
                    return
                }
                if chooseSingleResult, matches.count == 1, let result = matches.first { choose(result.place) }
                else { searchResults = matches; submittedQuery = fallbackName }
            } catch {
                guard !Task.isCancelled, generation == searchGeneration else { return }
                isResolving = false
                activeSearch = nil
                searchTask = nil
                self.error = PlaceSearchRequest.message(for: error)
                DeveloperLogStore.shared.record("place_search_failed", ["domain": (error as NSError).domain, "code": String((error as NSError).code)])
            }
        }
    }
}

private struct PlaceSearchResult: Identifiable {
    let id = UUID()
    let place: RoutePlace
    let address: String
}

private struct DeviceOriginSheet: View {
    @EnvironmentObject private var session: SpoofSession
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var waitedForFix = false
    let onChoose: (RoutePlace) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(session.hasSession
                         ? "Your phone may report the fake location while spoofing. This option uses the device location saved before you started. It might be old—check the time below."
                         : "Uses the latest location your phone reports.")
                    if session.hasSession {
                        Text("This only chooses where the route starts. It doesn't stop or move your current spoof. You can also search for your real starting address.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    ForegroundTimeline { context in
                        if let fix = session.deviceLocationFix,
                           session.hasSession || context.timeIntervalSince(fix.timestamp) < 30 {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 4) {
                                    Text("Recorded")
                                    Text(fix.timestamp, style: .relative)
                                    Text("ago")
                                }.font(.caption).foregroundStyle(.secondary)
                                Text("Accuracy: about \(Int(fix.horizontalAccuracy.rounded())) m")
                                    .font(.caption).foregroundStyle(.secondary)
                                Button {
                                    onChoose(RoutePlace(name: session.hasSession ? "Device location before spoofing" : "Device location",
                                                        coordinate: fix.coordinate))
                                } label: {
                                    Text(session.hasSession ? "Use saved device location" : "Use this location")
                                        .frame(maxWidth: .infinity, minHeight: 44).contentShape(Rectangle())
                                }.buttonStyle(.borderless)
                            }
                        } else if session.hasSession {
                            Text("No earlier device location was saved. Go back and search for your starting address instead.")
                                .foregroundStyle(.secondary)
                        } else if waitedForFix {
                            Text("Your phone hasn't sent a fresh location yet. Allow Location access for Elsepin in iPhone settings, or search for your address.")
                                .foregroundStyle(.secondary)
                        } else { ProgressView("Getting device location…") }
                    }
                }
            }
            .shiftScreen().loggedNavigationTitle("Device location").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .task(id: scenePhase) {
                guard scenePhase == .active else { session.cancelDeviceLocationRefresh(); return }
                waitedForFix = false
                session.refreshDeviceLocation()
                do { try await Task.sleep(nanoseconds: 15_000_000_000) } catch { return }
                waitedForFix = true
            }
            .onDisappear { session.cancelDeviceLocationRefresh() }
        }
    }
}
