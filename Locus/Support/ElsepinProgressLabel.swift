import SwiftUI
import ThinkingOrbsKit

/// A request-owned status label, never an independent loading timer. Call sites
/// remove it when their existing request finishes/cancels; it cannot drive work.
@MainActor
struct ElsepinProgressLabel: View {
    let title: LocalizedStringKey
    var state: OrbState = .searching
    let lowPower: Bool
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var orbSize = 20.0
    @State private var visible = false

    init(_ title: LocalizedStringKey, state: OrbState = .searching, lowPower: Bool) {
        self.title = title
        self.state = state
        self.lowPower = lowPower
    }

    var body: some View {
        HStack(spacing: 8) {
            // Upstream paused rendering uses one static Canvas, without TimelineView.
            ThinkingOrb(state: state, size: .px20, theme: .auto,
                        paused: ProgressMotion.isPaused(visible: visible,
                            active: scenePhase == .active, reduceMotion: reduceMotion,
                            lowPower: lowPower), displaySize: orbSize)
                .accessibilityHidden(true)
            Text(title).fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .onAppear { visible = true }
        .onDisappear { visible = false }
    }
}
