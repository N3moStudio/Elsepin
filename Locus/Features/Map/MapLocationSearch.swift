import MapKit
import SwiftUI

/// Search changes the editor's camera only. Polygon points and live movement stay untouched.
struct MapLocationSearch: View {
    var center: CLLocationCoordinate2D?
    let onChoose: (CLLocationCoordinate2D) -> Void
    @EnvironmentObject private var session: SpoofSession
    @State private var query = ""
    @State private var results: [RoutePlace] = []
    @State private var task: Task<Void, Never>?
    @State private var operation: PlaceSearchRequest?
    @State private var busy = false
    @State private var error: String?
    @State private var generation = UUID()
    @FocusState private var focused: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Find an area or nearby place", text: $query).focused($focused).submitLabel(.search).onSubmit(search)
                if busy { Button("Cancel") { cancel() } }
                else { Button("Search", action: search).disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
            }.padding(12).locusGlass(.regular, in: RoundedRectangle(cornerRadius: 14))
            if !query.isEmpty {
                ForEach(session.namedAreas.filter { $0.name.localizedCaseInsensitiveContains(query) }.prefix(4)) { area in
                    if let point = area.points.first { Button { choose(point.coordinate) } label: { Label(area.name, systemImage: "square.dashed").frame(minHeight: 44) } }
                }
                ForEach(results.indices, id: \.self) { index in
                    Button { choose(results[index].coordinate) } label: {
                        Label(results[index].name, systemImage: "mappin").frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                }
                if let error { Text(error).font(.caption).foregroundStyle(LocusTheme.statusWarn) }
            }
        }.onChange(of: query) { _, _ in cancel(); results = []; error = nil }
            .onDisappear { cancel() }
    }
    private func cancel() { generation = UUID(); operation?.cancel(); task?.cancel(); operation = nil; task = nil; busy = false }
    private func choose(_ coordinate: CLLocationCoordinate2D) { cancel(); focused = false; query = ""; results = []; onChoose(coordinate) }
    private func search() {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        cancel(); focused = false; busy = true; error = nil
        let token = generation
        let request = MKLocalSearch.Request()
        PlaceSearchRequest.configure(request, query: text)
        if let center { request.region = MKCoordinateRegion(center: center, latitudinalMeters: 20_000, longitudinalMeters: 20_000) }
        let search = PlaceSearchRequest(request); operation = search
        task = Task { @MainActor in
            do {
                let response = try await search.start()
                guard !Task.isCancelled, generation == token else { return }
                results = response.mapItems.prefix(6).compactMap {
                    guard CLLocationCoordinate2DIsValid($0.placemark.coordinate) else { return nil }
                    return RoutePlace(name: $0.name ?? text, coordinate: $0.placemark.coordinate)
                }
                if results.isEmpty { error = "No places found. Try adding a city." }
            } catch {
                guard !Task.isCancelled, generation == token else { return }
                self.error = PlaceSearchRequest.message(for: error)
            }
            busy = false; operation = nil; task = nil
        }
    }
}
