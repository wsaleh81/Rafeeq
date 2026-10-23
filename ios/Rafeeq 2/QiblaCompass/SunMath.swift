import Foundation

/// Where the sun is right now and where it rises and sets today, for a place on Earth.
struct SunInfo {
    let az: Double        // degrees clockwise from true north
    let alt: Double       // degrees above the horizon (negative = below)
    let riseAz: Double
    let setAz: Double
    let northern: Bool    // sun crosses the southern sky (northern hemisphere)
    var up: Bool { alt > 0 }
}

enum SunMath {
    private static func rad(_ d: Double) -> Double { d * .pi / 180 }
    private static func deg(_ r: Double) -> Double { r * 180 / .pi }
    private static func fix(_ a: Double, _ b: Double) -> Double { a - b * floor(a / b) }

    static func info(lat: Double, lon: Double, date: Date) -> SunInfo {
        let jd = date.timeIntervalSince1970 / 86400 + 2440587.5
        let d = jd - 2451545.0
        let g = fix(357.529 + 0.98560028 * d, 360)
        let q = fix(280.459 + 0.98564736 * d, 360)
        let l = fix(q + 1.915 * sin(rad(g)) + 0.020 * sin(rad(2 * g)), 360)
        let e = 23.439 - 0.00000036 * d
        let ra = fix(deg(atan2(cos(rad(e)) * sin(rad(l)), cos(rad(l)))) / 15, 24)
        let dec = deg(asin(sin(rad(e)) * sin(rad(l))))
        let eqt = q / 15 - ra
        let ut = fix(date.timeIntervalSince1970, 86400) / 3600
        let h = fix(15 * (ut + lon / 15 - 12 + eqt), 360)
        let az = fix(deg(atan2(sin(rad(h)), cos(rad(h)) * sin(rad(lat)) - tan(rad(dec)) * cos(rad(lat)))) + 180, 360)
        let alt = deg(asin(sin(rad(lat)) * sin(rad(dec)) + cos(rad(lat)) * cos(rad(dec)) * cos(rad(h))))
        let x = max(-1, min(1, sin(rad(dec)) / max(0.0001, cos(rad(lat)))))
        let rise = deg(acos(x))
        return SunInfo(az: az, alt: alt, riseAz: rise, setAz: 360 - rise, northern: lat >= 0)
    }
}
