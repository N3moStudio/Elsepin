import MapKit
import SwiftUI

/// Draft itinerary only. Selecting a result rebuilds the preview; it never
/// redirects an active trip or sends a simulated location.
struct RouteStopSearchSheet: View {
    let route: PlannedRoute
    let onChoose: (RoutePlace, Bool) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SpoofSession
    @StateObject private var model: RouteStopSearchModel
    @State private var selectedID: UUID?
    @FocusState private var searchFocused: Bool

    init(route: PlannedRoute, onChoose: @escaping (RoutePlace, Bool) -> Void) {
        self.route = route
        self.onChoose = onChoose
        _model = StateObject(wrappedValue: RouteStopSearchModel(track: route.track))
    }

    var body: some View {
        List {
            Section {
                Picker("Search area", selection: $model.scope) {
                    Text("Along route").tag(RouteStopSearchModel.Scope.alongRoute)
                    Text("Everywhere").tag(RouteStopSearchModel.Scope.everywhere)
                }.pickerStyle(.segmented)
                resultMap
                if let selectedID, let result = model.results.first(where: { $0.id == selectedID }) {
                    resultRow(result)
                }
            }.shiftSettingsRows()
            if model.query.isEmpty {
                Section("Find a stop") {
                    ForEach(["Coffee", "Food", "Groceries", "Parks"], id: \.self) { category in
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
                    Text(model.scope == .alongRoute ? "Along your route" : "Search results")
                } footer: {
                    Text("Distance from the path isn't extra travel distance. Adding a stop recalculates your route preview.")
                }.shiftSettingsRows()
            }
        }
        .shiftSettingsScreen().loggedNavigationTitle("Find a stop")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $model.query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Place, address, or category")
        .searchFocused($searchFocused)
        .onSubmit(of: .search, submit)
        .onChange(of: model.scope) { _, _ in selectedID = nil; if !model.query.isEmpty { submit() } }
        .onChange(of: model.query) { _, _ in selectedID = nil }
        .onDisappear { model.cancel() }
    }

    private var resultMap: some View {
        Map(initialPosition: .automatic, selection: $selectedID) {
            MapPolyline(coordinates: route.coordinates).stroke(LocusTheme.accent, lineWidth: 4)
            ForEach(model.results) { result in
                Marker(result.place.name, coordinate: result.place.coordinate).tint(LocusTheme.accentSecondary).tag(result.id)
            }
        }
        .mapStyle(.standard(elevation: .flat)).mapControlVisibility(.hidden)
        .frame(height: 200).clipShape(RoundedRectangle(cornerRadius: 16))
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
                Image(systemName: "plus.circle.fill").foregroundStyle(LocusTheme.accent)
            }.frame(maxWidth: .infinity, minHeight: 52, alignment: .leading).contentShape(Rectangle())
        }.buttonStyle(.borderless).accessibilityHint("Add this stop to the route preview")
    }

    private func choose(_ place: RoutePlace) {
        model.cancel()
        session.pushNamedRecent(name: place.name, coordinate: place.coordinate)
        onChoose(place, model.scope == .alongRoute)
        dismiss()
    }

    private func submit() { searchFocused = false; selectedID = nil; model.search() }
}

@MainActor
private final class RouteStopSearchModel: ObservableObject {
    enum Scope: Hashable { case alongRoute, everywhere }
    struct Result: Identifiable {
        let id = UUID()
        let place: RoutePlace
        let address: String
        let match: RouteSearchCorridor.Match?
    }
    @Published var query = "" { didSet { if query != oldValue { clear() } } }
    @Published var scope = Scope.alongRoute { didSet { if scope != oldValue { clear() } } }
    @Published private(set) var results: [Result] = []
    @Published private(set) var isSearching = false
    @Published private(set) var message: String?
    private let corridor: RouteSearchCorridor
    private var task: Task<Void, Never>?
    private var activeSearch: MKLocalSearch?
    private var generation = UUID()

    init(track: RouteTrack) { corridor = RouteSearchCorridor(track: track) }

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
        let regions: [RouteSearchCorridor.Region?] = alongRoute ? corridor.regions.map { Optional($0) } : [nil]
        isSearching = true; message = nil
        task = Task { @MainActor [weak self] in
            guard let self else { return }
            var found: [Result] = []
            var failures = 0
            for region in regions {
                guard !Task.isCancelled, ticket == generation else { return }
                let request = MKLocalSearch.Request()
                request.naturalLanguageQuery = text
                request.resultTypes = [.address, .pointOfInterest]
                if let region {
                    request.region = MKCoordinateRegion(center: region.center.coordinate,
                        latitudinalMeters: region.diameter, longitudinalMeters: region.diameter)
                }
                let search = MKLocalSearch(request: request)
                activeSearch = search
                do {
                    let response = try await search.start()
                    guard !Task.isCancelled, ticket == generation else { return }
                    for item in response.mapItems {
                        let point = RoutePoint(item.placemark.coordinate)
                        guard point.isValid else { continue }
                        let match = corridor.match(point)
                        guard !alongRoute || match != nil else { continue }
                        let name = item.name ?? text
                        guard !found.contains(where: {
                            RouteSearchCorridor.isDuplicate(name: name, point: point, ofName: $0.place.name, point: RoutePoint($0.place.coordinate))
                        }) else { continue }
                        let street = [item.placemark.subThoroughfare, item.placemark.thoroughfare].compactMap { $0 }.joined(separator: " ")
                        let address = [street, item.placemark.locality, item.placemark.administrativeArea].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
                        found.append(Result(place: RoutePlace(name: name, coordinate: point.coordinate), address: address, match: match))
                    }
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
                message = alongRoute ? "No matches near this path. Try another category or search Everywhere." : "No matches. Try adding a city or a more specific address."
            }
        }
    }
}
