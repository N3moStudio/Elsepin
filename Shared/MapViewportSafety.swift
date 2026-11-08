import Foundation

/// Validate transient camera samples before building another native map camera.
/// This affects drawing/magnifier presentation, never location commands or speed.
enum MapViewportSafety {
    static func validCamera(latitude: Double, longitude: Double, distance: Double,
                            pitch: Double, heading: Double) -> Bool {
        latitude.isFinite && longitude.isFinite && (-90...90).contains(latitude)
            && (-180...180).contains(longitude) && distance.isFinite && distance > 0
            && pitch.isFinite && (0...90).contains(pitch) && heading.isFinite
    }
}
