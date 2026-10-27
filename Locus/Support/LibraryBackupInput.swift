import SwiftUI
import UniformTypeIdentifiers
import UIKit

@MainActor
final class LibraryBackupInput: ObservableObject {
    struct Request: Identifiable { let id = UUID() }
    @Published var request: Request?
    @Published private(set) var state = BackupImportState()
    private var pending: BackupFileAccess?
    private var receivedResult = false
    private var preparation: Task<Void, Never>?

    func chooseFile() {
        guard request == nil, pending == nil, !state.isLoading else { return }
        receivedResult = false
        state.notice(nil)
        request = Request()
    }

    func picked(_ url: URL?, for presented: Request) {
        guard request?.id == presented.id else { return }
        receivedResult = true
        // Acquire provider access before the picker dismisses; keep it through reading.
        pending = url.map(BackupFileAccess.init)
        if url == nil { state.notice("No file selected. Your previous preview is unchanged.") }
        request = nil
    }

    func dismissed() {
        guard let access = pending else {
            if !receivedResult {
                state.notice("Files closed before returning a file. Try again, or copy the JSON contents and use Paste backup text.")
            }
            return
        }
        pending = nil
        prepare {
            defer { withExtendedLifetime(access) {} }
            return try BackupImportReader.file(access.url)
        }
    }

    func paste(_ strings: [String]) {
        guard request == nil, pending == nil, let text = strings.first else { return }
        prepare { try BackupImportReader.text(text) }
    }

    func clearPreview() { state.clearPreview() }

    func cancelPreparation() {
        preparation?.cancel()
        preparation = nil
        state.cancel()
    }

    private func prepare(_ load: @escaping @Sendable () throws -> BackupImportPreview) {
        guard let id = state.begin() else { return }
        let worker = Task.detached(priority: .userInitiated) { Result { try load() } }
        preparation = Task {
            let result = await withTaskCancellationHandler {
                await worker.value
            } onCancel: { worker.cancel() }
            guard !Task.isCancelled else { return }
            state.finish(id, result: result)
            preparation = nil
        }
    }
}

/// Immutable access lease, released after the worker (also on failure/cancellation).
private final class BackupFileAccess: @unchecked Sendable {
    let url: URL
    private let scoped: Bool
    init(_ url: URL) { self.url = url; scoped = url.startAccessingSecurityScopedResource() }
    deinit { if scoped { url.stopAccessingSecurityScopedResource() } }
}

/// Broad file-data selection avoids relying on the host/provider recognizing JSON.
/// Contents still pass the exact same backup validator as pasted text.
struct LibraryBackupPicker: UIViewControllerRepresentable {
    let finished: (URL?) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(finished) }
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.data], asCopy: true)
        picker.title = "Choose Backup File"
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ controller: UIDocumentPickerViewController, context: Context) {}
    static func dismantleUIViewController(_ controller: UIDocumentPickerViewController, coordinator: Coordinator) {
        controller.delegate = nil
        coordinator.invalidate() // Teardown is not a user cancellation.
    }
    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        private var finished: ((URL?) -> Void)?
        init(_ finished: @escaping (URL?) -> Void) { self.finished = finished }
        func invalidate() { finished = nil }
        private func finish(_ url: URL?) {
            let callback = finished
            finished = nil // Deliver actual selection/cancellation only once.
            callback?(url)
        }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) { finish(urls.first) }
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) { finish(nil) }
    }
}
