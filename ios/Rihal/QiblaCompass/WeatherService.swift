import Foundation
import Network
import Combine

/// Current temperature for the chip on the Qibla screen. Needs internet; the last result is cached for offline use.
/// Source: Open-Meteo (no key). Kept behind this one class so it can be swapped for Apple WeatherKit later.
final class WeatherService: ObservableObject {
    struct Snapshot: Codable { var tempC: Double; var code: Int; var isDay: Bool; var updated: Date; var lat: Double; var lon: Double }

    @Published var snapshot: Snapshot?
    @Published var loading = false
    private var inflight = false

    init() {
        if let d = UserDefaults.standard.data(forKey: "weatherCache"),
           let s = try? JSONDecoder().decode(Snapshot.self, from: d) { snapshot = s }
    }

    /// Refresh when the data is older than 15 minutes or you moved more than 20 km.
    func refresh(lat: Double, lon: Double, force: Bool = false) {
        if inflight { return }
        if !force, let s = snapshot,
           Date().timeIntervalSince(s.updated) < 900,
           QiblaMath.haversineKm(s.lat, s.lon, lat, lon) < 20 { return }
        guard let url = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=\(String(format: "%.2f", lat))&longitude=\(String(format: "%.2f", lon))&current=temperature_2m,weather_code,is_day&timezone=auto") else { return }
        inflight = true; loading = true
        var req = URLRequest(url: url); req.timeoutInterval = 10
        URLSession.shared.dataTask(with: req) { [weak self] data, _, _ in
            var snap: Snapshot?
            if let data,
               let j = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let c = j["current"] as? [String: Any],
               let t = c["temperature_2m"] as? Double {
                snap = Snapshot(tempC: t, code: (c["weather_code"] as? Int) ?? 0, isDay: ((c["is_day"] as? Int) ?? 1) == 1,
                                updated: Date(), lat: lat, lon: lon)
            }
            DispatchQueue.main.async {
                guard let self else { return }
                self.inflight = false; self.loading = false
                if let snap {
                    self.snapshot = snap
                    if let d = try? JSONEncoder().encode(snap) { UserDefaults.standard.set(d, forKey: "weatherCache") }
                }
            }
        }.resume()
    }

    static func symbol(code: Int, isDay: Bool) -> String {
        switch code {
        case 0: return isDay ? "sun.max.fill" : "moon.stars.fill"
        case 1, 2: return isDay ? "cloud.sun.fill" : "cloud.moon.fill"
        case 3: return "cloud.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51...57: return "cloud.drizzle.fill"
        case 61...67, 80...82: return "cloud.rain.fill"
        case 71...77, 85, 86: return "cloud.snow.fill"
        case 95...99: return "cloud.bolt.rain.fill"
        default: return "cloud.fill"
        }
    }
}

/// Online / offline indicator.
final class NetworkMonitor: ObservableObject {
    @Published var online = true
    private let monitor = NWPathMonitor()
    init() {
        monitor.pathUpdateHandler = { [weak self] p in
            DispatchQueue.main.async { self?.online = p.status == .satisfied }
        }
        monitor.start(queue: DispatchQueue(label: "net.monitor"))
    }
}
