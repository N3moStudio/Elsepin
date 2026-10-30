import SwiftUI

struct PairOnDeviceView: View {
    enum Mode {
        /// Settings sheet — Close toolbar, dismiss on Done.
        case sheet
        /// First-run setup — no toolbar; calls `onFinished` after success.
        case embedded
    }

    @EnvironmentObject private var pairing: PairingStore
    @EnvironmentObject private var preferences: SessionPreferences
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var host = PairOnDeviceService()

    var mode: Mode = .sheet
    var onFinished: (() -> Void)?

    var body: some View {
        Group {
            if mode == .sheet {
                NavigationStack {
                    scrollContent
                        .shiftScreen().loggedNavigationTitle("Pair on this iPhone")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Close") {
                                    host.resetToIdle()
                                    dismiss()
                                }
                            }
                        }
                }
            } else {
                scrollContent
            }
        }
        .onChange(of: host.phase) { _, phase in
            if case .succeeded = phase {
                pairing.refresh()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active, host.isBusy {
                _ = host.pin
            }
        }
        .onDisappear { host.resetToIdle() }
    }

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if mode == .sheet {
                    header
                } else {
                    embeddedIntro
                }

                steps

                statusCard

                actions
            }
            .padding(mode == .embedded ? 16 : 20)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No computer needed")
                .font(.title2.weight(.bold))
            Text("Start in Elsepin, then finish in iPhone Settings.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var embeddedIntro: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Follow these steps")
                .font(.headline)
            Text("Start here, then open iPhone Settings. Touch and hold Elsepin in the Dynamic Island to read the code.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var steps: some View {
        // These are instructions, not inferred completion states. The native
        // pairing service remains the only source of success or a real code.
        VStack(alignment: .leading, spacing: 0) {
            step(1, title: "Start here", detail: "Tap Start pairing. Allow Local Network and Location when asked.")
            step(2, title: "Open iPhone Settings", detail: "Privacy & Security › Developer Mode › Pair with Elsepin. Tap Pair, then enter your unlock passcode.")
            step(3, title: "Enter the pairing code", detail: "Touch and hold Elsepin in the Dynamic Island. Enter its 6-digit code in the second Settings prompt.", isLast: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .locusGlass(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func step(_ n: Int, title: String, detail: String, isLast: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(n)").font(.caption.weight(.semibold))
                .foregroundStyle(LocusTheme.accent)
                .frame(width: 24, height: 24)
                .background(LocusTheme.accent.opacity(0.10), in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, isLast ? 0 : 20)
        }
        .fixedSize(horizontal: false, vertical: true)
        // Background receives the final wrapped row height. It needs no
        // geometry state, timer or animated progress/completion assumption.
        .background(alignment: .leading) {
            if !isLast {
                Rectangle().fill(LocusTheme.accent.opacity(0.22))
                    .frame(width: 1).padding(.leading, 11.5).padding(.top, 24)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(n) of 3. \(title). \(detail)")
    }

    @ViewBuilder
    private var statusCard: some View {
        VStack(spacing: 14) {
            switch host.phase {
            case .idle:
                Label("Ready when you are", systemImage: "antenna.radiowaves.left.and.right")
                    .foregroundStyle(.secondary)
            case .advertising:
                ProgressView()
                Text("Waiting for Settings…")
                    .font(.headline)
                Text("In Developer Mode tap Pair with Elsepin → Pair.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Text("The code will appear in the expanded Dynamic Island when iOS connects. Live Activities must be enabled.")
                    .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
            case .deviceConnected:
                ProgressView()
                Text("iPhone connected")
                    .font(.headline)
                Text("Generating your 6-digit code…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .awaitingPIN(let pin):
                Text("Enter this code in Settings")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(pin)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .tracking(10)
                    .monospacedDigit()
                    .foregroundStyle(LocusTheme.accent)
                    .textSelection(.enabled)
                    .privacySensitive()
                    .accessibilityLabel("Pairing code \(pin.map(String.init).joined(separator: " "))")
                Text("Second prompt only — after your unlock passcode.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            case .succeeded:
                Image(systemName: "checkmark.seal.fill")
                    .font(.largeTitle)
                    .foregroundStyle(LocusTheme.statusGood)
                Text("Paired")
                    .font(.title3.weight(.bold))
                Text(mode == .embedded
                     ? "Next we’ll set up LocalDevVPN."
                     : "RPPairing file saved. Connect LocalDevVPN, then teleport.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            case .failed(let message):
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(LocusTheme.statusWarn)
                Text("Pairing failed")
                    .font(.title3.weight(.bold))
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .locusGlass(.regular, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private var actions: some View {
        switch host.phase {
        case .idle, .failed:
            Button {
                host.acknowledgeFailure()
                host.start(pairingStore: pairing, preferences: preferences)
            } label: {
                Text(host.phase == .idle ? "Start pairing" : "Try again")
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(ShiftActionStyle())
        case .succeeded:
            Button {
                if let onFinished {
                    onFinished()
                } else {
                    dismiss()
                }
            } label: {
                Text(mode == .embedded ? "Continue" : "Done")
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(ShiftActionStyle())
        case .advertising, .deviceConnected, .awaitingPIN:
            Text({
                switch host.phase {
                case .awaitingPIN: return "Type the code above into the second Settings prompt."
                case .deviceConnected: return "Connected — code coming next."
                default: return "Waiting for iOS to connect… don’t force-quit Elsepin."
                }
            }())
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
        }
    }
}
