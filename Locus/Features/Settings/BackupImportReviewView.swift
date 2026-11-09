import SwiftUI

struct BackupImportReviewView: View {
    @EnvironmentObject private var session: SpoofSession
    @EnvironmentObject private var library: TripLibrary
    @EnvironmentObject private var planner: RoutePlanner
    @EnvironmentObject private var preferences: SessionPreferences
    let backup: LibraryBackup
    let finished: (String) -> Void
    @Binding var selection: BackupImportSelection
    @State private var confirmation = false
    @State private var confirmedContext: BackupImportContext?
    @State private var message: String?

    private var current: BackupImportContext {
        BackupImportContext(preferences: session.backupPreferences,
            places: session.savedPins.map(\.backupPlace), trips: library.trips, areas: session.namedAreas)
    }

    var body: some View {
        let review = BackupImportReview(backup: backup, current: current)
        let result = Result { try review.plan(selection) }
        let plan = try? result.get()
        List {
            Section {
                if let plan { overview(plan, review: review) }
                else if case .failure(let error) = result { Text(error.localizedDescription).font(.footnote) }
            } header: { Text("Overview") } footer: {
                Text("Selected changes, compared with your current data.")
            }.shiftSettingsRows()

            if !review.changes.isEmpty {
                Section {
                    DisclosureGroup("Settings · \(selection.settings.intersection(review.changedSettings).count) selected") {
                        selectionButtons(all: review.changedSettings, values: $selection.settings, name: "settings")
                        ForEach(BackupSettingGroup.allCases) { group in
                            let changes = review.changes.filter { $0.changesValue && $0.key.group == group }
                            if !changes.isEmpty {
                                Text(group.rawValue).font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                                ForEach(changes) { change in
                                    BackupImportCheckRow(title: change.key.title, detail: "\(change.before) → \(change.after)",
                                        isSelected: selected(change.key, in: $selection.settings))
                                }
                            }
                        }
                        let unchanged = review.changes.filter { !$0.changesValue }
                        if !unchanged.isEmpty {
                            DisclosureGroup("Already the same · \(unchanged.count)") {
                                ForEach(unchanged) { change in
                                    BackupImportCheckRow(title: change.key.title, detail: change.before,
                                        isSelected: .constant(false), enabled: false)
                                }
                            }
                        }
                    }
                } header: { Text("Settings changes") } footer: {
                    Text("Unchecked settings stay as they are. Overview shows the final selected values.")
                }.shiftSettingsRows()
            }
            if !backup.trips.isEmpty {
                Section {
                    DisclosureGroup("Routes · \(selection.trips.intersection(review.defaultSelection.trips).count) selected") {
                        selectionButtons(all: review.defaultSelection.trips, values: $selection.trips, name: "routes")
                        ForEach(backup.trips) { trip in
                            let exists = review.existingTrips.contains(trip.id)
                            BackupImportCheckRow(title: trip.name,
                                detail: exists ? "Already saved — keep current version" : "Add route · \(trip.points.count) points · \(trip.stops.count) stops\n\(trip.originName) → \(trip.destinationName)",
                                isSelected: selected(trip.id, in: $selection.trips), enabled: !exists)
                        }
                    }
                } header: { Text("Routes to add") }.shiftSettingsRows()
            }
            if !backup.places.isEmpty {
                Section {
                    DisclosureGroup("Pins · \(selection.places.intersection(review.defaultSelection.places).count) selected") {
                        selectionButtons(all: review.defaultSelection.places, values: $selection.places, name: "places")
                        ForEach(backup.places, id: \.id) { place in
                            let exists = review.existingPlaces.contains(place.id)
                            BackupImportCheckRow(title: place.name,
                                detail: exists ? "Already saved — keep current version" : "\(place.latitude.formatted(.number.precision(.fractionLength(5)))), \(place.longitude.formatted(.number.precision(.fractionLength(5))))",
                                isSelected: selected(place.id, in: $selection.places), enabled: !exists)
                        }
                    }
                } header: { Text("Pins to add") }.shiftSettingsRows()
            }
            if let areas = backup.areas, !areas.isEmpty {
                Section {
                    DisclosureGroup("Named areas · \(selection.areas.intersection(review.defaultSelection.areas).count) selected") {
                        selectionButtons(all: review.defaultSelection.areas, values: $selection.areas, name: "areas")
                        ForEach(areas) { area in
                            let exists = review.existingAreas.contains(area.id)
                            BackupImportCheckRow(title: area.name,
                                detail: exists ? "Already saved — keep current boundary" : "Add named area · \(area.points.count) boundary points",
                                isSelected: selected(area.id, in: $selection.areas), enabled: !exists)
                        }
                    }
                } header: { Text("Areas to add") }.shiftSettingsRows()
            }
            Section {
                if let plan {
                    if plan.settingKeys.contains(.recentHistoryRetention),
                       let retention = plan.preferences?.display?.recentHistoryRetention, retention != .forever {
                        Text("The selected history limit removes older recent locations: \(retention.title).")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
                Button("Import selected changes") {
                    confirmedContext = current
                    confirmation = true
                }
                .frame(minHeight: 44)
                .disabled((plan?.count ?? 0) == 0 || plan?.needsStoppedSession(hasSession: session.hasSession, isBusy: session.isBusy) == true)
                Button("Cancel import", role: .cancel) { finished("Import canceled. Nothing was changed.") }
            } footer: {
                if plan?.needsStoppedSession(hasSession: session.hasSession, isBusy: session.isBusy) == true {
                    Text("Stop spoofing to apply selected settings that affect movement and session controls. You can import only library items while spoofing.")
                }
            }.shiftSettingsRows()
            if let message { Section { Text(message).font(.footnote) }.shiftSettingsRows() }
        }
        .shiftSettingsScreen().loggedNavigationTitle("Review import").navigationBarTitleDisplayMode(.inline)
        .loggedConfirmationDialog("Apply selected changes?", isPresented: $confirmation, titleVisibility: .visible) {
            Button("Import selected changes") { apply() }
            Button("Keep reviewing", role: .cancel) { }
        } message: {
            Text((plan?.summary ?? "No changes selected") + ". Unchecked items stay unchanged.")
        }
    }

    @ViewBuilder private func overview(_ plan: BackupImportPlan, review: BackupImportReview) -> some View {
        if plan.count == 0 {
            Text("No changes selected").foregroundStyle(.secondary)
        } else {
            if !plan.places.isEmpty || !plan.trips.isEmpty || !plan.areas.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Added").font(.subheadline.weight(.semibold))
                    VStack(spacing: 6) {
                        if !plan.places.isEmpty { LabeledContent("Pins", value: "\(plan.places.count)") }
                        if !plan.trips.isEmpty { LabeledContent("Routes", value: "\(plan.trips.count)") }
                        if !plan.areas.isEmpty { LabeledContent("Areas", value: "\(plan.areas.count)") }
                    }.padding(.leading, 16)
                }
            }
            let changes = review.settingChanges(in: plan)
            if !changes.isEmpty {
                DisclosureGroup("Changed settings · \(changes.count)") {
                    ForEach(BackupSettingGroup.allCases) { group in
                        let grouped = changes.filter { $0.key.group == group }
                        if !grouped.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(group.rawValue).font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                                ForEach(grouped) { change in
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(change.key.title)
                                        Text("\(change.before) → \(change.after)").font(.footnote).foregroundStyle(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }.padding(.leading, 16).accessibilityElement(children: .combine)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func selected<ID: Hashable>(_ id: ID, in values: Binding<Set<ID>>) -> Binding<Bool> {
        Binding(get: { values.wrappedValue.contains(id) }, set: { flag in
            if flag { values.wrappedValue.insert(id) } else { values.wrappedValue.remove(id) }
        })
    }
    private func selectionButtons<ID: Hashable>(all: Set<ID>, values: Binding<Set<ID>>, name: String) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                Button("Select all \(name)") { values.wrappedValue = all }.disabled(all.isEmpty)
                Spacer()
                Button("Select none") { values.wrappedValue = [] }.disabled(values.wrappedValue.isEmpty)
            }
            VStack(alignment: .leading) {
                Button("Select all \(name)") { values.wrappedValue = all }.disabled(all.isEmpty)
                Button("Select none") { values.wrappedValue = [] }.disabled(values.wrappedValue.isEmpty)
            }
        }.buttonStyle(.borderless).frame(minHeight: 44)
    }
    private func apply() {
        guard library.isCurrentWorkspace, !DevModeController.shared.switching else {
            message = "The data workspace changed. Reopen the backup and review it again."; return
        }
        let context = current
        guard context == confirmedContext else {
            message = "Your library or settings changed while reviewing. Check the updated preview and confirm again."
            return
        }
        do {
            let plan = try BackupImportReview(backup: backup, current: context).plan(selection)
            guard !plan.needsStoppedSession(hasSession: session.hasSession, isBusy: session.isBusy) else {
                message = "Stop spoofing before applying changed settings, or uncheck Settings to import only library items."
                return
            }
            guard plan.count > 0 else { return }
            let places = try LibraryMerge.places(local: context.places, incoming: plan.places)
            let areas = plan.areas.isEmpty ? context.areas : try LibraryMerge.areas(local: context.areas, incoming: plan.areas)
            if !plan.trips.isEmpty {
                guard try library.merge(plan.trips) else { message = library.error; return }
            }
            if !plan.areas.isEmpty, !session.replaceNamedAreas(areas) {
                message = "Areas could not be saved. Your settings are unchanged. Any routes already added will be kept on retry."
                return
            }
            if !plan.places.isEmpty || plan.preferences != nil {
                session.importLibraryPlaces(places, settings: plan.preferences)
            }
            if let settings = plan.preferences { planner.preferWalkingPaths = settings.preferWalkingPaths }
            finished("Import complete. \(plan.summary).")
        } catch { message = error.localizedDescription }
    }
}

private struct BackupImportCheckRow: View {
    let title: String
    let detail: String
    @Binding var isSelected: Bool
    var enabled = true
    var body: some View {
        Button { isSelected.toggle() } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: enabled && isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(enabled && isSelected ? Color.accentColor : Color.secondary)
                    .font(.title3).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).foregroundStyle(.primary)
                    Text(detail).font(.footnote).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading).contentShape(Rectangle())
        }
        .buttonStyle(.plain).disabled(!enabled)
        .accessibilityElement(children: .combine)
        .accessibilityValue(enabled ? (isSelected ? "Selected for import" : "Not selected") : "No change")
        .accessibilityHint(enabled ? "Double tap to include or exclude this change." : "Your current item is kept.")
    }
}
