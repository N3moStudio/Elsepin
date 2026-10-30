import SafariServices
import SwiftUI

/// A system browser for the optional JSON helper. No script bridge, automatic
/// file transfer or clipboard reads: importing still uses Paste and review.
struct BackupJSONBrowser: UIViewControllerRepresentable {
    static let siteURL = URL(string: "https://json.site")!
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(dismiss: dismiss) }

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let browser = SFSafariViewController(url: Self.siteURL)
        browser.dismissButtonStyle = .done
        browser.delegate = context.coordinator
        return browser
    }

    func updateUIViewController(_ browser: SFSafariViewController, context: Context) {
        // Do not recreate/reload Safari on preference changes; preserve the
        // user's selected file and copy action until they dismiss it.
        context.coordinator.dismiss = dismiss
    }

    @MainActor
    final class Coordinator: NSObject, SFSafariViewControllerDelegate {
        var dismiss: DismissAction
        init(dismiss: DismissAction) { self.dismiss = dismiss }
        nonisolated func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            // The legacy delegate requirement is not actor-isolated. Keep the
            // SwiftUI dismissal on MainActor without transferring the controller.
            Task { @MainActor [weak self] in self?.dismiss() }
        }
    }
}
