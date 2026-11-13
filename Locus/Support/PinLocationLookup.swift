import MapKit

struct PinLocationDetails {
    let name: String
    let address: String?
}

/// Runs only for a selected pin, never movement ticks or map panning. Each
/// request has a deadline and cancellation; callers must reject obsolete results.
@MainActor enum PinLocationLookup {
    static func resolve(_ coordinate: CLLocationCoordinate2D) async -> PinLocationDetails? {
        guard CLLocationCoordinate2DIsValid(coordinate), !Task.isCancelled else { return nil }
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        var address: String?
        var title: String?
        if #available(iOS 26.0, *) {
            if let request = MKReverseGeocodingRequest(location: location) {
                let timeout = Task { @MainActor in
                    do { try await Task.sleep(for: .seconds(5)) } catch { return }
                    request.cancel()
                }
                defer { timeout.cancel() }
                let items = try? await withTaskCancellationHandler {
                    try await request.mapItems
                } onCancel: { Task { @MainActor in request.cancel() } }
                if let item = items?.first {
                    address = item.addressRepresentations?.fullAddress(includingRegion: false, singleLine: true)
                    title = item.name
                }
            }
        } else {
            let geocoder = CLGeocoder()
            let timeout = Task { @MainActor in
                do { try await Task.sleep(for: .seconds(5)) } catch { return }
                geocoder.cancelGeocode()
            }
            defer { timeout.cancel() }
            let marks = try? await withTaskCancellationHandler {
                try await geocoder.reverseGeocodeLocation(location)
            } onCancel: { Task { @MainActor in geocoder.cancelGeocode() } }
            if let mark = marks?.first {
                let street = [mark.subThoroughfare, mark.thoroughfare].compactMap { $0 }.joined(separator: " ")
                address = [street, mark.locality, mark.administrativeArea].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
                title = mark.name
            }
        }
        guard !Task.isCancelled else { return nil }
        // A nearby business is a hint, not a claim the dropped coordinate is its entrance.
        let nearby = PlaceSearchRequest(pointsOfInterest: MKLocalPointsOfInterestRequest(center: coordinate, radius: 60))
        if let response = try? await nearby.start(seconds: 3), !Task.isCancelled,
           let item = response.mapItems.filter({ distance($0, from: location) <= 45 })
            .min(by: { distance($0, from: location) < distance($1, from: location) }),
           let name = item.name, !name.isEmpty {
            title = "Near \(name)"
        }
        guard !Task.isCancelled else { return nil }
        let name = String((title ?? address ?? "Dropped pin").prefix(120))
        return PinLocationDetails(name: name, address: address.flatMap { $0.isEmpty ? nil : String($0.prefix(300)) })
    }

    private static func distance(_ item: MKMapItem, from location: CLLocation) -> CLLocationDistance {
        if #available(iOS 26.0, *) { return item.location.distance(from: location) }
        return item.placemark.location?.distance(from: location) ?? .infinity
    }
}
