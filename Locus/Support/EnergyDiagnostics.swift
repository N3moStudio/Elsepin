import Darwin
import Foundation
import UIKit

/// Foreground diagnostic sample, not a battery meter. CPU is process time and
/// RSS is peak resident memory; neither attributes watts to an individual feature.
struct EnergyDiagnostics {
    private var previous: (uptime: Double, cpu: Double)?
    mutating func sample() -> [String: String] {
        let uptime = ProcessInfo.processInfo.systemUptime
        var usage = rusage()
        var result = ["thermal_state": String(ProcessInfo.processInfo.thermalState.rawValue),
            "low_power": String(ProcessInfo.processInfo.isLowPowerModeEnabled),
            "app_active": String(UIApplication.shared.applicationState == .active)]
        if getrusage(RUSAGE_SELF, &usage) == 0 {
            let cpu = Double(usage.ru_utime.tv_sec + usage.ru_stime.tv_sec)
                + Double(usage.ru_utime.tv_usec + usage.ru_stime.tv_usec) / 1_000_000
            result["peak_resident_mb"] = String(format: "%.1f", Double(usage.ru_maxrss) / 1_048_576)
            if let previous, uptime - previous.uptime >= 1, cpu >= previous.cpu {
                result["cpu_percent_one_core"] = String(format: "%.1f", (cpu - previous.cpu) / (uptime - previous.uptime) * 100)
                result["sample_seconds"] = String(format: "%.1f", uptime - previous.uptime)
            }
            previous = (uptime, cpu)
        }
        return result
    }
    mutating func reset() { previous = nil }
}
