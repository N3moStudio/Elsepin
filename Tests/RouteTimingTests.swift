import XCTest
@testable import SessionPresentation

final class RouteTimingTests: XCTestCase {
    private func track(_ points: [RoutePoint]) throws -> RouteTrack { try XCTUnwrap(RouteTrack(points)) }
    private func profile(_ route: RouteTrack, speed: Double = SpeedConversion.metresPerSecond(mph: 10),
                         smooth: Bool = false, stops: [RouteStop] = [], sections: [RouteTravelSection] = []) -> RouteTimingProfile {
        RouteTimingProfile(track: route, mode: .eBike, speed: speed, smooth: smooth, stops: stops, sections: sections)
    }

    func testTenMPHMeansSixMinutesPerMileAndUnitSwitchIsEquivalent() throws {
        let metres = 1_609.344 * (40.0 / 6)
        let route = try track([.init(latitude: 0, longitude: 0), .init(latitude: 0, longitude: metres / 6_371_000 * 180 / .pi)])
        XCTAssertEqual(profile(route).seconds, 40 * 60, accuracy: 0.001)
        let speed = SpeedConversion.metresPerSecond(mph: SpeedUnit.kilometersPerHour.mph(from: 16.09344))
        XCTAssertEqual(profile(route, speed: speed).seconds, 40 * 60, accuracy: 0.001)
        XCTAssertEqual(profile(route).remaining(from: route.length / 2), 20 * 60, accuracy: 0.001)
    }

    func testSmoothEstimateAccountsForCornersAndMatchesPlayback() throws {
        let route = try track([.init(latitude: 0, longitude: 0), .init(latitude: 0, longitude: 0.01), .init(latitude: 0.01, longitude: 0.01)])
        let estimate = profile(route, smooth: true)
        XCTAssertGreaterThan(estimate.seconds, profile(route).seconds)
        let motion = RouteMotion(track: route), cruise = SpeedConversion.metresPerSecond(mph: 10)
        var position = 0.0, velocity = 0.0, elapsed = 0.0
        while position < route.length - 0.001, elapsed < 2_000 {
            let target = motion.target(cruise: cruise, position: position, stopAt: route.length, mode: .eBike)
            let step = RouteMotion.step(speed: velocity, target: target, remaining: route.length - position, mode: .eBike, smooth: true)
            position += step.metres; velocity = step.speed; elapsed += 0.5
        }
        XCTAssertEqual(position, route.length, accuracy: 0.001)
        XCTAssertEqual(estimate.seconds, elapsed, accuracy: 2)
        XCTAssertFalse(estimate.approximatedTail)
    }

    func testStopWaitsRemainSeparateFromMovingTime() throws {
        let route = try track([.init(latitude: 0, longitude: 0), .init(latitude: 0, longitude: 0.01)])
        let stop = RouteStop(name: "Stop", metres: route.length / 2, waitSeconds: 45)
        let moving = profile(route, stops: [stop])
        XCTAssertEqual(moving.seconds, profile(route).seconds, accuracy: 0.001)
        XCTAssertGreaterThan(profile(route, smooth: true, stops: [stop]).seconds, profile(route, smooth: true).seconds)
        var progress = RouteStopProgress(); progress.arrive(stop); progress.tick(0.5)
        XCTAssertEqual(moving.remaining(from: stop.metres) + progress.remainingWait(in: [stop]), moving.seconds / 2 + 44.5, accuracy: 0.001)
        progress.seek(to: stop.metres + 1, stops: [stop])
        XCTAssertEqual(progress.remainingWait(in: [stop]), 0)
    }

    func testDifferentSectionSpeedsSurviveSeeks() throws {
        let route = try track([.init(latitude: 0, longitude: 0), .init(latitude: 0, longitude: 0.01)])
        let sections = [RouteTravelSection(id: UUID(), startMetres: 0, endMetres: route.length / 2, mode: .walk, speedMPH: 3),
                        RouteTravelSection(id: UUID(), startMetres: route.length / 2, endMetres: route.length, mode: .eBike, speedMPH: 10)]
        let estimate = profile(route, sections: sections)
        XCTAssertEqual(estimate.seconds, RouteTravelSection.remainingSeconds(sections, from: 0), accuracy: 0.001)
        XCTAssertEqual(estimate.remaining(from: route.length * 0.75), RouteTravelSection.remainingSeconds(sections, from: route.length * 0.75), accuracy: 0.001)
        XCTAssertEqual(estimate.remaining(from: route.length), 0)
        XCTAssertEqual(estimate.remaining(from: .nan), estimate.seconds)
    }

    func testLongStraightRouteDoesNotRequirePerHalfSecondWork() throws {
        let route = try track([.init(latitude: 0, longitude: 0), .init(latitude: 0, longitude: 10)])
        let estimate = profile(route, smooth: true)
        XCTAssertLessThan(estimate.samples.count, 100)
        XCTAssertFalse(estimate.approximatedTail)
        XCTAssertGreaterThan(estimate.seconds, profile(route).seconds)
        XCTAssertLessThan(estimate.seconds - profile(route).seconds, 10)
    }

    func testCacheInvalidatesAfterSpeedAndSmoothChanges() throws {
        let route = try track([.init(latitude: 0, longitude: 0), .init(latitude: 0, longitude: 0.01)])
        let cache = RouteTimingCache(), id = UUID()
        func cached(_ speed: Double, _ smooth: Bool) -> RouteTimingProfile {
            cache.profile(routeID: id, track: route, mode: .eBike, speed: speed, smooth: smooth, stops: [], sections: [])
        }
        XCTAssertEqual(cached(10, false).seconds * 2, cached(5, false).seconds, accuracy: 0.001)
        XCTAssertGreaterThan(cached(5, true).seconds, cached(5, false).seconds)
    }
}
