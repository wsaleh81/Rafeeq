import SwiftUI
import UIKit

extension Color {
    init(light: UInt32, dark: UInt32) {
        self.init(UIColor { t in
            let v = t.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((v >> 16) & 0xFF) / 255, green: CGFloat((v >> 8) & 0xFF) / 255, blue: CGFloat(v & 0xFF) / 255, alpha: 1)
        })
    }
    init(hex: UInt32) { self.init(light: hex, dark: hex) }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case modern, classic
    var id: String { rawValue }
    var title: String { self == .modern ? "Modern" : "Classic" }
}


/// Colour palettes: each has a light and a dark side. "theme" keeps the Modern / Classic colours.
struct PaletteDef: Identifiable {
    let id: String, title: String
    // (light, dark) pairs
    let bg, card, ink, muted, line, tile, accent, accentDeep, tint, rowNow, onAccent: (UInt32, UInt32)
    var swatch: UInt32 { accent.0 }

    static let all: [PaletteDef] = [
        PaletteDef(id: "ocean", title: "Ocean",
            bg: (0xEDF2F8, 0x0A1430), card: (0xFFFFFF, 0x12224D), ink: (0x0E1726, 0xF5F0E4), muted: (0x5B677A, 0xA9B2CC),
            line: (0xDCE5F0, 0x2B4080), tile: (0xE3ECF6, 0x1C3170), accent: (0x2F9BE8, 0xE4BB68), accentDeep: (0x1B7FCC, 0xF1D9A2),
            tint: (0xDCEBFA, 0x1B2E66), rowNow: (0xDCEBFA, 0x1F3470), onAccent: (0xFFFFFF, 0x0A1430)),
        PaletteDef(id: "emerald", title: "Emerald",
            bg: (0xEAF5EF, 0x07140E), card: (0xFFFFFF, 0x0E3226), ink: (0x0B2A1F, 0xECF8F2), muted: (0x527466, 0xA3C4B6),
            line: (0xD2E5DB, 0x1F5A44), tile: (0xDDEEE5, 0x154633), accent: (0x22B07D, 0x34D399), accentDeep: (0x0A7552, 0x8DEBC6),
            tint: (0xD8F3E6, 0x154633), rowNow: (0xD8F3E6, 0x18503B), onAccent: (0xFFFFFF, 0x06150F)),
        PaletteDef(id: "royal", title: "Royal",
            bg: (0xF2EEFA, 0x130C26), card: (0xFFFFFF, 0x2A1B50), ink: (0x1B1230, 0xF3EEFC), muted: (0x6A5C86, 0xB9ABD3),
            line: (0xE1D8F2, 0x4A3590), tile: (0xE9E1F7, 0x38256A), accent: (0x8A5CE0, 0xB794F6), accentDeep: (0x6D3FC4, 0xD3BBFA),
            tint: (0xE8DEFA, 0x38256A), rowNow: (0xE8DEFA, 0x42307A), onAccent: (0xFFFFFF, 0x150E26)),
        PaletteDef(id: "sunset", title: "Sunset",
            bg: (0xFDF1EA, 0x1E0E07), card: (0xFFFFFF, 0x4B2010), ink: (0x2B1308, 0xFDF1EA), muted: (0x8A6552, 0xD2B3A0),
            line: (0xF3DACB, 0x7A3E1C), tile: (0xF9E5D8, 0x5E2C14), accent: (0xF26B21, 0xFF8A4C), accentDeep: (0xD04E0A, 0xFFC09A),
            tint: (0xFCDDC8, 0x5E2C14), rowNow: (0xFCDDC8, 0x6B3318), onAccent: (0xFFFFFF, 0x1E0C03)),
        PaletteDef(id: "rose", title: "Rose",
            bg: (0xFCEFF2, 0x1F0A11), card: (0xFFFFFF, 0x4D1828), ink: (0x2B0F18, 0xFDEFF3), muted: (0x8A5A68, 0xD3AEBB),
            line: (0xF2D6DD, 0x8A3552), tile: (0xF8E3E8, 0x66243A), accent: (0xEE5C85, 0xFF7A9C), accentDeep: (0xC8325A, 0xFFB5C9),
            tint: (0xFBDDE6, 0x66243A), rowNow: (0xFBDDE6, 0x722A42), onAccent: (0xFFFFFF, 0x1E0810)),
        PaletteDef(id: "graphite", title: "Graphite",
            bg: (0xEFF0F2, 0x111214), card: (0xFFFFFF, 0x24272C), ink: (0x15171A, 0xF2F3F5), muted: (0x5F656E, 0xA9AEB6),
            line: (0xDDE0E4, 0x42474E), tile: (0xE6E8EB, 0x30343A), accent: (0x4A5058, 0xD6DAE0), accentDeep: (0x2B3036, 0xE4E7EB),
            tint: (0xE1E4E8, 0x30343A), rowNow: (0xE1E4E8, 0x383D44), onAccent: (0xFFFFFF, 0x101113))
    ]
    static var current: PaletteDef? {
        let id = UserDefaults.standard.string(forKey: "paletteID") ?? "ocean"
        return all.first { $0.id == id } ?? all[0]
    }
}

extension Color { init(_ p: (UInt32, UInt32)) { self.init(light: p.0, dark: p.1) } }

/// Colors and type follow the theme stored in UserDefaults ("themeID"). Modern follows light and dark mode; Classic is the dark slate and blue look.
enum Theme {
    static var current: AppTheme { AppTheme(rawValue: UserDefaults.standard.string(forKey: "themeID") ?? "modern") ?? .modern }
    static var isClassic: Bool { true }
    static var strokeCards: Bool { isClassic || PaletteDef.current != nil }
    static var design: Font.Design { isClassic ? .default : .rounded }

    private static func pick(modern: Color, classic: Color) -> Color { isClassic ? classic : modern }

    static var bg: Color { if let p = PaletteDef.current { return Color(p.bg) }; return pick(modern: Color(light: 0xEDF1F5, dark: 0x0A101C), classic: Color(hex: 0x0B0F17)) }
    static var card: Color { if let p = PaletteDef.current { return Color(p.card) }; return pick(modern: Color(light: 0xFFFFFF, dark: 0x141C2E), classic: Color(hex: 0x2A3040)) }
    static var ink: Color { if let p = PaletteDef.current { return Color(p.ink) }; return pick(modern: Color(light: 0x0E1726, dark: 0xF1F5FB), classic: Color(hex: 0xEEF2F8)) }
    static var muted: Color { if let p = PaletteDef.current { return Color(p.muted) }; return pick(modern: Color(light: 0x5B677A, dark: 0x9AA7BB), classic: Color(hex: 0x9AA3B5)) }
    static var line: Color { if let p = PaletteDef.current { return Color(p.line) }; return pick(modern: Color(light: 0xE3E8EF, dark: 0x233048), classic: Color(hex: 0x3E4558)) }
    static var tile: Color { if let p = PaletteDef.current { return Color(p.tile) }; return pick(modern: Color(light: 0xF1F4F8, dark: 0x1B2538), classic: Color(hex: 0x3A4156)) }
    /// Main accent: mint in Modern, brass in Classic
    static var mint: Color { if let p = PaletteDef.current { return Color(p.accent) }; return pick(modern: Color(hex: 0x34E0A1), classic: Color(hex: 0x55BBFA)) }
    static var mintDeep: Color { if let p = PaletteDef.current { return Color(p.accentDeep) }; return pick(modern: Color(light: 0x0A7552, dark: 0x4ADFA8), classic: Color(hex: 0x55BBFA)) }
    static var mintTint: Color { if let p = PaletteDef.current { return Color(p.tint) }; return pick(modern: Color(light: 0xDDF8EC, dark: 0x12362B), classic: Color(hex: 0x1F3550)) }
    /// "Facing the Qibla" success color
    static var ok: Color { pick(modern: Color(hex: 0x34E0A1), classic: Color(hex: 0x3DD68C)) }
    static var sun: Color { Color(hex: 0xFFB627) }
    static var night: Color { if let p = PaletteDef.current { return Color(hex: p.bg.1) }; return pick(modern: Color(hex: 0x0E1726), classic: Color(hex: 0x0B0F17)) }
    static var hero: Color { if let p = PaletteDef.current { return Color(p.card) }; return pick(modern: Color(light: 0x0E1726, dark: 0x1C2740), classic: Color(hex: 0x2A3040)) }
    static var tick: Color { if let p = PaletteDef.current { return Color(p.line) }; return pick(modern: Color(light: 0xC4CDD9, dark: 0x3A4963), classic: Color(hex: 0x6B7488)) }
    static var rowNow: Color { if let p = PaletteDef.current { return Color(p.rowNow) }; return pick(modern: Color(light: 0xE4F9F0, dark: 0x112F27), classic: Color(hex: 0x34405A)) }
    static var onAccent: Color { if let p = PaletteDef.current { return Color(p.onAccent) }; return pick(modern: Color(hex: 0x0E1726), classic: Color(hex: 0x0B0F17)) }
    /// Turn-box and sun colors
    static var zoneRed: Color { Color(hex: 0xFF5A5F) }
    static var zoneYellow: Color { Color(hex: 0xFFC93C) }
    static var zoneGreen: Color { Color(hex: 0x3DD68C) }
    static var sunOrange: Color { Color(hex: 0xFF9F1C) }
}

struct CardStyle: ViewModifier {
    var radius: CGFloat = 24
    func body(content: Content) -> some View {
        content
            .background(Theme.card, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Theme.strokeCards ? Theme.line : .clear, lineWidth: 1)
            )
            .shadow(color: .black.opacity(Theme.isClassic ? 0.3 : 0.06), radius: 12, y: 6)
    }
}
extension View { func card(_ r: CGFloat = 24) -> some View { modifier(CardStyle(radius: r)) } }


/// Same title row on every page: English left, Arabic right in the accent colour.
struct PageTitle: View {
    let en: String
    let ar: String
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            if Loc.ar {
                Spacer()
                Text(ar).font(.sys(size: 26, weight: .bold)).foregroundStyle(Theme.ink).lineLimit(1).minimumScaleFactor(0.7)
            } else {
                Text(L(en)).font(.sys(size: 26, weight: .heavy, design: Theme.design)).foregroundStyle(Theme.ink)
                    .lineLimit(1).minimumScaleFactor(0.6)
                Spacer()
            }
        }
        .environment(\.layoutDirection, .leftToRight)   // Arabic sits on the right
        .padding(.top, 8).padding(.bottom, 6)
    }
}


/// Text size chosen in Settings (Auto follows the iPhone's text size).
extension Theme {
    static var textScale: Double {
        let v = UserDefaults.standard.string(forKey: "textSize") ?? "1"
        if v == "auto" {
            switch UIApplication.shared.preferredContentSizeCategory {
            case .extraSmall, .small, .medium: return 1
            case .large: return 1
            case .extraLarge: return 1.1
            case .extraExtraLarge: return 1.2
            case .extraExtraExtraLarge: return 1.3
            case .accessibilityMedium: return 1.4
            case .accessibilityLarge, .accessibilityExtraLarge: return 1.5
            default: return 1.6
            }
        }
        return Double(v) ?? 1
    }
    static var boldText: Bool { UserDefaults.standard.bool(forKey: "boldText") }
    static var azkarScale: Double { Double(UserDefaults.standard.string(forKey: "azkarSize") ?? "1") ?? 1 }
}

extension Font {
    /// App text: scales with the Text size setting and honours Bold text.
    static func sys(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
        var w = weight
        if Theme.boldText && (w == .regular || w == .light || w == .medium) { w = .semibold }
        if let f = AppFont.current {
            let heavy = w == .semibold || w == .bold || w == .heavy || w == .black
            return f.font(size: size * Theme.textScale, bold: heavy)
        }
        return .system(size: size * Theme.textScale, weight: w, design: design)
    }
}
