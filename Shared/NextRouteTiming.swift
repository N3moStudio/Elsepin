import Foundation

/// Automatic continuation is a one-session permission, never restored from disk.
enum NextRouteTiming {
    enum Decision: Equatable { case wait, start, cancel }
    static func decision(now: TimeInterval, due: TimeInterval, connected: Bool,
                         sameRoute: Bool, atOrigin: Bool) -> Decision {
        guard now.isFinite, due.isFinite, connected, sameRoute, atOrigin else { return .cancel }
        guard now >= due else { return .wait }
        // A suspended app must not launch a delayed route unexpectedly much later.
        return now - due <= 30 ? .start : .cancel
    }
}
