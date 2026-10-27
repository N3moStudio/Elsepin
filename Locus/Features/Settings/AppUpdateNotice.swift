import SwiftUI

struct AppUpdateNotice: View {
    let release: StableRelease
    let dismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                Label("Elsepin \(release.version) is available", systemImage: "arrow.down.circle")
                    .font(.headline).fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)
                Button(action: dismiss) {
                    Image(systemName: "xmark").font(.body.weight(.medium))
                        .foregroundStyle(.secondary).frame(width: 44, height: 44).contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Dismiss update notice")
                .accessibilityHint("Hides this release. A newer official release can appear later.")
            }
            Text("An official release is ready on GitHub.")
                .font(.subheadline).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Link(destination: release.url) {
                Label("More info", systemImage: "arrow.up.right")
                    .font(.subheadline.weight(.semibold)).frame(minHeight: 44)
            }
            .buttonStyle(.borderless)
            .accessibilityHint("Opens this release’s notes and downloads on GitHub.")
        }.padding(.vertical, 4)
    }
}

struct AppUpdateStatusSection: View {
    @EnvironmentObject private var updates: AppUpdateController
    var body: some View {
        Section {
            Button {
                Task { await updates.checkNow() }
            } label: {
                HStack {
                    Label(updates.isChecking ? "Checking…" : "Check for updates now", systemImage: "arrow.clockwise")
                    Spacer()
                    if updates.isChecking { ProgressView().accessibilityLabel("Checking GitHub") }
                }.frame(minHeight: 44)
            }.disabled(updates.isChecking)
            if let result = updates.manualResult {
                Text(result).font(.subheadline).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let release = updates.availableUpdate {
                Link(destination: release.url) {
                    Label("Elsepin \(release.version) release details", systemImage: "arrow.up.right")
                        .fixedSize(horizontal: false, vertical: true).frame(minHeight: 44)
                }
            } else {
                Link("Official releases on GitHub", destination: URL(string: "https://github.com/N3moStudio/Elsepin-Releases/releases/latest")!)
                    .frame(minHeight: 44)
            }
            if updates.state.lastCheckFailed {
                Text("Couldn’t check for updates. Elsepin will try again another day.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            if let date = updates.state.lastChecked {
                LabeledContent("Last checked") { Text(date, format: .dateTime.month(.abbreviated).day().hour().minute()) }
                    .font(.footnote).foregroundStyle(.secondary)
            }
        } header: { Text("Software updates") } footer: {
            Text("Automatic checks run once a day while the app is open. Check manually anytime. Official releases only; nothing downloads automatically.")
        }
        .shiftSettingsRows()
    }
}

#Preview("Official update") {
    List {
        Section {
            AppUpdateNotice(release: StableRelease(id: 1, tag: "v2.6.0", url: URL(string: "https://github.com/N3moStudio/Elsepin-Releases/releases/tag/v2.6.0")!), dismiss: {})
        }.shiftSettingsRows()
    }.shiftSettingsScreen()
}
