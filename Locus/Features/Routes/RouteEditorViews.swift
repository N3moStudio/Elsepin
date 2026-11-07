import Foundation
import MapKit
import SwiftUI

/// Receives an immutable route and local playback settings only. No session,
/// pairing store, location service, or location-write callback is available here.
struct RoutePracticeSheet: View {
    let route: PlannedRoute
    let mode: TravelMode
    let speed: Double
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var preview = RouteRehearsal()
    private var shouldPlay: Bool { scenePhase == .active && preview.isPlaying }

    var body: some View {
        ShiftEditorContainer {
            ScrollView {
            VStack(spacing: 16) {
                Label("Preview only — this moves the orange dot", systemImage: "eye")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(LocusTheme.statusWarn)
                    .padding(.horizontal)
                Map(initialPosition: .automatic, interactionModes: [.pan, .zoom]) {
                    MapPolyline(coordinates: route.coordinates).stroke(LocusTheme.accent, lineWidth: 5)
                    Marker("Start", systemImage: "circle", coordinate: route.origin.coordinate).tint(.secondary)
                    Marker("Finish", systemImage: "flag.checkered", coordinate: route.destination.coordinate).tint(.secondary)
                    ForEach(route.stops) { stop in
                        Marker(stop.name, systemImage: "pause.circle", coordinate: route.track.point(at: stop.metres).coordinate).tint(.orange)
                    }
                    Annotation("Preview dot", coordinate: route.track.point(at: preview.metres).coordinate) {
                        Image(systemName: currentMode.icon).font(.headline).foregroundStyle(.white)
                            .frame(width: 36, height: 36).background(.orange, in: Circle())
                            .overlay(Circle().stroke(.white, lineWidth: 3))
                    }
                }
                .mapStyle(.standard(elevation: .flat)).mapControlVisibility(.hidden)
                .frame(height: typeSize.isAccessibilitySize ? 220 : 300)
                .clipShape(RoundedRectangle(cornerRadius: 18)).padding(.horizontal)
                .accessibilityLabel("Route preview with an orange dot")
                controls.padding(.horizontal)
            }
            .padding(.bottom)
            }
            .shiftScreen().loggedNavigationTitle("Route preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .task(id: shouldPlay) {
                guard shouldPlay else { return }
                var last = ProcessInfo.processInfo.systemUptime
                while !Task.isCancelled {
                    do { try await Task.sleep(nanoseconds: 100_000_000) } catch { return }
                    let now = ProcessInfo.processInfo.systemUptime
                    if shouldPlay {
                        preview.advance(seconds: now - last, length: route.track.length, speed: speed,
                                        sections: route.travelSections, stops: route.stops)
                    }
                    last = now
                }
            }
            .onChange(of: scenePhase) { _, value in if value != .active { preview.isPlaying = false } }
            .onDisappear { preview.isPlaying = false }
        }
    }
    private var currentMode: TravelMode {
        RouteTravelSection.current(in: route.travelSections, at: preview.metres)?.mode ?? mode
    }
    private var controls: some View {
        VStack(spacing: 12) {
            Slider(value: Binding(get: { preview.metres }, set: {
                preview.seek(to: $0, length: route.track.length, stops: route.stops)
            }), in: 0...max(1, route.track.length))
                .tint(.orange)
                .accessibilityLabel("Preview position")
                .accessibilityValue(JourneyText.distance(preview.metres) + " from start")
            HStack {
                Text(currentMode.title)
                Spacer()
                Text("\(JourneyText.distance(preview.metres)) of \(JourneyText.distance(route.track.length))")
            }.font(.caption).foregroundStyle(.secondary)
            if !route.stops.isEmpty {
                Menu {
                    ForEach(route.stops) { stop in
                        Button("\(stop.name) · \(StopDuration.label(stop.waitSeconds))") {
                            preview.seek(to: stop.metres, length: route.track.length, stops: route.stops)
                        }
                    }
                } label: {
                    Label("Jump to a stop", systemImage: "mappin.and.ellipse")
                        .frame(minHeight: 44)
                }
                .accessibilityHint("Pauses the preview at the selected stop")
            }
            if preview.waitingID != nil {
                HStack {
                    Text("Planned stop · \(StopDuration.formatted(ceil(preview.waitingSeconds))) remaining").font(.caption)
                    Spacer()
                    Button { preview.skipWait() } label: {
                        Text("Skip wait").padding(.horizontal, 8).frame(minHeight: 44).contentShape(Rectangle())
                    }.buttonStyle(.plain)
                }
            }
            Picker("Preview speed", selection: $preview.rate) {
                Text("1×").tag(1.0); Text("10×").tag(10.0); Text("50×").tag(50.0); Text("100×").tag(100.0)
            }.pickerStyle(.segmented)
            HStack(spacing: 12) {
                Button {
                    if preview.metres >= route.track.length && preview.waitingID == nil { preview.reset() }
                    preview.isPlaying.toggle()
                } label: {
                    Label(preview.isPlaying ? "Pause preview" : "Play preview", systemImage: preview.isPlaying ? "pause.fill" : "play.fill")
                        .frame(maxWidth: .infinity, minHeight: 48).contentShape(Rectangle())
                }.buttonStyle(.plain).background(.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
                Button { preview.reset() } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .frame(minWidth: 90, minHeight: 48).contentShape(Rectangle())
                }.buttonStyle(.plain)
            }
            Text("Preview speed only speeds up this demonstration. Stops and section settings are included; connection delays and smooth movement are not simulated. Any existing spoofing session continues separately.")
                .font(.caption2).foregroundStyle(.secondary)
        }
    }
}

struct RouteWaypointEditor: View {
    let route: PlannedRoute
    let onSave: (RoutePoint, RoutePoint, [TripWaypoint]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var start: RoutePoint
    @State private var finish: RoutePoint
    @State private var stops: [TripWaypoint]
    @State private var addingStop = false
    @State private var position: MapCameraPosition = .automatic
    @State private var dragOrigin: CGPoint?
    @State private var draggingID: UUID?
    @State private var undoFrames: [Frame] = []
    private static let startID = UUID(uuidString: "A6000000-0000-0000-0000-000000000002")!
    private static let endID = RouteLegChoice.destinationID
    private struct Frame { let start: RoutePoint; let finish: RoutePoint; let stops: [TripWaypoint] }
    private struct Handle: Identifiable { let id: UUID; let label: String; let point: RoutePoint }

    init(route: PlannedRoute, stops: [TripWaypoint], onSave: @escaping (RoutePoint, RoutePoint, [TripWaypoint]) -> Void) {
        self.route = route
        self.onSave = onSave
        _start = State(initialValue: RoutePoint(route.origin.coordinate))
        _finish = State(initialValue: RoutePoint(route.destination.coordinate))
        _stops = State(initialValue: stops)
    }
    private var handles: [Handle] {
        [Handle(id: Self.startID, label: "S", point: start)]
        + stops.enumerated().map { Handle(id: $0.element.id, label: "\($0.offset + 1)", point: $0.element.point) }
        + [Handle(id: Self.endID, label: "F", point: finish)]
    }
    var body: some View {
        ShiftEditorContainer {
            VStack(spacing: 12) {
                Text(addingStop ? "Tap the map to add a stop." : "Drag S, F, or a numbered stop. Done finds new directions.")
                    .font(.subheadline).padding(.horizontal)
                MapReader { proxy in
                    Map(position: $position, interactionModes: [.pan, .zoom]) {
                        MapPolyline(coordinates: route.coordinates).stroke(.gray.opacity(0.6), lineWidth: 4)
                        MapPolyline(coordinates: handles.map { $0.point.coordinate })
                            .stroke(.orange.opacity(0.6), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                        ForEach(handles) { handle in
                            Annotation(handle.label, coordinate: handle.point.coordinate) {
                                Text(handle.label).font(.headline.monospacedDigit()).foregroundStyle(.white)
                                    .frame(width: 44, height: 44).background(LocusTheme.accent, in: Circle())
                                    .overlay(Circle().stroke(.white, lineWidth: 2)).contentShape(Circle())
                                    .highPriorityGesture(handleDrag(handle, proxy: proxy))
                                    .accessibilityLabel(handle.id == Self.startID ? "Drag start" : handle.id == Self.endID ? "Drag finish" : "Drag stop \(handle.label)")
                            }
                        }
                    }
                    .mapStyle(.standard(elevation: .flat)).mapControlVisibility(.hidden)
                    .onTapGesture(coordinateSpace: .named("waypointMap")) { point in
                        guard addingStop, stops.count < 8, let coordinate = proxy.convert(point, from: .named("waypointMap")) else { return }
                        remember()
                        stops.append(TripWaypoint(name: "Map stop \(stops.count + 1)", point: RoutePoint(coordinate), waitSeconds: 0))
                        addingStop = false
                    }
                    .coordinateSpace(name: "waypointMap")
                }
                .clipShape(RoundedRectangle(cornerRadius: 16)).padding(.horizontal)
                HStack {
                    Button { addingStop.toggle() } label: {
                        Label(addingStop ? "Cancel add" : "Add stop", systemImage: "plus.circle")
                            .frame(maxWidth: .infinity, minHeight: 44).contentShape(Rectangle())
                    }.disabled(stops.count >= 8)
                    Button { undo() } label: {
                        Label("Undo", systemImage: "arrow.uturn.backward")
                            .frame(maxWidth: .infinity, minHeight: 44).contentShape(Rectangle())
                    }.disabled(undoFrames.isEmpty)
                }.buttonStyle(.borderless).padding(.horizontal)
                Text("Orange dashed lines show the order only. They are not the route. Reorder or remove stops in the route timeline after saving.")
                    .font(.caption).foregroundStyle(.secondary).padding(.horizontal)
            }.padding(.bottom)
            .shiftScreen().loggedNavigationTitle("Edit route on map").navigationBarTitleDisplayMode(.inline)
            .onAppear {
                let line = MKPolyline(coordinates: route.coordinates, count: route.coordinates.count)
                let rect = line.boundingMapRect
                position = .rect(rect.insetBy(dx: -max(100, rect.width * 0.2), dy: -max(100, rect.height * 0.2)))
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { onSave(start, finish, stops); dismiss() }
                        .disabled(draggingID != nil)
                }
            }
        }
    }
    private func remember() {
        undoFrames.append(Frame(start: start, finish: finish, stops: stops))
        if undoFrames.count > 40 { undoFrames.removeFirst() }
    }
    private func undo() {
        guard let frame = undoFrames.popLast() else { return }
        start = frame.start; finish = frame.finish; stops = frame.stops
    }
    private func handleDrag(_ handle: Handle, proxy: MapProxy) -> some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .named("waypointMap"))
            .onChanged { value in
                if draggingID == nil {
                    guard let projected = proxy.convert(handle.point.coordinate, to: .named("waypointMap")) else { return }
                    remember()
                    draggingID = handle.id
                    dragOrigin = projected
                    addingStop = false
                }
                guard draggingID == handle.id, let origin = dragOrigin,
                      let coordinate = proxy.convert(CGPoint(x: origin.x + value.translation.width,
                          y: origin.y + value.translation.height), from: .named("waypointMap")) else { return }
                let point = RoutePoint(coordinate)
                guard point.isValid else { return }
                if handle.id == Self.startID { start = point }
                else if handle.id == Self.endID { finish = point }
                else if let index = stops.firstIndex(where: { $0.id == handle.id }) { stops[index].point = point }
            }
            .onEnded { _ in dragOrigin = nil; draggingID = nil }
    }
}

struct RouteSectionChoiceSheet: View {
    @EnvironmentObject private var preferences: SessionPreferences
    @Environment(\.shiftEditorEmbedded) private var embedded
    let title: String
    let original: RouteLegChoice
    let onSave: (RouteLegChoice, RouteLegPathChoice) -> Void
    let keepsExactPath: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var mode: TravelMode
    @State private var speed: Double
    @State private var confirmRoadChange = false

    init(title: String, choice: RouteLegChoice, keepsExactPath: Bool = false,
         onSave: @escaping (RouteLegChoice, RouteLegPathChoice) -> Void) {
        self.title = title; original = choice; self.onSave = onSave
        self.keepsExactPath = keepsExactPath
        _mode = State(initialValue: choice.mode); _speed = State(initialValue: choice.speedMPH)
    }
    var body: some View {
        ShiftEditorContainer {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(title).font(.subheadline).foregroundStyle(.secondary)
                    VStack(spacing: 0) {
                        ForEach(TravelMode.allCases) { item in
                            Button { mode = item } label: {
                                HStack(spacing: 12) {
                                    Label(item.title, systemImage: item.icon)
                                    Spacer()
                                    if mode == item { Image(systemName: "checkmark").foregroundStyle(LocusTheme.accent) }
                                }.frame(minHeight: 44).contentShape(Rectangle())
                            }.buttonStyle(.plain).accessibilityAddTraits(mode == item ? .isSelected : [])
                        }
                    }
                    Divider()
                    HStack {
                        Text("Speed").font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(preferences.speedUnit.formatted(mph: speed)).monospacedDigit()
                    }
                    SpeedSlider(mph: $speed, mode: mode)
                }.padding(20).frame(maxWidth: 600).frame(maxWidth: .infinity)
            }
            .shiftScreen().loggedNavigationTitle("Leg movement").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !embedded { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        if RouteLegPathPolicy.needsChoice(from: original.mode, to: mode, exactPath: keepsExactPath) { confirmRoadChange = true }
                        else { save(.keepCurrent) }
                    }
                }
            }
            .onChange(of: mode) { _, new in speed = new.defaultSpeedMPH }
            .loggedConfirmationDialog("Which path?", isPresented: $confirmRoadChange, titleVisibility: .visible) {
                Button("Keep current path") { save(.keepCurrent) }
                Button("Recalculate directions") { save(.recalculate) }
                Button("Cancel", role: .cancel) { }
            } message: { Text("Keep the path and change movement only, or find directions for the new mode.") }
        }
    }
    private func save(_ path: RouteLegPathChoice) {
        onSave(RouteLegChoice(mode: mode, speedMPH: mode.clampedSpeedMPH(speed)), path)
        dismiss()
    }
}
