import Foundation

// Self-contained prayer-time calculator for the widget (same maths as the app's PrayerCalculator).

enum WPrayer: String, CaseIterable {
    case fajr, dhuhr, asr, maghrib, isha

    var english: String {
        switch self {
        case .fajr: return "Fajr"
        case .dhuhr: return "Dhuhr"
        case .asr: return "Asr"
        case .maghrib: return "Maghrib"
        case .isha: return "Isha"
        }
    }
    var arabic: String {
        switch self {
        case .fajr: return "الفجر"
        case .dhuhr: return "الظهر"
        case .asr: return "العصر"
        case .maghrib: return "المغرب"
        case .isha: return "العشاء"
        }
    }
}

struct WMethod {
    let fajr: Double
    let isha: Double
    static let kuwait = WMethod(fajr: 18, isha: 17.5)
    static let mwl = WMethod(fajr: 18, isha: 17)
}

struct WEvent {
    let prayer: WPrayer
    let date: Date
}

enum WCalc {
    private static func rad(_ d: Double) -> Double { d * .pi / 180 }
    private static func deg(_ r: Double) -> Double { r * 180 / .pi }
    private static func fix(_ a: Double, _ b: Double) -> Double {
        let v = a - b * floor(a / b)
        return v < 0 ? v + b : v
    }

    private static func julian(_ y: Int, _ m: Int, _ d: Int) -> Double {
        var y = y, m = m
        if m <= 2 { y -= 1; m += 12 }
        let a = floor(Double(y) / 100)
        let b = 2 - a + floor(a / 4)
        return floor(365.25 * Double(y + 4716)) + floor(30.6001 * Double(m + 1)) + Double(d) + b - 1524.5
    }

    private static func sun(_ jd: Double) -> (decl: Double, eqt: Double) {
        let d = jd - 2451545.0
        let g = fix(357.529 + 0.98560028 * d, 360)
        let q = fix(280.459 + 0.98564736 * d, 360)
        let l = fix(q + 1.915 * sin(rad(g)) + 0.020 * sin(rad(2 * g)), 360)
        let e = 23.439 - 0.00000036 * d
        let ra = fix(deg(atan2(cos(rad(e)) * sin(rad(l)), cos(rad(l)))) / 15, 24)
        return (deg(asin(sin(rad(e)) * sin(rad(l)))), q / 15 - ra)
    }

    static func day(year: Int, month: Int, day: Int, lat: Double, lon: Double, method: WMethod) -> [WPrayer: Date] {
        let jd = julian(year, month, day) - lon / (15 * 24)
        func midDay(_ t: Double) -> Double { fix(12 - sun(jd + t).eqt, 24) }
        func angle(_ a: Double, _ t: Double, ccw: Bool) -> Double {
            let dec = sun(jd + t).decl
            let x = (-sin(rad(a)) - sin(rad(dec)) * sin(rad(lat))) / (cos(rad(dec)) * cos(rad(lat)))
            let tt = deg(acos(x)) / 15
            return midDay(t) + (ccw ? -tt : tt)
        }
        func asr(_ f: Double, _ t: Double) -> Double {
            let dec = sun(jd + t).decl
            let a = -deg(atan(1 / (f + tan(rad(abs(lat - dec))))))
            return angle(a, t, ccw: false)
        }
        var fajr = 5.0, sunrise = 6.0, dhuhr = 12.0, asrT = 13.0, sunset = 18.0, isha = 18.0
        for _ in 0..<2 {
            fajr = angle(method.fajr, fajr / 24, ccw: true)
            sunrise = angle(0.833, sunrise / 24, ccw: true)
            dhuhr = midDay(dhuhr / 24)
            asrT = asr(1, asrT / 24)
            sunset = angle(0.833, sunset / 24, ccw: false)
            isha = angle(method.isha, isha / 24, ccw: false)
        }
        if !sunrise.isNaN && !sunset.isNaN {
            let night = fix(sunrise - sunset, 24)
            if method.fajr > 0 {
                let portion = method.fajr / 60 * night
                if fajr.isNaN || fix(sunrise - fajr, 24) > portion { fajr = sunrise - portion }
            }
            if method.isha > 0 {
                let portion = method.isha / 60 * night
                if isha.isNaN || fix(isha - sunset, 24) > portion { isha = sunset + portion }
            }
        }
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        guard let base = utc.date(from: DateComponents(year: year, month: month, day: day)) else { return [:] }
        let offset = lon / 15
        func make(_ h: Double) -> Date? {
            if h.isNaN || h.isInfinite { return nil }
            return base.addingTimeInterval((h - offset) * 3600)
        }
        var out: [WPrayer: Date] = [:]
        let pairs: [(WPrayer, Double)] = [(.fajr, fajr), (.dhuhr, dhuhr), (.asr, asrT), (.maghrib, sunset), (.isha, isha)]
        for (p, h) in pairs {
            if let d = make(h) { out[p] = d }
        }
        return out
    }

    /// Yesterday, today and tomorrow in the place's time zone, sorted by time.
    static func events(around now: Date, lat: Double, lon: Double, timeZone: TimeZone, method: WMethod) -> [WEvent] {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let c = cal.dateComponents([.year, .month, .day], from: now)
        var all: [WEvent] = []
        for k in -1...1 {
            var utc = Calendar(identifier: .gregorian)
            utc.timeZone = TimeZone(identifier: "UTC")!
            guard let anchor = utc.date(from: DateComponents(year: c.year, month: c.month, day: (c.day ?? 1) + k)) else { continue }
            let u = utc.dateComponents([.year, .month, .day], from: anchor)
            let t = day(year: u.year!, month: u.month!, day: u.day!, lat: lat, lon: lon, method: method)
            for (p, d) in t { all.append(WEvent(prayer: p, date: d)) }
        }
        all.sort { $0.date < $1.date }
        return all
    }
}
