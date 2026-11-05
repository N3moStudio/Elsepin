import Foundation

/// History is optional, local-only and bounded independently of the saved library.
struct RecentRoute: Codable, Identifiable, Equatable {
    var trip: SavedTrip
    var visitedAt: Date
    var id: UUID { trip.id }

    static func kept(_ values: [Self], retention: RecentHistoryRetention, enabled: Bool, now: Date = Date()) -> [Self] {
        guard enabled else { return [] }
        var ids = Set<UUID>()
        var pointCount = 0
        return Array(values.sorted { $0.visitedAt > $1.visitedAt }.filter {
            guard $0.visitedAt.timeIntervalSince1970.isFinite, $0.visitedAt <= now, $0.trip.isValid, retention.keeps(visitedAt: $0.visitedAt, now: now),
                  ids.insert($0.id).inserted, pointCount + $0.trip.points.count <= 100_000 else { return false }
            pointCount += $0.trip.points.count
            return true
        }.prefix(10))
    }
}
