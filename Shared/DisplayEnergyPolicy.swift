import Foundation

/// Only optional rendering/waiting work. Never changes movement speed, sample
/// cadence, provider verification, connection keep-alives or recovery windows.
enum DisplayEnergyPolicy {
    static func stopWaitInterval(remaining: Double, foreground: Bool, constrained: Bool) -> Double {
        min(max(0, remaining), foreground ? (constrained ? 2 : 1) : 5)
    }
    static func cameraInterval(lowPower: Bool, thermallyLimited: Bool) -> Double {
        thermallyLimited ? 3 : lowPower ? 2 : 1
    }
}
