import SwiftUI

/// The symbol remains centered on its coordinate; revealing the label never
/// shifts the pin. Tapping selects a preview; only Teleport sends a location.
struct SavedPinMapIcon: View {
    let pin: SavedPlace
    let selected: Bool
    // MapKit hosts/recycles annotation content outside the normal view ancestry.
    // Pass presentation values explicitly: EnvironmentObject can be absent there
    // and traps while a pin reappears after zooming or starting a route (build 76).
    let pinSize: Double
    let labelBackground: Color
    let preparesLocation: Bool
    let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            Group {
                if let emoji = pin.emoji, PinAppearance.isSingleEmoji(emoji) { Text(emoji) }
                else { Image(systemName: pin.symbol == .pin ? "mappin.circle.fill" : pin.symbol.rawValue) }
            }
                .font(.system(size: pinSize, weight: .medium, design: .rounded))
                .foregroundStyle(pin.tint.swatch)
                .background(Circle().fill(.background).padding(2))
                .overlay { if pin.emoji != nil { Circle().stroke(pin.tint.swatch, lineWidth: 2) } }
                .frame(width: max(44, pinSize + 8), height: max(44, pinSize + 8))
                .contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityLabel(pin.displayName)
            .accessibilityHint(preparesLocation ? "Shows the name and selects this pin. Tap Teleport to move." : "Shows or hides the name without changing your route.")
            .overlay(alignment: .top) {
                if selected {
                    VStack(spacing: 2) {
                        Text(pin.displayName).font(.caption.weight(.semibold)).lineLimit(1)
                        if let address = pin.address, !address.isEmpty {
                            Text(address).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                        }
                    }
                        .padding(.horizontal, 9).padding(.vertical, 5)
                        .background(labelBackground, in: Capsule())
                        .frame(maxWidth: 160).fixedSize(horizontal: true, vertical: true)
                        .offset(y: -30).allowsHitTesting(false).accessibilityHidden(true)
                }
            }
    }
}
