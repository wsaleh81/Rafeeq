import Foundation

enum QiblaMath {
    static let kaaba = (lat: 21.422487, lon: 39.826206)

    static func bearing(lat: Double, lon: Double) -> Double {
        let p1 = lat * .pi / 180, p2 = kaaba.lat * .pi / 180
        let dl = (kaaba.lon - lon) * .pi / 180
        let y = sin(dl) * cos(p2)
        let x = cos(p1) * sin(p2) - sin(p1) * cos(p2) * cos(dl)
        return norm(atan2(y, x) * 180 / .pi)
    }

    static func distanceKm(lat: Double, lon: Double) -> Double {
        let dp = (kaaba.lat - lat) * .pi / 180
        let dl = (kaaba.lon - lon) * .pi / 180
        let a = sin(dp / 2) * sin(dp / 2) + cos(lat * .pi / 180) * cos(kaaba.lat * .pi / 180) * sin(dl / 2) * sin(dl / 2)
        return 2 * 6371 * asin(sqrt(a))
    }

    static func haversineKm(_ lat1: Double, _ lon1: Double, _ lat2: Double, _ lon2: Double) -> Double {
        let dp = (lat2 - lat1) * .pi / 180, dl = (lon2 - lon1) * .pi / 180
        let a = sin(dp / 2) * sin(dp / 2) + cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) * sin(dl / 2) * sin(dl / 2)
        return 2 * 6371 * asin(sqrt(a))
    }

    static func norm(_ d: Double) -> Double {
        var v = d.truncatingRemainder(dividingBy: 360)
        if v < 0 { v += 360 }
        return v
    }

    /// Signed shortest difference a - b in -180...180
    static func diff(_ a: Double, _ b: Double) -> Double {
        let d = (a - b + 540).truncatingRemainder(dividingBy: 360)
        return (d < 0 ? d + 360 : d) - 180
    }

    static let points = ["N","NNE","NE","ENE","E","ESE","SE","SSE","S","SSW","SW","WSW","W","WNW","NW","NNW"]
    static func cardinal(_ d: Double) -> String {
        points[Int((norm(d) / 22.5).rounded()) % 16]
    }
}
