import Combine
import Foundation
import UIKit
import UserNotifications

@MainActor
final class AppResetController: ObservableObject {
    @Published private(set) var isResetting = false
    @Published private(set) var revision = UUID()
    @Published var notice: String?
    @Published private(set) var noticeTitle = "Reset"

    func canReset(_ session: SpoofSession) -> Bool {
        AppResetRules.canReset(hasSession: session.hasSession,
            busy: session.isBusy || session.reliability.running,
            setupWorkerRunning: LocationEngine.setupCheckIsRunning || PairOnDeviceService.nativeWorkOutstanding,
            iconChanging: ShiftIconController.shared.changing)
    }

    func perform(_ scope: AppResetScope, session: SpoofSession, pairing: PairingStore,
                 preferences: SessionPreferences, library: TripLibrary,
                 privacy: AppPrivacyController, updates: AppUpdateController) async {
        guard !AppDataWorkspace.shared.isDemo, !DevModeController.shared.switching else {
            noticeTitle = "Turn off Dev Mode first"
            notice = "App-wide resets are unavailable while demo data is open. Turn Dev Mode off to manage your real data."
            return
        }
        guard !isResetting, canReset(session) else {
            noticeTitle = "Finish the current session first"
            notice = "Stop spoofing completely and finish any pairing, connection check or icon change before resetting. If pairing was cancelled but is still finishing, reopen Elsepin before trying again."
            return
        }
        isResetting = true
        defer { isResetting = false }
        guard await privacy.authorizeReset(), canReset(session) else {
            noticeTitle = "Reset cancelled"
            notice = "Nothing was reset. Keep Elsepin open and confirm device authentication if app lock is enabled."
            return
        }
        let result = await AppResetRules.execute(scope) { stage in
            // Recheck after every suspension; never erase an unfinished-session marker.
            guard !session.hasSession, !session.isBusy, !session.reliability.running,
                  !LocationEngine.setupCheckIsRunning, !PairOnDeviceService.nativeWorkOutstanding else {
                throw ResetFailure.busy
            }
            switch stage {
            case .trips: try library.resetAll()
            case .deletedItems: try RecentlyDeletedStore.shared.resetAll()
            case .places: session.resetPlacesAndAreas()
            case .recovery: try await session.recovery.resetAll()
            case .diagnostics:
                try await DeveloperLogStore.shared.resetForAppWipe()
                SessionDiagnostics.shared.clear()
                session.reliability.resetAll()
            case .cloudLink:
                guard RemoteFindMyController.shared.unpair() else { throw ResetFailure.credentials }
            case .computerLink:
                guard CompanionClient.shared.unpair() else { throw ResetFailure.credentials }
            case .widgetData: try HomeWidgetPublisher.resetSharedData()
            case .settings:
                AppResetRules.clearPreferences(in: .standard, scope: scope)
                DeveloperLogStore.shared.setEnabled(false)
                preferences.reloadAfterReset()
                session.resetMovementPreferences()
                RemoteFindMyController.shared.resetPreferences()
                CompanionClient.shared.enabled = false
                SessionDiagnostics.shared.recordingEnabled = true
                if scope.wipesData {
                    updates.reset()
                    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                    UNUserNotificationCenter.current().removeAllDeliveredNotifications()
                }
            case .icon: try await ShiftIconController.shared.restoreDefaultForReset()
            case .pairingAndSetup:
                try pairing.removePairing()
                for key in AppResetRules.setupKeys { UserDefaults.standard.removeObject(forKey: key) }
                pairing.lastError = nil
            }
        }
        privacy.preferencesChanged()
        // Recreate planners and settings drafts so old state cannot repopulate wiped storage.
        revision = UUID()
        noticeTitle = result.title
        notice = result.message
    }
    private enum ResetFailure: Error { case busy, credentials }
}
