import SwiftUI

struct JoystickPad: View {
    var radius: CGFloat = 52
    var inputEnabled = true
    var onChange: (CGVector) -> Void

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var nudgeTask: Task<Void, Never>?
    @State private var dragOffset: CGSize = .zero
    @State private var input = JoystickInput()
    @GestureState private var touchActive = false

    private var available: Bool {
        inputEnabled && isEnabled && scenePhase == .active && radius.isFinite && radius > 0
    }
    private var displayRadius: CGFloat { radius.isFinite && radius > 0 ? radius : 52 }

    var body: some View {
        ZStack {
            Circle()
                .frame(width: displayRadius * 2 + 28, height: displayRadius * 2 + 28)
                .locusGlass(.clear, in: Circle())

            Circle()
                .stroke(LocusTheme.accent.opacity(0.4), lineWidth: 2)
                .frame(width: displayRadius * 2, height: displayRadius * 2)

            Circle()
                .fill(LocusTheme.accent)
                .frame(width: 44, height: 44)
                .shadow(color: LocusTheme.accent.opacity(0.45), radius: 8)
                .offset(dragOffset)
        }
        .frame(width: displayRadius * 2 + 28, height: displayRadius * 2 + 28)
        .contentShape(Circle())
        // Measure against the stationary base, never the thumb we're moving.
        // Position relative to its center also makes touching the ring intuitive.
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .updating($touchActive) { _, active, _ in active = true }
                .onChanged { value in
                    guard available else { stopMovement(); return }
                    guard input.updateTouch() else { return }
                    nudgeTask?.cancel(); nudgeTask = nil
                    let center = radius + 14
                    let vector = JoystickInput.vector(x: Double(value.location.x - center),
                                                      y: Double(value.location.y - center), radius: Double(radius))
                    var transaction = Transaction(); transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        dragOffset = CGSize(width: CGFloat(vector.x) * radius, height: CGFloat(vector.y) * radius)
                    }
                    onChange(CGVector(dx: CGFloat(vector.x), dy: CGFloat(vector.y)))
                }
                .onEnded { _ in
                    guard input.finishTouch() else { return }
                    finishMovement(animated: available)
                }
        )
        .allowsHitTesting(available)
        .accessibilityLabel("Movement joystick")
        .accessibilityHint("Directions follow the map on screen. Choose a direction to move briefly, or Stop movement.")
        .accessibilityRepresentation {
            VStack {
                directionButton("Move up on map", vector: CGVector(dx: 0, dy: -1))
                HStack {
                    directionButton("Move left on map", vector: CGVector(dx: -1, dy: 0))
                    Button("Stop movement") { stopMovement(force: true) }
                    directionButton("Move right on map", vector: CGVector(dx: 1, dy: 0))
                }
                directionButton("Move down on map", vector: CGVector(dx: 0, dy: 1))
            }.disabled(!available)
        }
        .onChange(of: touchActive) { _, active in
            // Unlike onEnded, GestureState also resets when iOS cancels the touch.
            // An ordinary release already finished; it must not stop a newer nudge.
            if !active, input.finishTouch() { finishMovement(animated: available) }
        }
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { _ in stopMovement() }
        .onAppear { if !touchActive { _ = input.finishTouch() } }
        .onDisappear { stopMovement() }
        .onChange(of: radius) { _, _ in stopMovement() }
        .onChange(of: available) { _, enabled in if !enabled { stopMovement() } }
        .onChange(of: reduceMotion) { _, _ in stopMovement() }
    }

    private func directionButton(_ title: String, vector: CGVector) -> some View {
        Button(title) {
            guard available, let id = input.beginNudge() else { return }
            nudgeTask?.cancel()
            onChange(vector)
            nudgeTask = Task { @MainActor in
                do { try await Task.sleep(nanoseconds: 250_000_000) } catch { return }
                guard !Task.isCancelled, input.finishNudge(id) else { return }
                onChange(.zero)
                nudgeTask = nil
            }
        }.frame(minWidth: 44, minHeight: 44)
    }
    private func stopMovement(force: Bool = false) {
        let hadMovement = input.hasMovement
        input.interrupt(gestureActive: touchActive)
        // The hidden expanded pad must not stop input owned by the compact pad.
        finishMovement(animated: false, notify: force || hadMovement)
    }

    private func finishMovement(animated: Bool, notify: Bool = true) {
        nudgeTask?.cancel(); nudgeTask = nil
        // Stop the movement timer now, independently of the thumb's visual return.
        if notify { onChange(.zero) }
        var transaction = Transaction(animation: animated && !reduceMotion
            ? .spring(response: 0.25, dampingFraction: 1) : nil)
        transaction.disablesAnimations = !animated || reduceMotion
        withTransaction(transaction) { dragOffset = .zero }
    }
}
