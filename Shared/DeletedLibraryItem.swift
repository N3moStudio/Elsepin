import Foundation

enum DeletedPayload: Codable, Equatable {
    case place(BackupPlace), trip(SavedTrip), area(NamedArea)
    var name: String {
        switch self { case .place(let v): return v.name; case .trip(let v): return v.name; case .area(let v): return v.name }
    }
    var kind: String {
        switch self { case .place: return "Saved place"; case .trip: return "Saved trip"; case .area: return "Named area" }
    }
    var isValid: Bool {
        switch self { case .place(let v): return v.isValid; case .trip(let v): return v.isValid; case .area(let v): return v.isValid }
    }
}

struct DeletedLibraryItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var deletedAt = Date()
    var payload: DeletedPayload
    static let lifetime: TimeInterval = 30 * 24 * 60 * 60
    var expiresAt: Date { deletedAt.addingTimeInterval(Self.lifetime) }
    func isRetained(at now: Date) -> Bool {
        payload.isValid && deletedAt.timeIntervalSince1970.isFinite && expiresAt > now
    }
}

struct DeletedItemsSelection: Equatable {
    var ids: Set<UUID> = []
    mutating func toggle(_ id: UUID) { if !ids.insert(id).inserted { ids.remove(id) } }
    mutating func reconcile(with items: [DeletedLibraryItem], now: Date) {
        ids.formIntersection(items.filter { $0.isRetained(at: now) }.map(\.id))
    }
    mutating func selectAll(_ items: [DeletedLibraryItem], now: Date) {
        ids = Set(items.filter { $0.isRetained(at: now) }.map(\.id))
    }
    func review(_ items: [DeletedLibraryItem], now: Date) -> DeletedItemsDeletion? {
        let chosen = items.filter { ids.contains($0.id) && $0.isRetained(at: now) }
        return chosen.isEmpty ? nil : DeletedItemsDeletion(items: chosen)
    }
}

/// Immutable confirmation scope. A newly deleted item is never added by Select All later.
struct DeletedItemsDeletion: Identifiable {
    let id = UUID()
    let items: [DeletedLibraryItem]
    var summary: String {
        let counts = Dictionary(grouping: items, by: { $0.payload.kind })
        return ["Saved place", "Saved trip", "Named area"].compactMap { kind -> String? in
            guard let count = counts[kind]?.count else { return nil }
            return "\(count) \(kind.lowercased())\(count == 1 ? "" : "s")"
        }.joined(separator: ", ")
    }
    func commit(current: [DeletedLibraryItem], now: Date,
                save: (Data) throws -> Void) throws -> [DeletedLibraryItem] {
        let ids = Set(items.map(\.id))
        guard !items.isEmpty, ids.count == items.count,
              items.allSatisfy({ $0.isRetained(at: now) && current.contains($0) }) else {
            throw DeletionError.changed
        }
        let remaining = current.filter { !ids.contains($0.id) }
        let data = try JSONEncoder().encode(remaining)
        guard data.count <= LibraryBackup.maximumBytes else { throw BackupError.tooLarge }
        try save(data) // One atomic save; callers update memory only after success.
        return remaining
    }
    enum DeletionError: LocalizedError {
        case changed
        var errorDescription: String? { "The selected items changed or expired. Nothing was deleted. Review your selection and try again." }
    }
}
