import SwiftUI
import UniformTypeIdentifiers

enum CloudHelp {
    // Published with the matching source update; no credentials in documentation URLs.
    static let guide = URL(string: "https://github.com/N3moStudio/Elsepin-Releases/blob/main/docs/CLOUD-GUIDE.md")!
}

struct RemoteFindMyView: View {
    @EnvironmentObject private var session: SpoofSession
    @EnvironmentObject private var preferences: SessionPreferences
    @ObservedObject private var remote = RemoteFindMyController.shared
    @State private var confirmDisconnect = false
    var body: some View {
        List {
            if remote.paired {
                Section {
                    Toggle("Check while spoofing", isOn: $remote.enabled)
                    Toggle("Check Find My iPhone", isOn: $remote.findMyEnabled)
                    Toggle("Check Life360", isOn: $remote.life360Enabled).disabled(remote.helperWebsite == nil)
                    if remote.life360Enabled && remote.supportsLife360 == false {
                        Text("Update your helper to enable Life360.").font(.footnote).foregroundStyle(.secondary)
                    }
                } footer: { Text("Find My uses Devices. People is not connected.") }.shiftSettingsRows()
                Section("Latest checks") {
                    if remote.findMyEnabled { FindMyEvidenceSummary() }
                    if remote.life360Enabled { FindMyEvidenceSummary(life360: true) }
                    if let message = remote.checkMessage { Text(message).font(.subheadline).foregroundStyle(.secondary) }
                    Button { remote.checkNow() } label: {
                        Label(remote.checking ? "Checking…" : "Check now", systemImage: "arrow.clockwise").frame(minHeight: 44)
                    }.disabled(!remote.enabled || !session.isSpoofing || remote.checking)
                    if !session.isSpoofing { Text("Start a location session to compare reports.").font(.footnote).foregroundStyle(.secondary) }
                }.shiftSettingsRows()
                Section("Notifications & Live Activity") {
                    Toggle("Warn me if checks fail", isOn: $remote.alerts)
                        .onChange(of: remote.alerts) { _, value in
                            if value { Task { _ = await SessionNotifications.shared.requestPermission() } }
                        }
                    Toggle("Show Find My iPhone status", isOn: $preferences.showFindMyStatus)
                    Toggle("Show Life360 status", isOn: $preferences.showLife360Status)
                }.shiftSettingsRows()
                if let website = remote.helperWebsite, remote.supportsNearby == true {
                    Section {
                        Link(destination: website.appendingPathComponent("nearby")) {
                            Label("Nearby alerts", systemImage: "bell.badge").frame(minHeight: 44)
                        }
                    } footer: { Text("Managed on your website. Pause nearby alerts there.") }.shiftSettingsRows()
                }
            } else {
                Section { Text("Connect your helper to check Find My Devices or Life360.").foregroundStyle(.secondary) }.shiftSettingsRows()
            }
            Section("Advanced") {
                NavigationLink(remote.paired ? "Connection settings" : "Connect your helper") { RemoteFindMySetupView() }
                if let website = remote.helperWebsite {
                    Link(destination: website) { Label("Open helper / sign in", systemImage: "safari").frame(minHeight: 44) }
                }
                if remote.paired {
                    Button { Task { await remote.testConnection() } } label: {
                        if remote.testingConnection {
                            ElsepinProgressLabel("Connecting…", state: .connecting, lowPower: session.lowPower)
                        } else {
                            Text("Test connection")
                        }
                    }.frame(minHeight: 44).disabled(remote.testingConnection)
                    if let message = remote.connectionMessage { Text(message).font(.subheadline).foregroundStyle(.secondary) }
                }
                Link(destination: CloudHelp.guide) { Label("Setup guide on GitHub", systemImage: "book.closed").frame(minHeight: 44) }
                if remote.paired { Button("Disconnect helper", role: .destructive) { confirmDisconnect = true }.frame(minHeight: 44) }
            }.shiftSettingsRows()
        }.shiftSettingsScreen().loggedNavigationTitle("Cloud helper").navigationBarTitleDisplayMode(.inline)
        .loggedConfirmationDialog("Disconnect cloud checks?", isPresented: $confirmDisconnect, titleVisibility: .visible) {
            Button("Disconnect helper", role: .destructive) { remote.unpair() }
        } message: { Text("Website Nearby alerts stay separate. Pause them on your helper website.") }
    }
}

/// The Apple report and the helper response are separate pieces of evidence.
struct FindMyEvidenceSummary: View {
    var useWindows = false
    var life360 = false
    @ObservedObject private var remote = RemoteFindMyController.shared
    @ObservedObject private var computer = CompanionClient.shared
    private var state: RemoteFindMyState {
        if life360 { return useWindows ? computer.life360ActivityStatus?.state ?? .ready : remote.life360State }
        return useWindows ? computer.activityStatus?.state ?? .ready : remote.state
    }
    private var reportDate: Date? {
        useWindows ? computer.reports.first { $0.provider == (life360 ? "life360" : "findmy-device") }?.locatedAt.map { Date(timeIntervalSince1970: $0) } : (life360 ? remote.life360ReportDate : remote.reportDate)
    }
    private var repliedAt: Date? { useWindows ? computer.connectedAt : remote.checkedAt }
    var body: some View {
        ForegroundTimeline { _ in
            VStack(alignment: .leading, spacing: 12) {
                Label(life360 ? state.life360Title : state.title, systemImage: state == .match ? "checkmark.circle.fill" : "clock")
                    .font(.headline).foregroundStyle(state == .match ? LocusTheme.statusGood : .primary)
                if let date = reportDate { evidenceDate(life360 ? "Life360’s location report" : "Apple’s location report", date: date) }
                if let date = repliedAt { evidenceDate("Helper response", date: date) }
                if let message = useWindows ? computer.message ?? state.warning : (life360 ? state.life360Warning : state.warning) { Text(message).font(.subheadline).foregroundStyle(.secondary) }
            }.padding(.vertical, 6)
        }
    }
    private func evidenceDate(_ title: String, date: Date) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.subheadline.weight(.medium))
            Text(date, style: .relative).font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
                .accessibilityLabel(Text(title) + Text(": ") + Text(date, style: .relative))
        }
    }
}

private struct RemoteFindMySetupView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var remote = RemoteFindMyController.shared
    @State private var endpoint = ""
    @State private var helperKey = ""
    @State private var showImport = false
    @State private var pending: Data?
    @State private var error: String?
    var body: some View {
        List {
            Section {
                TextField("https://your-helper.onrender.com", text: $endpoint)
                    .keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                    .accessibilityLabel("Helper website URL")
                SecureField("Helper key", text: $helperKey).textInputAutocapitalization(.never).autocorrectionDisabled()
                Button("Connect") {
                    do { pending = try RemoteFindMyController.renderPairing(endpoint: endpoint, helperKey: helperKey) }
                    catch { self.error = "Enter your HTTPS onrender.com address and the helper key from Render’s Environment settings." }
                }.frame(minHeight: 44).disabled(endpoint.isEmpty || helperKey.isEmpty)
            } header: { Text("Connect Render") } footer: {
                Text("Use your helper key, not your Apple or Life360 password.")
            }.shiftSettingsRows()
            Section {
                Button { showImport = true } label: {
                    Label("Import setup file instead", systemImage: "square.and.arrow.down").frame(minHeight: 44)
                }
            } footer: { Text("Choose your helper’s pairing file.") }.shiftSettingsRows()
            Section("Need a helper?") {
                if let file = Bundle.main.url(forResource: "Elsepin-FindMy-Cloud", withExtension: "zip") {
                    ShareLink(item: file) { Label("Download helper files", systemImage: "square.and.arrow.up").frame(minHeight: 44) }
                }
                Link(destination: CloudHelp.guide) {
                    Label("Setup guide on GitHub", systemImage: "book.closed").frame(minHeight: 44)
                }
            }.shiftSettingsRows()
        }.shiftSettingsScreen().loggedNavigationTitle("Connect cloud helper").navigationBarTitleDisplayMode(.inline)
        .onDisappear { helperKey = "" }
        .fileImporter(isPresented: $showImport, allowedContentTypes: [.json]) { result in
            do {
                let url = try result.get()
                let access = url.startAccessingSecurityScopedResource()
                defer { if access { url.stopAccessingSecurityScopedResource() } }
                guard ((try url.resourceValues(forKeys: [.fileSizeKey])).fileSize ?? 0) <= 4096 else { throw RemoteFindMyController.RemoteError.invalid }
                let data = try Data(contentsOf: url)
                guard let link = try? JSONDecoder().decode(RemoteFindMyLink.self, from: data), link.valid else { throw RemoteFindMyController.RemoteError.invalid }
                pending = data
            } catch { if (error as NSError).code != NSUserCancelledError { self.error = error.localizedDescription } }
        }
        .loggedAlert("Connect your private cloud helper?", isPresented: Binding(get: { pending != nil }, set: { if !$0 { pending = nil } })) {
            Button("Cancel", role: .cancel) { pending = nil }
            Button("Connect") {
                if let pending { do { try remote.pair(pending); helperKey = ""; dismiss() } catch { self.error = error.localizedDescription } }
                pending = nil
            }
        } message: {
            Text("Only connect your own helper. Turning on checks shares recent spoofed points and their times with that server during your session. It reads Find My Devices and/or your selected Life360 profile; it cannot control spoofing.")
        }
        .loggedAlert("Cloud helper", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("OK", role: .cancel) { error = nil }
        } message: { Text(error ?? "") }
    }
}
