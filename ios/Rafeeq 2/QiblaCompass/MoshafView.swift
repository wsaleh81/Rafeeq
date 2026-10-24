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
            GeometryReader { p in
                BookPager(page: $page, landscape: landscape, size: p.size)
                    .frame(width: p.size.width, height: p.size.height)
                    .id(landscape)
            }   // its own size, below the top strip
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

/// The real page curl of iOS (the one in Apple Books), set up as a right-to-left book: pages turn from left to right.
/// Landscape: the open book, two pages with the spine in the middle (odd page on the right, even on the left).
/// Portrait: one page with the spine on the right edge.
private struct BookPager: UIViewControllerRepresentable {
    @Binding var page: Int
    let landscape: Bool
    let size: CGSize

    private var ph: CGFloat { size.height }
    private var pw: CGFloat { landscape ? min(size.width / 2, ph * 0.9) : size.width }

    final class PageHost: UIHostingController<AnyView> {
        var number = 1
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let c = context.coordinator
        let spine: UIPageViewController.SpineLocation = landscape ? .mid : .max
        let pvc = UIPageViewController(transitionStyle: .pageCurl, navigationOrientation: .horizontal,
                                       options: [.spineLocation: NSNumber(value: spine.rawValue)])
        pvc.isDoubleSided = landscape
        pvc.dataSource = c
        pvc.delegate = c
        pvc.view.backgroundColor = .white
        c.landscape = landscape; c.pw = pw; c.ph = ph
        pvc.setViewControllers(c.controllers(for: page), direction: .forward, animated: false)
        return pvc
    }

    func updateUIViewController(_ pvc: UIPageViewController, context: Context) {
        let c = context.coordinator
        c.parent = self; c.pw = pw; c.ph = ph
        let shown = (pvc.viewControllers ?? []).compactMap { ($0 as? PageHost)?.number }.min() ?? 0
        let target = landscape ? ((page - 1) / 2) * 2 + 1 : page
        if shown != target {      // jumped from the index
            pvc.setViewControllers(c.controllers(for: page), direction: target > shown ? .forward : .reverse, animated: false)
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiViewController: UIPageViewController, context: Context) -> CGSize? {
        CGSize(width: landscape ? pw * 2 : pw, height: ph)
    }

    final class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: BookPager
        var landscape = false, pw: CGFloat = 0, ph: CGFloat = 0
        init(_ p: BookPager) { parent = p }

        private func host(_ n: Int) -> PageHost {
            let h = PageHost(rootView: AnyView(
                MushafPageView(page: n).environment(\.layoutDirection, .leftToRight)
                    .background(Color.white)
            ))
            h.number = n
            h.view.backgroundColor = .white
            return h
        }

        func controllers(for page: Int) -> [UIViewController] {
            if landscape {
                let b = ((page - 1) / 2) * 2 + 1
                return [host(min(b + 1, 604)), host(b)]   // left: even page, right: odd page
            }
            return [host(page)]
        }

        func pageViewController(_ p: UIPageViewController, viewControllerBefore vc: UIViewController) -> UIViewController? {
            // the curl runs left to right for the NEXT page (Arabic book), so "before" in curl terms is the next page
            guard let n = (vc as? PageHost)?.number, n < 604 else { return nil }
            return host(n + 1)
        }
        func pageViewController(_ p: UIPageViewController, viewControllerAfter vc: UIViewController) -> UIViewController? {
            guard let n = (vc as? PageHost)?.number, n > 1 else { return nil }
            return host(n - 1)
        }
        func pageViewController(_ p: UIPageViewController, didFinishAnimating finished: Bool,
                                previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
            guard completed, let n = (p.viewControllers ?? []).compactMap({ ($0 as? PageHost)?.number }).min() else { return }
            parent.page = n
        }
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
