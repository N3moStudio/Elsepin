import Foundation
import idevice
import UIKit
import UserNotifications
import CoreLocation

/// Runs idevice's iOS 27+ pairable-host flow on-device.
///
/// Advertising uses Network.framework NWListener (Bonjour). Inbound TCP is
/// relayed to the Rust pairable-host on loopback. The 6-digit PIN is created
/// only after that connection + pair-setup handshake.
@MainActor
final class PairOnDeviceService: ObservableObject {
    nonisolated private static let workerGate = AppResetWorkGate()
    static var nativeWorkOutstanding: Bool { workerGate.isBusy }
    enum Phase: Equatable {
        case idle
        case advertising
        case deviceConnected
        case awaitingPIN(String)
        case succeeded
        case failed(String)
    }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var pin: String?
    @Published private(set) var debugPort: UInt16?

    private var worker: Thread?
    private var callbackBox: PairCallbackBox?
    private var activityOwner: UUID?
    private var activityVisibilityTask: Task<Void, Never>?
    private var pinNotificationIdentifier = "locus.pairing.pin.\(UUID().uuidString)"
    private var pinNotificationActive = false
    private var backgroundTask = UIBackgroundTaskIdentifier.invalid
    private let keepAlive = PairingKeepAlive()
    private let audioKeepAlive = SilentAudioKeepAlive()
    private let advertiser = PairableHostAdvertiser()

    var isBusy: Bool {
        switch phase {
        case .advertising, .deviceConnected, .awaitingPIN: return true
        default: return false
        }
    }

    func start(pairingStore: PairingStore, preferences: SessionPreferences) {
        guard !isBusy else { return }
        guard Self.workerGate.begin() else {
            phase = .failed("The previous pairing is still finishing. Close its prompt in iPhone Settings, then try again.")
            return
        }
        phase = .advertising
        pin = nil
        debugPort = nil
        pinNotificationIdentifier = "locus.pairing.pin.\(UUID().uuidString)"
        // A distinct box per attempt prevents a late native callback from an old
        // attempt attaching itself to a new attempt after Cancel/Retry.
        let box = PairCallbackBox()
        box.owner = self
        callbackBox = box

        if preferences.liveActivities {
            let owner = UUID()
            activityOwner = owner
            let state = PairingActivity(stage: .waiting, now: Date())
            SessionActivityController.shared.beginPairing(owner: owner, state: state,
                style: preferences.visualStyle.rawValue, icon: preferences.iconSelection.design.rawValue)
            scheduleActivityExpiry(owner: owner)
        }

        requestNotificationPermission()
        beginKeepAlive()

        _ = pairingStore.pairingURL
        try? FileManager.default.createDirectory(
            at: pairingStore.pairingURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let outputPath = pairingStore.pairingURL.path

        worker = Thread {
            defer { Self.workerGate.end() }
            autoreleasepool {
                Self.runBlockingAccept(outputPath: outputPath, box: box)
            }
        }
        worker?.name = "locus.pairable-host"
        worker?.qualityOfService = .userInitiated
        worker?.start()
    }

    func acknowledgeFailure() {
        if case .failed = phase {
            teardown()
            phase = .idle
            pin = nil
        }
    }

    func resetToIdle() {
        teardown()
        phase = .idle
        pin = nil
        debugPort = nil
    }

    fileprivate func handleListening(
        port: UInt16,
        serviceIdentifier: String,
        name: String,
        model: String,
        authTag: String,
        ver: String,
        minVer: String
    ) {
        guard isBusy else { return }
        debugPort = port
        advertiser.publish(
            port: port,
            serviceIdentifier: serviceIdentifier,
            name: name,
            model: model,
            authTag: authTag,
            ver: ver,
            minVer: minVer
        )
        phase = .advertising
        NSLog("[Elsepin] listening on %u, Bonjour id=%@", port, serviceIdentifier)
    }

    fileprivate func handleConnected() {
        guard isBusy else { return }
        phase = .deviceConnected
        updateActivity(stage: .connected)
        Self.postPlainNotification(
            title: "Elsepin connected",
            body: "Generating pairing code…"
        )
    }

    fileprivate func handlePIN(_ value: String) {
        guard isBusy else { return }
        guard PairingActivity.validCode(value) else {
            handleFailure("Pairing did not return a valid six-digit code. Try again.")
            return
        }
        pin = value
        phase = .awaitingPIN(value)
        updateActivity(stage: .code, code: value)
        postPINNotification(value)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    fileprivate func handleSuccess() {
        guard isBusy else { return }
        pin = nil
        phase = .succeeded
        teardown()
        Self.postPlainNotification(
            title: "Elsepin paired",
            body: "RPPairing is ready. Connect LocalDevVPN, then teleport."
        )
    }

    fileprivate func handleFailure(_ message: String) {
        guard isBusy else { return }
        pin = nil
        phase = .failed(message)
        teardown()
    }

    private func teardown() {
        callbackBox?.owner = nil
        callbackBox = nil
        finishActivity()
        clearPINNotification()
        advertiser.stop()
        endKeepAlive()
    }

    private func updateActivity(stage: PairingActivity.Stage, code: String? = nil) {
        guard let owner = activityOwner else { return }
        SessionActivityController.shared.updatePairing(owner: owner,
            state: PairingActivity(stage: stage, code: code, now: Date()))
        scheduleActivityExpiry(owner: owner)
    }

    private func scheduleActivityExpiry(owner: UUID) {
        activityVisibilityTask?.cancel()
        // One sleep per pairing event, never a polling loop. The extension also
        // hides stale codes if iOS suspends this cleanup task. This is a display
        // lifetime, not a claim about the native protocol's code validity.
        activityVisibilityTask = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(PairingActivity.visibilityLifetime)) }
            catch { return }
            guard let self, self.activityOwner == owner else { return }
            self.finishActivity()
            self.clearPINNotification()
        }
    }

    private func finishActivity() {
        activityVisibilityTask?.cancel()
        activityVisibilityTask = nil
        if let owner = activityOwner { SessionActivityController.shared.endPairing(owner: owner) }
        activityOwner = nil
    }

    private func clearPINNotification() {
        pinNotificationActive = false
        let center = UNUserNotificationCenter.current()
        let identifiers = [pinNotificationIdentifier, "locus.pairing.pin"]
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    private func beginKeepAlive() {
        UIApplication.shared.isIdleTimerDisabled = true
        keepAlive.start()
        audioKeepAlive.start()
        guard backgroundTask == .invalid else { return }
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "locus.pairable-host") { [weak self] in
            self?.finishActivity()
            self?.clearPINNotification()
            self?.endKeepAlive()
        }
    }

    private func endKeepAlive() {
        UIApplication.shared.isIdleTimerDisabled = false
        keepAlive.stop()
        audioKeepAlive.stop()
        guard backgroundTask != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func postPINNotification(_ pin: String) {
        pinNotificationActive = true
        let identifier = pinNotificationIdentifier
        let content = UNMutableNotificationContent()
        content.title = "Elsepin pairing code"
        content.body = pin
        content.sound = .default
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { [weak self] _ in
            // Notification submission is asynchronous too. A late completion
            // must not leave a cancelled code behind or clear a newer attempt.
            Task { @MainActor in
                guard let self, self.isBusy, self.pinNotificationActive,
                      self.pinNotificationIdentifier == identifier else {
                    let center = UNUserNotificationCenter.current()
                    center.removePendingNotificationRequests(withIdentifiers: [identifier])
                    center.removeDeliveredNotifications(withIdentifiers: [identifier])
                    return
                }
            }
        }
    }

    private static func postPlainNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: "locus.pairing.status.\(UUID().uuidString)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    nonisolated private static func runBlockingAccept(outputPath: String, box: PairCallbackBox) {
        let name = "Elsepin"
        let model = "Mac17,7"

        var outFile: OpaquePointer?
        var altIRK = [UInt8](repeating: 0, count: 16)

        let err: UnsafeMutablePointer<IdeviceFfiError>? = name.withCString { namePtr in
            model.withCString { modelPtr in
                pairable_host_accept(
                    namePtr,
                    modelPtr,
                    0,
                    pinDisplayTrampoline,
                    Unmanaged.passUnretained(box).toOpaque(),
                    listeningTrampoline,
                    Unmanaged.passUnretained(box).toOpaque(),
                    connectedTrampoline,
                    Unmanaged.passUnretained(box).toOpaque(),
                    &altIRK,
                    &outFile
                )
            }
        }

        if let err {
            let message: String
            if let cMessage = err.pointee.message {
                message = String(cString: cMessage)
            } else {
                message = "Unknown pairing error (\(err.pointee.code))"
            }
            idevice_error_free(err)
            DispatchQueue.main.async { box.owner?.handleFailure(message) }
            return
        }

        guard let outFile else {
            DispatchQueue.main.async {
                box.owner?.handleFailure("Pairing finished but no pairing file was returned.")
            }
            return
        }

        defer { rp_pairing_file_free(outFile) }

        let parent = (outputPath as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: parent, withIntermediateDirectories: true)

        let writeError = outputPath.withCString { path in
            rp_pairing_file_write(outFile, path)
        }
        if let writeError {
            let message: String
            if let cMessage = writeError.pointee.message {
                message = String(cString: cMessage)
            } else {
                message = "Failed to write pairing file"
            }
            idevice_error_free(writeError)
            DispatchQueue.main.async {
                box.owner?.handleFailure("Paired, but failed to save file: \(message)")
            }
            return
        }

        try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: outputPath)
        DispatchQueue.main.async { box.owner?.handleSuccess() }
    }
}

private final class PairingKeepAlive: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        manager.pausesLocationUpdatesAutomatically = false
        manager.allowsBackgroundLocationUpdates = true
        manager.showsBackgroundLocationIndicator = true
    }

    func start() {
        manager.requestAlwaysAuthorization()
        manager.startUpdatingLocation()
    }

    func stop() {
        manager.stopUpdatingLocation()
    }
}

final class PairCallbackBox: @unchecked Sendable {
    weak var owner: PairOnDeviceService?
}

private func pinDisplayTrampoline(pin: UnsafePointer<CChar>?, context: UnsafeMutableRawPointer?) {
    guard let pin, let context else { return }
    let value = String(cString: pin)
    let box = Unmanaged<PairCallbackBox>.fromOpaque(context).takeUnretainedValue()
    DispatchQueue.main.async { box.owner?.handlePIN(value) }
}

private func listeningTrampoline(
    port: UInt16,
    serviceIdentifier: UnsafePointer<CChar>?,
    name: UnsafePointer<CChar>?,
    model: UnsafePointer<CChar>?,
    authTag: UnsafePointer<CChar>?,
    ver: UnsafePointer<CChar>?,
    minVer: UnsafePointer<CChar>?,
    context: UnsafeMutableRawPointer?
) {
    guard let context else { return }
    let box = Unmanaged<PairCallbackBox>.fromOpaque(context).takeUnretainedValue()
    let values = (
        port,
        serviceIdentifier.map { String(cString: $0) } ?? "",
        name.map { String(cString: $0) } ?? "Elsepin",
        model.map { String(cString: $0) } ?? "Mac17,7",
        authTag.map { String(cString: $0) } ?? "",
        ver.map { String(cString: $0) } ?? "26",
        minVer.map { String(cString: $0) } ?? "17"
    )
    // NetService must be touched on the main thread / runloop.
    DispatchQueue.main.async {
        box.owner?.handleListening(
            port: values.0,
            serviceIdentifier: values.1,
            name: values.2,
            model: values.3,
            authTag: values.4,
            ver: values.5,
            minVer: values.6
        )
    }
}

private func connectedTrampoline(context: UnsafeMutableRawPointer?) {
    guard let context else { return }
    let box = Unmanaged<PairCallbackBox>.fromOpaque(context).takeUnretainedValue()
    DispatchQueue.main.async { box.owner?.handleConnected() }
}
