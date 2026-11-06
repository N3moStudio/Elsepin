import SwiftUI

/// The symbol remains centered on its coordinate; revealing the label never
/// shifts the pin. Tapping selects a preview; only Teleport sends a location.
struct SavedPinMapIcon: View {
    let pin: SavedPlace
    let selected: Bool
    let onTap: () -> Void
    @EnvironmentObject private var preferences: SessionPreferences
    var body: some View {
        Button(action: onTap) {
            Image(systemName: pin.symbol == .pin ? "mappin.circle.fill" : pin.symbol.rawValue)
                .font(.system(size: preferences.mapPinSize, weight: .medium, design: .rounded))
                .foregroundStyle(pin.tint.swatch)
                .background(Circle().fill(.background).padding(2))
                .frame(width: max(44, preferences.mapPinSize + 8), height: max(44, preferences.mapPinSize + 8))
                .contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityLabel(pin.displayName)
            .accessibilityHint("Selects this pin. Tap Teleport to move.")
            .overlay(alignment: .top) {
                if selected {
                    Text(pin.displayName).font(.caption.weight(.semibold)).lineLimit(2)
                        .padding(.horizontal, 9).padding(.vertical, 5)
                        .background(ShiftPalette.color(.surface, style: preferences.visualStyle), in: Capsule())
                        .frame(maxWidth: 160).fixedSize(horizontal: true, vertical: true)
                        .offset(y: -30).allowsHitTesting(false).accessibilityHidden(true)
                }
            }
    }
}
