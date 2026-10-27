import SwiftUI

struct AppResetSection: View {
    @EnvironmentObject private var session: SpoofSession
    @EnvironmentObject private var reset: AppResetController
    @State private var reviewing: AppResetScope?
    var body: some View {
        Section {
            Button("Restore default settings…") { reviewing = .settings }
                .frame(minHeight: 44)
            NavigationLink { AppWipeChoicesView() } label: {
                Label("Wipe everything…", systemImage: "trash").foregroundStyle(.red)
            }.frame(minHeight: 44)
        } header: { Text("Reset Elsepin") } footer: {
            Text("Review what will be removed before confirming. Stop spoofing completely first. Pairing and connection checks must also finish.")
        }.shiftSettingsRows()
        .disabled(reset.isResetting || session.hasSession || session.isBusy)
        .sheet(item: $reviewing) { AppResetReview(scope: $0) }
    }
}

private struct AppWipeChoicesView: View {
    @State private var reviewing: AppResetScope?
    var body: some View {
        List {
            Section {
                choice(.full, detail: "Remove local data, settings and pairing. Start setup again.")
                choice(.keepSetup, detail: "Remove local data and settings. Keep device pairing, the tunnel address and setup progress.")
            } footer: { Text("Both choices permanently delete saved routes, places, areas and Recently Deleted. Neither choice changes iOS settings or deletes exports in Files.") }.shiftSettingsRows()
        }.shiftSettingsScreen().loggedNavigationTitle("Wipe everything").navigationBarTitleDisplayMode(.inline)
        .sheet(item: $reviewing) { AppResetReview(scope: $0) }
    }
    private func choice(_ scope: AppResetScope, detail: String) -> some View {
        Button { reviewing = scope } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(scope.title).foregroundStyle(.red)
                Text(detail).font(.footnote).foregroundStyle(.secondary)
            }.frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
        }
    }
}

private struct AppResetReview: View {
    let scope: AppResetScope
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SpoofSession
    @EnvironmentObject private var pairing: PairingStore
    @EnvironmentObject private var preferences: SessionPreferences
    @EnvironmentObject private var library: TripLibrary
    @EnvironmentObject private var privacy: AppPrivacyController
    @EnvironmentObject private var updates: AppUpdateController
    @EnvironmentObject private var reset: AppResetController
    var body: some View {
        NavigationStack {
            List {
                Section("Review reset") {
                    Text(scope.title).font(.headline)
                    Text(scope.detail).font(.subheadline)
                    Text(scope.wipesData
                        ? "Open drafts will close. Deleted data cannot be recovered. Export a backup first if you want to keep it."
                        : "Open drafts will close. Your saved library and connection setup will stay available.")
                        .font(.footnote).foregroundStyle(.secondary)
                }.shiftSettingsRows()
                Section {
                    Button(scope.title, role: .destructive) {
                        dismiss()
                        Task {
                            await reset.perform(scope, session: session, pairing: pairing,
                                preferences: preferences, library: library, privacy: privacy, updates: updates)
                        }
                    }.frame(minHeight: 44).disabled(reset.isResetting || session.hasSession || session.isBusy)
                } footer: { Text("If a reset step fails, Elsepin stops and tells you which steps already finished. Pairing and setup are removed last.") }.shiftSettingsRows()
            }.shiftSettingsScreen().loggedNavigationTitle("Confirm reset").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }
}
