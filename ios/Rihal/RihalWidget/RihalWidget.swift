import WidgetKit
import SwiftUI
import CoreLocation
import MapKit

// MARK: - Palette (navy and gold)

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }
}

enum RihalColor {
    static let gold300 = Color(hex: 0xF1D9A2)
    static let gold400 = Color(hex: 0xE4BB68)
    static let goldDeep = Color(hex: 0xC99A45)
    static let ink = Color(hex: 0xF5F0E4)
    static let inkDim = Color(hex: 0xA9B2CC)

    static let face = LinearGradient(
        colors: [Color(hex: 0x1C3170), Color(hex: 0x0F1D46), Color(hex: 0x0A1430)],
        startPoint: .topLeading, endPoint: .bottomTrailing)
    static let ringGold = LinearGradient(
        colors: [gold300, goldDeep],
        startPoint: .topLeading, endPoint: .bottomTrailing)
}

// MARK: - Data

struct WMosque: Codable {
    var name: String
    var lat: Double
    var lon: Double
}

struct PrayerEntry: TimelineEntry {
    let date: Date
    let prevDate: Date?
    let next: WEvent?
    let city: String
    let mosqueName: String?
    let mosqueMeters: Int?

    var progress: Double {
        guard let p = prevDate, let n = next else { return 0 }
        let total = n.date.timeIntervalSince(p)
        guard total > 0 else { return 0 }
        return min(max(date.timeIntervalSince(p) / total, 0), 1)
    }

    static func sample(now: Date = Date()) -> PrayerEntry {
        PrayerEntry(date: now,
                    prevDate: now.addingTimeInterval(-6 * 3600),
                    next: WEvent(prayer: .dhuhr, date: now.addingTimeInterval(47 * 60)),
                    city: "Kuwait City",
                    mosqueName: "Masjid Al-Noor",
                    mosqueMeters: 350)
    }
}

// MARK: - Location, place name, nearest mosque

final class LocationFetcher: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var done: ((CLLocation?) -> Void)?
    private var keepAlive: LocationFetcher?
    private var finished = false

    func fetch(_ completion: @escaping (CLLocation?) -> Void) {
        DispatchQueue.main.async {
            self.keepAlive = self
            self.done = completion
            self.manager.delegate = self
            self.manager.desiredAccuracy = kCLLocationAccuracyKilometer
            if self.manager.isAuthorizedForWidgetUpdates {
                if let last = self.manager.location, abs(last.timestamp.timeIntervalSinceNow) < 1800 {
                    self.finish(last)
                    return
                }
                self.manager.requestLocation()
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) { self.finish(self.manager.location) }
            } else {
                self.finish(self.manager.location)
            }
        }
    }

    private func finish(_ loc: CLLocation?) {
        if finished { return }
        finished = true
        let cb = done
        done = nil
        keepAlive = nil
        cb?(loc)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        finish(locations.last)
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        finish(manager.location)
    }
}

enum Finder {
    static let placeKey = "widget.lastPlace.v1"
    static let mosqueKey = "widget.lastMosque.v1"

    struct SavedPlace: Codable { var name: String; var tz: String; var lat: Double; var lon: Double }

    static func savedPlace() -> SavedPlace? {
        guard let d = UserDefaults.standard.data(forKey: placeKey) else { return nil }
        return try? JSONDecoder().decode(SavedPlace.self, from: d)
    }
    static func save(place: SavedPlace) {
        if let d = try? JSONEncoder().encode(place) { UserDefaults.standard.set(d, forKey: placeKey) }
    }
    static func savedMosque() -> WMosque? {
        guard let d = UserDefaults.standard.data(forKey: mosqueKey) else { return nil }
        return try? JSONDecoder().decode(WMosque.self, from: d)
    }
    static func save(mosque: WMosque) {
        if let d = try? JSONEncoder().encode(mosque) { UserDefaults.standard.set(d, forKey: mosqueKey) }
    }

    /// Place name and time zone for a position (needs internet; falls back to the device time zone).
    static func resolvePlace(_ loc: CLLocation, _ done: @escaping (SavedPlace) -> Void) {
        CLGeocoder().reverseGeocodeLocation(loc) { marks, _ in
            let p = marks?.first
            let name = p?.locality ?? p?.administrativeArea ?? p?.country ?? "My location"
            let tz = (p?.timeZone ?? TimeZone.current).identifier
            done(SavedPlace(name: name, tz: tz, lat: loc.coordinate.latitude, lon: loc.coordinate.longitude))
        }
    }

    /// Nearest mosque from Apple Maps; tries a small area first, then a wider one.
    static func nearestMosque(to loc: CLLocation, _ done: @escaping (WMosque?) -> Void) {
        func search(span: Double, next: (() -> Void)?) {
            let req = MKLocalSearch.Request()
            req.naturalLanguageQuery = "mosque"
            req.region = MKCoordinateRegion(center: loc.coordinate, latitudinalMeters: span, longitudinalMeters: span)
            MKLocalSearch(request: req).start { resp, _ in
                var best: (WMosque, Double)?
                for it in resp?.mapItems ?? [] {
                    let c = it.placemark.coordinate
                    let name = it.name ?? "Mosque"
                    if name.lowercased().contains("parking") { continue }
                    let d = loc.distance(from: CLLocation(latitude: c.latitude, longitude: c.longitude))
                    if d > 20000 { continue }
                    if best == nil || d < best!.1 { best = (WMosque(name: name, lat: c.latitude, lon: c.longitude), d) }
                }
                if let b = best { done(b.0) }
                else if let n = next { n() }
                else { done(nil) }
            }
        }
        search(span: 3000) { search(span: 16000, next: nil) }
    }
}

// MARK: - Timeline

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> PrayerEntry { .sample() }

    func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) {
        completion(.sample())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
        LocationFetcher().fetch { loc in
            let fallback = Finder.savedPlace()
            let here = loc ?? fallback.map { CLLocation(latitude: $0.lat, longitude: $0.lon) }
                ?? CLLocation(latitude: 29.3759, longitude: 47.9774) // Kuwait City until a position is known

            Finder.resolvePlace(here) { resolved in
                var place = resolved
                if loc == nil, let f = fallback { place = f }
                Finder.save(place: place)

                Finder.nearestMosque(to: here) { found in
                    var mosque = found
                    if let m = found { Finder.save(mosque: m) }
                    else if let old = Finder.savedMosque(),
                            here.distance(from: CLLocation(latitude: old.lat, longitude: old.lon)) < 20000 {
                        mosque = old
                    }
                    let tl = Self.build(place: place, here: here, mosque: mosque)
                    completion(tl)
                }
            }
        }
    }

    static func build(place: Finder.SavedPlace, here: CLLocation, mosque: WMosque?) -> Timeline<PrayerEntry> {
        let now = Date()
        let tz = TimeZone(identifier: place.tz) ?? .current
        let inKuwait = (28.4...30.2).contains(place.lat) && (46.4...48.7).contains(place.lon)
        let events = WCalc.events(around: now, lat: place.lat, lon: place.lon, timeZone: tz,
                                  method: inKuwait ? .kuwait : .mwl)

        var meters: Int?
        if let m = mosque {
            meters = Int(here.distance(from: CLLocation(latitude: m.lat, longitude: m.lon)))
        }

        func entry(at d: Date) -> PrayerEntry? {
            let prev = events.last(where: { $0.date <= d })
            guard let next = events.first(where: { $0.date > d }) else { return nil }
            return PrayerEntry(date: d, prevDate: prev?.date, next: next, city: place.name,
                               mosqueName: mosque?.name, mosqueMeters: meters)
        }

        guard let target = events.first(where: { $0.date > now })?.date else {
            return Timeline(entries: [PrayerEntry.sample(now: now)], policy: .after(now.addingTimeInterval(15 * 60)))
        }

        var dates: [Date] = [now]
        var d = now.addingTimeInterval(60)
        while d < target && dates.count < 90 {
            dates.append(d)
            d = d.addingTimeInterval(60)
        }
        if target.timeIntervalSince(now) <= 90 * 60 { dates.append(target) }

        let entries = dates.compactMap { entry(at: $0) }
        // Refresh at the latest in 30 minutes so the position and mosque stay current.
        let reload = min(dates.last ?? now, now.addingTimeInterval(30 * 60)).addingTimeInterval(1)
        return Timeline(entries: entries.isEmpty ? [PrayerEntry.sample(now: now)] : entries, policy: .after(reload))
    }
}

// MARK: - Text

private let deviceIsArabic: Bool = (Locale.preferredLanguages.first ?? "en").hasPrefix("ar")

private func shortTime(_ date: Date) -> String {
    date.formatted(date: .omitted, time: .shortened)
}

private func distanceText(_ meters: Int) -> String {
    let walk = max(1, Int((Double(meters) / 80).rounded()))
    if deviceIsArabic {
        let d = meters >= 1000 ? String(format: "%.1f كم", Double(meters) / 1000) : "\(meters) م"
        return "\(d) · \(walk) د مشيًا"
    }
    let d = meters >= 1000 ? String(format: "%.1f km", Double(meters) / 1000) : "\(meters) m"
    return "\(d) · \(walk) min walk"
}

// MARK: - Square widget (small): countdown ring

struct RingView: View {
    let progress: Double
    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.10), lineWidth: 7)
            Circle()
                .trim(from: 0, to: max(progress, 0.005))
                .stroke(RihalColor.ringGold, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

struct SmallView: View {
    let e: PrayerEntry
    var body: some View {
        ZStack {
            RingView(progress: e.progress)
            VStack(spacing: 2) {
                Text(deviceIsArabic ? "التالية" : "NEXT")
                    .font(.system(size: 8, weight: .medium))
                    .tracking(1.6)
                    .foregroundStyle(RihalColor.inkDim)
                Text(e.next?.prayer.arabic ?? "—")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(RihalColor.gold300)
                if let n = e.next {
                    Text(n.date, style: .timer)
                        .font(.system(size: 20, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(RihalColor.ink)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: 84)
                    Text(shortTime(n.date))   // time only, so the line stays inside the ring
                        .font(.system(size: 10))
                        .foregroundStyle(RihalColor.inkDim)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: 88)
                }
            }
        }
        .padding(8)
    }
}

// MARK: - Rectangle widget (medium): next prayer + nearest mosque

struct MediumView: View {
    let e: PrayerEntry
    var body: some View {
        HStack(spacing: 12) {
            Link(destination: URL(string: "rihal://prayer")!) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(RihalColor.gold400)
                    Text(e.next?.prayer.arabic ?? "—")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(RihalColor.gold300)
                }
                if let n = e.next {
                    Text(shortTime(n.date))
                        .font(.system(size: 36, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(RihalColor.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    HStack(spacing: 4) {
                        Text(n.prayer.english)
                        Text(n.date, style: .relative)
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(RihalColor.inkDim)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            }

            Link(destination: URL(string: "rihal://mosques")!) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(RihalColor.gold300)
                    Text(deviceIsArabic ? "أقرب مسجد" : "NEAREST")
                        .font(.system(size: 8, weight: .medium))
                        .tracking(1.4)
                        .foregroundStyle(RihalColor.inkDim)
                }
                if let name = e.mosqueName {
                    Text(name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(RihalColor.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    if let m = e.mosqueMeters {
                        Text(distanceText(m))
                            .font(.system(size: 11))
                            .foregroundStyle(RihalColor.inkDim)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                } else {
                    Text(e.city)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(RihalColor.ink)
                        .lineLimit(2)
                    Text(deviceIsArabic ? "لا يوجد مسجد قريب" : "No mosque found yet")
                        .font(.system(size: 11))
                        .foregroundStyle(RihalColor.inkDim)
                        .lineLimit(2)
                }
            }
            .padding(10)
            .frame(width: 128, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.09))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            }
        }
        .padding(2)
    }
}

// MARK: - Widget


// MARK: - Lock Screen widgets (accessory families)

struct LockCircularView: View {
    let e: PrayerEntry
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Circle().stroke(Color.white.opacity(0.25), lineWidth: 3).padding(3)
            Circle().trim(from: 0, to: max(e.progress, 0.02))
                .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90)).padding(3)
                .widgetAccentable()
            VStack(spacing: 0) {
                Text((deviceIsArabic ? (e.next?.prayer.arabic ?? "—") : (e.next?.prayer.english ?? "—"))).font(.system(size: 11, weight: .bold)).lineLimit(1).minimumScaleFactor(0.6)
                if let d = e.next?.date {
                    Text(d, style: .timer).font(.system(size: 11, weight: .medium)).monospacedDigit()
                        .multilineTextAlignment(.center).lineLimit(1).minimumScaleFactor(0.5).frame(maxWidth: 40)
                }
            }
            .padding(6)
        }
    }
}

struct LockRectangularView: View {
    let e: PrayerEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "moon.stars.fill").font(.system(size: 11)).widgetAccentable()
                Text((deviceIsArabic ? (e.next?.prayer.arabic ?? "—") : (e.next?.prayer.english ?? "—"))).font(.system(size: 15, weight: .bold)).lineLimit(1)
                Spacer(minLength: 2)
                if let d = e.next?.date { Text(shortTime(d)).font(.system(size: 15, weight: .semibold)).monospacedDigit() }
            }
            if let d = e.next?.date {
                Text(d, style: .timer).font(.system(size: 22, weight: .semibold)).monospacedDigit().lineLimit(1).minimumScaleFactor(0.6)
            }
            ProgressView(value: e.progress).progressViewStyle(.linear).widgetAccentable()
        }
    }
}

struct LockInlineView: View {
    let e: PrayerEntry
    var body: some View {
        if let d = e.next?.date {
            Text("\((deviceIsArabic ? (e.next?.prayer.arabic ?? "—") : (e.next?.prayer.english ?? "—"))) \(shortTime(d)) · ") + Text(d, style: .relative)
        } else {
            Text("Rihal")
        }
    }
}

struct RihalWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PrayerEntry

    var body: some View {
        Group {
            switch family {
            case .systemMedium: MediumView(e: entry).widgetURL(URL(string: "rihal://prayer"))
            case .accessoryCircular: LockCircularView(e: entry).widgetURL(URL(string: "rihal://prayer"))
            case .accessoryRectangular: LockRectangularView(e: entry).widgetURL(URL(string: "rihal://prayer"))
            case .accessoryInline: LockInlineView(e: entry).widgetURL(URL(string: "rihal://prayer"))
            default: SmallView(e: entry).widgetURL(URL(string: "rihal://prayer"))
            }
        }
        .containerBackground(for: .widget) {
            switch family {
            case .accessoryCircular, .accessoryRectangular, .accessoryInline: Color.clear
            default: RihalColor.face
            }
        }
    }
}

struct RihalWidget: Widget {
    let kind = "RihalPrayerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            RihalWidgetView(entry: entry)
        }
        .configurationDisplayName("Rihal")
        .description("Next prayer countdown and the nearest mosque.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

@main
struct RihalWidgetBundle: WidgetBundle {
    var body: some Widget { RihalWidget() }
}
