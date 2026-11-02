import Foundation

/// Main-actor-owned in the app. Intent is separate from checkpoint writes so an
/// explicit Pause/Stop revokes auto-resume even if a queued file save is unfinished.
final class TripResumePolicy {
    private let defaults: UserDefaults
    private let key = "locus.tripRecoveryAutoResume"
    init(defaults: UserDefaults) { self.defaults = defaults }
    func setAllowed(_ allowed: Bool) { defaults.set(allowed, forKey: key) }

    func isEligible(_ checkpoint: TripCheckpoint?, now: Date = Date()) -> Bool {
        guard defaults.bool(forKey: key), let checkpoint, checkpoint.isValid else { return false }
        let age = now.timeIntervalSince(checkpoint.savedAt)
        return age >= 0 && age <= 24 * 60 * 60
    }

    func takeAttempt(_ checkpoint: TripCheckpoint?, now: Date = Date(),
                     foreground: Bool, wifi: Bool, paired: Bool, busy: Bool) -> Bool {
        guard foreground, wifi, paired, !busy, isEligible(checkpoint, now: now) else { return false }
        // Consume before connecting. Failure/relaunch cannot cause a retry loop.
        // Only confirmed playback checkpoints can re-arm automatic recovery.
        setAllowed(false)
        return true
    }
}
