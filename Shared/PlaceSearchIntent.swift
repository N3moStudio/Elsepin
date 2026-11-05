import Foundation

enum PlaceSearchIntent: String {
    case food, coffee, groceries, parks, fuel
    static func category(for text: String) -> Self? {
        let value = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        switch value {
        case "fast food", "fast foods", "food", "restaurants", "restaurant", "food near me", "fast food near me": return .food
        case "coffee", "cafe", "cafes", "coffee shops": return .coffee
        case "groceries", "grocery", "supermarket", "supermarkets": return .groceries
        case "park", "parks": return .parks
        case "gas", "gas station", "gas stations", "fuel": return .fuel
        default: return nil
        }
    }
    static func query(_ text: String) -> String {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return ["fast food", "fast foods", "fast food near me"].contains(value.lowercased()) ? "fast food restaurants" : value
    }
}
