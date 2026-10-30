import SwiftUI
import MapKit

/// Square badge with the country's two-letter ISO code.
struct ISOBadge: View {
    let code: String
    var body: some View {
        Text(code)
            .font(.sys(size: 12.5, weight: .bold, design: .rounded)).minimumScaleFactor(0.8)
            .foregroundStyle(Theme.mintDeep)
            .frame(width: 46, height: 34)
            .background(Theme.mintDeep.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Theme.mintDeep.opacity(0.35), lineWidth: 1))
    }
}

/// Search + list of cities: bundled list first (works offline), more results from Apple Maps when online.
struct CityPickerList<Header: View>: View {
    let selectedName: String?
    let onPick: (Place) -> Void
    @ViewBuilder var header: () -> Header
    @State private var query = ""
    @State private var online: [Place] = []
    @State private var searching = false
    @EnvironmentObject var model: AppModel

    private static func fold(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }

    private var local: [Place] {
        let q = Self.fold(query.trimmingCharacters(in: .whitespaces))
        guard !q.isEmpty else { return Cities.all.sorted { $0.name < $1.name } }
        func score(_ c: Place) -> Int {
            let n = Self.fold(c.name), k = Self.fold(c.country), i = c.isoCode.lowercased()
            if n.hasPrefix(q) { return 0 }
            if i == q || c.iso2.lowercased() == q { return 1 }
            if k.hasPrefix(q) { return 2 }
            if n.contains(q) { return 3 }
            if k.contains(q) { return 4 }
            return 9
        }
        return Cities.all.filter { score($0) < 9 }.sorted { (score($0), $0.name) < (score($1), $1.name) }
    }

    private var extra: [Place] {
        let have = Set(local.map { Self.fold($0.name) + $0.iso2 })
        return online.filter { !have.contains(Self.fold($0.name) + $0.iso2) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundStyle(Theme.muted)
                    TextField(L("Search city, country or code"), text: $query)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    if searching { ProgressView().controlSize(.small) }
                    else if !query.isEmpty {
                        Button { query = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.muted) }
                    }
                }
                .padding(.horizontal, 14).frame(height: 48)
                .background(Theme.tile, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                header()

                if local.isEmpty && extra.isEmpty && !searching {
                    Text(L(model.network.online ? "No city found. Try another spelling." : "No match offline. Connect to the internet to search more cities."))
                        .font(.sys(size: 14)).foregroundStyle(Theme.muted).padding(.vertical, 20).frame(maxWidth: .infinity)
                }
                if !local.isEmpty { rows(local) }
                if !extra.isEmpty {
                    Text(L("More results")).font(.sys(size: 13, weight: .semibold)).foregroundStyle(Theme.muted).padding(.leading, 6)
                    rows(extra)
                }
            }
            .padding(.horizontal, 20).padding(.bottom, 40)
        }
        .scrollIndicators(.hidden).scrollDismissesKeyboard(.interactively)
        .background(Theme.bg.ignoresSafeArea())
        .task(id: query) { await searchOnline() }
    }

    private func rows(_ items: [Place]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { idx, c in
                Button { onPick(c) } label: {
                    HStack(spacing: 12) {
                        ISOBadge(code: c.isoCode)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(c.name).font(.sys(size: 17, weight: .semibold)).lineLimit(1)
                            Text(c.country).font(.sys(size: 13)).foregroundStyle(Theme.muted).lineLimit(1)
                        }
                        Spacer()
                        if selectedName == c.name { Image(systemName: "checkmark").foregroundStyle(Theme.mintDeep) }
                    }
                    .foregroundStyle(selectedName == c.name ? Theme.mintDeep : Theme.ink)
                    .frame(minHeight: 56).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if idx < items.count - 1 { Divider().overlay(Theme.line) }
            }
        }
        .padding(.horizontal, 16).card(28)
    }

    private func searchOnline() async {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard q.count >= 2, model.network.online else { online = []; searching = false; return }
        try? await Task.sleep(nanoseconds: 450_000_000)
        if Task.isCancelled { return }
        searching = true
        defer { searching = false }
        let req = MKLocalSearch.Request()
        req.naturalLanguageQuery = q
        req.resultTypes = .address
        guard let res = try? await MKLocalSearch(request: req).start() else { return }
        var out: [Place] = []
        for m in res.mapItems {
            let p = m.placemark
            guard let name = p.locality ?? p.name, let cc = p.isoCountryCode, let country = p.country else { continue }
            out.append(Place(name: name, country: country, lat: p.coordinate.latitude, lon: p.coordinate.longitude,
                             tz: (m.timeZone ?? .current).identifier, isGPS: false, iso: cc))
        }
        if !Task.isCancelled { online = out }
    }
}
