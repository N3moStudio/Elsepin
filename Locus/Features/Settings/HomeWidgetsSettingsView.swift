import SwiftUI

struct HomeWidgetsSettingsView: View {
    @EnvironmentObject private var session: SpoofSession
    @EnvironmentObject private var library: TripLibrary
    @State private var selected: [String] = []
    @State private var primary = ""
    @State private var message: String?
    private var choices: [WidgetLibraryItem] { HomeWidgetPublisher.choices(places: session.savedPins, trips: library.trips) }
    var body: some View {
        List {
            Section {
                SettingsHelp(title: "Add a widget", lines: [
                    "Hold an empty spot on your Home Screen → Edit → Add Widget → Elsepin.",
                    "Choose Location shortcut, then hold the added widget → Edit Widget. Pick any saved place or route start. Add more widgets and choose a different location for each.",
                    "Tapping only sets a preview pin. You must tap Teleport to pin in Elsepin, even when spoofing is already active. Your current session keeps running until you choose otherwise.",
                    "Favorite shortcut and Saved shortcuts use the shared selections below.",
                    "The medium widget shows 2 shortcuts; the large one shows 4. Some signing setups cannot share widget data; any error appears here."
                ])
            }.shiftSettingsRows()
            if let message {
                Section(HomeWidgetPublisher.available ? "Widget status" : "Signing permission missing") {
                    Text(message).font(.footnote).foregroundStyle(LocusTheme.statusWarn)
                }.shiftSettingsRows()
            }
            Section("Favorite shortcut") {
                Picker("Show", selection: $primary) {
                    Text("First selected item").tag("")
                    ForEach(choices.filter { selected.contains($0.id.uuidString) }) { Text($0.title).tag($0.id.uuidString) }
                }
            }.shiftSettingsRows().disabled(!HomeWidgetPublisher.available)
            Section {
                if choices.isEmpty { Text("Save a place or trip first.").foregroundStyle(.secondary) }
                ForEach(choices) { item in
                    Toggle(item.title, isOn: Binding(get: { selected.contains(item.id.uuidString) }, set: { enabled in
                        if enabled { if selected.count < 4 { selected.append(item.id.uuidString) } }
                        else { selected.removeAll { $0 == item.id.uuidString }; if primary == item.id.uuidString { primary = "" } }
                    })).disabled(selected.count >= 4 && !selected.contains(item.id.uuidString))
                }
            } header: { Text("Up to 4 saved shortcuts") } footer: {
                Text("Selected names are visible on your Home Screen.")
            }.shiftSettingsRows().disabled(!HomeWidgetPublisher.available)
        }.shiftSettingsScreen().loggedNavigationTitle("Home Screen widgets").navigationBarTitleDisplayMode(.inline)
        .onAppear {
            selected = UserDefaults.standard.stringArray(forKey: "locus.widget.selected") ?? Array(choices.prefix(4).map { $0.id.uuidString })
            selected = selected.filter { id in choices.contains { $0.id.uuidString == id } }
            primary = UserDefaults.standard.string(forKey: "locus.widget.primary") ?? ""
            save()
        }
        .onChange(of: selected) { _, _ in save() }.onChange(of: primary) { _, _ in save() }
    }
    private func save() {
        UserDefaults.standard.set(selected, forKey: "locus.widget.selected")
        UserDefaults.standard.set(primary, forKey: "locus.widget.primary")
        message = HomeWidgetPublisher.publish(places: session.savedPins, trips: library.trips)
    }
}
