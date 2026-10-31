import SwiftUI

enum AzkharCategory: String, CaseIterable, Identifiable {
    case morning, evening, afterPrayer, sleep, travel
    var id: String { rawValue }

    func title(_ lang: String) -> String {
        let t: [String: [String]] = [
            // morning, evening, after prayer, sleep, travel
            "ar": ["الصباح", "المساء", "بعد الصلاة", "النوم", "السفر"],
            "en": ["Morning", "Evening", "After prayer", "Sleep", "Travel"],
            "tr": ["Sabah", "Akşam", "Namaz sonrası", "Uyku", "Yolculuk"],
            "fr": ["Matin", "Soir", "Après la prière", "Sommeil", "Voyage"],
            "it": ["Mattina", "Sera", "Dopo la preghiera", "Sonno", "Viaggio"],
            "de": ["Morgen", "Abend", "Nach dem Gebet", "Schlaf", "Reise"],
            "nl": ["Ochtend", "Avond", "Na het gebed", "Slaap", "Reis"],
            "es": ["Mañana", "Tarde", "Tras la oración", "Dormir", "Viaje"]
        ]
        let list = LocX.cats[lang] ?? t[lang] ?? t["en"]!
        return list[Self.allCases.firstIndex(of: self)!]
    }
    var arabicTitle: String { title("ar") }
    var icon: String {
        switch self {
        case .morning: "sunrise.fill"
        case .evening: "sunset.fill"
        case .afterPrayer: "hands.sparkles.fill"
        case .sleep: "moon.stars.fill"
        case .travel: "airplane"
        }
    }
}

struct CatIcon: View {
    let cat: AzkharCategory
    let size: CGFloat
    var body: some View {
        if cat == .afterPrayer {
            Image("DuaSolid").renderingMode(.template).resizable().scaledToFit().frame(width: size * 1.1, height: size * 1.1)
        } else {
            Image(systemName: cat.icon).font(.sys(size: size, weight: .semibold))
        }
    }
}

struct AzkharDetailView: View {
    @AppStorage("langID") private var langID = "ar"
    let cat: AzkharCategory
    @Binding var counts: [String: Int]
    var onClose: () -> Void

    private var bodyFont: Font { .sys(size: 19 * Theme.azkarScale) }

    private var hint: String {
        switch langID {
        case "ar": "اضغط على البطاقة للعدّ. النصوص مضمّنة وتعمل بدون إنترنت."
        case "tr": "Saymak için karta dokunun. Metinler çevrimdışı çalışır."
        case "fr": "Touchez une carte pour compter. Les textes fonctionnent hors ligne."
        case "it": "Tocca una scheda per contare. I testi funzionano offline."
        case "de": "Karte antippen zum Zählen. Die Texte funktionieren offline."
        case "nl": "Tik op een kaart om te tellen. De teksten werken offline."
        case "es": "Toca una tarjeta para contar. Los textos funcionan sin conexión."
        default: LocX.hint[langID] ?? "Tap a card to count. Texts work offline."
        }
    }
    private var doneText: String {
        switch langID {
        case "ar": "تم"; case "tr": "Tamam"; case "fr": "Terminé"; case "it": "Fatto"
        case "de": "Fertig"; case "nl": "Klaar"; case "es": "Hecho"; default: LocX.done[langID] ?? "Done"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button(action: onClose) {
                    Image(systemName: "chevron.left").font(.sys(size: 17, weight: .bold))
                        .foregroundStyle(Theme.ink).frame(width: 40, height: 40)
                        .background(Theme.tile, in: Circle())
                }
                CatIcon(cat: cat, size: 18).foregroundStyle(Theme.mintDeep)
                Text(cat.title(langID)).font(.sys(size: 22, weight: .bold, design: Theme.design)).foregroundStyle(Theme.ink)
                Spacer()
            }
            .padding(.horizontal, 20).padding(.vertical, 12)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(AzkharData.items(cat.rawValue)) { d in card(d) }
                    Text(hint).font(.sys(size: 12)).foregroundStyle(Theme.muted)
                        .multilineTextAlignment(.center).padding(.top, 4)
                    Text(Loc.ar ? "القرآن: تنزيل · الأذكار: حصن المسلم" : L("Quran: Tanzil · Adhkar: Hisn al-Muslim"))
                        .font(.sys(size: 11)).foregroundStyle(Theme.muted.opacity(0.8))
                }
                .padding(.horizontal, 20).padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
        .background(Theme.bg.ignoresSafeArea())
        .contentShape(Rectangle())
        .simultaneousGesture(DragGesture(minimumDistance: 30).onEnded { v in
            if v.translation.width > 80 && abs(v.translation.width) > 1.6 * abs(v.translation.height) { onClose() }
        })
    }

    private func translation(_ d: Dhikr) -> String? {
        // Arabic app language: Arabic only. Other languages: their own translation.
        if langID == "ar" { return nil }
        return d.translations[langID] ?? LocX.azkar[d.id]?[langID] ?? d.translations["en"]
    }

    private func card(_ d: Dhikr) -> some View {
        let n = counts[d.id] ?? 0
        let done = n >= d.times
        return Button {
            if n < d.times { counts[d.id] = n + 1; UIImpactFeedbackGenerator(style: .light).impactOccurred() }
        } label: {
            VStack(spacing: 12) {
                // Arabic: from the right, justified
                JustifiedText(text: d.arabic, size: 19 * Theme.azkarScale, color: UIColor(Theme.ink), lineSpacing: 9, markColor: UIColor(Theme.mintDeep))
                if let t = translation(d) {
                    Divider().overlay(Theme.line)
                    Text(t)
                        .font(bodyFont).lineSpacing(4)
                        .foregroundStyle(Theme.muted)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Text(d.ref).font(.sys(size: 12, weight: .medium)).foregroundStyle(Theme.mintDeep)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 10) {
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.tile)
                        GeometryReader { g in Capsule().fill(Theme.mint).frame(width: g.size.width * CGFloat(min(n, d.times)) / CGFloat(d.times)) }
                    }
                    .frame(height: 6)
                    Text(done ? doneText : "\(n) / \(d.times)")
                        .font(.sys(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(done ? Theme.mintDeep : Theme.ink).monospacedDigit()
                    if n > 0 {
                        Button { counts[d.id] = 0 } label: {
                            Image(systemName: "arrow.counterclockwise").font(.sys(size: 13, weight: .semibold)).foregroundStyle(Theme.muted)
                                .frame(width: 28, height: 28)
                        }
                    }
                }
            }
            .padding(16)
            .background(done ? Theme.rowNow : Theme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(done ? Theme.mint.opacity(0.5) : Theme.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

/// All Azkar collections, opened from the Azkar card.
struct AzkharCollectionsView: View {
    @AppStorage("langID") private var langID = "ar"
    var onClose: (() -> Void)? = nil
    @State private var counts: [String: Int] = [:]
    @State private var flipped: AzkharCategory? = nil
    @State private var opened: AzkharCategory? = nil
    @State private var showMore = false

    private let cols = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    private var subtitle: String {
        switch langID {
        case "ar": "اختر مجموعة أذكار"
        case "tr": "Bir zikir grubu seçin"
        case "fr": "Choisissez une série d’invocations"
        case "it": "Scegli una raccolta di adhkar"
        case "de": "Wähle eine Gruppe von Adhkar"
        case "nl": "Kies een groep adhkar"
        case "es": "Elige un grupo de adhkar"
        default: "Choose a collection"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                if let onClose {
                    Button(action: onClose) {
                        Image(systemName: "chevron.left").font(.sys(size: 17, weight: .bold))
                            .foregroundStyle(Theme.ink).frame(width: 40, height: 40)
                            .background(Theme.tile, in: Circle())
                    }
                }
                PageTitle(en: "Azkhar", ar: "الأذكار")
            }
            .padding(.horizontal, 20).padding(.top, 8)
            Text(subtitle).font(.sys(size: 14)).foregroundStyle(Theme.muted)
                .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20).padding(.top, 2)

            ScrollView {
                LazyVGrid(columns: cols, spacing: 14) {
                    ForEach(AzkharCategory.allCases) { c in tile(c) }
                    moreTile
                }
                .padding(.horizontal, 20).padding(.vertical, 16)
            }
            .scrollIndicators(.hidden)
        }
        .background(Theme.bg.ignoresSafeArea())
        .fullScreenCover(item: $opened, onDismiss: { withAnimation(.easeInOut(duration: 0.35)) { flipped = nil } }) { c in
            AzkharDetailView(cat: c, counts: $counts, onClose: { opened = nil })
        }
        .fullScreenCover(isPresented: $showMore) {
            MoreAzkarView(counts: $counts, onClose: { showMore = false })
        }
    }

    /// Sixth card: opens the 24 more sections (provision duas and the rest of Hisn al-Muslim)
    private var moreTile: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            showMore = true
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                Text("📚").font(.system(size: 28))
                    .frame(width: 52, height: 52)
                    .background(Theme.mintDeep.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                Spacer(minLength: 8)
                Text(MoreAzkar.title(langID)).font(.sys(size: 19, weight: .bold, design: Theme.design)).foregroundStyle(Theme.ink)
                    .lineLimit(1).minimumScaleFactor(0.8)
                HStack {
                    Spacer()
                    Text("\(MoreAzkar.groups.count)").font(.sys(size: 13, weight: .bold, design: .rounded)).foregroundStyle(Theme.muted)
                }
            }
            .padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 168)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Theme.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func tile(_ c: AzkharCategory) -> some View {
        let isFlipped = flipped == c
        let n = AzkharData.items(c.rawValue).count
        return Button {
            guard flipped == nil else { return }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.easeInOut(duration: 0.45)) { flipped = c }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { opened = c }
        } label: {
            ZStack {
                front(c, n).opacity(isFlipped ? 0 : 1)
                back(c).opacity(isFlipped ? 1 : 0).rotation3DEffect(.degrees(180), axis: (0, 1, 0))
            }
            .frame(height: 168)
            .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (0, 1, 0), perspective: 0.6)
        }
        .buttonStyle(.plain)
    }

    private func front(_ c: AzkharCategory, _ n: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            CatIcon(cat: c, size: 26).foregroundStyle(Theme.mintDeep)
                .frame(width: 52, height: 52)
                .background(Theme.mintDeep.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            Spacer(minLength: 8)
            Text(c.title(langID)).font(.sys(size: 19, weight: .bold, design: Theme.design)).foregroundStyle(Theme.ink)
                .lineLimit(1).minimumScaleFactor(0.8)
            HStack {
                Spacer()
                Text("\(n)").font(.sys(size: 13, weight: .bold, design: .rounded)).foregroundStyle(Theme.muted)
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Theme.line, lineWidth: 1))
    }

    private func back(_ c: AzkharCategory) -> some View {
        VStack(spacing: 10) {
            CatIcon(cat: c, size: 34)
            Text(c.title(langID)).font(.sys(size: 22, weight: .bold))
        }
        .foregroundStyle(Theme.onAccent)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.mint, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

/// Azkar tab: one card for all Azkar collections and one for the Moshaf.
struct AzkharView: View {
    @AppStorage("langID") private var langID = "ar"
    @AppStorage("moshafPage") private var moshafPage = 1
    @State private var showAzkar = false
    @State private var showMoshaf = false

    /// The Azkar tab opens the collections directly; the Mushaf has its own tab.
    var body: some View {
        AzkharCollectionsView()
    }

    private func open(_ flag: Binding<Bool>) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        flag.wrappedValue = true
    }

    private var azkarCard: some View {
        Button { open($showAzkar) } label: {
            HStack(spacing: 14) {
                Image("DuaSolid").renderingMode(.template).resizable().scaledToFit().frame(width: 30, height: 30)
                    .foregroundStyle(Theme.mintDeep)
                    .frame(width: 60, height: 60)
                    .background(Theme.mintDeep.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("Azkhar")).font(.sys(size: 21, weight: .bold, design: Theme.design)).foregroundStyle(Theme.ink)
                    Text(AzkharCategory.allCases.map { $0.title(langID) }.joined(separator: " · "))
                        .font(.sys(size: 13)).foregroundStyle(Theme.muted).lineLimit(2)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.forward").font(.sys(size: 15, weight: .bold)).foregroundStyle(Theme.muted)
            }
            .padding(16).frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Theme.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var moshafCard: some View {
        let q = Quran.shared
        let page = min(max(moshafPage, 1), 604)
        let sura = q.isLoaded ? "سورة " + q.suras[q.sura(ofPage: page) - 1].ar : ""
        return Button { open($showMoshaf) } label: {
            HStack(spacing: 14) {
                Image(systemName: "book.closed.fill").font(.sys(size: 26, weight: .semibold))
                    .foregroundStyle(Theme.mintDeep)
                    .frame(width: 60, height: 60)
                    .background(Theme.mintDeep.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(Loc.ar ? "المصحف" : L("Mushaf")).font(.sys(size: 21, weight: .bold, design: Theme.design)).foregroundStyle(Theme.ink)
                        if !Loc.ar { Spacer(); Text("المصحف").font(.sys(size: 18, weight: .bold)).foregroundStyle(Theme.mintDeep) }
                    }
                    Text(page > 1
                         ? (Loc.ar ? "تابع القراءة: صفحة \(Moshaf.arabicDigits(page)) · \(sura)" : Loc.f("Continue: page {0}", "\(page)") + " · " + sura)
                         : (Loc.ar ? "القرآن الكريم · رواية حفص" : L("The Holy Quran · Hafs")))
                        .font(.sys(size: 13)).foregroundStyle(Theme.muted).lineLimit(2)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.forward").font(.sys(size: 15, weight: .bold)).foregroundStyle(Theme.muted)
            }
            .padding(16).frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Theme.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
