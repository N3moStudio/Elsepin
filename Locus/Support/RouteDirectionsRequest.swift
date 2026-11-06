import MapKit

/// Own the native operation so abandoning a draft also stops network work.
@MainActor final class RouteDirectionsRequest {
    private let directions: MKDirections
    private var timedOut = false
    init(_ request: MKDirections.Request) { directions = MKDirections(request: request) }
    func calculate() async throws -> MKDirections.Response {
        let deadline = Task { @MainActor [weak self] in
            do { try await Task.sleep(for: .seconds(15)) } catch { return }
            self?.timedOut = true
            self?.directions.cancel()
        }
        defer { deadline.cancel() }
        return try await withTaskCancellationHandler {
            do {
                try Task.checkCancellation()
                let response = try await directions.calculate()
                try Task.checkCancellation()
                return response
            } catch {
                try Task.checkCancellation()
                if timedOut { throw URLError(.timedOut) }
                throw error
            }
        } onCancel: { Task { @MainActor in self.directions.cancel() } }
    }
}
