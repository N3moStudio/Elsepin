import Foundation

/// Repositioning a saved pin changes its coordinate-based ID. Validate before
/// replacing so a move cannot duplicate its old record or overwrite a neighbor.
enum SavedPinReplacement {
    enum Issue: Error, Equatable { case missingSource, destinationOccupied }
    static func validate(sourceID: String?, destinationID: String, savedIDs: Set<String>) -> Issue? {
        guard let sourceID else { return nil }
        guard savedIDs.contains(sourceID) else { return .missingSource }
        if sourceID != destinationID, savedIDs.contains(destinationID) { return .destinationOccupied }
        return nil
    }
}
