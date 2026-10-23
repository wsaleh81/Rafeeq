import SwiftUI
import CoreText

/// Arabic fonts bundled with the app (all free, SIL Open Font License; see Fonts/FONT-LICENSES.txt).
/// The font is chosen in Settings > App font and applied through Font.sys.
struct AppFont: Identifiable, Hashable {
    let id: String
    let title: String
    let regular: String     // PostScript name of the regular file
    let bold: String?       // PostScript name of the bold file (nil: this family has one weight)

    static let all: [AppFont] = [
        AppFont(id: "cairo", title: "Cairo", regular: "Cairo-Regular", bold: "Cairo-Bold"),
        AppFont(id: "tajawal", title: "Tajawal", regular: "Tajawal-Regular", bold: "Tajawal-Bold"),
        AppFont(id: "almarai", title: "Almarai", regular: "Almarai-Regular", bold: "Almarai-Bold"),
        AppFont(id: "ibm-plex-sans-arabic", title: "IBM Plex Sans Arabic", regular: "IBMPlexSansArabic-Regular", bold: "IBMPlexSansArabic-Bold"),
        AppFont(id: "readex-pro", title: "Readex Pro", regular: "ReadexPro-Regular", bold: "ReadexPro-Bold"),
        AppFont(id: "mada", title: "Mada", regular: "Mada-Regular", bold: "Mada-Bold"),
        AppFont(id: "changa", title: "Changa", regular: "Changa-Regular", bold: "Changa-Bold"),
        AppFont(id: "el-messiri", title: "El Messiri", regular: "ElMessiri-Regular", bold: "ElMessiri-Bold"),
        AppFont(id: "noto-kufi-arabic", title: "Noto Kufi Arabic", regular: "NotoKufiArabic-Regular", bold: "NotoKufiArabic-Bold"),
        AppFont(id: "reem-kufi", title: "Reem Kufi", regular: "ReemKufi-Regular", bold: "ReemKufi-Bold"),
        AppFont(id: "kufam", title: "Kufam", regular: "Kufam-Regular", bold: "Kufam-Bold"),
        AppFont(id: "reem-kufi-fun", title: "Reem Kufi Fun", regular: "ReemKufiFun-Regular", bold: "ReemKufiFun-Bold"),
        AppFont(id: "alexandria", title: "Alexandria", regular: "Alexandria-Regular", bold: "Alexandria-Bold"),
        AppFont(id: "marhey", title: "Marhey", regular: "Marhey-Regular", bold: "Marhey-Bold"),
        AppFont(id: "baloo-bhaijaan-2", title: "Baloo Bhaijaan 2", regular: "BalooBhaijaan2-Regular", bold: "BalooBhaijaan2-Bold"),
        AppFont(id: "blaka", title: "Blaka", regular: "Blaka-Regular", bold: nil),
        AppFont(id: "lalezar", title: "Lalezar", regular: "Lalezar-Regular", bold: nil),
        AppFont(id: "rakkas", title: "Rakkas", regular: "Rakkas-Regular", bold: nil),
        AppFont(id: "noto-naskh-arabic", title: "Noto Naskh Arabic", regular: "NotoNaskhArabic-Regular", bold: "NotoNaskhArabic-Bold"),
        AppFont(id: "amiri", title: "Amiri", regular: "Amiri-Regular", bold: "Amiri-Bold"),
    ]

    static var current: AppFont? {
        let id = UserDefaults.standard.string(forKey: "fontID") ?? "system"
        return all.first { $0.id == id }
    }

    func font(size: CGFloat, bold wantsBold: Bool = false) -> Font {
        if wantsBold, let b = bold { return .custom(b, fixedSize: size) }
        return .custom(regular, fixedSize: size)
    }

    private static var registered = false
    /// Makes the bundled font files available to SwiftUI. Call once at launch.
    static func registerAll() {
        guard !registered else { return }
        registered = true
        for f in all {
            for name in [f.regular, f.bold].compactMap({ $0 }) {
                if let url = Bundle.main.url(forResource: name, withExtension: "ttf") {
                    CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
                }
            }
        }
    }
}

struct FontPickerView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                row(id: "system", title: L("System default"),
                    titleFont: .system(size: 20, weight: .semibold), sampleFont: .system(size: 16))
                ForEach(AppFont.all) { f in
                    row(id: f.id, title: f.title,
                        titleFont: f.font(size: 20, bold: true), sampleFont: f.font(size: 17))
                }
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(L("App font"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(id: String, title: String, titleFont: Font, sampleFont: Font) -> some View {
        let on = model.fontID == id
        return Button { model.fontID = id } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title).font(titleFont).foregroundStyle(Theme.ink)
                    Text("رحال · الظهر 11:28 · Prayer times").font(sampleFont).foregroundStyle(Theme.muted).lineLimit(1)
                }
                Spacer()
                if on { Image(systemName: "checkmark.circle.fill").font(.system(size: 22)).foregroundStyle(Theme.mintDeep) }
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(on ? Theme.mintDeep : Theme.line, lineWidth: on ? 2 : 1))
        }
        .buttonStyle(.plain)
    }
}
