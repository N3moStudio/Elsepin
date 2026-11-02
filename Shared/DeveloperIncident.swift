import Foundation

/// Diagnostic-only identity. Never participates in movement or backup state.
struct RouteDiagnosticAttempt: Equatable {
    enum Kind: String { case marker, retry, undo }
    let id: UUID
    let kind: Kind
    let routeID: UUID?

    init(kind: Kind, routeID: UUID?, id: UUID = UUID()) {
        self.id = id; self.kind = kind; self.routeID = routeID
    }

    func fields(stage: String, details: [String: String] = [:]) -> [String: String] {
        var fields = details
        fields["attempt"] = id.uuidString
        fields["action"] = kind.rawValue
        fields["stage"] = stage
        if let routeID { fields["route"] = routeID.uuidString }
        return fields
    }

    func record(_ stage: String, _ details: [String: String] = [:]) {
        DeveloperLogStore.shared.record("route_interaction", fields(stage: stage, details: details))
    }
}

/// An explicit export of retained evidence, not an always-running recorder.
enum DeveloperIncident {
    static let radius: TimeInterval = 5 * 60
    static let maximumBytes = 8 * 1024 * 1024

    struct Slice {
        var data = Data()
        var events = 0
        var malformedLines = 0
        var truncated = false
    }

    // Stream the capped on-disk log off the main thread. Do not load a whole
    // 256 MiB batch just to export ten minutes. Keep original JSONL records.
    static func read(from url: URL, around moment: Date, marker: String,
                     maximumBytes: Int = maximumBytes) throws -> Slice {
        let reader = try FileHandle(forReadingFrom: url)
        defer { try? reader.close() }
        let lower = moment.addingTimeInterval(-radius).timeIntervalSince1970 * 1000
        let upper = moment.addingTimeInterval(radius).timeIntervalSince1970 * 1000
        var result = Slice(), buffer = Data()
        func consume(_ line: Data) {
            guard !line.isEmpty else { return }
            guard let object = try? JSONSerialization.jsonObject(with: line) as? [String: Any],
                  let milliseconds = object["timeMilliseconds"] as? Double, milliseconds.isFinite,
                  let event = object["event"] as? String else {
                result.malformedLines += 1; return
            }
            let details = object["details"] as? [String: String]
            // A note added later still belongs to this incident. Other notes
            // outside the time window are excluded, including nearby markers.
            let ownNote = event == "problem_note" && details?["marker"] == marker
            guard ownNote || (lower...upper).contains(milliseconds) else { return }
            guard !result.truncated, result.data.count + line.count + 1 <= maximumBytes else {
                result.truncated = true; return
            }
            result.data.append(line); result.data.append(0x0A); result.events += 1
        }
        while let chunk = try reader.read(upToCount: 64 * 1024), !chunk.isEmpty {
            buffer.append(chunk)
            while let newline = buffer.firstIndex(of: 0x0A) {
                consume(Data(buffer[..<newline]))
                buffer.removeSubrange(...newline)
            }
            // Real records are bounded by DeveloperLogEvent. Reject a damaged
            // oversized line instead of letting corrupt storage exhaust memory.
            if buffer.count > 128 * 1024 { throw IncidentExportError.damaged }
        }
        if !buffer.isEmpty { result.malformedLines += 1 }
        return result
    }
}

enum IncidentExportError: LocalizedError {
    case expired, damaged
    var errorDescription: String? {
        switch self {
        case .expired: return "This moment is no longer in the current log. Choose a retained moment or record a new one."
        case .damaged: return "The log contains a damaged record. The full log is still available to export."
        }
    }
}
