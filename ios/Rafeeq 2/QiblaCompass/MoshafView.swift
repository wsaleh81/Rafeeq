import SwiftUI
import UIKit
import CoreText

// Quran text: King Fahd Glorious Quran Printing Complex, Hafs narration in the Uthmani script of the
// Madinah Mushaf (Quran/quran-hafs.txt, unchanged, obtained from the Quran.com API).
// Font: KFGQPC HAFS Uthmanic Script v18 (Quran/UthmanicHafs1Ver18.ttf), free to use and distribute unmodified.
// Surah names, juz and the 604 Madani page breaks: Tanzil Quran Metadata (Quran/quran-meta.json).
// Line layout, 15 lines per page as printed: Quran.com API (Quran/mushaf-lines.json).

struct SuraInfo: Decodable {
    let ar: String, tr: String, en: String, type: String, ayas: Int
}

final class Quran {
    static let shared = Quran()
    let suras: [SuraInfo]
    let pages: [[Int]]          // start [sura, aya] of each page
    let juz: [[Int]]            // start [sura, aya] of each juz
    private let ayahs: [[String]]
    private let bismillah: String

    private init() {
        struct Meta: Decodable { let suras: [SuraInfo]; let pages: [[Int]]; let juz: [[Int]] }
        let meta = Bundle.main.url(forResource: "quran-meta", withExtension: "json")
            .flatMap { try? Data(contentsOf: $0) }
            .flatMap { try? JSONDecoder().decode(Meta.self, from: $0) }
        suras = meta?.suras ?? []; pages = meta?.pages ?? []; juz = meta?.juz ?? []

        var a = suras.map { [String](repeating: "", count: $0.ayas) }
        let txt = Bundle.main.url(forResource: "quran-hafs", withExtension: "txt")
            .flatMap { try? String(contentsOf: $0, encoding: .utf8) } ?? ""
        for line in txt.split(separator: "\n") where !line.hasPrefix("#") {
            let p = line.split(separator: "|", maxSplits: 2)
            guard p.count == 3, let s = Int(p[0]), let n = Int(p[1]), a.indices.contains(s - 1), a[s - 1].indices.contains(n - 1) else { continue }
            a[s - 1][n - 1] = String(p[2])
        }
        ayahs = a
        // 1:1 without its ayah number
        bismillah = (a.first?.first ?? "").replacingOccurrences(of: "\\s*[٠-٩]+$", with: "", options: .regularExpression)
    }

    var isLoaded: Bool { suras.count == 114 && pages.count == 604 }
    var bismillahText: String { bismillah }

    /// Ayah text as printed, ending with its number (drawn by the Madinah font as the ayah rosette).
    /// The space before the number is made non-breaking so the rosette never starts a line.
    func text(_ s: Int, _ n: Int) -> String {
        ayahs[s - 1][n - 1].replacingOccurrences(of: " ([٠-٩]+)$", with: "\u{00A0}$1", options: .regularExpression)
    }

    private func before(_ a: [Int], _ b: [Int]) -> Bool { a[0] < b[0] || (a[0] == b[0] && a[1] < b[1]) }

    /// Ayahs on a page (1...604), in order.
    func ayahs(onPage p: Int) -> [(sura: Int, aya: Int)] {
        guard pages.indices.contains(p - 1) else { return [] }
        let end = p < pages.count ? pages[p] : [115, 1]
        var out: [(Int, Int)] = []
        var s = pages[p - 1][0], n = pages[p - 1][1]
        while before([s, n], end) {
            out.append((s, n))
            if n < suras[s - 1].ayas { n += 1 } else { s += 1; n = 1; if s > 114 { break } }
        }
        return out
    }

    func page(of s: Int, _ n: Int = 1) -> Int { (pages.lastIndex { !before([s, n], $0) } ?? 0) + 1 }
    func juz(ofPage p: Int) -> Int { guard pages.indices.contains(p - 1) else { return 1 }; return (juz.lastIndex { !before(pages[p - 1], $0) } ?? 0) + 1 }
    func sura(ofPage p: Int) -> Int { pages.indices.contains(p - 1) ? pages[p - 1][0] : 1 }
}

/// The King Fahd Complex Uthmanic Hafs font of the Madinah Mushaf, registered from the app bundle.
enum MadinahFont {
    private static let registered: Bool = {
        guard let url = Bundle.main.url(forResource: "UthmanicHafs1Ver18", withExtension: "ttf") else { return false }
        return CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }()

    static func font(_ size: CGFloat) -> UIFont {
        _ = registered
        return UIFont(name: "KFGQPCHAFSUthmanicScript-Regula", size: size) ?? .systemFont(ofSize: size)
    }
}

enum Moshaf {
    /// One size for the surah title and the juz tab, so both read in the same font
    static let labelSize: CGFloat = 19
    /// Very light blue page, fixed in light and dark mode like printed paper
    static let paper = Color(hex: 0xF2F9FD)
    static let paperDeep = Color(hex: 0xD4EAF7)
    static let ink = Color(hex: 0x14233A)
    static let frame = Color(hex: 0x2A78AE)
    static let muted = Color(hex: 0x5A6E86)
    // Zukhrufa border of the Madinah Mushaf
    static let navy = Color(hex: 0x133D63)
    static let sky = Color(hex: 0x8ED0EE)
    static let sky2 = Color(hex: 0xBFE6F7)
    static let gold = Color(hex: 0xC79A3A)
    static let tab = Color(hex: 0xBFE6F7)
    static let text = Color(hex: 0x111111)

    static func arabicDigits(_ n: Int) -> String {
        String(String(n).compactMap { $0.wholeNumberValue.map { Character(UnicodeScalar(0x0660 + $0)!) } })
    }
    static func digits(_ n: Int) -> String { Loc.ar ? arabicDigits(n) : "\(n)" }

    static let juzOrdinals = [
        "الأول", "الثاني", "الثالث", "الرابع", "الخامس", "السادس", "السابع", "الثامن", "التاسع", "العاشر",
        "الحادي عشر", "الثاني عشر", "الثالث عشر", "الرابع عشر", "الخامس عشر", "السادس عشر", "السابع عشر", "الثامن عشر", "التاسع عشر", "العشرون",
        "الحادي والعشرون", "الثاني والعشرون", "الثالث والعشرون", "الرابع والعشرون", "الخامس والعشرون", "السادس والعشرون", "السابع والعشرون", "الثامن والعشرون", "التاسع والعشرون", "الثلاثون"
    ]
    static func juzName(_ j: Int) -> String { "الجزء " + juzOrdinals[min(max(j, 1), 30) - 1] }
}

// MARK: reader

struct MoshafView: View {
    @AppStorage("moshafPage") private var savedPage = 1
    /// Starts on the saved page, so the pager never has to jump there (a jump reports the pages in between).
    @State private var page = min(max(UserDefaults.standard.integer(forKey: "moshafPage"), 1), 604)
    @State private var showIndex = false
    var onClose: () -> Void
    private let q = Quran.shared

    private func circleButton(_ icon: String) -> some View {
        Image(systemName: icon).font(.sys(size: 17, weight: .bold))
            .foregroundStyle(Moshaf.ink).frame(width: 40, height: 40)
            .background(Moshaf.paperDeep, in: Circle())
    }

    /// Landscape: the page spread is the unit (odd page on the right, even page on the left, like the open book).
    private var spread: Binding<Int> {
        Binding(get: { (page - 1) / 2 }, set: { page = min($0 * 2 + 1, 604) })
    }

    private func topBar(compact: Bool) -> some View {
        HStack(spacing: 10) {
            Button(action: onClose) { circleButton("chevron.left") }
                .accessibilityLabel(L("Done"))
            Spacer()
            if q.isLoaded && !compact {
                Text("سورة " + q.suras[q.sura(ofPage: page) - 1].ar).font(.sys(size: 19, weight: .bold)).foregroundStyle(Moshaf.ink)
            }
            Spacer()
            Button { showIndex = true } label: { circleButton("list.bullet") }
                .accessibilityLabel(Loc.ar ? "الفهرس" : L("Surahs"))
        }
        .padding(.horizontal, 16).padding(.vertical, compact ? 4 : 8)
    }

    var body: some View {
        GeometryReader { g in
            let landscape = g.size.width > g.size.height
            Group {
                if landscape {
                    // the pages sit below the white strip that holds the buttons
                    VStack(spacing: 0) {
                        topBar(compact: true)
                        pager(landscape: true, size: CGSize(width: g.size.width, height: g.size.height - 44))
                    }
                } else {
                    VStack(spacing: 0) {
                        topBar(compact: false)
                        pager(landscape: false, size: g.size)
                    }
                }
            }
        }
        .background(Color.white.ignoresSafeArea())
        .environment(\.colorScheme, .light)
        .onAppear { OrientationLock.set(.allButUpsideDown) }
        .onDisappear { OrientationLock.set(.portrait) }
        .onChange(of: page) { _, p in savedPage = p }
        .sheet(isPresented: $showIndex) {
            MoshafIndex { p in page = p; showIndex = false }
                .presentationDetents([.large])
        }
    }

    @ViewBuilder private func pager(landscape: Bool, size: CGSize) -> some View {
        if q.isLoaded {
            BookPager(page: $page, landscape: landscape, size: size)
        } else {
            VStack {
                Spacer()
                Text(Loc.ar ? "تعذّر تحميل نص المصحف." : "The Quran text could not be loaded.").foregroundStyle(Moshaf.muted)
                Spacer()
            }
        }
    }
}

// MARK: page turn

/// A page that really turns, like a book. Landscape: the open book, the left page lifts, swings over the spine
/// and lands on the right (next pages). Portrait: the page lifts off from the left edge and shows the next one.
private struct BookPager: View {
    @Binding var page: Int
    let landscape: Bool
    let size: CGSize
    /// -1...1: positive = turning forward (drag left to right), negative = turning back
    @State private var t: CGFloat = 0

    private var ph: CGFloat { size.height }
    private var pw: CGFloat { landscape ? min(size.width / 2, ph * 0.9) : size.width }
    private var step: Int { landscape ? 2 : 1 }
    /// first page of the current view: the odd (right) page in landscape
    private var base: Int { landscape ? ((page - 1) / 2) * 2 + 1 : page }

    private func face(_ n: Int) -> some View {
        Group {
            if (1...604).contains(n) { MushafPageView(page: n) } else { Moshaf.paper }
        }
        .frame(width: pw, height: ph)
        .environment(\.layoutDirection, .leftToRight)
    }

    private func canTurn(_ forward: Bool) -> Bool {
        forward ? base + step <= 604 : base - step >= 1
    }

    var body: some View {
        let p = abs(t)
        let forward = t > 0
        ZStack {
            if landscape { landscapeBook(p: p, forward: forward) } else { portraitBook(p: p, forward: forward) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 12)
                .onChanged { v in
                    let fw = v.translation.width > 0
                    guard canTurn(fw) else { t = 0; return }
                    let span = landscape ? size.width * 0.5 : size.width * 0.8
                    t = (fw ? 1 : -1) * min(abs(v.translation.width) / span, 1)
                }
                .onEnded { v in
                    let fw = t > 0
                    let flick = abs(v.predictedEndTranslation.width) > size.width * 0.5
                    if t != 0, abs(t) > 0.35 || flick {
                        withAnimation(.easeOut(duration: 0.28)) { t = fw ? 1 : -1 } completion: {
                            var tx = Transaction(); tx.disablesAnimations = true
                            withTransaction(tx) {
                                page = fw ? min(base + step, 604) : max(base - step, 1)
                                t = 0
                            }
                        }
                    } else {
                        withAnimation(.easeOut(duration: 0.22)) { t = 0 }
                    }
                }
        )
    }

    // open book: left page = base+1, right page = base
    private func landscapeBook(p: CGFloat, forward: Bool) -> some View {
        let b = base
        // pages lying under the leaf
        let left = p == 0 ? b + 1 : (forward ? b + 3 : b + 1)
        let right = p == 0 ? b : (forward ? b : b - 2)
        // the leaf: angle -180 (flat on the left) ... 0 (flat on the right)
        let a: Double = forward ? Double(-180 + 180 * p) : Double(-180 * p)
        let faceR = forward ? b + 2 : b          // seen while the leaf is on the right half
        let faceL = forward ? b + 1 : b - 1      // seen while the leaf is on the left half
        return ZStack {
            HStack(spacing: 0) { face(left); face(right) }
            if p > 0 {
                Group {
                    if a > -90 { face(faceR) } else { face(faceL).scaleEffect(x: -1) }
                }
                .overlay(Color.black.opacity(0.30 * abs(sin(a * .pi / 180))).allowsHitTesting(false))
                .rotation3DEffect(.degrees(a), axis: (x: 0, y: 1, z: 0), anchor: .leading, perspective: 0.35)
                .shadow(color: .black.opacity(0.35 * abs(sin(a * .pi / 180))), radius: 12, x: a > -90 ? 6 : -6)
                .offset(x: pw / 2)
            }
        }
        .frame(width: pw * 2, height: ph)
    }

    // single page: the page lifts off from its left edge
    private func portraitBook(p: CGFloat, forward: Bool) -> some View {
        let b = base
        return ZStack {
            face(p == 0 ? b : (forward ? b + 1 : b))
            if p > 0 {
                // forward: the current page lifts (0 -> 90deg); back: the previous page comes down (90 -> 0)
                let a: Double = forward ? 90 * Double(p) : 90 * Double(1 - p)
                let n = forward ? b : b - 1
                face(n)
                    .overlay(Color.black.opacity(0.25 * sin(a * .pi / 180)).allowsHitTesting(false))
                    .rotation3DEffect(.degrees(a), axis: (x: 0, y: 1, z: 0), anchor: .trailing, perspective: 0.35)
                    .shadow(color: .black.opacity(0.3 * sin(a * .pi / 180)), radius: 10, x: -6)
            }
        }
        .frame(width: pw, height: ph)
    }
}

// MARK: index

private struct MoshafIndex: View {
    @State private var byJuz = false
    var onPick: (Int) -> Void
    private let q = Quran.shared

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $byJuz) {
                Text(Loc.ar ? "السور" : L("Surahs")).tag(false)
                Text(Loc.ar ? "الأجزاء" : L("Juz")).tag(true)
            }
            .pickerStyle(.segmented).padding(16)

            List {
                if byJuz {
                    ForEach(1...30, id: \.self) { j in
                        let start = q.juz[j - 1]
                        row(num: j, title: Loc.ar ? "الجزء \(Moshaf.arabicDigits(j))" : Loc.f("Juz {0}", "\(j)"),
                            sub: "سورة " + q.suras[start[0] - 1].ar + " · " + Moshaf.digits(start[1]),
                            page: q.page(of: start[0], start[1]))
                    }
                } else {
                    ForEach(1...114, id: \.self) { s in
                        let info = q.suras[s - 1]
                        row(num: s, title: "سورة " + info.ar,
                            sub: (Loc.ar ? "" : info.tr + " · ") + (Loc.ar ? (info.type == "Meccan" ? "مكية" : "مدنية") + " · \(Moshaf.arabicDigits(info.ayas)) آية" : Loc.f("{0} ayahs", "\(info.ayas)")),
                            page: q.page(of: s))
                    }
                }
                Section {
                    Link(destination: URL(string: "https://qurancomplex.gov.sa")!) {
                        Text(Loc.ar ? "نص المصحف وخطه: مجمع الملك فهد لطباعة المصحف الشريف، الرسم العثماني برواية حفص (مصحف المدينة النبوية)"
                                    : "Quran text and font: King Fahd Glorious Quran Printing Complex, Uthmani script, Hafs (Madinah Mushaf)")
                            .font(.sys(size: 12)).foregroundStyle(Moshaf.muted)
                    }
                    Link(destination: URL(string: "https://tanzil.net")!) {
                        Text(Loc.ar ? "بيانات الصفحات والأجزاء: مشروع تنزيل · tanzil.net" : "Page and juz data: Tanzil Project · tanzil.net")
                            .font(.sys(size: 12)).foregroundStyle(Moshaf.muted)
                    }
                    Link(destination: URL(string: "https://quran.com")!) {
                        Text(Loc.ar ? "ترتيب الأسطر (١٥ سطرًا في الصفحة): Quran.com" : "Line layout (15 lines per page): Quran.com")
                            .font(.sys(size: 12)).foregroundStyle(Moshaf.muted)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .background(Moshaf.paper.ignoresSafeArea())
        .environment(\.colorScheme, .light)
    }

    private func row(num: Int, title: String, sub: String, page: Int) -> some View {
        Button { onPick(page) } label: {
            HStack(spacing: 12) {
                Text(Moshaf.digits(num)).font(.sys(size: 14, weight: .bold)).foregroundStyle(Moshaf.frame)
                    .frame(width: 36, height: 36).background(Moshaf.paperDeep, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.sys(size: 17, weight: .bold)).foregroundStyle(Moshaf.ink)
                    Text(sub).font(.sys(size: 12)).foregroundStyle(Moshaf.muted)
                }
                Spacer()
                Text(Moshaf.digits(page)).font(.sys(size: 13, weight: .semibold)).foregroundStyle(Moshaf.muted).monospacedDigit()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
    }
}
