import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    var isRoot = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var preferences: SessionPreferences
    @EnvironmentObject private var updates: AppUpdateController
    @Environment(\.scenePhase) private var scenePhase
    @State private var search = ""
    @ObservedObject private var demo = DevModeController.shared

    var body: some View {
        NavigationStack {
            List {
                if search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    if let release = updates.notice {
                        Section { AppUpdateNotice(release: release) { updates.dismiss(release) } }
                            .shiftSettingsRows()
                    }
                    if demo.enabled {
                        Section {
                            NavigationLink { ExperimentalFeaturesView() } label: {
                                Label("Dev Mode · Demo data", systemImage: "hammer")
                            }
                        }.shiftSettingsRows()
                    }
                    settingsIdentity
                    Section("Your connection") {
                        NavigationLink { ConnectionSettingsView() } label: { SettingsConnectionSummary() }
                        setting(.remoteFindMy)
                    }.shiftSettingsRows()
                    Section("Display & alerts") {
                        setting(.activity, value: preferences.liveActivities ? "On" : "Off")
                        setting(.widgets)
                        setting(.notifications)
                    }.shiftSettingsRows()
                    Section("Movement") {
                        setting(.speeds)
                        setting(.shortcuts)
                        setting(.recovery)
                    }.shiftSettingsRows()
                    Section("Your data") {
                        setting(.privacy)
                        setting(.backup)
                    }.shiftSettingsRows()
                    Section("Help & updates") {
                        setting(.updates, value: updates.availableUpdate == nil ? nil : "New")
                        setting(.report)
                        setting(.diagnostics)
                        setting(.experimental)
                        setting(.about)
                    }.shiftSettingsRows()
                    Section { ShiftSignature().frame(maxWidth: .infinity).padding(.vertical, 8) }
                        .listRowBackground(Color.clear)
                } else {
                    let matches = SettingsDestination.results(for: search)
                    if matches.isEmpty { ContentUnavailableView.search(text: search).listRowBackground(Color.clear) }
                    else { Section("Results") { ForEach(matches) { setting($0) } }.shiftSettingsRows() }
                }
            }
            .shiftSettingsScreen().loggedNavigationTitle("Settings")
            // Keep the title compact, while the native drawer still reveals search
            // on scroll. Reserve content spacing instead of overlaying a search bar.
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Find a setting")
            .contentMargins(.top, 16, for: .scrollContent)
            .task(id: scenePhase) {
                guard scenePhase == .active else { return }
                await updates.checkIfDue()
            }
            .toolbar {
                if !isRoot { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            }
        }
    }

    private var settingsIdentity: some View {
        // Intentionally roomier than the compact settings rows: the user kept
        // this larger identity card while choosing compact layout elsewhere.
        Section {
            NavigationLink { AppearanceSettingsView() } label: {
                HStack(alignment: .center, spacing: 18) {
                    ShiftAppIconPreview(selection: preferences.iconSelection, size: 70)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("MAKE IT YOURS").font(.caption.weight(.semibold)).tracking(1.5).foregroundStyle(LocusTheme.accent)
                        Text("Your space. Your way.").font(.title2.weight(.bold)).foregroundStyle(.primary)
                        Text(preferences.visualStyle.title + " · " + (preferences.glassPanel ? "Glass" : "Solid"))
                            .font(.subheadline).foregroundStyle(.secondary)
                    }.fixedSize(horizontal: false, vertical: true)
                }.padding(.vertical, 16)
            }
        }.shiftSettingsRows()
    }

    private func setting(_ item: SettingsDestination, value: String? = nil) -> some View {
        NavigationLink { destination(for: item) } label: {
            HStack(spacing: 12) {
                ShiftSettingsIcon(symbol: item.symbol)
                Text(item.title).foregroundStyle(.primary).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 4)
                if let value { Text(value).font(.subheadline).foregroundStyle(.secondary) }
            }.frame(minHeight: 44)
        }
    }

    @ViewBuilder private func destination(for item: SettingsDestination) -> some View {
        switch item {
        case .updates:
            List { AppUpdateStatusSection() }.shiftSettingsScreen().loggedNavigationTitle("Software updates").navigationBarTitleDisplayMode(.inline)
        case .connection: ConnectionSettingsView()
        case .appearance: AppearanceSettingsView()
        case .activity, .notifications:
            List { SessionSettingsSections(category: item == .activity ? .activity : .warnings) }
                .shiftSettingsScreen().loggedNavigationTitle(item.title).navigationBarTitleDisplayMode(.inline)
        case .privacy:
            List { PrivacySettingsSection() }.shiftSettingsScreen().loggedNavigationTitle(item.title).navigationBarTitleDisplayMode(.inline)
        case .speeds: UsualSpeedsSettingsView()
        case .shortcuts: PanelShortcutsView()
        case .widgets: HomeWidgetsSettingsView()
        case .recovery: TripRecoveryView()
        case .experimental: ExperimentalFeaturesView()
        case .remoteFindMy: FindMyChecksView()
        case .report: ProblemReportView()
        case .diagnostics:
            List { DeveloperLogExportSection() }.shiftSettingsScreen()
                .loggedNavigationTitle("Diagnostics").navigationBarTitleDisplayMode(.inline)
        case .about: LocusAboutSettingsView()
        case .backup: LibraryBackupView()
        }
    }

}

private struct SettingsConnectionSummary: View {
    @EnvironmentObject private var session: SpoofSession
    var body: some View {
        ForegroundTimeline { _ in
            HStack(spacing: 12) {
                ShiftSettingsIcon(symbol: "antenna.radiowaves.left.and.right")
                VStack(alignment: .leading, spacing: 4) {
                    Text("Connection").font(.body).foregroundStyle(.primary)
                    Text(session.effectivePhase.title).font(.subheadline).foregroundStyle(session.effectivePhase.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        }
    }
}

/// Details stay available without filling the screen before someone needs them.
struct SettingsHelp: View {
    var title = "How it works"
    let lines: [String]
    var body: some View {
        DisclosureGroup {
            ForEach(lines.indices, id: \.self) { index in
                Text(lines[index]).font(.footnote).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading).fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 3)
            }
        } label: {
            Label(title, systemImage: "questionmark.circle")
                .font(.subheadline).foregroundStyle(.secondary)
                .padding(.vertical, 3)
        }
    }
}

struct ConnectionSettingsView: View {
    @EnvironmentObject private var pairing: PairingStore
    @EnvironmentObject private var session: SpoofSession
    @Environment(\.scenePhase) private var scenePhase
    @State private var showImporter = false
    @State private var showPairOnDevice = false
    @State private var confirmRemovePairing = false
    @State private var showSetupChecklist = false
    @State private var tunnelIP = TunnelConfig.targetIP
    @State private var localDevVPNInstalled = LocalDevVPN.isInstalled
    private var supportsOnDevicePairing: Bool {
        if #available(iOS 27.0, *) { return true }
        return false
    }
    var body: some View {
        List {
            SessionSettingsSections(category: .connection)
            Section {
                Button { showSetupChecklist = true } label: { Label("Review setup checklist", systemImage: "checklist").frame(minHeight: 44) }
                    .disabled(session.hasSession || session.isBusy)
                if session.hasSession { Text("Stop spoofing before running a setup check.").font(.footnote).foregroundStyle(.secondary) }
            }.shiftSettingsRows()
            Section("iPhone pairing") {
                Label(pairing.hasPairingFile ? "Pairing file ready" : "Pairing needed",
                      systemImage: pairing.hasPairingFile ? "checkmark.circle" : "exclamationmark.circle")
                    .foregroundStyle(pairing.hasPairingFile ? LocusTheme.statusGood : LocusTheme.statusWarn)
                if supportsOnDevicePairing {
                    Button("Pair on this iPhone") { showPairOnDevice = true }.frame(minHeight: 44)
                        .disabled(session.hasSession || session.isBusy)
                }
                DisclosureGroup("Import or manage pairing") {
                    Button("Import pairing file") { showImporter = true }.frame(minHeight: 44)
                    Button("Paste pairing file") {
                        do { try pairing.importPairingFromClipboard() }
                        catch { session.lastError = error.localizedDescription }
                    }.frame(minHeight: 44)
                    if pairing.hasPairingFile {
                        Button("Remove pairing file", role: .destructive) { confirmRemovePairing = true }
                            .frame(minHeight: 44).disabled(session.hasSession || session.isBusy)
                    }
                    Text("Use an RPPairing file from idevice_pair. A SideStore pairing file is different.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                .disabled(session.hasSession || session.isBusy)
                if session.hasSession { Text("Stop spoofing before changing this iPhone’s pairing.").font(.footnote).foregroundStyle(.secondary) }
                SettingsHelp(title: "Pairing help", lines: [
                    supportsOnDevicePairing
                        ? "Tap Pair on this iPhone, then follow the code shown there. No computer is needed."
                        : "Create an RPPairing file with idevice_pair on a computer, then import it here.",
                    "Choose the pairing file from Files, or paste its contents when file selection is unavailable."
                ])
            }.shiftSettingsRows()
            Section {
                Button(localDevVPNInstalled ? "Open LocalDevVPN" : "Get LocalDevVPN") {
                    if localDevVPNInstalled { LocalDevVPN.openInstalled() }
                    else { LocalDevVPN.openAppStore() }
                }.frame(minHeight: 44)
                DisclosureGroup("Advanced connection settings") {
                    TextField("Device tunnel IP", text: $tunnelIP)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                        .onSubmit { TunnelConfig.setTargetIP(tunnelIP) }
                    Button("Save tunnel IP") { TunnelConfig.setTargetIP(tunnelIP) }
                    Text("Default: 10.7.0.1. Only change this if your VPN setup needs it.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            } footer: { Text("Start on Wi-Fi with LocalDevVPN on. An existing connection may keep working on cellular.") }.shiftSettingsRows()
        }
        .shiftSettingsScreen().loggedNavigationTitle("Connection").navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showImporter) {
            PairingDocumentPicker(onPick: { url in
                showImporter = false
                do { try pairing.importPairing(from: url) }
                catch { session.lastError = error.localizedDescription }
            }, onCancel: { showImporter = false }).ignoresSafeArea()
        }
        .loggedConfirmationDialog("Remove this iPhone’s pairing?", isPresented: $confirmRemovePairing, titleVisibility: .visible) {
            Button("Remove pairing", role: .destructive) {
                guard !session.hasSession, !session.isBusy else { return }
                do { try pairing.removePairing() } catch { session.lastError = error.localizedDescription }
            }
        } message: { Text("You’ll need to pair this iPhone again before sending another location. Saved places and routes stay here.") }
        .sheet(isPresented: $showSetupChecklist) {
            SetupFlowView(initialStep: SetupGate.initialStep(hasPairingFile: pairing.hasPairingFile), onFinished: {
                SetupGate.markComplete(); showSetupChecklist = false
            }, onSkip: { showSetupChecklist = false })
        }
        .sheet(isPresented: $showPairOnDevice) { PairOnDeviceView().environmentObject(pairing) }
        .onAppear { localDevVPNInstalled = LocalDevVPN.isInstalled }
        .onChange(of: scenePhase) { _, phase in if phase == .active { localDevVPNInstalled = LocalDevVPN.isInstalled } }
    }
}

private struct LocusAboutSettingsView: View {
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize = 48.0
    private var appVersion: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        return build.isEmpty ? short : "\(short) (\(build))"
    }
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 18) {
                    ShiftMark().fill(LocusTheme.accent.gradient).frame(width: 72, height: 72).accessibilityHidden(true)
                    Text("Elsepin").font(.system(size: titleSize, weight: .bold)).tracking(-2)
                    ShiftSignature()
                }.padding(.vertical, 24).frame(maxWidth: .infinity, alignment: .leading)
                    .listRowBackground(Color.clear)
            }.shiftSettingsRows()
            Section {
                LabeledContent("Version", value: appVersion)
                LabeledContent("Engine", value: "idevice DVT location simulation")
            }.shiftSettingsRows()
            AppUpdateStatusSection()
            Section("Built on open source") {
                Text("Includes open-source components. Original authors and terms are listed in Licenses.")
                    .font(.subheadline).foregroundStyle(.secondary)
                NavigationLink { ShiftAcknowledgmentsView() } label: { Label("Licenses & acknowledgments", systemImage: "text.document") }
            }.shiftSettingsRows()
        }.shiftSettingsScreen().loggedNavigationTitle("About Elsepin").navigationBarTitleDisplayMode(.inline)
    }
}

struct PlacesView: View {
    var isRoot = false
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SpoofSession
    @EnvironmentObject private var library: TripLibrary
    private enum Category: String, CaseIterable { case favorites = "Favorites", pins = "Pins", routes = "Routes", areas = "Areas" }
    @State private var category = Category.favorites
    @State private var search = ""
    @ObservedObject private var demo = DevModeController.shared
    @State private var selectedFolder: String?
    @State private var pinEditor: PinDraft?
    @State private var areaEditor: NamedAreaDraft?
    @State private var folderPlace: SavedPlace?
    @State private var deletingPlace: SavedPlace?
    var onTrip: (SavedTrip) -> Void = { _ in }
    var onPlace: (SavedPlace) -> Void = { _ in }
    var onFindPlace: (() -> Void)? = nil
    var onCreateRoute: (() -> Void)? = nil

    var body: some View {
        NavigationStack {
            searchableContent
                .shiftScreen().loggedNavigationTitle("Library")
                .toolbar { if !isRoot { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } } }
                .fullScreenCover(item: $pinEditor) { draft in PinEditor(draft: draft) }
                .fullScreenCover(item: $areaEditor) { draft in
                    NamedAreaEditor(draft: draft) { area in
                        session.replaceNamedAreas(session.namedAreas.filter { $0.id != area.id } + [area])
                    }
                }
                .sheet(item: $folderPlace) { place in
                    LibraryFolderSheet(current: place.folder, folders: folders) { session.moveFavorite(place, folder: $0) }
                }
                .loggedConfirmationDialog("Delete pin?", isPresented: Binding(get: { deletingPlace != nil }, set: { if !$0 { deletingPlace = nil } }), titleVisibility: .visible) {
                    Button("Delete pin", role: .destructive) {
                        if let deletingPlace { session.removeFavorite(deletingPlace) }
                        deletingPlace = nil
                    }
                    Button("Cancel", role: .cancel) { deletingPlace = nil }
                } message: {
                    Text("\(deletingPlace?.displayName ?? "This pin") will move to Recently Deleted for 30 days.")
                }
        }
    }

    @ViewBuilder private var searchableContent: some View {
        if category == .favorites { content }
        else { content.searchable(text: $search, prompt: "Search \(category.rawValue.lowercased())") }
    }
    private var content: some View {
        List {
            Section {
                if typeSize.isAccessibilitySize { categoryPicker.pickerStyle(.menu) }
                else { categoryPicker.pickerStyle(.segmented) }
            }.listRowInsets(EdgeInsets()).listRowBackground(Color.clear)
            if (category == .pins || category == .routes) && !folders.isEmpty {
                Section {
                    Picker("Folder", selection: $selectedFolder) {
                        Text("All saved items").tag(String?.none)
                        ForEach(folders, id: \.self) { Text($0).tag(Optional($0)) }
                    }
                }
            }
            if category == .favorites || category == .pins {
                Section("Pins") {
                    if category == .pins {
                        Button("Add pin", systemImage: "mappin.and.ellipse") {
                            pinEditor = PinDraft(place: nil, center: session.pin ?? session.simulated ?? session.realCoordinate)
                        }
                    }
                    if shownPins.isEmpty { Text(category == .favorites ? "Star a pin to find it here." : "Name pins on the map, or add one here.").foregroundStyle(.secondary) }
                    ForEach(shownPins) { place in pinRow(place) }
                }
            }
            if category == .favorites || category == .routes {
                SavedTripsSection(onChoose: onTrip, favoritesOnly: category == .favorites,
                                  search: category == .favorites ? "" : search,
                                  folder: category == .favorites ? nil : selectedFolder, folders: folders, onCreate: onCreateRoute)
            }
            if category == .areas {
                NamedAreasSection(search: search) { area in
                    areaEditor = NamedAreaDraft(area: area, center: session.pin ?? session.simulated ?? session.realCoordinate)
                }
            }
            Section { NavigationLink { RecentlyDeletedView() } label: { Label("Recently Deleted", systemImage: "trash") } }
        }
    }
    private var categoryPicker: some View {
        Picker("Library category", selection: $category) {
            ForEach(Category.allCases, id: \.self) { Text($0.rawValue).tag($0) }
        }.frame(minHeight: 44)
    }
    private var folders: [String] { Array(Set(session.savedPins.compactMap(\.folder) + library.trips.compactMap(\.folder))).sorted() }
    private var shownPins: [SavedPlace] {
        category == .favorites ? session.favorites : session.savedPins.filter {
            (selectedFolder == nil || $0.folder == selectedFolder) && SavedNameSearch.matches(search, fields: [$0.displayName, $0.folder ?? ""])
        }
    }
    private func pinRow(_ place: SavedPlace) -> some View {
        HStack {
            Button { onPlace(place); if !isRoot { dismiss() } } label: {
                HStack(spacing: 12) {
                    SavedPlaceBadge(symbol: place.symbol, tint: place.tint)
                    Text(place.displayName).foregroundStyle(.primary)
                    Spacer()
                }.frame(minHeight: 48).contentShape(Rectangle())
            }.buttonStyle(.borderless)
            Button { session.togglePinFavorite(place) } label: {
                Image(systemName: place.isFavorite ? "star.fill" : "star").frame(width: 44, height: 44)
            }.buttonStyle(.borderless).accessibilityLabel(place.isFavorite ? "Remove favorite" : "Favorite pin")
            Menu {
                Button("Edit pin", systemImage: "pencil") { pinEditor = PinDraft(place: place, center: place.coordinate) }
                Button("Move to folder…", systemImage: "folder") { folderPlace = place }
                Button("Delete pin", role: .destructive) { deletingPlace = place }
            } label: { Image(systemName: "ellipsis").frame(width: 44, height: 44) }
                .buttonStyle(.borderless).accessibilityLabel("Options for \(place.displayName)")
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("Delete", systemImage: "trash") { deletingPlace = place }.tint(.red)
            Button(place.isFavorite ? "Unfavorite" : "Favorite", systemImage: place.isFavorite ? "star.slash" : "star") {
                session.togglePinFavorite(place)
            }.tint(.orange)
        }
    }
}
