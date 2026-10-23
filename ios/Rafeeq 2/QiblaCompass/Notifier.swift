import Foundation
import UserNotifications
import UIKit
import AVFoundation

/// Local (on-device) prayer-time notifications. No server involved.
enum Notifier {
    static func requestAuth(_ done: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { ok, _ in
            DispatchQueue.main.async { done?(ok) }
        }
    }

    static func status(_ done: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { s in
            DispatchQueue.main.async { done(s.authorizationStatus) }
        }
    }

    static func openIPhoneSettings() {
        if let u = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(u) }
    }

    /// The adhan sound for prayer alerts (Sounds/allahu-akbar.caf, 29 s; recording supplied by the app owner).
    static let azanFile = "allahu-akbar.caf"
    private static var player: AVAudioPlayer?

    /// Plays the alert sound in the app, for the preview button in Settings.
    static func previewAzan() {
        guard let url = Bundle.main.url(forResource: "allahu-akbar", withExtension: "caf") else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        player = try? AVAudioPlayer(contentsOf: url)
        player?.play()
    }

    /// Each prayer has two switches: the notification (bell) and the alarm (adhan sound).
    /// Alarm on: the alert plays the adhan. Alarm off, bell on: a normal notification. Both off: nothing.
    static func schedule(place: Place, method: CalcMethod, hanafi: Bool, on: Bool, before: Int, muted: [Prayer: Bool], alarm: [Prayer: Bool]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        guard on else { return }
        let now = Date()
        var items: [(Date, Prayer, Bool)] = []          // date, prayer, isReminder
        for day in 0..<7 {
            let d = now.addingTimeInterval(Double(day) * 86400)
            let ev = PrayerCalculator.events(around: d, lat: place.lat, lon: place.lon, timeZone: place.timeZone,
                                             method: method, hanafi: hanafi).today
            for (p, t) in ev where muted[p] != true || alarm[p] == true {
                if t > now { items.append((t, p, false)) }
                if before > 0, p != .sunrise {
                    let r = t.addingTimeInterval(-Double(before) * 60)
                    if r > now { items.append((r, p, true)) }
                }
            }
        }
        items.sort { $0.0 < $1.0 }
        var cal = Calendar(identifier: .gregorian); cal.timeZone = place.timeZone
        let f = DateFormatter(); f.timeZone = place.timeZone; f.locale = Locale(identifier: "en_GB"); f.dateFormat = "HH:mm"
        for (t, p, reminder) in items.prefix(60) {
            let c = UNMutableNotificationContent()
            let when = reminder ? t.addingTimeInterval(Double(before) * 60) : t
            c.title = p.name
            c.body = Loc.ar ? (reminder ? "\(p.name) بعد \(before) دقيقة · \(f.string(from: when)) · \(place.name)" : "حان الآن وقت \(p.name) · \(f.string(from: when)) · \(place.name)")
                       : ((reminder ? Loc.f("{0} in {1} min", p.name, "\(before)") : Loc.f("It is time for {0}", p.name)) + " · \(f.string(from: when)) · \(place.name)")
            c.sound = reminder ? nil : (alarm[p] == true ? UNNotificationSound(named: UNNotificationSoundName(azanFile)) : .default)
            var comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: t)
            comps.timeZone = place.timeZone
            let trig = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            center.add(UNNotificationRequest(identifier: "\(p.rawValue)-\(Int(t.timeIntervalSince1970))", content: c, trigger: trig))
        }
    }
}

/// Show the banner and play the sound even while the app is open.
final class NotifDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotifDelegate()
    func userNotificationCenter(_ c: UNUserNotificationCenter, willPresent n: UNNotification,
                                withCompletionHandler h: @escaping (UNNotificationPresentationOptions) -> Void) {
        h([.banner, .sound])
    }
}
