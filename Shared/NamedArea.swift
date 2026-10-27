import Foundation

enum PlaceLabel {
    static func isCoordinate(_ text: String) -> Bool {
        let parts = text.split(separator: ",")
        return parts.count == 2 && parts.allSatisfy { Double($0.trimmingCharacters(in: .whitespacesAndNewlines)) != nil }
    }
    static func readable(_ text: String, fallback: String = "Saved place") -> String {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty || isCoordinate(value) ? fallback : value
    }
}

/// Local display labels, never a location-monitoring or location-write service.
struct NamedArea: Codable, Equatable, Identifiable {
    var id = UUID()
    var name: String
    var points: [RoutePoint]

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && name.count <= 120 &&
        (3...200).contains(points.count) && points.allSatisfy(\.isValid) &&
        Set(points.map { "\($0.latitude),\($0.longitude)" }).count == points.count && area > 0.000000000001 && !hasCrossingEdges
    }

    // Unwrap around the first vertex so a small area can cross the date line.
    private func x(_ longitude: Double) -> Double {
        guard let first = points.first else { return longitude }
        let delta = longitude - first.longitude
        return delta - 360 * floor((delta + 180) / 360)
    }
    var area: Double {
        guard points.count >= 3 else { return 0 }
        return abs(points.indices.reduce(0.0) { sum, i in
            let a = points[i], b = points[(i + 1) % points.count]
            return sum + x(a.longitude) * b.latitude - x(b.longitude) * a.latitude
        }) / 2
    }
    private var hasCrossingEdges: Bool {
        guard points.count >= 4 else { return false }
        func turn(_ a: RoutePoint, _ b: RoutePoint, _ c: RoutePoint) -> Double {
            (x(b.longitude) - x(a.longitude)) * (c.latitude - a.latitude) -
            (b.latitude - a.latitude) * (x(c.longitude) - x(a.longitude))
        }
        for i in points.indices {
            for j in (i + 1)..<points.count {
                if j == i + 1 || (i == 0 && j == points.count - 1) { continue }
                let a = points[i], b = points[(i + 1) % points.count]
                let c = points[j], d = points[(j + 1) % points.count]
                if turn(a, b, c) * turn(a, b, d) < 0 && turn(c, d, a) * turn(c, d, b) < 0 { return true }
            }
        }
        return false
    }
    func contains(_ point: RoutePoint) -> Bool {
        guard point.isValid, points.count >= 3 else { return false }
        let px = x(point.longitude), py = point.latitude
        var inside = false
        for i in points.indices {
            let a = points[i], b = points[(i + 1) % points.count]
            let ax = x(a.longitude), bx = x(b.longitude)
            let cross = (px - ax) * (b.latitude - a.latitude) - (py - a.latitude) * (bx - ax)
            if abs(cross) < 1e-12 && px >= min(ax, bx) && px <= max(ax, bx) &&
                py >= min(a.latitude, b.latitude) && py <= max(a.latitude, b.latitude) { return true }
            if (a.latitude > py) != (b.latitude > py),
               px < (bx - ax) * (py - a.latitude) / (b.latitude - a.latitude) + ax { inside.toggle() }
        }
        return inside
    }
    static func name(at point: RoutePoint, in areas: [NamedArea]) -> String? {
        // Smallest containing area wins; array order breaks ties deterministically.
        areas.filter { $0.contains(point) }.enumerated().min {
            $0.element.area == $1.element.area ? $0.offset < $1.offset : $0.element.area < $1.element.area
        }?.element.name
    }

    /// Interior intersection. Shared edges/corners are allowed so separate pieces
    /// with the same label can meet without covering the same ground.
    func overlaps(_ other: NamedArea) -> Bool {
        guard points.count >= 3, other.points.count >= 3, let origin = points.first else { return false }
        struct XY { let x: Double; let y: Double }
        let epsilon = 1e-12
        func project(_ points: [RoutePoint]) -> [XY] {
            guard let anchor = points.first else { return [] }
            let offset = RoutePoint.longitudeDelta(anchor.longitude - origin.longitude)
            // Unwrap each outline around its own anchor before aligning them.
            // Otherwise a distant date-line area can appear to span Greenwich.
            return points.map { XY(x: offset + RoutePoint.longitudeDelta($0.longitude - anchor.longitude), y: $0.latitude - origin.latitude) }
        }
        let a = project(points), b = project(other.points)
        func bounds(_ p: [XY]) -> (Double, Double, Double, Double) {
            (p.map(\.x).min()!, p.map(\.x).max()!, p.map(\.y).min()!, p.map(\.y).max()!)
        }
        let aa = bounds(a), bb = bounds(b)
        guard min(aa.1, bb.1) - max(aa.0, bb.0) > epsilon,
              min(aa.3, bb.3) - max(aa.2, bb.2) > epsilon else { return false }
        func cross(_ p: XY, _ q: XY, _ r: XY) -> Double {
            (q.x - p.x) * (r.y - p.y) - (q.y - p.y) * (r.x - p.x)
        }
        func strictInside(_ p: XY, _ polygon: [XY]) -> Bool {
            var inside = false
            for i in polygon.indices {
                let u = polygon[i], v = polygon[(i + 1) % polygon.count]
                if abs(cross(u, v, p)) <= epsilon && p.x >= min(u.x, v.x) - epsilon && p.x <= max(u.x, v.x) + epsilon &&
                    p.y >= min(u.y, v.y) - epsilon && p.y <= max(u.y, v.y) + epsilon { return false }
                if (u.y > p.y) != (v.y > p.y), p.x < (v.x - u.x) * (p.y - u.y) / (v.y - u.y) + u.x { inside.toggle() }
            }
            return inside
        }
        func winding(_ p: [XY]) -> Double {
            p.indices.reduce(0) { $0 + p[$1].x * p[($1 + 1) % p.count].y - p[($1 + 1) % p.count].x * p[$1].y }
        }
        if a.contains(where: { strictInside($0, b) }) || b.contains(where: { strictInside($0, a) }) { return true }
        let sameWinding = winding(a) * winding(b) > 0
        for i in a.indices {
            let u = a[i], v = a[(i + 1) % a.count]
            if strictInside(XY(x: (u.x + v.x) / 2, y: (u.y + v.y) / 2), b) { return true }
            for j in b.indices {
                let s = b[j], t = b[(j + 1) % b.count]
                let c1 = cross(u, v, s), c2 = cross(u, v, t), c3 = cross(s, t, u), c4 = cross(s, t, v)
                func opposite(_ x: Double, _ y: Double) -> Bool { (x > epsilon && y < -epsilon) || (x < -epsilon && y > epsilon) }
                if opposite(c1, c2) && opposite(c3, c4) { return true }
                if abs(c1) <= epsilon && abs(c2) <= epsilon {
                    let alongX = abs(v.x - u.x) >= abs(v.y - u.y)
                    let overlap = alongX ? min(max(u.x, v.x), max(s.x, t.x)) - max(min(u.x, v.x), min(s.x, t.x)) :
                        min(max(u.y, v.y), max(s.y, t.y)) - max(min(u.y, v.y), min(s.y, t.y))
                    let sameDirection = (v.x - u.x) * (t.x - s.x) + (v.y - u.y) * (t.y - s.y) > 0
                    if overlap > epsilon && sameWinding == sameDirection { return true }
                }
            }
        }
        return b.indices.contains { i in
            let u = b[i], v = b[(i + 1) % b.count]
            return strictInside(XY(x: (u.x + v.x) / 2, y: (u.y + v.y) / 2), a)
        }
    }

    func conflictingArea(in areas: [NamedArea]) -> NamedArea? {
        areas.first { $0.id != id && overlaps($0) }
    }
    static func overlapMessage(_ name: String) -> String {
        "This outline overlaps \"\(name)\". Move its corners outside the saved area. Borders can touch, and separate areas can share a name."
    }
    /// Preserve previously saved geometry, including legacy overlapping areas.
    /// New or reshaped outlines must not introduce overlap; renaming is harmless.
    static func newConflict(in proposed: [NamedArea], replacing current: [NamedArea]) -> NamedArea? {
        for area in proposed where !current.contains(where: { $0.id == area.id && $0.points == area.points }) {
            if let conflict = area.conflictingArea(in: proposed) { return conflict }
        }
        return nil
    }
}
