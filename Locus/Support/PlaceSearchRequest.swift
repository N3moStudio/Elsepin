import MapKit

/// One owner per native request. Cancellation and deadlines cancel MapKit too;
/// an obsolete request never cancels a replacement search or changes movement.
@MainActor final class PlaceSearchRequest {
    private let search: MKLocalSearch
    private var timedOut = false
    init(_ request: MKLocalSearch.Request) { search = MKLocalSearch(request: request) }
    init(pointsOfInterest request: MKLocalPointsOfInterestRequest) { search = MKLocalSearch(request: request) }
    func cancel() { search.cancel() }
    func start(seconds: Double = 7) async throws -> MKLocalSearch.Response {
        let deadline = Task { @MainActor [weak self] in
            do { try await Task.sleep(for: .seconds(seconds)) } catch { return }
            self?.timedOut = true
            self?.cancel()
        }
        defer { deadline.cancel() }
        return try await withTaskCancellationHandler {
            do {
                try Task.checkCancellation()
                let response = try await search.start()
                try Task.checkCancellation()
                return response
            } catch {
                try Task.checkCancellation()
                if timedOut { throw URLError(.timedOut) }
                throw error
            }
        } onCancel: { Task { @MainActor in self.cancel() } }
    }
    static func configure(_ request: MKLocalSearch.Request, query: String) {
        request.naturalLanguageQuery = PlaceSearchIntent.query(query)
        request.resultTypes = [.address, .pointOfInterest]
        if let category = PlaceSearchIntent.category(for: query) {
            // Exact generic categories intentionally search businesses, not
            // similarly named street addresses. Specific queries keep both.
            request.resultTypes = .pointOfInterest
            request.pointOfInterestFilter = MKPointOfInterestFilter(including: category.mapCategories)
        }
    }
    static func message(for error: Error) -> String {
        if (error as? URLError)?.code == .timedOut { return "Search took too long. Try again, or add a city to narrow the area." }
        if (error as? URLError)?.code == .notConnectedToInternet { return "You're offline. Reconnect and try again; saved pins still work." }
        return "Map search couldn't finish. Check your connection and try again, or add a city."
    }
}

extension PlaceSearchIntent {
    var mapCategories: [MKPointOfInterestCategory] {
        switch self {
        case .food: return [.restaurant]
        case .coffee: return [.cafe]
        case .groceries: return [.foodMarket]
        case .parks: return [.park]
        case .fuel: return [.gasStation]
        }
    }
}
