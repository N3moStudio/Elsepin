import CryptoKit
import Foundation
import MetricKit

/// OS-generated evidence only. Reports may arrive later/on a later launch;
/// absence is NOT proof of a clean exit. Nothing is uploaded automatically.
@MainActor final class SystemDiagnosticCollector {
    static let shared = SystemDiagnosticCollector()
    private var owner: AnyObject?
    func start() {
        guard owner == nil else { return }
        if #available(iOS 27.0, *) { owner = ModernSystemDiagnostics() }
        else { owner = LegacySystemDiagnostics() }
    }

    nonisolated static func save(_ data: Data, kind: String) {
        let log = DeveloperLogStore.shared
        guard log.enabled else { return }
        let id = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        guard let chunks = DiagnosticReportChunks.encode(data) else {
            log.record("system_report_omitted", ["report_id": id, "kind": kind,
                "bytes": String(data.count), "reason": "empty_or_exceeds_256_KiB"])
            return
        }
        log.record("system_report_begin", ["report_id": id, "kind": kind,
            "bytes": String(data.count), "parts": String(chunks.count), "encoding": "base64"])
        for (index, chunk) in chunks.enumerated() {
            log.record("system_report_part", ["report_id": id, "index": String(index), "data": chunk])
        }
        log.record("system_report_end", ["report_id": id, "parts": String(chunks.count)])
        log.maintenance(flush: true)
    }
}

@available(iOS 27.0, *)
@MainActor private final class ModernSystemDiagnostics {
    private let manager = MetricManager()
    private var tasks: [Task<Void, Never>] = []
    init() {
        let manager = manager
        tasks = [Task {
            for await report in manager.diagnosticReports {
                guard !Task.isCancelled else { return }
                if let data = try? JSONEncoder().encode(report) {
                    SystemDiagnosticCollector.save(data, kind: "diagnostic")
                }
            }
        }, Task {
            for await report in manager.metricReports {
                guard !Task.isCancelled else { return }
                if let data = try? JSONEncoder().encode(report) {
                    SystemDiagnosticCollector.save(data, kind: "daily_metrics")
                }
            }
        }]
    }
    deinit { tasks.forEach { $0.cancel() } }
}

@available(iOS, introduced: 14.0, obsoleted: 27.0)
private final class LegacySystemDiagnostics: NSObject, MXMetricManagerSubscriber {
    override init() { super.init(); MXMetricManager.shared.add(self) }
    deinit { MXMetricManager.shared.remove(self) }
    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for report in payloads { SystemDiagnosticCollector.save(report.jsonRepresentation(), kind: "diagnostic") }
    }
    func didReceive(_ payloads: [MXMetricPayload]) {
        for report in payloads { SystemDiagnosticCollector.save(report.jsonRepresentation(), kind: "daily_metrics") }
    }
}
