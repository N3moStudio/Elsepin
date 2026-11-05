import SwiftUI

/// The symbol remains centered on its coordinate; revealing the label never
/// shifts the pin or changes the map's selected/spoofed location.
struct SavedPinMapIcon: View {
    let pin: SavedPlace
    let selected: Bool
    let onTap: () -> Void
    @EnvironmentObject private var preferences: SessionPreferences
    var body: some View {
        Button(action: onTap) {
            Image(systemName: pin.symbol == .pin ? "mappin.circle.fill" : pin.symbol.rawValue)
                .font(.title2).foregroundStyle(pin.tint.swatch)
                .frame(width: 44, height: 44).contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityLabel(pin.displayName)
            .overlay(alignment: .top) {
                if selected {
                    Text(pin.displayName).font(.caption.weight(.semibold)).lineLimit(2)
                        .padding(.horizontal, 9).padding(.vertical, 5)
                        .background(ShiftPalette.color(.surface, style: preferences.visualStyle), in: Capsule())
                        .frame(maxWidth: 160).fixedSize(horizontal: true, vertical: true)
                        .offset(y: -32).allowsHitTesting(false).accessibilityHidden(true)
                }
            }
    }
}
