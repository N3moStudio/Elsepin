import Foundation

/// Process-local command gate plus the existing durable unknown-location marker.
/// Termination is not evidence of a clear. UIKit may never deliver its callback.
final class SessionLifetime: @unchecked Sendable {
    static let shared = SessionLifetime(defaults: .standard)
    private let defaults: UserDefaults
    private let lock = NSLock()
    private var terminating = false
    private let unfinishedKey = "locus.unfinishedSession"

    init(defaults: UserDefaults) { self.defaults = defaults }

    var previousLocationMayRemain: Bool { defaults.bool(forKey: unfinishedKey) }
    func locationMayRemain() { defaults.set(true, forKey: unfinishedKey) }
    // Call only after an accepted clear, or proof no location was ever sent.
    func locationCleared() { defaults.set(false, forKey: unfinishedKey) }

    var acceptsCommands: Bool {
        lock.lock(); defer { lock.unlock() }
        return !terminating
    }

    /// Closes queued/new commands without blocking a vendor call already in flight.
    /// The owner must enqueue clear on the SAME serial engine queue after this.
    func beginTermination() -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard !terminating else { return false }
        terminating = true
        return true
    }
}
