import Foundation

/// A canceled touch cannot resume merely because its control becomes available again.
/// SwiftUI's gesture-state reset opens the gate for the next touch.
struct ControlTouchSession: Equatable {
    private enum Phase { case idle, tracking, interrupted }
    private var phase: Phase = .idle
    var isTracking: Bool { phase == .tracking }
    var isIdle: Bool { phase == .idle }

    mutating func update() -> Bool {
        guard phase != .interrupted else { return false }
        phase = .tracking
        return true
    }

    @discardableResult mutating func finish() -> Bool {
        let wasTracking = isTracking
        phase = .idle
        return wasTracking
    }

    mutating func interrupt(gestureActive: Bool) {
        if phase != .idle || gestureActive { phase = .interrupted }
    }
}

struct ControlTrayDrag: Equatable {
    private var touch = ControlTouchSession()
    private var isVertical: Bool?
    private(set) var translation: Double = 0
    var isTracking: Bool { touch.isTracking }

    mutating func update(x: Double, y: Double) {
        guard x.isFinite, y.isFinite else {
            interrupt(gestureActive: true)
            return
        }
        guard touch.update() else { return }
        // Decide ownership once; a sideways swipe cannot turn into a tray drag later.
        if isVertical == nil { isVertical = abs(y) > abs(x) * 1.2 }
        if isVertical == true { translation = y }
    }

    mutating func finish(collapsed: Bool, height: Double, predictedY: Double) -> Bool {
        let acceptsRelease = touch.finish() && isVertical == true
        defer { translation = 0; isVertical = nil }
        guard acceptsRelease, height.isFinite, height > 0 else { return collapsed }
        // This is projected displacement in points, not velocity. Use the projected
        // position so a last-moment reversal settles toward the intended anchor.
        let travel = predictedY.isFinite ? predictedY : translation
        let projected = (collapsed ? 0.0 : 1.0) - travel / max(80, height)
        if projected == 0.5 { return collapsed }
        return projected < 0.5
    }

    mutating func interrupt(gestureActive: Bool) {
        touch.interrupt(gestureActive: gestureActive)
        translation = 0
        isVertical = nil
    }

    mutating func gestureDidReset() {
        touch.finish()
        translation = 0
        isVertical = nil
    }
}

struct JoystickInput {
    private var touch = ControlTouchSession()
    private var nudgeID: UUID?
    var isTracking: Bool { touch.isTracking }
    var hasMovement: Bool { touch.isTracking || nudgeID != nil }

    mutating func updateTouch() -> Bool {
        guard touch.update() else { return false }
        nudgeID = nil
        return true
    }

    mutating func finishTouch() -> Bool { touch.finish() }

    mutating func interrupt(gestureActive: Bool) {
        touch.interrupt(gestureActive: gestureActive)
        nudgeID = nil
    }

    mutating func beginNudge() -> UUID? {
        guard touch.isIdle else { return nil }
        let id = UUID()
        nudgeID = id
        return id
    }

    mutating func finishNudge(_ id: UUID) -> Bool {
        guard nudgeID == id else { return false }
        nudgeID = nil
        return true
    }

    static func vector(x: Double, y: Double, radius: Double) -> (x: Double, y: Double) {
        guard x.isFinite, y.isFinite, radius.isFinite, radius > 0 else { return (0, 0) }
        let length = hypot(x, y)
        guard length.isFinite else { return (0, 0) }
        let divisor = max(radius, length)
        return (x / divisor, y / divisor)
    }
}
