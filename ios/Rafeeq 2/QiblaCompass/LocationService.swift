import Foundation
import CoreLocation
import Combine

/// Wraps CoreLocation: GPS position, a compass heading corrected to TRUE north, and a place name.
final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var status: CLAuthorizationStatus = .notDetermined
    @Published var coordinate: CLLocationCoordinate2D?
    @Published var placeName: String?
    @Published var timeZone: TimeZone?
    @Published var placeCountry: String?
    @Published var fixDate: Date?
    @Published var failed = false
    @Published var accuracy: Double?          // metres
    @Published var heading: Double?          // degrees from true north when available
    @Published var headingAccuracy: Double = -1
    @Published var usesTrueNorth = false

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var lastGeocode = Date.distantPast

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 50
        manager.headingFilter = 1
        manager.headingOrientation = .portrait
        status = manager.authorizationStatus
        if isAuthorized { start() }
    }

    static var headingAvailable: Bool { CLLocationManager.headingAvailable() }

    var isAuthorized: Bool { status == .authorizedWhenInUse || status == .authorizedAlways }
    var denied: Bool { status == .denied || status == .restricted }

    func requestAccess() {
        if status == .notDetermined { manager.requestWhenInUseAuthorization() }
        else if isAuthorized { start() }
    }

    func start() {
        manager.startUpdatingLocation()
        if CLLocationManager.headingAvailable() { manager.startUpdatingHeading() }
    }

    /// Ask for a fresh position now and re-resolve the place name.
    func refresh() {
        failed = false
        lastGeocode = .distantPast
        if status == .notDetermined { manager.requestWhenInUseAuthorization() }
        else if isAuthorized { manager.stopUpdatingLocation(); manager.startUpdatingLocation(); manager.requestLocation() }
    }

    func stop() {
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
    }

    func locationManagerDidChangeAuthorization(_ m: CLLocationManager) {
        status = m.authorizationStatus
        if isAuthorized { start() }
    }

    func locationManager(_ m: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        coordinate = loc.coordinate
        fixDate = Date()
        accuracy = loc.horizontalAccuracy >= 0 ? loc.horizontalAccuracy : nil
        failed = false
        if Date().timeIntervalSince(lastGeocode) > 120 {
            lastGeocode = Date()
            geocoder.reverseGeocodeLocation(loc) { [weak self] marks, _ in
                guard let self, let p = marks?.first else { return }
                self.placeName = p.locality ?? p.administrativeArea ?? p.country
                self.timeZone = p.timeZone
                self.placeCountry = p.country
            }
        }
    }

    func locationManager(_ m: CLLocationManager, didUpdateHeading h: CLHeading) {
        headingAccuracy = h.headingAccuracy
        if h.trueHeading >= 0 { heading = h.trueHeading; usesTrueNorth = true }
        else { heading = h.magneticHeading; usesTrueNorth = false }
    }

    func locationManagerShouldDisplayHeadingCalibration(_ m: CLLocationManager) -> Bool { true }
    func locationManager(_ m: CLLocationManager, didFailWithError error: Error) { if coordinate == nil { failed = true } }
}
