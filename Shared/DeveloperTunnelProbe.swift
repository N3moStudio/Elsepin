import Foundation
#if canImport(Darwin)
import Darwin

/// A bounded TCP round trip to the configured local developer endpoint. Unlike
/// a VPN icon/interface hint, success means that endpoint accepted a connection.
/// It does NOT prove simulation or what Find My/Life360 reports. Engine queue only.
enum DeveloperTunnelProbe {
    static func reaches(_ ip: String, port: UInt16 = 49152) -> Bool {
        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = in_port_t(port).bigEndian
        guard ip.withCString({ inet_pton(AF_INET, $0, &address.sin_addr) }) == 1 else { return false }
        let fd = socket(AF_INET, SOCK_STREAM, 0)
        guard fd >= 0 else { return false }
        defer { close(fd) }
        let flags = fcntl(fd, F_GETFL)
        guard flags >= 0, fcntl(fd, F_SETFL, flags | O_NONBLOCK) == 0 else { return false }
        let result = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.connect(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        if result == 0 { return true }
        guard errno == EINPROGRESS else { return false }
        var descriptor = pollfd(fd: fd, events: Int16(POLLOUT), revents: 0)
        // The local endpoint completed in 0–3 ms in the build-71 device log.
        // Keep a bounded grace period without a two-second missing-VPN delay.
        guard poll(&descriptor, 1, 750) > 0 else { return false }
        var socketError: Int32 = 0
        var length = socklen_t(MemoryLayout<Int32>.size)
        return getsockopt(fd, SOL_SOCKET, SO_ERROR, &socketError, &length) == 0 && socketError == 0
    }
}
#endif
