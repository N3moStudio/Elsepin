import Darwin
import Foundation
import UIKit
import os

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
            result["voluntary_context_switches"] = String(usage.ru_nvcsw)
            result["involuntary_context_switches"] = String(usage.ru_nivcsw)
            if let previous, uptime - previous.uptime >= 1, cpu >= previous.cpu {
                result["cpu_percent_one_core"] = String(format: "%.1f", (cpu - previous.cpu) / (uptime - previous.uptime) * 100)
                result["sample_seconds"] = String(format: "%.1f", uptime - previous.uptime)
            }
            previous = (uptime, cpu)
        }
        var memory = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let status = withUnsafeMutablePointer(to: &memory) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        if status == KERN_SUCCESS {
            result["resident_mb"] = String(format: "%.1f", Double(memory.resident_size) / 1_048_576)
            result["footprint_mb"] = String(format: "%.1f", Double(memory.phys_footprint) / 1_048_576)
            result["peak_footprint_mb"] = String(format: "%.1f", Double(memory.ledger_phys_footprint_peak) / 1_048_576)
        }
        // Advisory current headroom only. Zero is ambiguous, not unlimited memory.
        let available = os_proc_available_memory()
        result["available_memory_mb"] = available > 0
            ? String(format: "%.1f", Double(available) / 1_048_576) : "zero_or_unavailable"
        result["demo_data"] = String(AppDataWorkspace.shared.isDemo)
        return result
    }
    mutating func reset() { previous = nil }
}
