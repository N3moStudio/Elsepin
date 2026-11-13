import Foundation

/// A missing cycling route may use a labeled walking path. Connection failures
/// and cancellation must propagate, rather than masquerading as missing coverage.
enum RouteDirectionsPolicy {
    struct NoBikePath: Error { }

    static func calculate<Result>(
        mode: TravelMode, preferWalkingPaths: Bool, cyclingAvailable: Bool,
        isMissingPath: (Error) -> Bool,
        request: (RouteNetwork, RoutePathSource) async throws -> Result
    ) async throws -> Result {
        try Task.checkCancellation()
        guard mode.routeNetwork == .cycling else {
            return try await request(mode.routeNetwork, .apple(mode.routeNetwork))
        }
        if preferWalkingPaths {
            return try await request(.walking, .walkingForCycling(fallback: false))
        }
        if cyclingAvailable {
            do { return try await request(.cycling, .apple(.cycling)) }
            catch {
                try Task.checkCancellation()
                guard isMissingPath(error) else { throw error }
            }
        }
        try Task.checkCancellation()
        do { return try await request(.walking, .walkingForCycling(fallback: true)) }
        catch {
            try Task.checkCancellation()
            guard isMissingPath(error) else { throw error }
            throw NoBikePath()
        }
    }
}
