import SwiftUI

/// Search belongs to this editor, not its ancestor NavigationStack. A native
/// searchable controller can otherwise remain over the planner after a pop or alert.
struct RouteSearchField: View {
    @Binding var query: String
    @FocusState.Binding var focused: Bool
    let prompt: String
    let submit: () -> Void
    @Environment(\.shiftVisualStyle) private var style

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary).accessibilityHidden(true)
            TextField(prompt, text: $query)
                .textFieldStyle(.plain).focused($focused).submitLabel(.search)
                .autocorrectionDisabled().onSubmit(submit)
                .accessibilityLabel(prompt)
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                        .frame(width: 44, height: 44).contentShape(Rectangle())
                }.buttonStyle(.plain).accessibilityLabel("Clear search")
            }
        }
        .padding(.leading, 12).padding(.trailing, query.isEmpty ? 12 : 0)
        .frame(minHeight: 44)
        .background(ShiftPalette.color(.surface, style: style), in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 16).padding(.vertical, 8)
        .background(ShiftCanvas())
    }
}
