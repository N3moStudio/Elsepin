import Foundation

/// Transient setup state, never a preference or backup field. The code is only
/// supplied by the native pairing callback; it is not a device unlock passcode.
struct PairingActivity: Codable, Hashable {
    enum Stage: String, Codable { case waiting, connected, code }
    static let visibilityLifetime: TimeInterval = 5 * 60
    var stage: Stage
    var code: String?
    var updatedAt: Date
    var visibleUntil: Date

    init(stage: Stage, code: String? = nil, now: Date) {
        self.stage = stage
        self.code = stage == .code && Self.validCode(code) ? code : nil
        updatedAt = now
        visibleUntil = now.addingTimeInterval(Self.visibilityLifetime)
    }

    static func validCode(_ code: String?) -> Bool {
        guard let code, code.utf8.count == 6 else { return false }
        return code.utf8.allSatisfy { (48...57).contains($0) }
    }

    func visibleCode(at now: Date, systemIsStale: Bool = false) -> String? {
        guard stage == .code, !isExpired(at: now, systemIsStale: systemIsStale), Self.validCode(code) else { return nil }
        return code
    }

    func isExpired(at now: Date, systemIsStale: Bool = false) -> Bool {
        systemIsStale || now < updatedAt || now >= visibleUntil
    }

    var title: String {
        switch stage {
        case .waiting: return "Waiting for Settings"
        case .connected: return "Preparing pairing code"
        case .code: return "Pairing code"
        }
    }

    var instruction: String {
        switch stage {
        case .waiting: return "Developer Mode → Pair with Elsepin"
        case .connected: return "Keep the pairing prompt open."
        case .code: return "Enter after your iPhone unlock passcode."
        }
    }
}

struct SessionActivityRequest: Equatable {
    var id: UUID
    var snapshot: SessionSnapshot?
}

/// One activity writer owns both setup and movement. Routine idle-session
/// updates must not dismiss the setup code while the user is in iOS Settings.
struct SessionActivitySelection {
    private(set) var session = SessionActivityRequest(id: UUID(), snapshot: nil)
    private(set) var pairingOwner: UUID?
    private(set) var pairing: SessionActivityRequest?
    var current: SessionActivityRequest { pairing ?? session }

    mutating func setSession(_ request: SessionActivityRequest) { session = request }

    mutating func beginPairing(owner: UUID, request: SessionActivityRequest) {
        pairingOwner = owner
        pairing = request
    }

    @discardableResult
    mutating func updatePairing(owner: UUID, state: PairingActivity) -> Bool {
        guard pairingOwner == owner, var request = pairing, var snapshot = request.snapshot else { return false }
        snapshot.pairing = state
        snapshot.expiresAt = state.visibleUntil
        request.snapshot = snapshot
        pairing = request
        return true
    }

    @discardableResult
    mutating func endPairing(owner: UUID) -> Bool {
        guard pairingOwner == owner else { return false }
        pairingOwner = nil
        pairing = nil
        return true
    }
}
