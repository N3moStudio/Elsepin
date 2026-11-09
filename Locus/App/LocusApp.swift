import SwiftUI
import UIKit

@main
struct LocusApp: App {
    @UIApplicationDelegateAdaptor(SessionLifecycleDelegate.self) private var lifecycle
    @StateObject private var session = SpoofSession()
    @StateObject private var pairing = PairingStore()
    @StateObject private var preferences = SessionPreferences.shared
    @StateObject private var privacy = AppPrivacyController()
    @StateObject private var appUpdates = AppUpdateController()
    @StateObject private var reset = AppResetController()
    @StateObject private var demo = DevModeController.shared
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(SetupGate.defaultsKey) private var setupComplete = false
    @AppStorage(SetupGate.deferredKey) private var setupDeferred = false
    @State private var pendingShortcut: LocusShortcut?
    @StateObject private var notificationNavigation = SessionNotificationNavigation.shared
    @State private var pendingImports: [PendingImport] = []

    /// Skipping opens the map without claiming the connection has been verified.
    private var showMap: Bool {
        setupComplete || setupDeferred
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if showMap {
                    RootView(incomingShortcut: $pendingShortcut, incomingSessionDetails: $notificationNavigation.pendingSessionDetails)
                } else {
                    SetupFlowView(initialStep: SetupGate.initialStep(hasPairingFile: pairing.hasPairingFile), onFinished: {
                        finishInitialSetup(verified: true)
                    }, onSkip: {
                        finishInitialSetup(verified: false)
                    })
                }
            }
            .id(reset.revision.uuidString + demo.revision.uuidString)
            .modifier(ElsepinResourceUsage())
            .onAppear { lifecycle.session = session }
            .disabled(reset.isResetting || demo.switching)
            .overlay {
                if reset.isResetting || demo.switching {
                    ZStack {
                        Color.black.opacity(0.12).ignoresSafeArea().contentShape(Rectangle())
                        ProgressView(demo.switching ? "Switching data…" : "Resetting Elsepin…").padding(24).background(ShiftPalette.surface, in: RoundedRectangle(cornerRadius: 16))
                    }.accessibilityAddTraits(.isModal)
                }
            }
            .opacity(privacy.access.isLocked ? 0 : 1)
            .allowsHitTesting(!privacy.access.isLocked)
            .accessibilityHidden(privacy.access.isLocked)
            .modifier(AppearancePresentation())
            .environmentObject(session)
            .environmentObject(session.recovery)
            .environmentObject(session.reliability)
            .environmentObject(pairing)
            .environmentObject(preferences)
            .environmentObject(privacy)
            .environmentObject(appUpdates)
            .environmentObject(reset)
            .loggedAlert(reset.noticeTitle, isPresented: Binding(get: { reset.notice != nil }, set: { if !$0 { reset.notice = nil } })) {
                Button("OK", role: .cancel) { reset.notice = nil }
            } message: { Text(reset.notice ?? "") }
            .onChange(of: reset.revision.uuidString + demo.revision.uuidString) { _, _ in
                pendingShortcut = nil
                notificationNavigation.pendingSessionDetails = false
                for item in pendingImports where item.holdsSecurityScope { item.url.stopAccessingSecurityScopedResource() }
                pendingImports.removeAll()
            }
            .background(PrivacyWindowAnchor(controller: privacy).frame(width: 0, height: 0))
            .background(DeveloperTouchAnchor().frame(width: 0, height: 0))
            .privacySensitive()
            .environment(\.shiftVisualStyle, preferences.visualStyle)
            .environment(\.shiftIconDesign, preferences.iconSelection.design)
            .background(ShiftAppearanceAnchor(style: preferences.visualStyle).frame(width: 0, height: 0))
            .preferredColorScheme(preferences.colorScheme)
            .tint(ShiftPalette.color(.accent, style: preferences.visualStyle))
            .onChange(of: scenePhase) { _, phase in
                DeveloperLogStore.shared.record("scene_changed", ["phase": String(describing: phase)])
                DeveloperLogStore.shared.maintenance(flush: phase != .active)
                privacy.sceneChanged(phase)
                if phase == .inactive { session.becameInactive() }
                if phase == .active {
                    DeveloperLogObserver.shared.snapshot(session: session)
                    ShiftIconController.shared.refresh()
                    guard !reset.isResetting, !demo.switching else { return }
                    session.becameActive(pairing: pairing)
                    session.updateAutomaticRecovery(pairing: pairing, allowed: privacy.canOpenContent && showMap)
                    session.refreshRecentHistory()
                    RecentlyDeletedStore.shared.prune()
                    SessionDiagnostics.shared.recordAppActivity(isActive: true)
                    drainIncoming()
                }
                if phase == .background {
                    session.verification.cancel()
                    session.enteredBackground()
                    SessionDiagnostics.shared.recordAppActivity(isActive: false)
                }
            }
            .onChange(of: preferences.appLockEnabled) { _, _ in privacy.preferencesChanged() }
            .onChange(of: preferences.hideInAppSwitcher) { _, _ in privacy.preferencesChanged() }
            .onChange(of: preferences.saveRecentLocations) { _, _ in session.refreshRecentHistory() }
            .onChange(of: preferences.recentHistoryRetention) { _, _ in session.refreshRecentHistory() }
            .onChange(of: privacy.canOpenContent) { _, allowed in
                if allowed { drainIncoming() }
                session.updateAutomaticRecovery(pairing: pairing, allowed: allowed && showMap && scenePhase == .active && !reset.isResetting)
            }
            .onChange(of: showMap) { _, _ in
                drainIncoming()
                session.updateAutomaticRecovery(pairing: pairing, allowed: privacy.canOpenContent && showMap && scenePhase == .active && !reset.isResetting)
            }
            .onChange(of: pairing.revision) { _, _ in
                session.updateAutomaticRecovery(pairing: pairing, allowed: privacy.canOpenContent && showMap && scenePhase == .active && !reset.isResetting)
            }
            .onChange(of: reset.isResetting) { _, resetting in
                session.updateAutomaticRecovery(pairing: pairing, allowed: privacy.canOpenContent && showMap && scenePhase == .active && !resetting)
            }
            .task(id: scenePhase) {
                guard scenePhase == .active, !reset.isResetting, !demo.switching else { return }
                await appUpdates.checkIfDue()
            }
            .task(id: scenePhase) {
                guard scenePhase == .active else { return }
                while !Task.isCancelled {
                    do { try await Task.sleep(nanoseconds: 60_000_000_000) } catch { return }
                    guard !reset.isResetting, !demo.switching else { continue }
                    DeveloperLogStore.shared.maintenance()
                    DeveloperLogObserver.shared.snapshot(session: session)
                    if preferences.recentHistoryRetention != .forever { session.refreshRecentHistory() }
                }
            }
            .onChange(of: preferences.visualStyle) { _, _ in session.appearanceChanged() }
            .onChange(of: preferences.iconSelection) { _, _ in session.appearanceChanged() }
            .onChange(of: preferences.liveActivities) { _, _ in session.preferencesChanged() }
            .onChange(of: preferences.connectionCheckSeconds) { _, _ in session.connectionCheckIntervalChanged() }
            .onChange(of: preferences.hideLocation) { _, _ in session.preferencesChanged() }
            .onChange(of: preferences.hideIslandLocation) { _, _ in session.preferencesChanged() }
            .onChange(of: preferences.lockScreenProgress) { _, _ in session.preferencesChanged() }
            .onChange(of: preferences.islandProgress) { _, _ in session.preferencesChanged() }
            .onChange(of: preferences.islandTimer) { _, _ in session.preferencesChanged() }
            .onChange(of: preferences.showFindMyStatus) { _, _ in session.preferencesChanged() }
            .onChange(of: preferences.showLife360Status) { _, _ in session.preferencesChanged() }
            .onChange(of: preferences.connectionAlerts) { _, enabled in
                session.preferencesChanged()
                if enabled, !reset.isResetting { session.enableNotifications() }
            }
            .onChange(of: preferences.reminderMinutes) { _, _ in if !reset.isResetting { session.enableNotifications() } }
            .onReceive(NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)) { _ in
                session.updatePowerState()
            }
            .onOpenURL { url in
                guard !reset.isResetting, !demo.switching else { return }
                if ["shift", "locus"].contains(url.scheme?.lowercased() ?? ""), url.host?.lowercased() == "session" {
                    notificationNavigation.pendingSessionDetails = true
                } else { queueIncoming(url) }
            }
            .onAppear {
                ShiftIconController.shared.refresh()
                preferences.publishAppearance()
                UIDevice.current.isBatteryMonitoringEnabled = true
                SessionDiagnostics.shared.observe(session: session, pairing: pairing)
                DeveloperLogObserver.shared.start(session: session)
                privacy.sceneChanged(scenePhase)
                session.becameActive(pairing: pairing)
                session.updateAutomaticRecovery(pairing: pairing, allowed: privacy.canOpenContent && showMap && scenePhase == .active && !reset.isResetting)
                session.refreshRecentHistory()
            }
        }
    }

    private func finishInitialSetup(verified: Bool) {
        if verified {
            SetupGate.markComplete()
            setupComplete = true
            setupDeferred = false
        } else {
            SetupGate.markDeferred()
            setupDeferred = true
        }
    }

    private struct PendingImport {
        let url: URL
        let holdsSecurityScope: Bool
    }

    private func queueIncoming(_ url: URL) {
        guard !reset.isResetting, !demo.switching else { return }
        if let shortcut = LocusShortcut(url: url) { pendingShortcut = shortcut; drainIncoming(); return }
        guard url.isFileURL, ["plist", "mobiledevicepairing", "mobiledevicepair", "gpx"].contains(url.pathExtension.lowercased()) else { return }
        let item = PendingImport(url: url, holdsSecurityScope: url.startAccessingSecurityScopedResource())
        if pendingImports.count == 5 {
            let oldest = pendingImports.removeFirst()
            if oldest.holdsSecurityScope { oldest.url.stopAccessingSecurityScopedResource() }
        }
        pendingImports.append(item)
        drainIncoming()
    }

    private func drainIncoming() {
        guard privacy.canOpenContent, !reset.isResetting else { return }
        // A later run-loop turn lets the map install its import receiver after
        // setup/unlock. Recheck access before processing each queued document.
        DispatchQueue.main.async {
            guard privacy.canOpenContent, !reset.isResetting else { return }
            while let index = pendingImports.firstIndex(where: { showMap || $0.url.pathExtension.lowercased() != "gpx" }) {
                let item = pendingImports.remove(at: index)
                handleIncoming(item.url)
                if item.holdsSecurityScope { item.url.stopAccessingSecurityScopedResource() }
            }
        }
    }

    private func handleIncoming(_ url: URL) {
        guard privacy.canOpenContent, !reset.isResetting else { return }
        let ext = url.pathExtension.lowercased()
        if ["plist", "mobiledevicepairing", "mobiledevicepair"].contains(ext) {
            guard !session.hasSession, !session.isBusy else {
                session.lastError = "Stop spoofing before replacing this iPhone’s pairing file."
                return
            }
            do { try pairing.importPairing(from: url) }
            catch { session.lastError = error.localizedDescription }
        } else if ext == "gpx" {
            NotificationCenter.default.post(name: .locusImportGPX, object: url)
        }
    }
}

/// UIKit does not guarantee this callback on force-quit or system termination.
/// Background/inactive scenes deliberately do not invoke termination cleanup.
@MainActor
final class SessionLifecycleDelegate: NSObject, UIApplicationDelegate {
    weak var session: SpoofSession?

    func applicationWillTerminate(_ application: UIApplication) {
        session?.prepareForTermination()
    }
}

extension Notification.Name {
    static let locusImportGPX = Notification.Name("locusImportGPX")
}
