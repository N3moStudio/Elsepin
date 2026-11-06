import Foundation

/// Visual diameter only. Map coordinates and minimum 44-point hit targets stay unchanged.
enum MapPinSize {
    static let range = 22.0...64.0
    static let defaultValue = 34.0
    static func bounded(_ value: Double) -> Double {
        value.isFinite ? min(range.upperBound, max(range.lowerBound, value)) : defaultValue
    }
}
