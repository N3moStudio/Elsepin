import MapKit

/// Own the native operation so abandoning a draft also stops network work.
@MainActor final class RouteDirectionsRequest {
    private let directions: MKDirections
    init(_ request: MKDirections.Request) { directions = MKDirections(request: request) }
    func calculate() async throws -> MKDirections.Response {
        try await withTaskCancellationHandler {
            try Task.checkCancellation()
            let response = try await directions.calculate()
            try Task.checkCancellation()
            return response
        } onCancel: { Task { @MainActor in self.directions.cancel() } }
    }
}
