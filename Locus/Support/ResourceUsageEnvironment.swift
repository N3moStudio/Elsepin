import SwiftUI

private struct ElsepinReducedResourcesKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var elsepinReducedResources: Bool {
        get { self[ElsepinReducedResourcesKey.self] }
        set { self[ElsepinReducedResourcesKey.self] = newValue }
    }
}

/// OS pressure reduces discretionary visuals only. Never feed this value into
/// location command timing, connection recovery, route speed or Stop behavior.
struct ElsepinResourceUsage: ViewModifier {
    @ViewBuilder func body(content: Content) -> some View {
        if #available(iOS 27, *) { content.modifier(SystemResourceUsage()) }
        else { content }
    }
}

@available(iOS 27, *)
private struct SystemResourceUsage: ViewModifier {
    @Environment(\.systemPrefersReducedResourceUsage) private var reduced
    func body(content: Content) -> some View {
        content.environment(\.elsepinReducedResources, reduced)
            .onChange(of: reduced, initial: true) { _, value in
                DeveloperLogStore.shared.record("resource_pressure_changed", ["reduced_usage": String(value)])
            }
    }
}
