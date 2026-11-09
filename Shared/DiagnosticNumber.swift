import Foundation

/// Diagnostics must never trap while converting invalid/out-of-range UI values.
enum DiagnosticNumber {
    static func rounded(_ value: Double) -> String {
        guard value.isFinite else { return "unavailable" }
        guard abs(value) < 1e15 else { return "out_of_range" }
        return String(format: "%.0f", value.rounded(.towardZero))
    }
}
