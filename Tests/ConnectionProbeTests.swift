import XCTest
@testable import SessionPresentation
#if canImport(Darwin)
import Darwin
#endif

final class ConnectionProbeTests: XCTestCase {
    func testOnlyContinuousCommandsReuseRecentSameEndpointEvidence() {
        XCTAssertFalse(ConnectionProbePolicy.needsProbe(explicit: false, endpoint: "10.7.0.1", previousEndpoint: "10.7.0.1", checkedAt: 100, now: 101))
        XCTAssertTrue(ConnectionProbePolicy.needsProbe(explicit: true, endpoint: "10.7.0.1", previousEndpoint: "10.7.0.1", checkedAt: 100, now: 101))
        XCTAssertTrue(ConnectionProbePolicy.needsProbe(explicit: false, endpoint: "10.7.0.2", previousEndpoint: "10.7.0.1", checkedAt: 100, now: 101))
        XCTAssertTrue(ConnectionProbePolicy.needsProbe(explicit: false, endpoint: "10.7.0.1", previousEndpoint: "10.7.0.1", checkedAt: 100, now: 110))
        XCTAssertTrue(ConnectionProbePolicy.needsProbe(explicit: false, endpoint: "10.7.0.1", previousEndpoint: "10.7.0.1", checkedAt: 100, now: 99))
        XCTAssertTrue(ConnectionProbePolicy.needsProbe(explicit: false, endpoint: "10.7.0.1", previousEndpoint: nil, checkedAt: nil, now: 101))
    }
    #if canImport(Darwin)
    func testProbeRequiresActualListeningEndpoint() throws {
        let listener = socket(AF_INET, SOCK_STREAM, 0)
        XCTAssertGreaterThanOrEqual(listener, 0)
        guard listener >= 0 else { return }
        var open = true
        defer { if open { close(listener) } }
        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        address.sin_addr.s_addr = inet_addr("127.0.0.1")
        let bound = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(listener, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        XCTAssertEqual(bound, 0)
        XCTAssertEqual(listen(listener, 1), 0)
        var size = socklen_t(MemoryLayout<sockaddr_in>.size)
        let named = withUnsafeMutablePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { getsockname(listener, $0, &size) }
        }
        XCTAssertEqual(named, 0)
        let port = UInt16(bigEndian: address.sin_port)
        XCTAssertTrue(DeveloperTunnelProbe.reaches("127.0.0.1", port: port))
        close(listener); open = false
        let start = Date()
        XCTAssertFalse(DeveloperTunnelProbe.reaches("127.0.0.1", port: port))
        XCTAssertLessThan(Date().timeIntervalSince(start), 3)
        XCTAssertFalse(DeveloperTunnelProbe.reaches("invalid address", port: port))
    }
    #endif
}
