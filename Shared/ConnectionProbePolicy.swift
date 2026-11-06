import Foundation

/// Reuse only a short, monotonic liveness check during continuous movement.
/// Explicit starts/teleports and Stop always ask the endpoint again.
enum ConnectionProbePolicy {
    static func needsProbe(explicit: Bool, endpoint: String, previousEndpoint: String?,
                           checkedAt: TimeInterval?, now: TimeInterval) -> Bool {
        guard !explicit, endpoint == previousEndpoint, let checkedAt else { return true }
        let age = now - checkedAt
        return age < 0 || age >= 10
    }
}
