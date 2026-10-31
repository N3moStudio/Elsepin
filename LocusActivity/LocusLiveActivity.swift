import ActivityKit
import SwiftUI
import WidgetKit

@main
struct LocusActivityBundle: WidgetBundle {
    var body: some Widget { LocusLiveActivity(); ShiftLocationWidget(); LocusFavoriteWidget(); LocusLibraryWidget() }
}

struct LocusLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LocusActivityAttributes.self) { context in
            ActivityLockScreen(context: context)
                .activityBackgroundTint(ShiftPalette.color(.canvas, style: ShiftVisualStyle(storedValue: context.state.visualStyle), dark: true))
                .activitySystemActionForegroundColor(.white)
                .widgetURL(context.state.pairing == nil ? URL(string: "shift://session") : nil)
        } dynamicIsland: { context in
            let phase = context.state.presentedPhase(at: Date(), systemIsStale: context.isStale)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    ShiftWidgetBrand(design: ShiftIconDesign(rawValue: context.state.iconDesign ?? "")).foregroundStyle(phase.tint(style: ShiftVisualStyle(storedValue: context.state.visualStyle)))
                        .padding(.leading, 6)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.pairing != nil {
                        Text("Setup").font(.caption).foregroundStyle(.secondary).padding(.trailing, 6)
                    } else if let last = context.state.lastConfirmedAt, context.state.islandShowsTimer != false {
                        Text(last, style: .timer)
                            .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                            .frame(width: 54, alignment: .trailing).lineLimit(1)
                            .accessibilityLabel("Time since the last location update was sent")
                            .padding(.trailing, 6)
                    } else {
                        Image(systemName: phase.symbol).foregroundStyle(phase.tint(style: ShiftVisualStyle(storedValue: context.state.visualStyle)))
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if let pairing = context.state.pairing {
                        PairingActivityDetails(pairing: pairing, systemIsStale: context.isStale)
                            .padding(.horizontal, 14).padding(.top, 4).padding(.bottom, 6)
                    } else {
                        ActivityDetails(state: context.state, phase: phase, place: context.state.islandPlace,
                                    journey: context.state.visibleJourney(onIsland: true, at: Date(), systemIsStale: context.isStale),
                                    systemIsStale: context.isStale)
                        .padding(.horizontal, 14).padding(.top, 4).padding(.bottom, 6)
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.pairing == nil ? phase.symbol : "key.fill")
                    .foregroundStyle(phase.tint(style: ShiftVisualStyle(storedValue: context.state.visualStyle)))
            } compactTrailing: {
                // A system-rendered timer reports the age of a historical fact,
                // even when iOS delays host updates or the stale presentation.
                if let pairing = context.state.pairing {
                    Text(pairing.visibleCode(at: Date(), systemIsStale: context.isStale) == nil ? "Pair" : "Code")
                        .font(.caption2).foregroundStyle(.secondary)
                        .accessibilityLabel("Elsepin pairing. Touch and hold for details.")
                } else if context.state.remoteFindMy != nil || context.state.remoteLife360 != nil {
                    ServiceActivityIcons(state: context.state, systemIsStale: context.isStale)
                } else if let last = context.state.lastConfirmedAt, context.state.islandShowsTimer != false,
                   phase == .active || phase == .unverified {
                    Text(last, style: .timer).monospacedDigit()
                        .font(.caption2).foregroundStyle(.secondary).frame(width: 48)
                        .accessibilityLabel("Time since last update; this is not a connection check")
                } else {
                    Image(systemName: phase.symbol).font(.caption2).foregroundStyle(phase.tint(style: ShiftVisualStyle(storedValue: context.state.visualStyle)))
                }
            } minimal: {
                if context.state.pairing != nil {
                    Image(systemName: "key.fill").accessibilityLabel("Elsepin pairing")
                } else if context.state.remoteFindMy != nil || context.state.remoteLife360 != nil {
                    ServiceActivityIcons(state: context.state, systemIsStale: context.isStale)
                } else {
                    Image(systemName: phase.symbol).foregroundStyle(phase.tint(style: ShiftVisualStyle(storedValue: context.state.visualStyle)))
                }
            }
            .widgetURL(context.state.pairing == nil ? URL(string: "shift://session") : nil)
            .keylineTint(phase.tint(style: ShiftVisualStyle(storedValue: context.state.visualStyle)))
        }
    }
}

private struct ActivityLockScreen: View {
    let context: ActivityViewContext<LocusActivityAttributes>
    var body: some View {
        let phase = context.state.presentedPhase(at: Date(), systemIsStale: context.isStale)
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                ShiftWidgetBrand(design: ShiftIconDesign(rawValue: context.state.iconDesign ?? "")).foregroundStyle(phase.tint(style: ShiftVisualStyle(storedValue: context.state.visualStyle)))
                Image(systemName: context.state.pairing == nil ? phase.symbol : "key.fill").font(.caption).foregroundStyle(phase.tint(style: ShiftVisualStyle(storedValue: context.state.visualStyle)))
                Spacer()
                if context.state.lowPower {
                    Image(systemName: "battery.25percent").foregroundStyle(.yellow)
                        .accessibilityLabel("Low Power Mode")
                }
                if let last = context.state.lastConfirmedAt {
                    Text(last, style: .timer)
                        .font(.caption.monospacedDigit()).foregroundStyle(.white.opacity(0.7))
                        .frame(width: 54, alignment: .trailing).lineLimit(1)
                        .accessibilityLabel("Time since the last location update was sent")
                }
            }
            if let pairing = context.state.pairing {
                PairingActivityDetails(pairing: pairing, systemIsStale: context.isStale)
            } else {
                ActivityDetails(state: context.state, phase: phase, place: context.state.place,
                            journey: context.state.visibleJourney(onIsland: false, at: Date(), systemIsStale: context.isStale),
                            systemIsStale: context.isStale)
            }
        }
        .padding(14)
        .foregroundStyle(.white)
    }
}

private struct PairingActivityDetails: View {
    let pairing: PairingActivity
    let systemIsStale: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if pairing.isExpired(at: Date(), systemIsStale: systemIsStale) {
                Text("Open Elsepin to check pairing").font(.headline)
                Text("The code is no longer shown here.").font(.caption).foregroundStyle(.secondary)
            } else {
                Text(pairing.title).font(.headline)
                if let code = pairing.visibleCode(at: Date(), systemIsStale: systemIsStale) {
                    Text(code)
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .monospacedDigit().tracking(5).lineLimit(1).minimumScaleFactor(0.7)
                        .privacySensitive()
                        .accessibilityLabel("Pairing code \(code.map(String.init).joined(separator: " "))")
                }
                Text(pairing.instruction).font(.caption).foregroundStyle(.secondary)
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ActivityDetails: View {
    let state: SessionSnapshot
    let phase: SessionPhase
    let place: String?
    let journey: JourneyActivity?
    var systemIsStale = false
    @Environment(\.dynamicTypeSize) private var textSize
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let journey {
                // Route information gets the available space; connection state
                // stays visible without repeating a headline and two timestamps.
                if !textSize.isAccessibilitySize {
                    Text(place ?? journey.state.title).font(.subheadline.weight(.semibold))
                        .lineLimit(1).privacySensitive()
                }
                HStack(spacing: 8) {
                    Text(journey.state == .moving ? "\(JourneyText.distance(journey.remainingMetres)) left" : journey.state.title)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    if let arrival = journey.estimatedArrival, journey.state == .moving {
                        (Text("ETA ") + Text(arrival, style: .time)).lineLimit(1).layoutPriority(1)
                    }
                }.font(.caption.monospacedDigit())
                ProgressView(value: journey.progress).tint(phase.tint(style: ShiftVisualStyle(storedValue: state.visualStyle)))
                    .accessibilityLabel(journey.state.title)
            }
            HStack(spacing: 6) {
                Label(phase == .active ? "Update sent" : phase.title, systemImage: phase.symbol)
                    .foregroundStyle(phase.tint(style: ShiftVisualStyle(storedValue: state.visualStyle)))
                    .lineLimit(1).layoutPriority(1)
                if state.remoteFindMy == nil && state.remoteLife360 == nil && phase == .active {
                    Text("Apps unchecked").foregroundStyle(.secondary).lineLimit(1)
                }
            }.font(.caption2)
            if let remote = state.remoteFindMy {
                FindMyActivityStatus(remote: remote, systemIsStale: systemIsStale, inlineAge: true)
            }
            if let remote = state.remoteLife360 {
                FindMyActivityStatus(remote: remote, systemIsStale: systemIsStale, life360: true, inlineAge: true)
            }
            if phase == .unverified {
                Text("Open Elsepin to check. Simulation may remain.").font(.caption2).lineLimit(2)
            } else if phase == .disconnected {
                Text("Update failed. The old location may remain.").font(.caption2).lineLimit(2)
            } else if journey == nil, let place {
                Text(place).font(.caption).lineLimit(1).privacySensitive()
            } else if journey == nil, phase != .active {
                Text(state.explanation).font(.caption2).lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ServiceActivityIcons: View {
    let state: SessionSnapshot
    let systemIsStale: Bool
    var body: some View {
        HStack(spacing: 3) {
            if let remote = state.remoteFindMy {
                FindMyActivityStatus(remote: remote, systemIsStale: systemIsStale, compact: true)
            }
            if let remote = state.remoteLife360 {
                FindMyActivityStatus(remote: remote, systemIsStale: systemIsStale, compact: true, life360: true)
            }
        }.font(.caption2).accessibilityElement(children: .combine)
    }
}

private struct FindMyActivityStatus: View {
    let remote: RemoteFindMyActivity
    var systemIsStale = false
    var compact = false
    var life360 = false
    var inlineAge = false
    private var status: RemoteFindMyState { remote.presented(at: Date(), systemIsStale: systemIsStale) }
    private var tint: Color {
        switch status {
        case .match: return .green
        case .different: return .red
        case .ready, .off, .paused: return .secondary
        default: return .orange
        }
    }
    private var symbol: String {
        if life360 {
            switch status {
            case .match: return "person.crop.circle.badge.checkmark"
            case .different, .old, .blocked: return "person.crop.circle.badge.exclamationmark"
            default: return "person.crop.circle.badge.questionmark"
            }
        }
        switch status {
        case .match: return "checkmark.icloud"
        case .different: return "exclamationmark.icloud"
        case .old: return "clock.badge.exclamationmark"
        case .signIn, .pairing: return "lock.icloud"
        default: return "icloud"
        }
    }
    private var shortStatus: String {
        switch status {
        case .match: return "matched"
        case .different: return "differed"
        case .old: return "old report"
        case .signIn: return "sign in"
        case .blocked: return "blocked"
        case .unavailable: return "no recent check"
        case .waiting: return "waiting"
        case .ready: return "ready"
        case .paused: return "paused"
        case .pairing: return "reconnect"
        case .off: return "off"
        }
    }
    var body: some View {
        if compact {
            Image(systemName: symbol).foregroundStyle(tint)
                .accessibilityLabel(remote.title(at: Date(), systemIsStale: systemIsStale, life360: life360))
        } else if inlineAge {
            HStack(spacing: 6) {
                Label("\(life360 ? "Life360" : "Find My"): \(shortStatus)", systemImage: symbol)
                    .foregroundStyle(tint)
                    .lineLimit(1).layoutPriority(1)
                    .accessibilityLabel(remote.title(at: Date(), systemIsStale: systemIsStale, life360: life360))
                Spacer(minLength: 0)
                if let date = remote.reportedAt {
                    Text(date, style: .relative).foregroundStyle(.secondary)
                        .lineLimit(1)
                        .accessibilityLabel(Text("Location report age: ") + Text(date, style: .relative))
                }
            }.font(.caption2)
        } else {
            VStack(alignment: .leading, spacing: 2) {
                Label(remote.title(at: Date(), systemIsStale: systemIsStale, life360: life360), systemImage: symbol)
                    .font(.caption).foregroundStyle(tint)
                if let date = remote.reportedAt {
                    HStack(spacing: 4) { Text(life360 ? "Life360 location age:" : "Apple location age:"); Text(date, style: .relative) }
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
    }
}

private extension SessionPhase {
    func tint(style: ShiftVisualStyle) -> Color {
        switch self {
        case .active: return ShiftPalette.color(.accent, style: style, dark: true)
        case .disconnected: return .red
        case .unverified, .connecting, .reconnecting, .stopping: return .orange
        case .idle: return .secondary
        }
    }
}
