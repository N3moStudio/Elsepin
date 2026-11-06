import Foundation

/// Keep complete OS reports inside the existing bounded JSONL export without
/// losing Unicode at per-field limits. Oversized reports are explicitly omitted,
/// never presented as complete. No credentials or other app data are supplied.
enum DiagnosticReportChunks {
    static let maximumBytes = 256 * 1024
    static func encode(_ data: Data) -> [String]? {
        guard !data.isEmpty, data.count <= maximumBytes else { return nil }
        let text = Array(data.base64EncodedString())
        return stride(from: 0, to: text.count, by: 900).map {
            String(text[$0..<min($0 + 900, text.count)])
        }
    }
}
