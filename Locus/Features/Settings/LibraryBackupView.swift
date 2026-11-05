import SwiftUI
import UniformTypeIdentifiers

struct LibraryBackupView: View {
    @EnvironmentObject private var session: SpoofSession
    @EnvironmentObject private var library: TripLibrary
    @StateObject private var input = LibraryBackupInput()
    @State private var document = LibraryBackupDocument()
    @State private var exporting = false
    @State private var confirmExport = false
    @State private var reviewing = false
    @State private var selection = BackupImportSelection()
    @State private var exportScope = BackupExportScope.everything
    @State private var exportName = "Elsepin-Routes-Areas.json"
    @State private var message: String?
    @State private var showingJSONSite = false

    var body: some View {
        List {
            Section {
                Button { message = nil; input.chooseFile() } label: {
                    HStack(spacing: 12) {
                        ShiftSettingsIcon(symbol: "doc")
                        Text("Choose backup file").foregroundStyle(.primary)
                    }.frame(minHeight: 44)
                }.disabled(input.state.isLoading)
                HStack(spacing: 12) {
                    ShiftSettingsIcon(symbol: "doc.on.clipboard")
                    Text("Paste backup text")
                    Spacer(minLength: 8)
                    PasteButton(payloadType: String.self) { strings in message = nil; input.paste(strings) }
                        .labelStyle(.titleOnly).accessibilityLabel("Paste backup text")
                        .accessibilityHint("Analyze copied JSON and review individual changes before importing.")
                        .disabled(input.state.isLoading || input.request != nil)
                }.frame(minHeight: 44)
                if input.state.isLoading { ProgressView("Analyzing backup…") }
                if input.state.preview != nil {
                    Button("Review selected backup") { reviewing = true }.frame(minHeight: 44)
                        .disabled(input.state.isLoading)
                }
            } header: { Text("Import settings, routes & areas") } footer: {
                Text("Open [json.site](https://json.site), copy the JSON, then tap Done and Paste here.")
                    .font(.footnote).foregroundStyle(.secondary)
                    // Intercept only this help link. Safari never receives backup
                    // contents from the app; choosing a file and copying are manual.
                    .environment(\.openURL, OpenURLAction { url in
                        guard url == BackupJSONBrowser.siteURL else { return .systemAction }
                        guard !input.state.isLoading, input.request == nil, !exporting, !confirmExport else { return .handled }
                        showingJSONSite = true
                        return .handled
                    })
            }.shiftSettingsRows()
            if let notice = message ?? input.state.message {
                Section { Text(notice).font(.footnote).textSelection(.enabled) }.shiftSettingsRows()
            }
            Section {
                Picker("Backup contents", selection: $exportScope) {
                    ForEach(BackupExportScope.allCases) { Text($0.title).tag($0) }
                }
                Button { confirmExport = true } label: {
                    HStack(spacing: 12) {
                        ShiftSettingsIcon(symbol: "square.and.arrow.up")
                        Text("Export backup").foregroundStyle(.primary)
                    }.frame(minHeight: 44)
                }
            } header: { Text("Export a backup") } footer: {
                Text("Save everything together, or choose settings or your saved library.")
            }.shiftSettingsRows()
            Section {
                SettingsHelp(title: "What's in a backup?", lines: [
                    "Routes, pins and named areas can be selected individually. Existing items keep their current versions.",
                    "Settings show current and imported values. Only checked settings change; unchanged settings are labeled Already the same.",
                    "Pairing, helper access keys, tunnel address, app lock, recent history entries and recovery points stay on this phone.",
                    "The file is readable and can contain saved locations. Nothing is uploaded automatically."
                ])
            }.shiftSettingsRows()
            Section("Other files") {
                NavigationLink { ConnectionSettingsView() } label: { Label("iPhone pairing file", systemImage: "iphone") }
                NavigationLink { FindMyChecksView() } label: { Label("Find My helper setup", systemImage: "icloud") }
            }.shiftSettingsRows()
        }
        .shiftSettingsScreen().loggedNavigationTitle("Import & export").navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $reviewing) {
            if let preview = input.state.preview {
                BackupImportReviewView(backup: preview.backup, finished: { result in
                    reviewing = false
                    input.clearPreview()
                    message = result
                }, selection: $selection).id(preview.id)
            }
        }
        .loggedConfirmationDialog("Export this backup?", isPresented: $confirmExport, titleVisibility: .visible) {
            Button("Export \(exportScope.title.lowercased())") {
                do {
                    let backup = LibraryBackup(places: session.savedPins.map(\.backupPlace), trips: library.trips,
                        preferences: session.backupPreferences, areas: session.namedAreas).selecting(exportScope.categories)
                    document = LibraryBackupDocument(data: try backup.encoded())
                    exportName = exportScope.filename
                    exporting = true
                } catch { message = error.localizedDescription }
            }
        } message: { Text("This readable file can include the selected settings, saved locations, routes and area boundaries. Pairing files and helper keys are excluded.") }
        .fileExporter(isPresented: $exporting, document: document, contentType: .json, defaultFilename: exportName) { result in
            switch result {
            case .success: message = "Backup exported."
            case .failure(let error): message = error.localizedDescription
            }
        }
        .sheet(item: $input.request, onDismiss: input.dismissed) { request in
            LibraryBackupPicker { url in input.picked(url, for: request) }.id(request.id)
        }
        .sheet(isPresented: $showingJSONSite) {
            BackupJSONBrowser()
        }
        .onChange(of: input.state.preview?.id) { _, id in
            guard id != nil, let backup = input.state.preview?.backup else { return }
            let current = BackupImportContext(preferences: session.backupPreferences,
                places: session.savedPins.map(\.backupPlace), trips: library.trips, areas: session.namedAreas)
            selection = BackupImportReview(backup: backup, current: current).defaultSelection
            reviewing = true
        }
        .onDisappear { if input.request == nil { input.cancelPreparation() } }
    }
}

private enum BackupExportScope: String, CaseIterable, Identifiable {
    case everything, settings, library
    var id: String { rawValue }
    var title: String {
        switch self { case .settings: return "Settings"; case .library: return "Saved routes & areas"; case .everything: return "Everything" }
    }
    var categories: Set<BackupCategory> {
        switch self { case .settings: return [.settings]; case .library: return [.places, .trips]; case .everything: return Set(BackupCategory.allCases) }
    }
    var filename: String {
        switch self { case .settings: return "Elsepin-Settings.json"; case .library: return "Elsepin-Routes-Areas.json"; case .everything: return "Elsepin-Library.json" }
    }
}

private struct LibraryBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data = Data()
    init(data: Data = Data()) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}
