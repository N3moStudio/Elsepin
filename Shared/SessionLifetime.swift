import Foundation

/// Process-local command gate plus the existing durable unknown-location marker.
/// Termination is not evidence of a clear. UIKit may never deliver its callback.
final class SessionLifetime: @unchecked Sendable {
    static let shared = SessionLifetime(defaults: .standard,
        markerURL: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("SessionState/location-may-remain"))
    private let defaults: UserDefaults
    private let lock = NSLock()
    private var terminating = false
    private let unfinishedKey = "locus.unfinishedSession"
    private let markerURL: URL?
    private var markerPersisted = false

    init(defaults: UserDefaults, markerURL: URL? = nil) {
        self.defaults = defaults
        self.markerURL = markerURL
        markerPersisted = markerURL.map { FileManager.default.fileExists(atPath: $0.path) } ?? false
    }

    var previousLocationMayRemain: Bool {
        lock.lock(); defer { lock.unlock() }
        return markerPersisted || defaults.bool(forKey: unfinishedKey)
    }
    /// UserDefaults persists asynchronously. Before the native write, also
    /// acknowledge a tiny file on disk so an abrupt process exit cannot forget
    /// an attempted write. Only the first write in a session performs disk I/O.
    @discardableResult func locationMayRemain() -> Bool {
        lock.lock(); defer { lock.unlock() }
        defaults.set(true, forKey: unfinishedKey)
        guard let markerURL, !markerPersisted else { return true }
        do {
            try FileManager.default.createDirectory(at: markerURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data([1]).write(to: markerURL, options: .atomic)
            let file = try FileHandle(forWritingTo: markerURL)
            defer { try? file.close() }
            try file.synchronize()
            markerPersisted = true
            return true
        } catch { return false }
    }
    // Call only after an accepted clear, or proof no location was ever sent.
    func locationCleared() {
        lock.lock(); defer { lock.unlock() }
        if let markerURL, FileManager.default.fileExists(atPath: markerURL.path) {
            do { try FileManager.default.removeItem(at: markerURL) }
            catch { return } // A cleanup failure preserves uncertainty on relaunch.
        }
        markerPersisted = false
        defaults.set(false, forKey: unfinishedKey)
    }

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
