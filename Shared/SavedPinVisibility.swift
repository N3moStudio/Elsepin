import Foundation

/// Visibility follows the ground span of the map, never camera altitude or the
/// distance from the phone. The wider default includes neighborhood overviews.
/// Selected pins, route markers and the simulated location are separate layers.
enum SavedPinVisibility {
    static let rangeMiles = 0.5...20.0
    static let defaultMiles = 5.0
    static let metersPerMile = 1_609.344

    static func boundedMiles(_ value: Double) -> Double {
        value.isFinite ? min(rangeMiles.upperBound, max(rangeMiles.lowerBound, value)) : defaultMiles
    }

    static func mapWidthMeters(mapPoints: Double, metersPerMapPoint: Double) -> Double? {
        let meters = mapPoints * metersPerMapPoint
        guard mapPoints.isFinite, mapPoints > 0, metersPerMapPoint.isFinite,
              metersPerMapPoint > 0, meters.isFinite else { return nil }
        return meters
    }

    static func isVisible(mapWidthMeters: Double?, maximumMiles: Double) -> Bool {
        guard let mapWidthMeters, mapWidthMeters.isFinite, mapWidthMeters > 0 else { return false }
        return mapWidthMeters <= boundedMiles(maximumMiles) * metersPerMile
    }

    static func label(miles: Double) -> String {
        "\(miles.formatted(.number.precision(.fractionLength(0...1)))) mi across"
    }
}
