import Foundation

/// Serial writes keep an older save from resurrecting history after Clear/Reset.
@MainActor
final class RecentRouteStore {
    static let key = "locus.recentRoutes"
    private static let availableKey = "locus.recentRoutesAvailable"
    private let queue = DispatchQueue(label: "locus.recent-routes", qos: .utility)
    private var revision = UUID()
    func load() -> [RecentRoute] {
        guard UserDefaults.standard.bool(forKey: Self.availableKey),
              let data = UserDefaults.standard.data(forKey: Self.key), data.count <= LibraryBackup.maximumBytes,
              let values = try? JSONDecoder().decode([RecentRoute].self, from: data) else { return [] }
        return values
    }
    func save(_ values: [RecentRoute]) {
        let key = Self.key
        let availableKey = Self.availableKey
        let token = UUID(); revision = token
        // Revoke reads immediately. Even termination before the queued deletion
        // cannot make cleared history visible at the next launch.
        if values.isEmpty { UserDefaults.standard.set(false, forKey: availableKey) }
        queue.async { [weak self] in
            if values.isEmpty { UserDefaults.standard.removeObject(forKey: key) }
            else if let data = try? JSONEncoder().encode(values), data.count <= LibraryBackup.maximumBytes {
                UserDefaults.standard.set(data, forKey: key)
                Task { @MainActor [weak self] in
                    guard self?.revision == token else { return }
                    UserDefaults.standard.set(true, forKey: availableKey)
                }
            }
        }
    }
}
