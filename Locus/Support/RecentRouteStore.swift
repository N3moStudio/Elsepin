import Foundation

/// Serial writes keep an older save from resurrecting history after Clear/Reset.
@MainActor
final class RecentRouteStore {
    static let key = "locus.recentRoutes"
    private static let availableKey = "locus.recentRoutesAvailable"
    private let queue = DispatchQueue(label: "locus.recent-routes", qos: .utility)
    private var revision = UUID()
    private let pending = DispatchGroup()
    func load() -> [RecentRoute] {
        guard AppDataWorkspace.defaults.bool(forKey: Self.availableKey),
              let data = AppDataWorkspace.defaults.data(forKey: Self.key), data.count <= LibraryBackup.maximumBytes,
              let values = try? JSONDecoder().decode([RecentRoute].self, from: data) else { return [] }
        return values
    }
    func finishPendingWrites() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            pending.notify(queue: queue) { continuation.resume() }
        }
    }
    func save(_ values: [RecentRoute]) {
        let workspace = AppDataWorkspace.shared.context
        let key = Self.key
        let availableKey = Self.availableKey
        let token = UUID(); revision = token
        // Revoke reads immediately. Even termination before the queued deletion
        // cannot make cleared history visible at the next launch.
        if values.isEmpty { workspace.defaults.set(false, forKey: availableKey) }
        let pending = pending
        pending.enter()
        queue.async { [weak self] in
            if values.isEmpty { workspace.defaults.removeObject(forKey: key); pending.leave() }
            else if let data = try? JSONEncoder().encode(values), data.count <= LibraryBackup.maximumBytes {
                workspace.defaults.set(data, forKey: key)
                Task { @MainActor [weak self] in
                    defer { pending.leave() }
                    guard self?.revision == token else { return }
                    workspace.defaults.set(true, forKey: availableKey)
                }
            } else { pending.leave() }
        }
    }
}
