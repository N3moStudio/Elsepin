import SwiftUI

/// Uses an independent planner so editing a continuation never replaces the
/// first route's draft. The normal Start remains the permission boundary.
struct NextRouteEditor: View {
    let source: PlannedRoute
    let existing: NextRoutePlan?
    let onSave: (NextRoutePlan) -> Void
    @EnvironmentObject private var session: SpoofSession
    @Environment(\.dismiss) private var dismiss
    @StateObject private var nextPlanner = RoutePlanner()
    @State private var showSearch = false
    @State private var pendingDestination: RoutePlace?
    @State private var showPlanner = false
    @State private var chosen: PreparedRoute?
    @State private var waitSeconds = 0.0
    @State private var automatically = false
    @State private var error: String?
    private var startingPlace: RoutePlace {
        RoutePlace(name: source.destination.name, coordinate: source.track.point(at: source.track.length).coordinate)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("From", value: source.destination.name)
                    Button("Return to start", systemImage: "arrow.uturn.backward") { plan(to: source.origin) }
                    Button("Choose another destination", systemImage: "magnifyingglass") { showSearch = true }
                    if let chosen {
                        Button { nextPlanner.editPreparedRoute(); showPlanner = true } label: {
                            LabeledContent("Edit next route", value: chosen.route.destination.name)
                        }
                    }
                }
                Section("Wait at destination") { StopDurationControl(seconds: $waitSeconds) }
                Section {
                    Toggle("Start next route automatically", isOn: $automatically)
                } footer: {
                    Text("When on, the next route starts after this wait without another tap. Stop or a connection interruption cancels it. Otherwise, tap Start next route after arrival.")
                }
                if let error { Text(error).foregroundStyle(LocusTheme.statusWarn) }
            }
            .shiftSettingsScreen().navigationTitle("Next route").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save", action: save).disabled(chosen == nil) }
            }
            .onAppear {
                guard chosen == nil else { return }
                if let existing {
                    chosen = existing.prepared
                    nextPlanner.useSaved(existing.route.savedTrip(name: existing.route.name, mode: existing.mode,
                        speed: existing.speedMPH, smooth: existing.smoothMovement, arrival: .stay))
                    _ = nextPlanner.prepareSelectedRoute(mode: existing.mode, speedMPH: existing.speedMPH, smoothMovement: existing.smoothMovement)
                    waitSeconds = existing.waitSeconds; automatically = existing.automatically
                } else {
                    nextPlanner.initializeDraftIfNeeded(mode: session.travelMode,
                        speedMPH: session.speedMPH(for: session.travelMode), smoothMovement: session.currentSmoothMovement)
                }
            }
            .sheet(isPresented: $showSearch, onDismiss: {
                if let place = pendingDestination {
                    pendingDestination = nil
                    plan(to: place)
                }
            }) {
                RoutePlaceSearchSheet(title: "Next destination") { place in
                    pendingDestination = place
                    showSearch = false
                }
            }
            .sheet(isPresented: $showPlanner, onDismiss: { nextPlanner.cancel() }) {
                RoutePlannerSheet(nextRouteMode: true, onPrepared: { prepared in
                    chosen = prepared; showPlanner = false
                }).environmentObject(nextPlanner)
            }
        }
    }
    private func plan(to place: RoutePlace) {
        error = nil
        nextPlanner.setOrigin(startingPlace, mode: nextPlanner.draftMode)
        nextPlanner.plan(to: place, defaultOrigin: startingPlace, mode: nextPlanner.draftMode)
        showPlanner = true
    }
    private func save() {
        guard let chosen else { return }
        let plan = NextRoutePlan(route: chosen.route, mode: chosen.mode, speedMPH: chosen.speedMPH,
            smoothMovement: chosen.smoothMovement, waitSeconds: StopDuration.normalized(waitSeconds), automatically: automatically)
        guard plan.begins(at: source) else {
            error = "The next path must begin within 5 metres of this route’s end. Edit its start or choose a matching travel mode."
            return
        }
        onSave(plan); dismiss()
    }
}
