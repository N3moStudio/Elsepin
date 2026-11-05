import Foundation

/// Serial writes keep an older save from resurrecting history after Clear/Reset.
@MainActor
final class RecentRouteStore {
    static let key = "locus.recentRoutes"
    private let queue = DispatchQueue(label: "locus.recent-routes", qos: .utility)
    func load() -> [RecentRoute] {
        guard let data = UserDefaults.standard.data(forKey: Self.key), data.count <= LibraryBackup.maximumBytes,
              let values = try? JSONDecoder().decode([RecentRoute].self, from: data) else { return [] }
        return values
    }
    func save(_ values: [RecentRoute]) {
        let key = Self.key
        queue.async {
            if values.isEmpty { UserDefaults.standard.removeObject(forKey: key) }
            else if let data = try? JSONEncoder().encode(values), data.count <= LibraryBackup.maximumBytes {
                UserDefaults.standard.set(data, forKey: key)
            }
        }
    }
}
