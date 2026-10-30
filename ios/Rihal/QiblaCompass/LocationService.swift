import Foundation
import CoreLocation
import Combine
import UIKit

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
        // the screen turns with the phone, so the compass must measure from the screen's top edge
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(screenTurned),
                                               name: UIDevice.orientationDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(screenTurned),
                                               name: OrientationLock.changed, object: nil)
    }

    /// Heading is measured along the top edge of the screen as it is shown now.
    /// Checked again after the turn animation, since the screen settles a moment after the phone.
    @objc private func screenTurned() {
        matchScreen()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in self?.matchScreen() }
    }

    /// Degrees to add to the phone's heading so it is measured from the top of the screen as shown.
    /// The phone always reports the heading of its own top edge (upright), so this is done here, not in CoreLocation.
    private var screenOffset: Double = 0
    private var rawHeading: Double?

    func matchScreen() {
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else { return }
        // Example: facing north, turn the phone a quarter left (its top points west, heading 270).
        // The screen turns to landscape-right and its top still points north: 270 + 90 = 0.
        let off: Double = switch scene.effectiveGeometry.interfaceOrientation {
        case .landscapeRight: 90
        case .landscapeLeft: -90
        case .portraitUpsideDown: 180
        default: 0
        }
        guard off != screenOffset else { return }
        screenOffset = off
        publishHeading()
    }

    private func publishHeading() {
        guard let r = rawHeading else { return }
        let h = (r + screenOffset).truncatingRemainder(dividingBy: 360)
        heading = h < 0 ? h + 360 : h
    }

    static var headingAvailable: Bool { CLLocationManager.headingAvailable() }

    var isAuthorized: Bool { status == .authorizedWhenInUse || status == .authorizedAlways }
    var denied: Bool { status == .denied || status == .restricted }

    func requestAccess() {
        if status == .notDetermined { manager.requestWhenInUseAuthorization() }
        else if isAuthorized { start() }
    }

    func start() {
        matchScreen()
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
        if h.trueHeading >= 0 { rawHeading = h.trueHeading; usesTrueNorth = true }
        else { rawHeading = h.magneticHeading; usesTrueNorth = false }
        publishHeading()
    }

    func locationManagerShouldDisplayHeadingCalibration(_ m: CLLocationManager) -> Bool { true }
    func locationManager(_ m: CLLocationManager, didFailWithError error: Error) { if coordinate == nil { failed = true } }
}
