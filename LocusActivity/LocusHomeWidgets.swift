import SwiftUI
import WidgetKit
import AppIntents

private struct LibraryEntry: TimelineEntry {
    let date: Date
    let library: WidgetLibrary
    let available: Bool
    var appearance: ShiftAppearanceSelection = ShiftWidgetAppearance.read()
}
private struct LibraryProvider: TimelineProvider {
    func placeholder(in context: Context) -> LibraryEntry {
        LibraryEntry(date: Date(), library: WidgetLibrary(items: [WidgetLibraryItem(id: UUID(), title: "Saved place", kind: "place")]), available: true)
    }
    func getSnapshot(in context: Context, completion: @escaping (LibraryEntry) -> Void) { completion(context.isPreview ? placeholder(in: context) : read()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<LibraryEntry>) -> Void) {
        completion(Timeline(entries: [read()], policy: .never))
    }
    private func read() -> LibraryEntry {
        guard let value = WidgetLibrary.read() else {
            return LibraryEntry(date: Date(), library: WidgetLibrary(items: []), available: false)
        }
        return LibraryEntry(date: Date(), library: value, available: true)
    }
}

struct WidgetPinEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Saved location"
    static var defaultQuery = WidgetPinQuery()
    var id: String
    var title: String
    var subtitle: String
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", subtitle: "\(subtitle)")
    }
    init(_ destination: WidgetPinDestination) {
        id = destination.id; title = destination.title; subtitle = destination.subtitle
    }
}

struct WidgetPinQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [WidgetPinEntity] {
        let library = WidgetLibrary.read()
        return identifiers.compactMap { library?.pinDestination(id: $0) }.map(WidgetPinEntity.init)
    }
    func suggestedEntities() async throws -> [WidgetPinEntity] {
        (WidgetLibrary.read()?.pinDestinations ?? []).map(WidgetPinEntity.init)
    }
    func entities(matching string: String) async throws -> [WidgetPinEntity] {
        (WidgetLibrary.read()?.pinDestinations ?? []).filter {
            $0.title.localizedCaseInsensitiveContains(string) || $0.subtitle.localizedCaseInsensitiveContains(string)
        }.map(WidgetPinEntity.init)
    }
}

struct LocationWidgetConfiguration: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Location shortcut"
    static var description = IntentDescription("Choose a saved place or route start for this widget. Tapping only sets a preview pin; start spoofing manually in Elsepin.")
    @Parameter(title: "Saved place or route start") var destination: WidgetPinEntity?
}

private struct LocationWidgetEntry: TimelineEntry {
    let date: Date
    let destination: WidgetPinDestination?
    let wasConfigured: Bool
    var appearance = ShiftWidgetAppearance.read()
}
private struct LocationWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> LocationWidgetEntry {
        LocationWidgetEntry(date: Date(), destination: WidgetPinDestination(WidgetLibraryItem(id: UUID(), title: "Saved location", kind: "place")), wasConfigured: true)
    }
    func snapshot(for configuration: LocationWidgetConfiguration, in context: Context) async -> LocationWidgetEntry {
        context.isPreview ? placeholder(in: context) : entry(configuration)
    }
    func timeline(for configuration: LocationWidgetConfiguration, in context: Context) async -> Timeline<LocationWidgetEntry> {
        Timeline(entries: [entry(configuration)], policy: .never)
    }
    private func entry(_ configuration: LocationWidgetConfiguration) -> LocationWidgetEntry {
        LocationWidgetEntry(date: Date(), destination: WidgetLibrary.read()?.pinDestination(id: configuration.destination?.id), wasConfigured: configuration.destination != nil)
    }
}

struct ShiftLocationWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "ShiftLocation", intent: LocationWidgetConfiguration.self, provider: LocationWidgetProvider()) { entry in
            VStack(alignment: .leading, spacing: 10) {
                Label(entry.destination?.subtitle ?? "Location shortcut", systemImage: entry.destination?.isRoute == true ? "point.topleft.down.curvedto.point.bottomright.up" : "mappin")
                    .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Text(entry.destination?.title ?? (entry.wasConfigured ? "Location unavailable" : "Choose a location"))
                    .font(.system(.title3, design: .rounded, weight: .semibold)).lineLimit(3)
                Text(entry.destination == nil ? "Hold this widget → Edit Widget" : "Set pin · Start manually in Elsepin")
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }.frame(maxWidth: .infinity, alignment: .leading)
                .containerBackground(for: .widget) { ShiftWidgetBackground(style: entry.appearance.style) }
                .widgetURL(entry.destination?.url)
        }
        .configurationDisplayName("Location shortcut")
        .description("Choose a different saved place or route start for each widget. Start spoofing manually in Elsepin.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
struct LocusFavoriteWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LocusFavorite", provider: LibraryProvider()) { entry in
            VStack(alignment: .leading, spacing: 12) {
                ShiftWidgetBrand(design: entry.appearance.icon.design).foregroundStyle(.primary)
                Spacer(minLength: 0)
                Text(entry.library.primary?.title ?? "Open Elsepin").font(.system(.title3, design: .rounded, weight: .bold)).lineLimit(3)
                Text(entry.library.primary?.kind == "trip" ? "Review trip" : "Choose your pin").font(.caption).foregroundStyle(.secondary)
            }.frame(maxWidth: .infinity, alignment: .leading)
            .containerBackground(for: .widget) { ShiftWidgetBackground(style: entry.appearance.style) }
            .widgetURL(entry.library.primary?.url ?? URL(string: "shift://session")!)
        }.configurationDisplayName("Favorite shortcut").description("Open a place or trip. You choose when to start.")
            .supportedFamilies([.systemSmall])
    }
}
struct LocusLibraryWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LocusLibrary", provider: LibraryProvider()) { entry in
            LibraryWidgetView(entry: entry).containerBackground(for: .widget) { ShiftWidgetBackground(style: entry.appearance.style) }
        }.configurationDisplayName("Saved shortcuts").description("Your selected places and trips, ready to open.")
            .supportedFamilies([.systemMedium, .systemLarge])
    }
}
private struct LibraryWidgetView: View {
    let entry: LibraryEntry
    @Environment(\.widgetFamily) private var family
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ShiftWidgetBrand(design: entry.appearance.icon.design).foregroundStyle(.primary)
            if entry.library.items.isEmpty {
                Link(destination: URL(string: "shift://session")!) {
                    VStack(alignment: .leading) {
                        Text("Open Elsepin").font(.headline)
                        Text(entry.available ? "Choose shortcuts in Settings → Home Screen widgets." : "Open the app to check widget setup.").font(.caption)
                    }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                }
            } else {
                ForEach(Array(entry.library.items.prefix(family == .systemLarge ? 4 : 2))) { item in
                    if let url = item.url {
                        Link(destination: url) {
                            Label(item.title, systemImage: item.kind == "place" ? "mappin" : "point.topleft.down.curvedto.point.bottomright.up")
                                .font(.subheadline.weight(.medium)).lineLimit(2)
                                .padding(.horizontal, 12)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                                .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
            }
        }.widgetURL(URL(string: "shift://session"))
    }
}

private struct ShiftWidgetBackground: View {
    let style: ShiftVisualStyle
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        ShiftPalette.color(.canvas, style: style)
            .overlay(alignment: .top) { Rectangle().fill(ShiftPalette.color(.accent, style: style)).frame(height: 3) }
    }
}
