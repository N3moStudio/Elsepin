import ActivityKit
import Combine
import Foundation

@MainActor
final class SessionActivityController: ObservableObject {
    static let shared = SessionActivityController()
    @Published private(set) var issue: String?
    private typealias Request = SessionActivityRequest
    private var selection = SessionActivitySelection()
    private var pending: Request?
    private var draining = false
    private var endingIDs: Set<String> = []
    private init() {}

    var isAuthorized: Bool { ActivityAuthorizationInfo().areActivitiesEnabled }

    /// One serial writer prevents a delayed 'active' update overtaking a stop or
    /// failure. Frequent movement updates are coalesced to the latest snapshot.
    func sync(id: UUID, snapshot: SessionSnapshot?) {
        selection.setSession(Request(id: id, snapshot: snapshot))
        enqueueCurrent()
    }

    /// Called from Start pairing while the app is still foregrounded. Activity
    /// creation is synchronous here; waiting for a PIN would be too late because
    /// the user is then in Settings. Reuse a live container rather than show two.
    func beginPairing(owner: UUID, state: PairingActivity, style: String, icon: String) {
        let existing = Activity<LocusActivityAttributes>.activities.first {
            !endingIDs.contains($0.id) && ($0.activityState == .active || $0.activityState == .stale)
        }
        let id = existing?.attributes.sessionID ?? owner
        let snapshot = SessionSnapshot(phase: .connecting, startedAt: state.updatedAt,
            expiresAt: state.visibleUntil, lowPower: false, visualStyle: style, iconDesign: icon, pairing: state)
        selection.beginPairing(owner: owner, request: Request(id: id, snapshot: snapshot))
        if existing == nil, isAuthorized {
            create(id: id, snapshot: snapshot)
        }
        enqueueCurrent()
    }

    func updatePairing(owner: UUID, state: PairingActivity) {
        guard selection.updatePairing(owner: owner, state: state) else { return }
        enqueueCurrent()
    }

    func endPairing(owner: UUID) {
        guard selection.endPairing(owner: owner) else { return }
        enqueueCurrent()
    }

    private func enqueueCurrent() {
        pending = selection.current
        guard !draining else { return }
        draining = true
        Task {
            while let request = pending {
                pending = nil
                await apply(request)
            }
            draining = false
        }
    }

    private func apply(_ request: Request) async {
        let existing = Activity<LocusActivityAttributes>.activities
        for activity in existing where request.snapshot == nil || activity.attributes.sessionID != request.id {
            // A synchronous beginPairing may reuse this container while an older
            // end is suspended. Never apply another old write after suspension.
            guard request == selection.current else { return }
            endingIDs.insert(activity.id)
            var endingState = activity.content.state
            endingState.phase = .idle
            endingState.place = nil
            endingState.islandPlace = nil
            endingState.expiresAt = nil
            endingState.journey = nil
            endingState.remoteFindMy = nil
            endingState.remoteLife360 = nil
            endingState.pairing = nil
            await activity.end(ActivityContent(state: endingState, staleDate: nil), dismissalPolicy: .immediate)
            endingIDs.remove(activity.id)
        }
        guard request == selection.current else { return }
        guard var snapshot = request.snapshot else { issue = nil; return }
        if let pairing = snapshot.pairing, pairing.isExpired(at: Date()) {
            snapshot.pairing?.code = nil
        }
        // A queued payload may already have expired while an older write ended.
        snapshot.phase = snapshot.presentedPhase(at: Date())
        if snapshot.phase != .active { snapshot.journey = nil }
        guard isAuthorized else {
            issue = "Live Activities are disabled in iPhone Settings for Elsepin."
            DeveloperLogStore.shared.record("live_activity_unavailable", ["reason": "not_authorized"])
            return
        }
        let content = ActivityContent(state: snapshot, staleDate: snapshot.expiresAt)
        if let activity = Activity<LocusActivityAttributes>.activities.first(where: {
            $0.attributes.sessionID == request.id && ($0.activityState == .active || $0.activityState == .stale)
        }) {
            // Compare the full evidence payload, including confirmation times
            // and expiry. Fresh acknowledgements must still extend staleDate.
            guard activity.content.state != snapshot || activity.content.staleDate != snapshot.expiresAt else {
                issue = nil
                return
            }
            await activity.update(content)
            DeveloperLogStore.shared.record("live_activity_update_finished", ["meaning": "API returned; not proof of onscreen rendering"])
            issue = nil
        } else {
            create(id: request.id, snapshot: snapshot)
        }
    }

    private func create(id: UUID, snapshot: SessionSnapshot) {
        do {
            _ = try Activity.request(attributes: LocusActivityAttributes(sessionID: id),
                content: ActivityContent(state: snapshot, staleDate: snapshot.expiresAt), pushType: nil)
            DeveloperLogStore.shared.record("live_activity_created")
            issue = nil
        } catch {
            DeveloperLogStore.shared.record("live_activity_request_failed", ["domain": (error as NSError).domain, "code": String((error as NSError).code)])
            issue = "Live Activity unavailable. Open Elsepin and retry; make sure its app extension was kept during installation."
        }
    }
}
