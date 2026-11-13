import Foundation

/// Library pins appear at neighborhood scale, not on city/country overviews.
/// Selected pins, route markers and the simulated location are separate layers.
enum SavedPinVisibility {
    static let maximumCameraDistance = 4_000.0

    static func isVisible(cameraDistance: Double?) -> Bool {
        guard let cameraDistance, cameraDistance.isFinite, cameraDistance > 0 else { return false }
        return cameraDistance <= maximumCameraDistance
    }
}
