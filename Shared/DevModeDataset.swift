import Foundation

/// Synthetic, local-only library examples. These drawn paths are not road-verified.
/// The caller must explicitly seed an isolated workspace; creating this value never
/// writes stores, pairs a device, or starts/restores a movement session.
struct DevModeDataset {
    let backup: LibraryBackup
    let tripLibrary: TripLibraryDocument
    let recentRoutes: [RecentRoute]
    let deletedItems: [DeletedLibraryItem]

    /// Stable identities and relative dates make repeated resets reproducible.
    /// Supply the current date when seeding so Recently Deleted remains usable.
    static func make(at now: Date) -> Self {
        let names = ["Demo Garden", "Demo Fountain", "Demo Reading Corner", "Demo Picnic Spot",
                     "Demo North Gate", "Demo South Gate", "Demo Lookout", "Demo Meeting Point"]
        let places = names.enumerated().map { index, name in
            BackupPlace(name: name, latitude: 40.77 + Double(index) * 0.001,
                        longitude: -73.975 + Double(index % 3) * 0.001,
                        folder: index < 4 ? "Demo Outdoors" : "Demo Places",
                        favorite: index.isMultiple(of: 2))
        }
        let specs: [(String, TravelMode, Double, Double)] = [
            ("Demo Garden Walk", .walk, 3, 15),
            ("Demo Bicycle Loop", .cycle, 10, 45),
            ("Demo Scenic Drive", .drive, 25, 7_200),
            ("Demo Electric Bike Ride", .eBike, 18, 30),
            ("Demo Morning Run", .run, 6, 10)
        ]
        var trips = specs.enumerated().map { index, spec in
            let latitude = 40.77 + Double(index) * 0.01
            let points = [point(latitude, -73.975), point(latitude + 0.002, -73.974),
                          point(latitude + 0.003, -73.971), point(latitude + 0.005, -73.97)]
            var trip = SavedTrip(name: spec.0, mode: spec.1, speedMPH: spec.2,
                smoothMovement: false, originName: "Demo Start", destinationName: "Demo Finish",
                points: points, source: .drawn, instructions: [],
                stops: [RouteStop(id: id(200 + index), name: "Demo Pause", metres: 100, waitSeconds: spec.3)],
                calculatedAt: now.addingTimeInterval(-3_600))
            trip.id = id(100 + index)
            trip.savedAt = now.addingTimeInterval(-1_800)
            trip.folder = index == 2 ? "Demo Drives" : "Demo Outdoors"
            trip.favorite = index == 0
            return trip
        }
        // Incoming section IDs match their stop (or the final destination), just
        // like a planned itinerary. Boundaries use this drawn path's real length.
        var mixed = trips[0]
        mixed.id = id(105)
        mixed.name = "Demo Walk Bike Drive"
        mixed.folder = "Demo Mixed Trips"
        mixed.favorite = false
        let length = zip(mixed.points, mixed.points.dropFirst()).reduce(0.0) {
            $0 + $1.0.distance(to: $1.1)
        }
        mixed.stops = [
            RouteStop(id: id(205), name: "Demo Bike Pickup", metres: length / 3, waitSeconds: 20),
            RouteStop(id: id(206), name: "Demo Car Pickup", metres: length * 2 / 3, waitSeconds: 90)
        ]
        mixed.travelSections = [
            RouteTravelSection(id: mixed.stops[0].id, startMetres: 0,
                endMetres: mixed.stops[0].metres, mode: .walk, speedMPH: 3),
            RouteTravelSection(id: mixed.stops[1].id, startMetres: mixed.stops[0].metres,
                endMetres: mixed.stops[1].metres, mode: .cycle, speedMPH: 10),
            RouteTravelSection(id: RouteLegChoice.destinationID, startMetres: mixed.stops[1].metres,
                endMetres: length, mode: .drive, speedMPH: 25)
        ]
        trips.append(mixed)
        let areas = [
            NamedArea(id: id(300), name: "Demo Garden Area", points: [
                point(40.769, -73.976), point(40.769, -73.972),
                point(40.773, -73.972), point(40.773, -73.976)]),
            NamedArea(id: id(301), name: "Demo Quiet Area", points: [
                point(40.78, -73.976), point(40.78, -73.972),
                point(40.784, -73.972), point(40.784, -73.976)])
        ]
        var previous = trips[0]
        previous.name = "Demo Earlier Walk"
        previous.savedAt = now.addingTimeInterval(-86_400)
        let revisions = [TripRevision(id: id(400), replacedAt: now.addingTimeInterval(-1_800),
                                      reason: .name, trip: previous)]
        let recent = trips.enumerated().map { index, trip in
            RecentRoute(trip: trip, visitedAt: now.addingTimeInterval(-Double(index + 1) * 600))
        }
        // Separate payload identities allow every example to be restored without
        // overwriting a seeded live item. Ten rows exercise selection and scrolling.
        var deleted = (0..<8).map { index in
            DeletedLibraryItem(id: id(500 + index),
                deletedAt: now.addingTimeInterval(-Double(index + 1) * 86_400),
                payload: .place(BackupPlace(name: "Demo Deleted Pin \(index + 1)",
                    latitude: 40.8 + Double(index) * 0.001, longitude: -73.96,
                    folder: "Demo Archive", favorite: index.isMultiple(of: 2))))
        }
        var deletedTrip = trips[1]
        deletedTrip.id = id(600)
        deletedTrip.name = "Demo Deleted Bicycle Route"
        deleted.append(DeletedLibraryItem(id: id(508), deletedAt: now.addingTimeInterval(-3_600),
                                          payload: .trip(deletedTrip)))
        let deletedArea = NamedArea(id: id(601), name: "Demo Deleted Area", points: [
            point(40.81, -73.976), point(40.81, -73.972), point(40.814, -73.974)])
        deleted.append(DeletedLibraryItem(id: id(509), deletedAt: now.addingTimeInterval(-7_200),
                                          payload: .area(deletedArea)))
        return Self(backup: LibraryBackup(createdAt: now, places: places, trips: trips,
                         preferences: nil, areas: areas, categories: [.places, .trips]),
                    tripLibrary: TripLibraryDocument(trips: trips, revisions: revisions),
                    recentRoutes: recent, deletedItems: deleted)
    }

    private static func point(_ latitude: Double, _ longitude: Double) -> RoutePoint {
        RoutePoint(latitude: latitude, longitude: longitude)
    }

    private static func id(_ value: Int) -> UUID {
        // Fixed fixture namespace; no random identifiers or account-derived input.
        UUID(uuid: (0xDE, 0xA0, 0xDA, 0x7A, 0, 0, 0x40, 0, 0x80, 0, 0, 0,
                    0, 0, UInt8((value >> 8) & 0xFF), UInt8(value & 0xFF)))
    }
}
