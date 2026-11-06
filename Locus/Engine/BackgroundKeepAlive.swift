import CoreLocation
import Foundation

final class BackgroundKeepAlive: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private(set) var lastKnownCoordinate: CLLocationCoordinate2D?
    var acceptDeviceFixes = true {
        didSet {
            if !acceptDeviceFixes {
                cancelPreciseFix()
            }
        }
    }
    var minimumDeviceFixDate = Date().addingTimeInterval(-30)
    var onDeviceLocation: ((CLLocation) -> Void)?
    private var precisionTask: Task<Void, Never>?
    private var running = false
    private var backgroundEnabled = false
    private var requestedAlways = false
    private var demand = LocationTrackingDemand.stopped
    var diagnosticState: String {
        "\(running ? "running" : "stopped"); demand=\(demand); precise=\(precisionTask != nil)"
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        manager.pausesLocationUpdatesAutomatically = false
        manager.allowsBackgroundLocationUpdates = false
        manager.showsBackgroundLocationIndicator = false
    }

    func updateDemand(_ demand: LocationTrackingDemand, appActive: Bool) {
        guard self.demand != demand || (!appActive && precisionTask != nil) else { return }
        self.demand = demand
        if !appActive {
            precisionTask?.cancel()
            precisionTask = nil
        }
        reconcile()
    }

    private func reconcile() {
        guard demand != .stopped || precisionTask != nil else {
            if running { manager.stopUpdatingLocation() }
            running = false
            backgroundEnabled = false
            manager.allowsBackgroundLocationUpdates = false
            manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
            return
        }
        manager.desiredAccuracy = precisionTask == nil
            ? kCLLocationAccuracyThreeKilometers : kCLLocationAccuracyNearestTenMeters
        let background = demand == .session
        // Browsing may pause naturally. Keep a confirmed simulation alive only
        // while the session owns the background location lease.
        manager.pausesLocationUpdatesAutomatically = !background && precisionTask == nil
        if backgroundEnabled != background {
            backgroundEnabled = background
            manager.allowsBackgroundLocationUpdates = background
        }
        if manager.authorizationStatus == .notDetermined { manager.requestWhenInUseAuthorization() }
        if background, !requestedAlways, manager.authorizationStatus == .authorizedWhenInUse {
            requestedAlways = true
            manager.requestAlwaysAuthorization()
        }
        guard !running else { return }
        running = true
        DeveloperLogStore.shared.record("location_manager_started", ["demand": String(describing: demand)])
        manager.startUpdatingLocation()
    }

    func cancelPreciseFix() {
        precisionTask?.cancel()
        precisionTask = nil
        reconcile()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Permission changes must be reconciled even when the demand is unchanged.
        reconcile()
    }

    func requestPreciseFix() {
        guard acceptDeviceFixes else { return }
        precisionTask?.cancel()
        precisionTask = Task { @MainActor [weak self] in
            do { try await Task.sleep(nanoseconds: 15_000_000_000) } catch { return }
            guard !Task.isCancelled else { return }
            self?.precisionTask = nil
            self?.reconcile()
        }
        reconcile()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastKnownCoordinate = locations.last?.coordinate
        guard acceptDeviceFixes, let fix = locations.last,
              fix.timestamp >= minimumDeviceFixDate,
              Date().timeIntervalSince(fix.timestamp) >= 0, Date().timeIntervalSince(fix.timestamp) < 30,
              fix.horizontalAccuracy.isFinite, fix.horizontalAccuracy >= 0,
              CLLocationCoordinate2DIsValid(fix.coordinate),
              fix.sourceInformation?.isSimulatedBySoftware == false,
              fix.sourceInformation?.isProducedByAccessory == false else { return }
        onDeviceLocation?(fix)
        // Finish the bounded precise request as soon as a useful fix arrives.
        if precisionTask != nil, fix.horizontalAccuracy <= 50 { cancelPreciseFix() }
    }
}
