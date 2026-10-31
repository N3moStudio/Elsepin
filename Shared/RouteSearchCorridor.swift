import Foundation

/// Search regions are hints to the provider. Filter actual returned coordinates
/// against the path; proximity is never presented as a driving/cycling detour.
struct RouteSearchCorridor {
    struct Region {
        let center: RoutePoint
        let diameter: Double
    }
    struct Match: Equatable {
        let metresAlong: Double
        let metresAway: Double
    }
    let track: RouteTrack
    let index: RouteSnapIndex
    let width: Double

    init(track: RouteTrack, width: Double = 1_500) {
        self.track = track
        index = RouteSnapIndex(track: track)
        self.width = width.isFinite ? max(100, min(10_000, width)) : 1_500
    }

    var samplesLongRoute: Bool { track.length / 4 + width * 2 > 200_000 }

    var regions: [Region] {
        // At most four explicit requests per submitted search, not per keypress.
        let count = min(4, max(1, Int(ceil(min(track.length, 80_000) / 20_000))))
        let span = track.length / Double(count)
        return (0..<count).map {
            Region(center: track.point(at: (Double($0) + 0.5) * span), diameter: min(200_000, span + width * 2))
        }
    }

    func match(_ point: RoutePoint) -> Match? {
        guard let nearest = index.nearest(to: point) else { return nil }
        let distance = track.point(at: nearest.metres).distance(to: point)
        guard distance <= width else { return nil }
        return Match(metresAlong: nearest.metres, metresAway: distance)
    }

    /// Insert into the current itinerary without changing the order of existing
    /// stops (including loop routes). Unmatched places retain append behavior.
    func insertionIndex(for point: RoutePoint, stopMetres: [Double]) -> Int {
        guard let match = match(point) else { return stopMetres.count }
        return stopMetres.firstIndex { $0 > match.metresAlong + 1 } ?? stopMetres.count
    }

    static func isDuplicate(name: String, point: RoutePoint, ofName otherName: String, point other: RoutePoint) -> Bool {
        name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX")) ==
            otherName.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX")) &&
            point.isValid && other.isValid && point.distance(to: other) <= 40
    }
}
