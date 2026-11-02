import SwiftUI
import UIKit

struct RootView: View {
    @Binding var incomingShortcut: LocusShortcut?
    @Binding var incomingSessionDetails: Bool
    @State private var showSessionDetails = false
    @State private var mapPreview: RoutePlace?
    @State private var searchMap = false
    @EnvironmentObject private var privacy: AppPrivacyController
    @EnvironmentObject private var reset: AppResetController
    @EnvironmentObject private var session: SpoofSession
    @EnvironmentObject private var preferences: SessionPreferences
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.shiftVisualStyle) private var visualStyle
    @StateObject private var planner = RoutePlanner()
    @StateObject private var tripLibrary = TripLibrary()
    private enum RootTab: String { case map, library, settings }
    @SceneStorage("shift.selectedTab") private var selectedTab = RootTab.map
    @State private var drawAfterPlanner = false
    @State private var showSettings = false
    @State private var showPlaces = false
    @State private var notice: String?
    @State private var noticeID = UUID()

    var body: some View {
        TabView(selection: $selectedTab) {
        Tab("Map", systemImage: "map.fill", value: RootTab.map) {
        MapHomeView(isVisible: selectedTab == .map && !planner.isPresented && !showSessionDetails && privacy.canOpenContent, incomingPlace: $mapPreview, incomingSearch: $searchMap)
        // Keep the native map's viewport fixed while the controls change height.
        // Resizing it through safeAreaInset during a glass animation can expose
        // an empty map frame and also moves its gesture coordinate space.
        .overlay(alignment: .bottom) {
            if !planner.isDrawing {
                BottomControlsView(showSettings: $showSettings, showPlaces: $showPlaces, showNotice: showNotice,
                                   controlsEnabled: selectedTab == .map && !planner.isPresented && !showSessionDetails && privacy.canOpenContent)
                    .padding(.horizontal, 16)
                    // Keep a strip of the map visible below the tray for its
                    // system attribution and legal link.
                    .padding(.bottom, 30)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        }
        Tab("Library", systemImage: "square.stack.fill", value: RootTab.library) {
        PlacesView(isRoot: true, onTrip: { trip in
            guard session.journey == nil, !session.isBusy else { showNotice("End the current route before opening another."); return }
            selectedTab = .map
            planner.useSaved(trip)
        }, onPlace: { place in
            guard session.journey == nil, !session.isBusy else { showNotice("End the current route before choosing another place."); return }
            selectedTab = .map
            planner.discardPreparedRoute()
            session.selectPin(place.coordinate, name: place.displayName)
            mapPreview = RoutePlace(name: place.name, coordinate: place.coordinate)
        }, onFindPlace: {
            guard session.journey == nil, !session.isBusy, !planner.isDrawing else { showNotice("End the current route or close its editor before choosing another place."); return }
            selectedTab = .map
            searchMap = true
        }, onCreateRoute: {
            guard session.journey == nil, !session.isBusy, !planner.isDrawing else { showNotice("End the current route or close its editor before creating another."); return }
            selectedTab = .map
            planner.isPresented = true
        })
        }
        Tab("Settings", systemImage: "gearshape.fill", value: RootTab.settings) {
            SettingsView(isRoot: true)
        }
        }
        // Keep one TabView alive. Solid navigation replaces only its chrome, never
        // the map or session. OS-owned menus and alerts still follow iOS settings.
        .modifier(ShiftTabBarBehavior())
        .background(ShiftCanvas())
        .toolbar(planner.isDrawing || solidNavigation ? .hidden : .visible, for: .tabBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if solidNavigation && !planner.isDrawing { solidTabBar }
        }
        .tint(ShiftPalette.color(.accent, style: visualStyle))
        .environmentObject(planner)
        .environmentObject(tripLibrary)
        .onChange(of: showSettings) { _, show in if show { selectedTab = .settings; showSettings = false } }
        .onChange(of: showPlaces) { _, show in if show { selectedTab = .library; showPlaces = false } }
        .fullScreenCover(isPresented: $planner.isPresented, onDismiss: {
            planner.discardDraft()
            if drawAfterPlanner {
                drawAfterPlanner = false
                NotificationCenter.default.post(name: .locusDrawRoute, object: nil)
            }
        }) {
            RoutePlannerSheet(onDraw: { drawAfterPlanner = true }).environmentObject(planner).environmentObject(tripLibrary)
                .environment(\.shiftEditorEmbedded, true)
        }
        .onAppear { DeveloperLogStore.shared.record("screen_opened", ["screen": "Map"]); publishWidgets(); openShortcutIfAllowed() }
        .onChange(of: session.favorites) { _, _ in publishWidgets() }
        .onChange(of: tripLibrary.trips) { _, _ in publishWidgets() }
        .sheet(isPresented: $showSessionDetails) {
            NavigationStack { ConnectionDetailsView().toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { showSessionDetails = false } }
            } }.presentationDetents([.large])
        }
        .onReceive(NotificationCenter.default.publisher(for: .locusImportGPX)) { note in
            guard !reset.isResetting else { return }
            guard let url = note.object as? URL else { return }
            guard session.journey == nil, !session.isBusy, !planner.isDrawing, !planner.isPresented else {
                session.lastError = "Close the current editor and end any moving route before importing a GPX file."
                return
            }
            do {
                let points = try GPXCodec.parse(url)
                selectedTab = .map
                planner.useCustom(points, source: .gpx)
            } catch { session.lastError = error.localizedDescription }
        }
        .onChange(of: incomingSessionDetails) { _, _ in openShortcutIfAllowed() }
        .onChange(of: incomingShortcut) { _, _ in openShortcutIfAllowed() }
        .onChange(of: privacy.canOpenContent) { _, _ in openShortcutIfAllowed() }
        .loggedAlert("Session needs attention", isPresented: Binding(
            get: { session.lastError != nil },
            set: { if !$0 { session.lastError = nil } }
        )) {
            Button("Connection details") {
                session.lastError = nil
                incomingSessionDetails = true
            }
            Button("OK", role: .cancel) { session.lastError = nil }
        } message: { Text(session.lastError ?? "") }
        .overlay(alignment: .center) {
            if let notice {
                Text(notice)
                    .font(.subheadline.weight(.medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 20).padding(.vertical, 14)
                    .background(Color(uiColor: .systemGray5), in: RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
                    .frame(maxWidth: 290)
                    .padding(24)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .task(id: noticeID) {
            guard let notice else { return }
            UIAccessibility.post(notification: .announcement, argument: notice)
            do { try await Task.sleep(nanoseconds: 2_500_000_000) } catch { return }
            DeveloperLogStore.shared.record("popup_dismissed", ["message": notice])
            withAnimation(.easeOut(duration: 0.15)) { self.notice = nil }
        }
    }

    private var solidNavigation: Bool { !preferences.glassPanel || reduceTransparency }
    private var solidTabBar: some View {
        HStack(spacing: 0) {
            solidTab(.map, title: "Map", symbol: "map.fill")
            solidTab(.library, title: "Library", symbol: "square.stack.fill")
            solidTab(.settings, title: "Settings", symbol: "gearshape.fill")
        }
        .padding(.top, 6).padding(.horizontal, 12)
        .background(ShiftPalette.color(.surface, style: visualStyle).ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { Rectangle().fill(Color.primary.opacity(0.12)).frame(height: 1) }
    }
    private func solidTab(_ tab: RootTab, title: String, symbol: String) -> some View {
        Button { selectedTab = tab } label: {
            Label(title, systemImage: symbol)
                .font(.footnote.weight(selectedTab == tab ? .bold : .medium))
                .labelStyle(.titleAndIcon)
                .foregroundStyle(ShiftPalette.color(selectedTab == tab ? .accent : .muted, style: visualStyle))
                .frame(maxWidth: .infinity, minHeight: 48).contentShape(Rectangle())
        }.buttonStyle(.plain)
            .accessibilityAddTraits(selectedTab == tab ? [.isSelected] : [])
            .accessibilityHint("Opens the \(title.lowercased()) tab")
    }

    private func openShortcutIfAllowed() {
        // Let the map install its preview receiver before consuming a cold-start link.
        DispatchQueue.main.async {
            guard privacy.canOpenContent, !reset.isResetting else { return }
            if incomingSessionDetails {
                incomingSessionDetails = false
                guard !planner.isPresented, !planner.isDrawing else {
                    showNotice("Close the route editor, then tap the status at the top of the map."); return
                }
                selectedTab = .map
                showSessionDetails = true
                return
            }
            guard let shortcut = incomingShortcut else { return }
            incomingShortcut = nil
            guard !planner.isPresented, !planner.isDrawing else {
                showNotice("Close the open editor or menu, then tap the widget again."); return
            }
            selectedTab = .map
            switch shortcut.kind {
            case .place:
                guard let place = HomeWidgetPublisher.place(for: shortcut.id, among: session.favorites) else { showNotice("That saved place is no longer available."); return }
                planner.discardPreparedRoute()
                session.selectPin(place.coordinate, name: place.displayName)
                mapPreview = RoutePlace(name: place.name, coordinate: place.coordinate)
            case .trip:
                guard session.journey == nil, !session.isBusy else { showNotice("Stop the current route before preparing another route."); return }
                guard let trip = tripLibrary.trips.first(where: { $0.id == shortcut.id }) else { showNotice("That saved trip is no longer available."); return }
                planner.useSaved(trip)
            case .tripStart:
                guard let trip = tripLibrary.trips.first(where: { $0.id == shortcut.id }), let start = trip.points.first else {
                    showNotice("That saved route is no longer available."); return
                }
                planner.discardPreparedRoute()
                session.selectPin(start.coordinate, name: trip.originName)
                mapPreview = RoutePlace(name: trip.originName, coordinate: start.coordinate)
            }
            // Selecting a pin must never send a location, cancel an active route,
            // or start a session. Only the explicit Teleport/Start controls do that.
            if shortcut.kind != .trip { showNotice("Pin ready. Tap Teleport to pin when you want to move.") }
        }
    }

    private func publishWidgets() {
        guard !reset.isResetting else { return }
        _ = HomeWidgetPublisher.publish(places: session.favorites, trips: tripLibrary.trips)
    }
    private func showNotice(_ message: String) {
        DeveloperLogStore.shared.record("popup_requested", ["message": message])
        withAnimation(.easeOut(duration: 0.15)) { notice = message }
        noticeID = UUID()
    }
}

private struct ShiftTabBarBehavior: ViewModifier {
    @ViewBuilder func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            // Map gestures must never collapse or move the navigation targets.
            content.tabBarMinimizeBehavior(.never)
        } else {
            content
        }
    }
}

/// Status text only needs a clock while its screen is visible. Session work
/// continues independently; returning to the view evaluates real timestamps.
struct ForegroundTimeline<Content: View>: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var visible = false
    var enabled = true
    @ViewBuilder var content: (Date) -> Content

    var body: some View {
        TimelineView(ForegroundSchedule(paused: !visible || scenePhase != .active || !enabled)) { context in
            content(context.date)
        }
        .onAppear { visible = true }
        .onDisappear { visible = false }
    }
}

private struct ForegroundSchedule: TimelineSchedule {
    var paused: Bool
    func entries(from startDate: Date, mode: TimelineScheduleMode) -> AnySequence<Date> {
        // One entry refreshes the text at a lifecycle transition, with no
        // subsequent timer events until the screen is active again.
        if paused { return AnySequence([startDate]) }
        return AnySequence(PeriodicTimelineSchedule(from: startDate, by: 1).entries(from: startDate, mode: mode))
    }
}

struct StatusBarView: View {
    var isVisible = true
    @EnvironmentObject private var session: SpoofSession
    @ObservedObject private var remote = RemoteFindMyController.shared
    @ObservedObject private var computer = CompanionClient.shared
    @State private var showDetails = false

    var body: some View {
        ForegroundTimeline(enabled: isVisible && !showDetails) { _ in
            let phase = session.effectivePhase
            Button { showDetails = true } label: {
            HStack(spacing: 10) {
                Image(systemName: session.showsClosedSessionNotice ? "info.circle" : phase.symbol)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(session.showsClosedSessionNotice ? Color.secondary : phase.color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.statusTitle).font(.subheadline.weight(.semibold))
                    if remote.enabled && remote.paired && session.remoteCheckSessionRequested {
                        Text(remote.state.title).font(.footnote)
                            .foregroundStyle(remote.state == .match ? Color.green : Color.secondary)
                    } else if let status = computer.activityStatus {
                        Text(status.title(at: Date())).font(.footnote).foregroundStyle(.secondary)
                    }
                    if let last = session.lastConfirmedAt {
                        HStack(spacing: 3) {
                            Text("Updated")
                            Text(last, style: .relative)
                        }
                        .font(.footnote).foregroundStyle(.secondary)
                    } else if phase == .unverified {
                        Text(session.showsClosedSessionNotice ? "Not running · Tap for details" : "Last location may still be set").font(.footnote).foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
                if session.lowPower {
                    Image(systemName: "battery.25percent").foregroundStyle(LocusTheme.statusWarn)
                        .accessibilityLabel("Low Power Mode")
                }
                if phase == .connecting || phase == .stopping { ProgressView().controlSize(.small) }
            }
            .padding(.horizontal, 16).padding(.vertical, 10).frame(minHeight: 52)
            .locusGlass(.regular, in: Capsule())
            .contentShape(Capsule())
            }.buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Open connection details")
            .accessibilityAction { showDetails = true }
        }
        .sheet(isPresented: $showDetails) {
            NavigationStack { ConnectionDetailsView().toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { showDetails = false } }
            } }.presentationDetents([.medium, .large])
        }
    }
}

struct BottomControlsView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var session: SpoofSession
    @EnvironmentObject private var pairing: PairingStore
    @EnvironmentObject private var planner: RoutePlanner
    @EnvironmentObject private var preferences: SessionPreferences
    @Binding var showSettings: Bool
    @Binding var showPlaces: Bool
    let showNotice: (String) -> Void
    var controlsEnabled = true
    @State private var collapsed = false
    @State private var routeDetailsCollapsed = false
    @State private var showMovementSheet = false
    @State private var showRecovery = false
    @State private var handleDrag = ControlTrayDrag()
    @GestureState private var handleTouchActive = false
    @State private var detailHeight: CGFloat = 0

    private var expansion: CGFloat {
        let base: CGFloat = collapsed ? 0 : 1
        return min(1, max(0, base - CGFloat(handleDrag.translation) / max(80, detailHeight)))
    }

    private var interactionsAvailable: Bool {
        controlsEnabled && scenePhase == .active && !showMovementSheet && !showRecovery && session.journey == nil
    }

    private var joystickInputEnabled: Bool { interactionsAvailable && !handleTouchActive }

    var body: some View {
        VStack(spacing: 10) {
            if session.journey != nil {
                compactJourneyPanel
            } else {
            if session.joystickActive && collapsed {
                JoystickPad(radius: 34, inputEnabled: joystickInputEnabled) { session.updateJoystick(vector: $0) }
                    .frame(width: 104, height: 104)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            VStack(spacing: 0) {
                panelHandle
                // Keep the same details in the tree throughout the drag. Only their
                // visible height changes; the map and its coordinate space never resize.
                expandedDetails
                    .padding(.bottom, 12)
                    .fixedSize(horizontal: false, vertical: true)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                        guard height.isFinite, height >= 0, height != detailHeight else { return }
                        interruptHandle()
                        detailHeight = height
                    }
                    .frame(height: detailHeight > 0 ? detailHeight * expansion : nil, alignment: .bottom)
                    .opacity(expansion)
                    .clipped()
                    .allowsHitTesting(!collapsed && !handleTouchActive)
                    .accessibilityHidden(collapsed)
                VStack(spacing: 10) {
                    primaryActions
                    if session.effectivePhase == .disconnected || session.effectivePhase == .unverified {
                        SessionRetryButton().font(.caption.weight(.semibold))
                    }
                    HStack(spacing: 4) { trayItems }
                        .padding(.top, 3)
                }
                .padding(.bottom, 12)
            }
            .padding(.horizontal, 16)
            .modifier(ControlPanelStyle(useGlass: preferences.glassPanel))
            .shadow(color: .black.opacity(0.12), radius: 20, y: 8)
            }
        }
        .sheet(isPresented: $showMovementSheet) { MovementControlsSheet() }
        .sheet(isPresented: $showRecovery) {
            NavigationStack {
                TripRecoveryView().toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { showRecovery = false } } }
            }
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { _ in interruptHandle() }
        .onChange(of: handleTouchActive) { _, active in
            if !active {
                // A canceled drag returns to its previous anchor; only onEnded commits.
                withAnimation(interactionsAvailable ? panelAnimation : nil) { handleDrag.gestureDidReset() }
            }
        }
        .onChange(of: interactionsAvailable) { _, available in if !available { interruptHandle() } }
        .onChange(of: session.activeRoute?.id) { _, _ in routeDetailsCollapsed = false }
        .onChange(of: reduceMotion) { _, _ in interruptHandle() }
        .onAppear { if !handleTouchActive { handleDrag.gestureDidReset() } }
        .onDisappear { interruptHandle() }
    }

    @ViewBuilder private var compactJourneyPanel: some View {
        if let route = session.activeRoute, let trip = session.journey {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(route.destination.name).font(.headline).lineLimit(routeDetailsCollapsed && !typeSize.isAccessibilitySize ? 1 : 2)
                        Text(session.restoredRouteAwaitingConnection ? "Saved route position" : session.recoveringRoute ? "Reconnecting…" : trip.state.title).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                    Button {
                        // Presentation only: never change the map viewport or route commands.
                        withAnimation(session.lowPower ? nil : panelAnimation) { routeDetailsCollapsed.toggle() }
                    } label: {
                        Image(systemName: routeDetailsCollapsed ? "chevron.up" : "chevron.down")
                            .font(.body.weight(.semibold))
                            .frame(width: 44, height: 44).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(!controlsEnabled || scenePhase != .active)
                    .accessibilityLabel(routeDetailsCollapsed ? "Expand route details" : "Collapse route details")
                    .accessibilityValue(routeDetailsCollapsed ? "Collapsed" : "Expanded")
                    .accessibilityHint("Route progress, Pause or Resume, and Stop stay available.")
                    Menu {
                        Button("Route details", systemImage: "list.bullet") { planner.isPresented = true }
                        Button("Mode & speed", systemImage: "speedometer") { showMovementSheet = true }
                        Button("End route and hold location", systemImage: "stop.fill") { session.stopRoute() }
                            .disabled(session.isBusy || session.routeStopping)
                        Divider()
                        ForEach(PanelShortcut.allCases.filter { $0 != .pause && $0 != .speed && $0 != .batterySaver }) { item in
                            Button { activate(item) } label: { Label(shortcutTitle(item), systemImage: shortcutIcon(item)) }
                        }
                    } label: {
                        Image(systemName: "ellipsis").frame(width: 44, height: 44).contentShape(Rectangle())
                    }.accessibilityLabel("Route controls and shortcuts")
                }
                if !routeDetailsCollapsed {
                    let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8)) : AnyLayout(HStackLayout(alignment: .top, spacing: 20))
                    layout {
                        Button { showMovementSheet = true } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(preferences.speedUnit.formatted(mph: session.speedMPH(for: session.travelMode)))
                                    .font(.title3.weight(.semibold)).monospacedDigit()
                                Label("Target speed", systemImage: session.travelMode.icon).font(.caption).foregroundStyle(.secondary)
                            }.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading).contentShape(Rectangle())
                        }.buttonStyle(.plain).accessibilityHint("Adjust mode and speed")
                        VStack(alignment: .leading, spacing: 3) {
                            Text(JourneyText.distance(trip.remainingMetres)).font(.title3.weight(.semibold)).monospacedDigit()
                            Text("Remaining").font(.caption).foregroundStyle(.secondary)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                ProgressView(value: trip.fraction).tint(LocusTheme.accent).accessibilityLabel("Route progress")
                if routeDetailsCollapsed {
                    Text("\(JourneyText.distance(trip.remainingMetres)) remaining")
                        .font(.caption).foregroundStyle(.secondary).monospacedDigit()
                }
                if trip.state == .arrived {
                    Text("Arrived. Stop spoofing to return control to your iPhone.").font(.caption).foregroundStyle(.secondary)
                } else if session.restoredRouteAwaitingConnection {
                    Text(session.automaticRecoveryPending ? "Waiting for Wi-Fi to resume. Keep LocalDevVPN on." : "Paused · Resume when ready.")
                        .font(.caption).foregroundStyle(.secondary)
                } else if session.effectivePhase != .active {
                    Text("Waiting for connection confirmation. ETA unavailable.").font(.caption).foregroundStyle(LocusTheme.statusWarn)
                } else if !routeDetailsCollapsed, let seconds = session.journeyRemainingSeconds {
                    Text("About \(JourneyText.duration(seconds)) including stops").font(.caption).foregroundStyle(.secondary)
                }
                if !routeDetailsCollapsed, session.currentStop == nil, let next = route.stops.first(where: { $0.metres > trip.travelledMetres + 0.001 }) {
                    Text("Next: \(next.name)").font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
                if let note = route.source.playbackNote(mode: session.travelMode) {
                    Text(note).font(.caption).foregroundStyle(LocusTheme.statusWarn)
                }
                RouteExtrasControls()
                ArrivalControls()
                if session.routeRerouting {
                    HStack { ProgressView("Finding route…"); Spacer(); Button("Cancel") { session.cancelReroute() }.frame(minHeight: 44) }.font(.caption)
                } else if session.routeJumping {
                    ProgressView("Moving to selected point…").font(.caption)
                }
                let actions = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 8)) : AnyLayout(HStackLayout(spacing: 10))
                actions {
                    if session.restoredRouteAwaitingConnection {
                        Button("Resume route") { showRecovery = true }
                            .buttonStyle(ShiftActionStyle(immediatePress: true)).frame(minHeight: 44)
                        Button("Cancel recovery") { session.stopRoute() }
                            .buttonStyle(ShiftActionStyle(kind: .secondary, immediatePress: true)).frame(minHeight: 44)
                    }
                    if session.routeActive && !session.routeStopping {
                        Button { session.toggleRoutePause() } label: {
                            Label(trip.state == .pausing ? "Pausing…" : session.routePaused ? "Resume" : "Pause",
                                  systemImage: session.routePaused ? "play.fill" : "pause.fill")
                                .frame(maxWidth: .infinity, minHeight: 44).contentShape(Rectangle())
                        }
                        .buttonStyle(ShiftActionStyle(immediatePress: true))
                        .disabled(!session.canEditRouteMovement || trip.state == .pausing || (session.routePaused && session.effectivePhase != .active))
                    }
                    if session.hasSession { stopSpoofing }
                }
                if session.routeStopping { ProgressView("Ending route…").font(.caption) }
                if session.effectivePhase == .disconnected || session.effectivePhase == .unverified {
                    SessionRetryButton().font(.caption.weight(.semibold))
                }
            }
            .padding(16)
            .modifier(ControlPanelStyle(useGlass: preferences.glassPanel))
            .shadow(color: .black.opacity(0.10), radius: 16, y: 6)
        }
    }

    private var panelHandle: some View {
        Button { setCollapsed(!collapsed) } label: {
            ZStack {
                Capsule().fill(Color.secondary.opacity(0.35)).frame(width: 36, height: 4).opacity(collapsed ? 0 : 1)
                if collapsed { Image(systemName: "chevron.up").font(.caption.weight(.bold)) }
            }
            .frame(maxWidth: .infinity, minHeight: 44).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!interactionsAvailable)
        .highPriorityGesture(
            DragGesture(minimumDistance: 12, coordinateSpace: .global)
                .updating($handleTouchActive) { _, active, _ in active = true }
                .onChanged { value in
                    guard interactionsAvailable else { interruptHandle(); return }
                    var transaction = Transaction(); transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        handleDrag.update(x: Double(value.translation.width), y: Double(value.translation.height))
                    }
                }
                .onEnded { value in
                    guard interactionsAvailable else { interruptHandle(); return }
                    withAnimation(panelAnimation) {
                        collapsed = handleDrag.finish(collapsed: collapsed, height: Double(detailHeight),
                                                      predictedY: Double(value.predictedEndTranslation.height))
                    }
                }
        )
        .accessibilityLabel(collapsed ? "Expand controls" : "Collapse controls")
    }

    @ViewBuilder private var expandedDetails: some View {
        VStack(alignment: .leading, spacing: 14) {
            if session.journey != nil {
                JourneyCard(showsControls: false)
            } else if let prepared = planner.preparedRoute {
                HStack(spacing: 12) {
                    ShiftRowIcon(symbol: prepared.mode.icon)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("READY TO START").font(.footnote.weight(.semibold)).tracking(1.6).foregroundStyle(.secondary)
                        Text(prepared.route.destination.name).font(.title3.weight(.semibold)).lineLimit(2)
                        Text(JourneyText.distance(prepared.route.track.length)).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                    Button { planner.editPreparedRoute() } label: {
                        Image(systemName: "slider.horizontal.3").frame(width: 44, height: 44).contentShape(Rectangle())
                    }.buttonStyle(.plain).accessibilityLabel("Edit route preview")
                }
            } else if !session.joystickActive {
                HStack(alignment: .center, spacing: 12) {
                    ShiftRowIcon(symbol: session.pinIsPreview ? "mappin" : session.hasSession ? "location.fill" : "map")
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.pinIsPreview ? "Selected place" : session.hasSession ? "Holding location" : "Where to next?")
                            .font(.headline)
                        if let point = session.pinIsPreview ? session.pin : session.simulated {
                            Text(session.suggestedFavoriteName(for: point)).font(.subheadline).foregroundStyle(.secondary)
                                .lineLimit(2)
                        } else {
                            Text("Search for a place or draw a route.").font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
            if session.joystickActive {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        RouteModeMenu()
                        speedButton
                    }
                    Spacer(minLength: 0)
                    JoystickPad(radius: 32, inputEnabled: joystickInputEnabled && !collapsed) { session.updateJoystick(vector: $0) }
                        .frame(width: 96, height: 96)
                }
            } else if session.journey != nil {
                HStack(spacing: 8) {
                    RouteModeMenu()
                    Spacer(minLength: 0)
                    speedButton
                }
            }
        }
    }

    private var speedButton: some View {
        Button { showMovementSheet = true } label: {
            HStack(spacing: 7) {
                Text(preferences.speedUnit.formatted(mph: session.speedMPH(for: session.travelMode))).monospacedDigit()
                Image(systemName: "slider.horizontal.3").font(.caption)
            }.font(.subheadline.weight(.semibold)).frame(minHeight: 44).contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityLabel("Adjust movement speed")
    }

    @ViewBuilder private var primaryActions: some View {
        if session.recoveryAvailable {
            Button { showRecovery = true } label: {
                Label("Resume interrupted trip…", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }.buttonStyle(ShiftActionStyle(kind: .secondary, immediatePress: true))
        }
        if planner.preparedRoute == nil && session.pin != nil && (session.pinIsPreview || !session.hasSession) { teleportPin }
        if session.journey != nil {
            if session.routeRerouting {
                HStack {
                    ProgressView("Finding route…")
                    Spacer()
                    Button("Cancel") { session.cancelReroute() }.frame(minHeight: 44)
                }.font(.caption)
            } else if session.routeJumping {
                ProgressView("Moving to selected point…").font(.caption)
            }
            RoutePlaybackControls(compact: true)
        } else if let prepared = planner.preparedRoute {
            PreparedRouteControls(prepared: prepared, compact: true)
        }
        if session.hasSession { stopSpoofing }
    }

    @ViewBuilder private var trayItems: some View {
        ForEach(preferences.panelShortcuts) { item in
            trayItem(shortcutTitle(item), icon: shortcutIcon(item), selected: (item == .joystick && session.joystickActive)) { activate(item) }
        }
        Menu {
            ForEach(PanelShortcut.allCases.filter { !preferences.panelShortcuts.contains($0) }) { item in
                Button { activate(item) } label: { Label(shortcutTitle(item), systemImage: shortcutIcon(item)) }
            }
            if session.journey != nil {
                Button { planner.isPresented = true } label: { Label("Route details", systemImage: "list.bullet") }
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "ellipsis").font(.body.weight(.medium))
                Text("More").font(.footnote.weight(.medium))
            }.frame(maxWidth: .infinity, minHeight: 44).foregroundStyle(.secondary).contentShape(Rectangle())
        }.accessibilityLabel("More controls")
    }

    private func shortcutTitle(_ item: PanelShortcut) -> String {
        return item == .pause ? (session.routePaused ? "Continue" : "Pause") : item.title
    }
    private func shortcutIcon(_ item: PanelShortcut) -> String {
        item == .pause && session.routePaused ? "play.fill" : item.icon
    }
    private func activate(_ item: PanelShortcut) {
        switch item {
        case .batterySaver: break // Legacy shortcut is removed during normalization.
        case .saved: showPlaces = true
        case .settings: showSettings = true
        case .joystick:
            if session.joystickActive { session.stopJoystick() }
            else if let message = session.startJoystick(pairing: pairing) { showNotice(message) }
        case .speed:
            if session.joystickActive || session.journey != nil { showMovementSheet = true }
            else { showNotice("Start a route or open the joystick to adjust speed.") }
        case .pause:
            if session.routeActive { session.toggleRoutePause() }
            else { showNotice("No moving route to pause.") }
        }
    }

    private var teleportPin: some View {
        Button {
            if let pin = session.pin { session.teleport(to: pin, pairing: pairing) }
        } label: {
            Label("Teleport to pin", systemImage: "location.fill")
                .font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(ShiftActionStyle(immediatePress: true))
        .disabled(session.pin == nil || session.isBusy)
    }

    private var stopSpoofing: some View {
        Button { session.stop(pairing: pairing) } label: {
            Label(session.stopButtonTitle, systemImage: "location.slash")
                .font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(ShiftActionStyle(kind: .destructive, immediatePress: true))
        .disabled(session.status == .stopping)
    }

    private var panelAnimation: Animation? {
        reduceMotion ? nil : .smooth(duration: 0.32)
    }

    private func setCollapsed(_ value: Bool) {
        guard interactionsAvailable else { return }
        withAnimation(panelAnimation) {
            handleDrag.interrupt(gestureActive: handleTouchActive)
            collapsed = value
        }
    }

    private func interruptHandle() {
        var transaction = Transaction(); transaction.disablesAnimations = true
        withTransaction(transaction) { handleDrag.interrupt(gestureActive: handleTouchActive) }
    }
    private func trayItem(_ title: String, icon: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.body.weight(.medium))
                Text(title).font(.footnote.weight(.medium))
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .foregroundStyle(selected ? LocusTheme.accent : .secondary).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

private struct PreparedRouteControls: View {
    @EnvironmentObject private var session: SpoofSession
    @EnvironmentObject private var pairing: PairingStore
    @EnvironmentObject private var planner: RoutePlanner
    let prepared: PreparedRoute
    var compact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !compact {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(prepared.route.destination.name).font(.headline).lineLimit(1)
                        Text("Preview · \(prepared.route.travelSections.isEmpty ? prepared.mode.title : "Section settings") · \(JourneyText.distance(prepared.route.track.length))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 4)
                    Button { planner.editPreparedRoute() } label: {
                        Image(systemName: "slider.horizontal.3").frame(width: 44, height: 44).contentShape(Rectangle())
                    }.buttonStyle(.plain).accessibilityLabel("Edit route preview")
                }
            }
            HStack(spacing: 10) {
                Button {
                    if session.startPreparedRoute(prepared, pairing: pairing) { planner.discardPreparedRoute() }
                } label: {
                    Label("Start route", systemImage: "play.fill")
                        .font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(ShiftActionStyle(immediatePress: true))
                .disabled(session.isBusy || session.routeActive || session.status == .stopping)
                Button { planner.discardPreparedRoute() } label: {
                    Image(systemName: "xmark").frame(width: 44, height: 44).contentShape(Rectangle())
                }.buttonStyle(.plain).accessibilityLabel("Discard route preview")
            }
            if let note = prepared.continuationNote {
                Text(note).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

private struct ControlPanelStyle: ViewModifier {
    @Environment(\.shiftVisualStyle) private var style
    let useGlass: Bool
    func body(content: Content) -> some View {
        if useGlass {
            content.locusGlass(.clear, allowInLowPower: true, in: RoundedRectangle(cornerRadius: style.cornerRadius + 6))
        } else {
            content.background(ShiftPalette.color(.surface, style: style), in: RoundedRectangle(cornerRadius: style.cornerRadius + 6))
                .overlay(RoundedRectangle(cornerRadius: style.cornerRadius + 6).stroke(Color.primary.opacity(0.08), lineWidth: 1))
        }
    }
}

struct SessionSpotNameButton: View {
    @EnvironmentObject private var session: SpoofSession
    @State private var showEditor = false
    @State private var text = ""
    @State private var target: NameTarget?

    private struct NameTarget {
        let point: RoutePoint
        let preview: Bool
        let context: UUID
    }

    private var spotTitle: String {
        if session.pinIsPreview { return session.pin.flatMap { session.placeName(at: $0) } ?? "Name this pin" }
        return session.simulated.flatMap { session.placeName(at: $0) } ?? "Name this location"
    }

    var body: some View {
        Button {
            let preview = session.pinIsPreview
            guard let coordinate = preview ? session.pin : session.simulated else { return }
            let point = RoutePoint(coordinate)
            target = NameTarget(point: point, preview: preview, context: session.namingContext)
            let existing = preview ? session.previewSpotName : session.sessionSpotName
            text = existing.flatMap { $0.point.distance(to: point) <= SessionSpotName.nearbyMetres ? $0.name : nil } ?? session.placeName(at: coordinate) ?? ""
            showEditor = true
        } label: {
            Image(systemName: "tag")
                .font(.body.weight(.medium)).frame(width: 44, height: 44).contentShape(Rectangle())
        }
        .buttonStyle(.plain).foregroundStyle(.primary)
        .disabled(session.isBusy || session.status == .stopping || session.routeJumping)
        .accessibilityLabel("Name this spot")
        .accessibilityValue(spotTitle)
        .loggedAlert("Name this spot", isPresented: $showEditor) {
            TextField("Home, work, coffee shop…", text: $text)
            Button("Save") { saveName(text) }
            Button("Remove name", role: .destructive) { saveName("") }
            Button("Cancel", role: .cancel) { target = nil }
        } message: {
            Text("Only for this session, within 5 meters of this spot. Beyond that, Elsepin uses the next matching place or named area. Turn off Hide location separately for the Lock Screen or Island to show names there.")
        }
    }

    private func saveName(_ value: String) {
        guard let target else { return }
        if !session.nameSpot(value, at: target.point, preview: target.preview, context: target.context) {
            session.lastError = "That spot or session changed. Choose Name again."
        }
        self.target = nil
    }
}

extension SessionPhase {
    var color: Color {
        switch self {
        case .active: return LocusTheme.accent
        case .disconnected: return LocusTheme.statusBad
        case .connecting, .reconnecting, .stopping, .unverified: return .orange
        case .idle: return .secondary
        }
    }
}
