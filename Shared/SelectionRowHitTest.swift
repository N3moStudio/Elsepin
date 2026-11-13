import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// Gesture positions and row frames must use the same coordinate space.
/// Prefer containment over center distance so tall rows remain selectable
/// across their whole height. Separator gaps use the nearest row edge.
enum SelectionRowHitTest {
    static func target<ID: Hashable>(y: CGFloat, frames: [ID: CGRect]) -> ID? {
        guard y.isFinite else { return nil }
        let rows = frames.filter {
            $0.value.minY.isFinite && $0.value.maxY.isFinite && $0.value.height > 0
        }.sorted { $0.value.minY < $1.value.minY }
        if let row = rows.first(where: { y >= $0.value.minY && y <= $0.value.maxY }) {
            return row.key
        }
        return rows.min {
            distance(y, from: $0.value) < distance(y, from: $1.value)
        }?.key
    }

    private static func distance(_ y: CGFloat, from frame: CGRect) -> CGFloat {
        max(frame.minY - y, y - frame.maxY, 0)
    }
}
