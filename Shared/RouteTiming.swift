import Foundation

/// Moving time only. Waits are added from RouteStopProgress so a seek, skipped
/// stop or partially completed wait cannot be counted twice. Uses the same
/// acceleration/corner rules as playback; it is not a real-road traffic ETA.
struct RouteTimingProfile {
    struct Sample { let metres: Double; let seconds: Double }
    let samples: [Sample]
    let approximatedTail: Bool
    var seconds: Double { samples.last?.seconds ?? 0 }

    init(track: RouteTrack, mode: TravelMode, speed: Double, smooth: Bool,
         stops: [RouteStop], sections: [RouteTravelSection]) {
        let speed = speed.isFinite && speed > 0 ? speed : mode.baseSpeed
        let sections = RouteTravelSection.valid(sections, length: track.length) ? sections : []
        let boundaries = Array(Set(stops.filter { $0.isValid(length: track.length) }.map(\.metres)
            + sections.map(\.endMetres) + [track.length])).filter { $0 > 0 }.sorted()
        var output = [Sample(metres: 0, seconds: 0)]
        if !smooth {
            // Exact piecewise distance/speed; changing display units never
            // changes the speed used here or in playback.
            var distance = 0.0, seconds = 0.0
            for boundary in boundaries {
                let section = RouteTravelSection.current(in: sections, at: distance)
                seconds += (boundary - distance) / (section?.metresPerSecond ?? speed)
                output.append(Sample(metres: boundary, seconds: seconds))
                distance = boundary
            }
            samples = output; approximatedTail = false
            return
        }
        let motion = RouteMotion(track: track)
        var position = 0.0, elapsed = 0.0, velocity = 0.0
        var boundaryIndex = 0, turnIndex = 0
        // Bound work for pathological imported paths. Long straight sections
        // are integrated analytically; only acceleration/corners need ticks.
        for _ in 0..<12_000 {
            guard position < track.length - 0.001 else { break }
            while boundaryIndex < boundaries.count - 1, boundaries[boundaryIndex] <= position + 0.001 { boundaryIndex += 1 }
            let end = boundaries[boundaryIndex]
            let section = RouteTravelSection.current(in: sections, at: position)
            let currentMode = section?.mode ?? mode, cruise = section?.metresPerSecond ?? speed
            while turnIndex < motion.turns.count, motion.turns[turnIndex].metres < position - 10 { turnIndex += 1 }
            let lookAhead = max(25, cruise * cruise / (2 * RouteMotion.braking(for: currentMode)) + 10)
            let nextTurn = turnIndex < motion.turns.count ? motion.turns[turnIndex].metres : end
            let straight = min(end, nextTurn) - lookAhead - position
            if abs(velocity - cruise) < 0.000001, straight > cruise {
                elapsed += straight / cruise
                position += straight
            } else {
                let target = motion.target(cruise: cruise, position: position, stopAt: end, mode: currentMode)
                let step = RouteMotion.step(speed: velocity, target: target, remaining: end - position,
                                            mode: currentMode, smooth: true)
                guard step.metres > 0 else { break }
                elapsed += RoutePlaybackClock.interval
                position = min(end, position + step.metres)
                velocity = step.speed
            }
            output.append(Sample(metres: position, seconds: elapsed))
        }
        let tail = position < track.length - 0.001
        if tail {
            let cruiseElapsed = sections.isEmpty ? position / speed
                : RouteTravelSection.remainingSeconds(sections, from: 0) - RouteTravelSection.remainingSeconds(sections, from: position)
            let ratio = cruiseElapsed > 0 ? max(1, elapsed / cruiseElapsed) : 1
            // Preserve section speeds in the bounded-work fallback too.
            for boundary in boundaries where boundary > position {
                let section = RouteTravelSection.current(in: sections, at: position)
                elapsed += (boundary - position) / (section?.metresPerSecond ?? speed) * ratio
                output.append(Sample(metres: boundary, seconds: elapsed))
                position = boundary
            }
        }
        samples = output; approximatedTail = tail
    }

    func remaining(from metres: Double) -> Double {
        guard metres.isFinite, let end = samples.last else { return seconds }
        if metres <= 0 { return seconds }
        if metres >= end.metres { return 0 }
        var low = 1, high = samples.count - 1
        while low < high {
            let middle = (low + high) / 2
            if samples[middle].metres < metres { low = middle + 1 } else { high = middle }
        }
        let a = samples[low - 1], b = samples[low]
        let fraction = (metres - a.metres) / (b.metres - a.metres)
        return max(0, seconds - (a.seconds + (b.seconds - a.seconds) * fraction))
    }
}

/// One entry per immutable PlannedRoute. Repeated UI/Activity updates only do
/// a key comparison and binary lookup, not a simulation on every refresh.
final class RouteTimingCache {
    private struct Key: Equatable {
        let routeID: UUID
        let mode: TravelMode
        let speed: Double
        let smooth: Bool
        let stops: [RouteStop]
        let sections: [RouteTravelSection]
    }
    private var stored: (key: Key, profile: RouteTimingProfile)?
    private let lock = NSLock()
    func profile(routeID: UUID, track: RouteTrack, mode: TravelMode, speed: Double,
                 smooth: Bool, stops: [RouteStop], sections: [RouteTravelSection]) -> RouteTimingProfile {
        let key = Key(routeID: routeID, mode: mode, speed: speed, smooth: smooth, stops: stops, sections: sections)
        lock.lock()
        if let stored, stored.key == key { lock.unlock(); return stored.profile }
        lock.unlock()
        let profile = RouteTimingProfile(track: track, mode: mode, speed: speed, smooth: smooth, stops: stops, sections: sections)
        lock.lock(); stored = (key, profile); lock.unlock()
        return profile
    }
}
