import Foundation
import Combine

@MainActor
final class AppUpdateController: ObservableObject {
    @Published private(set) var state: ReleaseUpdateState
    @Published private(set) var isChecking = false
    @Published private(set) var manualResult: String?
    let installedVersion: String
    let isPrerelease: Bool
    private let checker: StableReleaseChecker
    private var generation = UUID()

    init() {
        checker = StableReleaseChecker()
        state = checker.state
        installedVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        isPrerelease = Bundle.main.object(forInfoDictionaryKey: "ShiftReleaseChannel") as? String == "prerelease"
    }

    var notice: StableRelease? { state.update(for: installedVersion, isPrerelease: isPrerelease, at: Date()) }
    var availableUpdate: StableRelease? {
        state.update(for: installedVersion, isPrerelease: isPrerelease, at: Date(), includeDismissed: true)
    }

    func checkIfDue() async {
        guard !isChecking else { return }
        isChecking = true
        defer { isChecking = false }
        await checker.checkIfDue()
        if state != checker.state { state = checker.state }
    }

    func checkNow() async {
        guard !isChecking else { return }
        if let retry = checker.state.retryAfter, retry > Date() {
            manualResult = "GitHub asked us to wait. Try again after \(retry.formatted(date: .omitted, time: .shortened))."
            return
        }
        isChecking = true
        manualResult = nil
        let requestGeneration = generation
        defer { isChecking = false }
        await checker.checkIfDue(force: true)
        state = checker.state
        guard !Task.isCancelled, generation == requestGeneration else { return }
        if let retry = state.retryAfter, retry > Date() {
            manualResult = "GitHub asked us to wait. Try again after \(retry.formatted(date: .omitted, time: .shortened))."
        }
        else if state.lastCheckFailed { manualResult = "Couldn’t check. Check your connection and try again." }
        else if let update = availableUpdate { manualResult = "Version \(update.version) is available." }
        else if state.release == nil { manualResult = "No official release is listed yet." }
        else { manualResult = "You’re up to date with official releases." }
    }

    func dismiss(_ release: StableRelease) {
        checker.dismiss(release)
        state = checker.state
    }

    func reset() { generation = UUID(); checker.reset(); state = checker.state; manualResult = nil }
}
