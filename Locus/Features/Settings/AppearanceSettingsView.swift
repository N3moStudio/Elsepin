import SwiftUI

struct AppearanceSettingsView: View {
    @EnvironmentObject private var preferences: SessionPreferences
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        List {
            Section("Map pins") {
                HStack {
                    Text("Size")
                    Spacer()
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: preferences.mapPinSize)).foregroundStyle(LocusTheme.accent)
                        .frame(width: 72, height: 72)
                        .accessibilityHidden(true)
                }
                Slider(value: $preferences.mapPinSize, in: MapPinSize.range, step: 1,
                    label: { Text("Map pin size") },
                    minimumValueLabel: { Text("Small").font(.caption) },
                    maximumValueLabel: { Text("Large").font(.caption) })
                    .accessibilityValue("\(Int(preferences.mapPinSize)) points")
                VStack(alignment: .leading, spacing: 8) {
                    LabeledContent("Visible up to", value: SavedPinVisibility.label(miles: preferences.mapPinVisibilityMiles))
                    Slider(value: $preferences.mapPinVisibilityMiles, in: SavedPinVisibility.rangeMiles, step: 0.5,
                        label: { Text("Pin visibility range") },
                        minimumValueLabel: { Text("Closer").font(.caption) },
                        maximumValueLabel: { Text("Farther").font(.caption) })
                        .accessibilityValue(SavedPinVisibility.label(miles: preferences.mapPinVisibilityMiles))
                    Text("How far the map spans before saved pins hide. This isn't distance from you.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }.shiftSettingsRows()
            Section {
                Picker("Surfaces", selection: $preferences.appearanceOverrides.material) {
                    Text("Solid").tag(AppearanceMaterial.solid)
                    Text("Liquid Glass").tag(AppearanceMaterial.glass)
                }
            } footer: {
                Text("Your surface choice stays when you switch themes.")
            }.shiftSettingsRows()
            Section {
                ForEach(ShiftVisualStyle.allCases) { style in
                    Button { preferences.visualStyle = style } label: {
                        HStack(spacing: 14) {
                            StyleSwatch(style: style)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(style.title).font(.body.weight(.semibold)).foregroundStyle(.primary)
                                Text(style.detail).font(.subheadline).foregroundStyle(.secondary)
                            }.fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 4)
                            if preferences.visualStyle == style { Image(systemName: "checkmark").font(.body.weight(.semibold)).foregroundStyle(LocusTheme.accent) }
                        }.frame(minHeight: 60).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(style.title + ", " + style.detail)
                    .accessibilityAddTraits(preferences.visualStyle == style ? [.isSelected] : [])
                }
            } header: { Text("Themes") } footer: { Text("Each theme sets its colors. Your surface and icon choices stay independent.") }.shiftSettingsRows()
            Section {
                NavigationLink {
                    AppIconSettingsView()
                } label: {
                    HStack(spacing: 14) {
                        ShiftAppIconPreview(selection: preferences.iconSelection, size: 52)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Choose App Icon").foregroundStyle(.primary)
                            Text(preferences.iconSelection.title).font(.subheadline).foregroundStyle(.secondary)
                        }.fixedSize(horizontal: false, vertical: true)
                    }.padding(.vertical, 5)
                }
            } header: { Text("App Icon") } footer: { Text("Mix any icon with any interface style.") }.shiftSettingsRows()

        }
        .shiftSettingsScreen().loggedNavigationTitle("Appearance").navigationBarTitleDisplayMode(.inline)
    }

}

private struct StyleSwatch: View {
    let style: ShiftVisualStyle
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Capsule().fill(ShiftPalette.color(.accent, style: style, dark: style.defaultAppearance == "dark")).frame(width: 28, height: 5)
            Capsule().fill(ShiftPalette.color(.muted, style: style, dark: style.defaultAppearance == "dark").opacity(0.55)).frame(width: 35, height: 3)
            Capsule().fill(ShiftPalette.color(.accent, style: style, dark: style.defaultAppearance == "dark").opacity(0.20)).frame(height: 16)
        }.padding(9).frame(width: 55, height: 55)
            .background(ShiftPalette.color(.canvas, style: style, dark: style.defaultAppearance == "dark"), in: RoundedRectangle(cornerRadius: style.cornerRadius * 0.5))
            .overlay { RoundedRectangle(cornerRadius: style.cornerRadius * 0.5).stroke(Color.primary.opacity(0.14), lineWidth: 1) }
            .accessibilityHidden(true)
    }
}

struct AppIconSettingsView: View {
    @StateObject private var icons = ShiftIconController.shared
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        List {
            Section {
                HStack(spacing: 15) {
                    ShiftAppIconPreview(selection: icons.selected, size: 64)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(icons.changing ? "Changing Icon…" : "Current Icon").font(.headline)
                        Text(icons.selected.title).font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                    ProgressView().opacity(icons.changing ? 1 : 0)
                        .accessibilityHidden(!icons.changing)
                        .accessibilityLabel("Changing app icon")
                }.padding(.vertical, 5)
            } footer: { Text("Independent of your interface style. Your Home Screen appearance can also tint icons.") }.shiftSettingsRows()
            Section("New Icons") {
                LazyVGrid(columns: iconColumns, spacing: 16) {
                    ForEach(ShiftIconDesign.additions) { design in
                        iconButton(ShiftIconSelection(design: design), label: design.title)
                    }
                }.padding(.vertical, 4)
            }.shiftSettingsRows()
            ForEach(ShiftIconDesign.originals) { design in
                Section(design.title) {
                    LazyVGrid(columns: iconColumns, spacing: 16) {
                        ForEach(design.finishes) { finish in
                            iconButton(ShiftIconSelection(design: design, finish: finish), label: finish.title)
                        }
                    }.padding(.vertical, 4)
                }.shiftSettingsRows()
            }
            if !icons.supported {
                Section { Text("Icon changes aren't available in this installation.").font(.subheadline).foregroundStyle(.secondary) }.shiftSettingsRows()
            }
        }
        .shiftSettingsScreen().loggedNavigationTitle("App Icon").navigationBarTitleDisplayMode(.inline)
        .onAppear { icons.refresh() }
        .alert("Couldn't Change Icon", isPresented: Binding(get: { icons.error != nil }, set: { if !$0 { icons.error = nil } })) {
            Button("OK", role: .cancel) { icons.error = nil }
        } message: { Text(icons.error ?? "Try again while Elsepin is open.") }
    }
    private var iconColumns: [GridItem] {
        [GridItem(.adaptive(minimum: typeSize.isAccessibilitySize ? 150 : 100), spacing: 10, alignment: .top)]
    }
    private func iconButton(_ choice: ShiftIconSelection, label: String) -> some View {
        Button { icons.choose(choice) } label: {
            VStack(spacing: 9) {
                ShiftAppIconPreview(selection: choice)
                    .padding(5)
                    .overlay { RoundedRectangle(cornerRadius: 20).stroke(choice == icons.selected ? LocusTheme.accent : .clear, lineWidth: 2) }
                Text(label).font(.subheadline).foregroundStyle(.primary)
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                ZStack {
                    Image(systemName: choice == icons.selected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(choice == icons.selected ? LocusTheme.accent : .secondary)
                        .opacity(icons.pending == choice ? 0 : 1)
                    if icons.pending == choice { ProgressView().controlSize(.small) }
                }.frame(height: 20)
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: icons.selected)
            }.frame(maxWidth: .infinity).padding(.vertical, 8).contentShape(Rectangle())
        }
        .buttonStyle(.plain).disabled(!icons.supported || icons.changing)
        .accessibilityLabel(choice.title)
        .accessibilityValue(icons.pending == choice ? "Changing icon" : choice == icons.selected ? "Selected" : "")
        .accessibilityAddTraits(choice == icons.selected ? [.isSelected] : [])
    }
}
