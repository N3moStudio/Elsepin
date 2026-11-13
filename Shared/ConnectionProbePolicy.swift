import Foundation

/// Reuse only a short, monotonic liveness check during continuous movement.
/// Explicit starts/teleports and Stop always ask the endpoint again.
enum ConnectionProbePolicy {
    static func needsProbe(explicit: Bool, endpoint: String, previousEndpoint: String?,
                           checkedAt: TimeInterval?, now: TimeInterval, interval: TimeInterval = 10) -> Bool {
        guard !explicit, endpoint == previousEndpoint, let checkedAt else { return true }
        let age = now - checkedAt
        // Respect a shorter user cadence without weakening the existing maximum.
        guard age.isFinite, interval.isFinite else { return true }
        return age < 0 || age >= min(10, max(3, interval))
    }
}
