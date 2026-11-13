import MapKit
import SwiftUI

/// Draft itinerary only. Selecting a result rebuilds the preview; it never
/// redirects an active trip or sends a simulated location.
struct RouteStopSearchSheet: View {
    let route: PlannedRoute
    let browsing: Bool
    let onChoose: (RoutePlace, Bool) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SpoofSession
    @StateObject private var model: RouteStopSearchModel
    @State private var selectedID: UUID?
    @State private var fullMap = false
    @State private var pendingMapPlace: RoutePlace?
    @State private var visibleRegion: MKCoordinateRegion?
    @State private var resultPosition: MapCameraPosition = .automatic
    @FocusState private var searchFocused: Bool

    init(route: PlannedRoute, browsing: Bool = false, onChoose: @escaping (RoutePlace, Bool) -> Void) {
        self.route = route
        self.browsing = browsing
        self.onChoose = onChoose
        _model = StateObject(wrappedValue: RouteStopSearchModel(track: route.track))
    }

    var body: some View {
        List {
            Section {
                RouteStopSearchScopeControls(model: model, visibleRegion: visibleRegion) { region in
                    resultPosition = .region(region)
                }
                resultMap
                if let selectedID, let result = model.results.first(where: { $0.id == selectedID }) {
                    resultRow(result)
                }
            }.shiftSettingsRows()
            if model.query.isEmpty {
                Section("Find a stop") {
                    ForEach(["Fast food", "Coffee", "Groceries", "Parks"], id: \.self) { category in
                        Button(category) { model.query = category; submit() }
                            .frame(minHeight: 44)
                    }
                }.shiftSettingsRows()
            }
            if model.query.isEmpty {
                Section("Saved places") {
                    ForEach(session.favorites) { place in
                        Button(place.displayName) {
                            choose(RoutePlace(name: place.displayName, coordinate: place.coordinate))
                        }.frame(minHeight: 44)
                    }
                }.shiftSettingsRows()
                Section("Recent places") {
                    ForEach(session.recents.prefix(8)) { place in
                        Button(place.displayName) {
                            choose(RoutePlace(name: place.displayName, coordinate: place.coordinate))
                        }.frame(minHeight: 44)
                    }
                }.shiftSettingsRows()
            }
            if model.isSearching {
                Section {
                    HStack {
                        ElsepinProgressLabel("Searching places…", lowPower: session.lowPower)
                        Spacer()
                        Button("Cancel") { model.cancel() }.buttonStyle(.borderless)
                    }.frame(minHeight: 44)
                }.shiftSettingsRows()
            }
            if let message = model.message {
                Section { Text(message).font(.subheadline).foregroundStyle(.secondary) }.shiftSettingsRows()
            }
            if !model.results.isEmpty {
                Section {
                    ForEach(model.results) { result in resultRow(result) }
                } header: {
                    Text(model.scope == .alongRoute ? "Along your route" : model.scope == .mapArea ? "In selected area" : "Search results")
                } footer: {
                    Text(browsing ? "Tap a result to name and save its pin. Your current route keeps going unchanged." : "Distance from the path isn't extra travel distance. Adding a stop recalculates your route preview.")
                }.shiftSettingsRows()
            }
        }
        .shiftSettingsScreen().loggedNavigationTitle(browsing ? "Along your route" : "Find a stop")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .top, spacing: 0) {
            RouteSearchField(query: $model.query, focused: $searchFocused,
                             prompt: "Place, address, or category", submit: submit)
        }
        .onChange(of: model.scope) { _, _ in selectedID = nil }
        .onChange(of: model.query) { _, _ in selectedID = nil }
        .navigationDestination(isPresented: $fullMap) {
            RouteStopMapPicker(route: route, model: model, browsing: browsing) { place in pendingMapPlace = place }
        }
        .onChange(of: fullMap) { _, shown in if !shown { applyMapChoice() } }
        .onAppear { applyMapChoice() }
        .onDisappear { searchFocused = false; model.cancel() }
    }

    private var resultMap: some View {
        Map(position: $resultPosition, selection: $selectedID) {
            MapPolyline(coordinates: route.coordinates).stroke(LocusTheme.accent, lineWidth: 4)
            ForEach(model.results) { result in
                Marker(result.place.name, coordinate: result.place.coordinate).tint(LocusTheme.accentSecondary).tag(result.id)
            }
        }
        .mapStyle(.standard(elevation: .flat)).mapControlVisibility(.hidden)
        .onMapCameraChange(frequency: .onEnd) { visibleRegion = $0.region }
        .frame(height: 200).clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(alignment: .bottomTrailing) {
            Button { searchFocused = false; fullMap = true } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .frame(width: 44, height: 44).locusGlass(.regular, in: Circle())
            }.buttonStyle(.plain).padding(8).accessibilityLabel("Choose stop on full-screen map")
        }
        .accessibilityLabel("Planned route and matching stops. The same places are listed below.")
    }

    private func resultRow(_ result: RouteStopSearchModel.Result) -> some View {
        Button {
            choose(result.place)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.place.name).font(.body.weight(.medium)).foregroundStyle(.primary)
                    if !result.address.isEmpty { Text(result.address).font(.caption).foregroundStyle(.secondary) }
                    if let match = result.match {
                        Text("\(JourneyText.distance(match.metresAway)) from route · \(JourneyText.distance(match.metresAlong)) after start")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 4)
                Image(systemName: browsing ? "mappin.circle.fill" : "plus.circle.fill").foregroundStyle(LocusTheme.accent)
            }.frame(maxWidth: .infinity, minHeight: 52, alignment: .leading).contentShape(Rectangle())
        }.buttonStyle(.borderless).accessibilityHint(browsing ? "Name and save this pin without changing your route" : "Add this stop to the route preview")
    }

    private func choose(_ place: RoutePlace) {
        searchFocused = false
        DeveloperLogStore.shared.record("route_search_choice", ["screen": "Find a stop", "place": place.name,
            "latitude": String(place.coordinate.latitude), "longitude": String(place.coordinate.longitude)])
        model.cancel()
        session.pushNamedRecent(name: place.name, coordinate: place.coordinate)
        onChoose(place, model.scope == .alongRoute)
        dismiss()
    }

    private func applyMapChoice() {
        guard let place = pendingMapPlace else { return }
        pendingMapPlace = nil
        Task { @MainActor in
            await Task.yield()
            choose(place)
        }
    }

    private func submit() { searchFocused = false; selectedID = nil; model.search() }
}

struct RouteStopMapSelection: View {
    let route: PlannedRoute
    let onChoose: (RoutePlace) -> Void
    @StateObject private var model: RouteStopSearchModel
    init(route: PlannedRoute, onChoose: @escaping (RoutePlace) -> Void) {
        self.route = route; self.onChoose = onChoose
        _model = StateObject(wrappedValue: RouteStopSearchModel(track: route.track))
    }
    var body: some View { RouteStopMapPicker(route: route, model: model, browsing: true, onChoose: onChoose) }
}

/// This map only selects a draft stop. Search and map panning never send location commands.
private struct RouteStopMapPicker: View {
    let route: PlannedRoute
    @ObservedObject var model: RouteStopSearchModel
    let browsing: Bool
    let onChoose: (RoutePlace) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var position: MapCameraPosition = .automatic
    @State private var pin: RoutePlace?
    @State private var center: CLLocationCoordinate2D?
    @State private var visibleRegion: MKCoordinateRegion?
    @State private var previewLine: MKPolyline?
    @FocusState private var searchFocused: Bool

    var body: some View {
        MapReader { proxy in
            Map(position: $position, interactionModes: [.pan, .zoom]) {
                if let previewLine { MapPolyline(previewLine).stroke(LocusTheme.accent, lineWidth: 4) }
                ForEach(model.results) { result in
                    Annotation(result.place.name, coordinate: result.place.coordinate) {
                        Button { select(result.place) } label: {
                            Image(systemName: "mappin.circle.fill").font(.title)
                                .foregroundStyle(LocusTheme.accent).frame(width: 44, height: 44)
                        }.buttonStyle(.plain).accessibilityLabel(result.place.name)
                    }
                }
                if let pin { Marker(pin.name, coordinate: pin.coordinate).tint(LocusTheme.accent) }
            }
            .mapStyle(.standard(elevation: .flat)).mapControlVisibility(.hidden)
            .onTapGesture(coordinateSpace: .named("stopPickerMap")) { point in
                guard let coordinate = proxy.convert(point, from: .named("stopPickerMap")) else { return }
                pin = RoutePlace(name: "Dropped pin", coordinate: coordinate)
                searchFocused = false
            }
            .coordinateSpace(name: "stopPickerMap")
            .onMapCameraChange(frequency: .onEnd) { center = $0.region.center; visibleRegion = $0.region }
            .overlay(alignment: .top) { searchResults }
        }
        .onAppear {
            if previewLine == nil {
                previewLine = MKPolyline(coordinates: route.coordinates, count: route.coordinates.count)
                if model.scope == .mapArea, let area = model.searchArea { position = .region(area) }
            }
        }
        .loggedNavigationTitle("Choose stop").navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(spacing: 0) {
                RouteSearchField(query: $model.query, focused: $searchFocused, prompt: "Search places") {
                    searchFocused = false; pin = nil; model.search()
                }
                RouteStopSearchScopeControls(model: model, visibleRegion: visibleRegion) { region in
                    pin = nil; position = .region(region)
                }
                    .padding(.horizontal, 12).padding(.bottom, 6)
            }.background { ShiftSettingsCanvas() }
        }
        .onChange(of: model.query) { _, _ in pin = nil }
        .onChange(of: model.scope) { _, _ in pin = nil }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 6) {
                HStack {
                    Text(pin?.name ?? "Tap the map to drop a pin").font(.subheadline).lineLimit(2)
                    Spacer()
                    Button("Map center") {
                        if let center { pin = RoutePlace(name: "Dropped pin", coordinate: center) }
                    }.font(.caption).frame(minHeight: 44)
                }
                Button(browsing ? "Use this pin" : "Add stop here") {
                    guard let pin else { return }
                    model.cancel(); onChoose(pin); dismiss()
                }.buttonStyle(ShiftActionStyle(compact: true)).disabled(pin == nil)
            }.padding(12).background { ShiftSettingsCanvas() }
        }
        .onDisappear { searchFocused = false; model.cancel() }
    }

    @ViewBuilder private var searchResults: some View {
        if !model.query.isEmpty && (pin == nil || searchFocused) {
            VStack(spacing: 0) {
                if model.isSearching { ProgressView("Searching…").padding(8) }
                if let message = model.message { Text(message).font(.caption).padding(8) }
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(model.results) { result in
                            Button { select(result.place) } label: {
                                Text(result.place.name).frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            }.buttonStyle(.plain)
                            Divider()
                        }
                    }.padding(.horizontal, 12)
                }.frame(maxHeight: 180)
            }.background { ShiftSettingsCanvas() }
        }
    }
    private func select(_ place: RoutePlace) {
        pin = place; searchFocused = false
        position = .region(MKCoordinateRegion(center: place.coordinate, latitudinalMeters: 1200, longitudinalMeters: 1200))
    }
}

/// One explicit search area applies to category buttons and full-screen searches.
/// Panning the stop map doesn't silently replace an area the user chose.
private struct RouteStopSearchScopeControls: View {
    @ObservedObject var model: RouteStopSearchModel
    var visibleRegion: MKCoordinateRegion?
    var onChooseArea: (MKCoordinateRegion) -> Void
    @State private var choosingArea = false
    var body: some View {
        VStack(spacing: 4) {
            Picker("Search area", selection: $model.scope) {
                Text("Along route").tag(RouteStopSearchModel.Scope.alongRoute)
                Text("Everywhere").tag(RouteStopSearchModel.Scope.everywhere)
                if model.searchArea != nil { Text("Map area").tag(RouteStopSearchModel.Scope.mapArea) }
            }.pickerStyle(.segmented)
            Button("Choose map area", systemImage: "map") { choosingArea = true }
                .buttonStyle(.borderless).font(.subheadline).frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        }
        .sheet(isPresented: $choosingArea) {
            PlaceSearchAreaPicker(initialRegion: model.searchArea ?? visibleRegion ?? model.defaultSearchArea) {
                model.chooseSearchArea($0)
                onChooseArea($0)
            }
        }
    }
}

@MainActor
private final class RouteStopSearchModel: ObservableObject {
    enum Scope: Hashable { case alongRoute, everywhere, mapArea }
    struct Result: Identifiable {
        let id = UUID()
        let place: RoutePlace
        let address: String
        let match: RouteSearchCorridor.Match?
    }
    @Published var query = "" { didSet { if query != oldValue { clear() } } }
    @Published var scope = Scope.alongRoute {
        didSet {
            if scope != oldValue {
                clear()
                if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { search() }
            }
        }
    }
    @Published private(set) var searchArea: MKCoordinateRegion?
    @Published private(set) var results: [Result] = []
    @Published private(set) var isSearching = false
    @Published private(set) var message: String?
    private let corridor: RouteSearchCorridor
    private var task: Task<Void, Never>?
    private var activeSearch: PlaceSearchRequest?
    private var generation = UUID()

    init(track: RouteTrack) { corridor = RouteSearchCorridor(track: track) }

    var defaultSearchArea: MKCoordinateRegion {
        if let region = corridor.regions.first {
            return MKCoordinateRegion(center: region.center.coordinate,
                latitudinalMeters: region.diameter, longitudinalMeters: region.diameter)
        }
        return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                                  latitudinalMeters: 20_000, longitudinalMeters: 20_000)
    }

    func chooseSearchArea(_ region: MKCoordinateRegion) {
        guard region.searchBounds.isValid else { return }
        let alreadyInArea = scope == .mapArea
        searchArea = region
        scope = .mapArea
        if alreadyInArea {
            clear()
            if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { search() }
        }
    }

    func cancel() {
        generation = UUID()
        activeSearch?.cancel(); activeSearch = nil
        task?.cancel(); task = nil
        isSearching = false
    }
    private func clear() { cancel(); results = []; message = nil }

    func search() {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        cancel()
        let ticket = generation
        let alongRoute = scope == .alongRoute
        let chosenArea = scope == .mapArea ? searchArea : nil
        guard scope != .mapArea || chosenArea?.searchBounds.isValid == true else {
            message = "Choose a map area first."; return
        }
        let regions: [MKCoordinateRegion?] = alongRoute ? corridor.regions.map {
            MKCoordinateRegion(center: $0.center.coordinate, latitudinalMeters: $0.diameter, longitudinalMeters: $0.diameter)
        } : [chosenArea]
        isSearching = true; message = nil
        task = Task { @MainActor [weak self] in
            guard let self else { return }
            var found: [Result] = []
            var failures = 0
            for region in regions {
                guard !Task.isCancelled, ticket == generation else { return }
                let request = MKLocalSearch.Request()
                PlaceSearchRequest.configure(request, query: text)
                if let region {
                    request.region = region
                    if chosenArea != nil { request.regionPriority = .required }
                }
                let search = PlaceSearchRequest(request)
                activeSearch = search
                do {
                    let response = try await search.start(seconds: 5)
                    guard !Task.isCancelled, ticket == generation else { return }
                    for item in response.mapItems {
                        let point = RoutePoint(item.placemark.coordinate)
                        guard point.isValid else { continue }
                        guard chosenArea?.containsPlace(point.coordinate) ?? true else { continue }
                        let match = corridor.match(point)
                        guard !alongRoute || match != nil else { continue }
                        let name = item.name ?? text
                        guard !found.contains(where: {
                            RouteSearchCorridor.isDuplicate(name: name, point: point, ofName: $0.place.name, point: RoutePoint($0.place.coordinate))
                        }) else { continue }
                        let street = [item.placemark.subThoroughfare, item.placemark.thoroughfare].compactMap { $0 }.joined(separator: " ")
                        let address = [street, item.placemark.locality, item.placemark.administrativeArea].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
                        found.append(Result(place: RoutePlace(name: name, coordinate: point.coordinate), address: address, match: alongRoute ? match : nil))
                    }
                    results = Array(found.prefix(30))
                } catch {
                    guard !Task.isCancelled, ticket == generation else { return }
                    failures += 1
                    DeveloperLogStore.shared.record("route_stop_search_failed", ["domain": (error as NSError).domain, "code": String((error as NSError).code)])
                }
            }
            guard !Task.isCancelled, ticket == generation else { return }
            if alongRoute { found.sort { ($0.match?.metresAlong ?? 0) < ($1.match?.metresAlong ?? 0) } }
            results = Array(found.prefix(30))
            activeSearch = nil; task = nil; isSearching = false
            if failures == regions.count { message = "Search couldn't connect. Try again when you're online." }
            else if failures > 0 { message = "Some areas couldn't be searched. These results may be incomplete; search again to retry." }
            else if alongRoute && corridor.samplesLongRoute { message = "This long route is searched in four areas. Use Everywhere for places between them." }
            else if found.isEmpty {
                message = chosenArea != nil ? "No matches in this map area. Try another category or choose a larger area."
                    : alongRoute ? "No matches near this path. Try another category or search Everywhere." : "No matches. Try adding a city or a more specific address."
            }
        }
    }
}
