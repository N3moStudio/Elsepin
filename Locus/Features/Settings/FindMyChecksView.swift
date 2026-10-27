import SwiftUI

struct FindMyChecksView: View {
    @ObservedObject private var remote = RemoteFindMyController.shared
    @ObservedObject private var computer = CompanionClient.shared
    var body: some View {
        List {
            Section {
                NavigationLink { RemoteFindMyView() } label: {
                    helper("Cloud helper", detail: "Works with your laptop off · Wi-Fi or cellular",
                           icon: "icloud", status: remote.enabled && remote.paired ? "In use" : remote.paired ? "Saved" : "Set up")
                }
                NavigationLink { ServiceChecksView() } label: {
                    helper("Windows helper", detail: "Laptop awake · Same Wi-Fi",
                           icon: "laptopcomputer", status: computer.enabled && computer.paired ? "In use" : computer.paired ? "Saved" : "Set up")
                }
            } header: { Text("Choose your helper") } footer: {
                Text("Use one helper at a time. You can keep both setups saved and switch here.")
            }.shiftSettingsRows()
            Section("Advanced") {
                Link(destination: CloudHelp.guide) {
                    Label("Setup guide on GitHub", systemImage: "book.closed").frame(minHeight: 44)
                }
            }.shiftSettingsRows()
        }.shiftSettingsScreen().loggedNavigationTitle("Find My & Life360").navigationBarTitleDisplayMode(.inline)
    }
    private func helper(_ title: String, detail: String, icon: String, status: String) -> some View {
        HStack(spacing: 12) {
            ShiftSettingsIcon(symbol: icon, color: .purple)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
                Text(status).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            }
        }.padding(.vertical, 8).frame(minHeight: 44)
    }
}
