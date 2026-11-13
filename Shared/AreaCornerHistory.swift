import Foundation

/// Drawing's Undo still removes the last corner, including a previously saved
/// corner. Redo belongs only to this editor draft and is cleared by a new edit.
struct AreaCornerHistory {
    private(set) var points: [RoutePoint]
    private var removed: [RoutePoint] = []
    var canUndo: Bool { !points.isEmpty }
    var canRedo: Bool { !removed.isEmpty }

    init(_ points: [RoutePoint]) { self.points = points }

    mutating func replace(_ points: [RoutePoint]) {
        guard points != self.points else { return }
        self.points = points
        removed = []
    }

    mutating func undo() {
        guard let point = points.popLast() else { return }
        removed.append(point)
    }

    mutating func redo() {
        guard let point = removed.popLast() else { return }
        points.append(point)
    }
}
