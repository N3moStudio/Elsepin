import XCTest
@testable import SessionPresentation

final class RouteDirectionsPolicyTests: XCTestCase {
    enum Failure: Error, Equatable { case missing, offline }

    func testCyclingSuccessDoesNotRequestWalking() async throws {
        var calls: [RouteNetwork] = []
        let source = try await RouteDirectionsPolicy.calculate(mode: .eBike, preferWalkingPaths: false,
            cyclingAvailable: true, isMissingPath: { _ in true }) { network, source in
            calls.append(network); return source
        }
        XCTAssertEqual(calls, [.cycling])
        XCTAssertEqual(source, .apple(.cycling))
    }

    func testBothBikeModesUseLabeledWalkingFallbackOnlyAfterMissingCyclingPath() async throws {
        for mode in [TravelMode.cycle, .eBike] {
            var calls: [RouteNetwork] = []
            let source = try await RouteDirectionsPolicy.calculate(mode: mode, preferWalkingPaths: false,
                cyclingAvailable: true, isMissingPath: { ($0 as? Failure) == .missing }) { network, source in
                calls.append(network)
                if network == .cycling { throw Failure.missing }
                return source
            }
            XCTAssertEqual(calls, [.cycling, .walking])
            XCTAssertEqual(source, .walkingForCycling(fallback: true))
            XCTAssertTrue(source.supports(mode))
        }
    }

    func testOfflineAndCancellationDoNotRequestFallback() async {
        let failures: [Error] = [Failure.offline, URLError(.timedOut), CancellationError()]
        for failure in failures {
            var calls = 0
            do {
                let _: RoutePathSource = try await RouteDirectionsPolicy.calculate(mode: .eBike,
                    preferWalkingPaths: false, cyclingAvailable: true,
                    isMissingPath: { ($0 as? Failure) == .missing }) { _, _ in
                    calls += 1; throw failure
                }
                XCTFail("Expected original failure")
            } catch {
                XCTAssertTrue(error is CancellationError || (error as? Failure) == .offline ||
                    (error as? URLError)?.code == .timedOut)
            }
            XCTAssertEqual(calls, 1)
        }
    }

    func testNoCyclingAPIAndExplicitWalkingPreferenceSkipCycling() async throws {
        for explicitWalking in [false, true] {
            var calls: [RouteNetwork] = []
            let source = try await RouteDirectionsPolicy.calculate(mode: .eBike, preferWalkingPaths: explicitWalking,
                cyclingAvailable: false, isMissingPath: { _ in false }) { network, source in
                calls.append(network); return source
            }
            XCTAssertEqual(calls, [.walking])
            XCTAssertEqual(source, .walkingForCycling(fallback: !explicitWalking))
        }
    }

    func testWalkingFailureIsNotReportedAsCyclingOnlyFailure() async {
        var calls = 0
        do {
            let _: RoutePathSource = try await RouteDirectionsPolicy.calculate(mode: .cycle, preferWalkingPaths: false,
                cyclingAvailable: true, isMissingPath: { ($0 as? Failure) == .missing }) { _, _ in
                calls += 1; throw Failure.missing
            }
            XCTFail("Expected no usable bike path")
        } catch { XCTAssertTrue(error is RouteDirectionsPolicy.NoBikePath) }
        XCTAssertEqual(calls, 2)
    }

    func testNetworkFailureDuringWalkingFallbackIsPreserved() async {
        do {
            let _: RoutePathSource = try await RouteDirectionsPolicy.calculate(mode: .eBike,
                preferWalkingPaths: false, cyclingAvailable: true,
                isMissingPath: { ($0 as? Failure) == .missing }) { network, _ in
                if network == .cycling { throw Failure.missing }
                throw URLError(.notConnectedToInternet)
            }
            XCTFail("Expected the walking request's connection error")
        } catch { XCTAssertEqual((error as? URLError)?.code, .notConnectedToInternet) }
    }

    func testDrivingDoesNotUseBikeFallbackEvenWithWalkingPreference() async throws {
        var calls: [RouteNetwork] = []
        let source = try await RouteDirectionsPolicy.calculate(mode: .drive, preferWalkingPaths: true,
            cyclingAvailable: true, isMissingPath: { _ in true }) { network, source in
            calls.append(network); return source
        }
        XCTAssertEqual(calls, [.driving])
        XCTAssertEqual(source, .apple(.driving))
    }
}
