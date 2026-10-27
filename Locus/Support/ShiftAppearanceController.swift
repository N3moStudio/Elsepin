import SwiftUI
import UIKit
import WidgetKit

/// A trait change updates dynamic colors without replacing the map or its state.
struct ShiftAppearanceAnchor: UIViewRepresentable {
    let style: ShiftVisualStyle
    func makeUIView(context: Context) -> Anchor { Anchor(style: style) }
    func updateUIView(_ view: Anchor, context: Context) { view.style = style; view.apply() }
    final class Anchor: UIView {
        var style: ShiftVisualStyle
        init(style: ShiftVisualStyle) { self.style = style; super.init(frame: .zero); isUserInteractionEnabled = false }
        required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
        override func didMoveToWindow() { super.didMoveToWindow(); apply() }
        func apply() {
            // traitCollection includes the inherited/default style. Reading an
            // unset traitOverrides entry raises an Objective-C exception on first launch.
            guard let window, window.traitCollection[ShiftStyleTrait.self] != style.rawValue else { return }
            window.traitOverrides[ShiftStyleTrait.self] = style.rawValue
        }
    }
}

@MainActor
final class ShiftIconController: ObservableObject {
    static let shared = ShiftIconController()
    @Published private(set) var selected = ShiftIconSelection()
    @Published private(set) var pending: ShiftIconSelection?
    @Published var error: String?
    private var completionReceived = false
    private var completionFailed = false
    private var resetCompletion: CheckedContinuation<Void, Error>?
    var changing: Bool { pending != nil }
    var supported: Bool { UIApplication.shared.supportsAlternateIcons }

    func refresh() {
        // iOS may deactivate the scene while its icon confirmation is visible.
        // Keep global appearance/navigation stable until that transition ends.
        guard UIApplication.shared.applicationState == .active else { return }
        if let requested = pending {
            guard completionReceived else { return }
            let actual = ShiftIconSelection.installed(named: UIApplication.shared.alternateIconName)
            let failed = completionFailed || actual != requested
            if failed {
                error = "iOS couldn’t change the icon. Try again while Elsepin is open."
            }
            pending = nil
            completionReceived = false
            completionFailed = false
            if let continuation = resetCompletion {
                resetCompletion = nil
                if failed { continuation.resume(throwing: IconResetError.unavailable) }
                else { continuation.resume() }
            }
        }
        guard let actual = ShiftIconSelection.installed(named: UIApplication.shared.alternateIconName) else {
            error = "This installation uses an unrecognized icon. Choose a Elsepin icon to replace it."
            return
        }
        if selected != actual { selected = actual }
        SessionPreferences.shared.confirmIcon(actual)
    }

    func choose(_ choice: ShiftIconSelection) {
        guard !changing else { return }
        guard supported else { error = "This installation does not support changing the Home Screen icon."; return }
        guard UIApplication.shared.alternateIconName != choice.alternateName else { refresh(); return }
        guard UIApplication.shared.applicationState == .active else { return }
        pending = choice
        completionReceived = false
        completionFailed = false
        error = nil
        UIApplication.shared.setAlternateIconName(choice.alternateName) { [weak self] failure in
            Task { @MainActor in
                guard let self else { return }
                self.completionReceived = true
                self.completionFailed = failure != nil
                self.refresh()
            }
        }
    }

    func restoreDefaultForReset() async throws {
        let choice = ShiftIconSelection()
        guard !changing else { throw IconResetError.unavailable }
        if UIApplication.shared.alternateIconName == choice.alternateName { refresh(); return }
        guard supported, UIApplication.shared.applicationState == .active else { throw IconResetError.unavailable }
        try await withCheckedThrowingContinuation { continuation in
            resetCompletion = continuation
            choose(choice)
        }
    }
    private enum IconResetError: Error { case unavailable }
}

struct ShiftAppIconPreview: View {
    let selection: ShiftIconSelection
    var size: CGFloat = 64
    var body: some View {
        Group {
            if let image = UIImage(named: selection.previewName) {
                Image(uiImage: image).resizable().interpolation(.high).scaledToFit()
            } else { ShiftMark(design: selection.design).fill(LocusTheme.accent).padding(10) }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.235, style: .continuous))
        .accessibilityHidden(true)
    }
}
