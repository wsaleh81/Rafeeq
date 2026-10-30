import SwiftUI
import UIKit

/// SVG-style polygon: points are in a 300×300 design space and scale to the frame.
struct Poly: Shape {
    let pts: [CGPoint]
    var close = true
    init(_ p: [(CGFloat, CGFloat)], close: Bool = true) {
        pts = p.map { CGPoint(x: $0.0, y: $0.1) }
        self.close = close
    }
    func path(in r: CGRect) -> Path {
        let k = r.width / 300
        var p = Path()
        guard let f = pts.first else { return p }
        p.move(to: CGPoint(x: r.minX + f.x * k, y: r.minY + f.y * k))
        for q in pts.dropFirst() { p.addLine(to: CGPoint(x: r.minX + q.x * k, y: r.minY + q.y * k)) }
        if close { p.closeSubpath() }
        return p
    }
}

/// Classic theme compass: a slightly tilted slate disc with thickness, degree scale,
/// the sun's path for today, and a 3D arrow that points to a Kaaba model.
struct ClassicDial: View {
    var heading: Double
    var qibla: Double
    var sun: SunInfo?
    /// when set, the Kaaba model in the centre is replaced by a turn arrow (SF Symbol name, colour)
    var turn: (icon: String, color: Color)? = nil
    /// true: colours follow the app theme. false: the original grey and blue look (kept, not offered in Settings;
    /// set `compassStyle` to "classicGrey" to bring it back).
    var themed = true
    /// true when the phone faces the Qibla: the arrow glows
    var aligned = false

    /// Hidden for now. Flip to bring them back: the Kaaba model in the centre, or a plain arrow pointing at the Qibla.
    static let showCube = false
    static let showCenterArrow = true

    private struct Look {
        let faceTop, faceBottom, thickTop, thickBottom, inner, ink, muted, cardinal, degree, accent, accentLight, accentDark: Color
    }
    private var look: Look {
        if !themed {
            return Look(faceTop: Color(hex: 0x5A6480), faceBottom: Color(hex: 0x394058), thickTop: Color(hex: 0x2A3040), thickBottom: Color(hex: 0x12151D),
                        inner: Color(hex: 0x20242F), ink: Color(hex: 0xEEF2F8), muted: Color(hex: 0x8E98AE), cardinal: Color(hex: 0x7AD0FF), degree: Color(hex: 0xD0D6E3),
                        accent: Color(hex: 0x55BBFA), accentLight: Color(hex: 0xC9EBFF), accentDark: Color(hex: 0x1F78BF))
        }
        let a = Theme.mint
        return Look(faceTop: Theme.tile.mix(.white, 0.14), faceBottom: Theme.card, thickTop: Theme.line, thickBottom: Theme.line.mix(.black, 0.55),
                    inner: Theme.night, ink: Theme.ink, muted: Theme.muted, cardinal: a, degree: Theme.muted,
                    accent: a, accentLight: a.mix(.white, 0.6), accentDark: a.mix(.black, 0.5))
    }

    private func fixd(_ a: Double) -> Double { a - 360 * floor(a / 360) }

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let k = s / 300
            ZStack {
                dial(s: s, k: k)
                    .rotation3DEffect(.degrees(24), axis: (x: 1, y: 0, z: 0), anchor: .center, anchorZ: 0, perspective: 0.4)
            }
            .frame(width: s, height: s)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement()
        .accessibilityLabel("Compass")
        .accessibilityValue("Qibla is \(Int(QiblaMath.diff(qibla, heading).magnitude)) degrees away")
    }

    private func dial(s: CGFloat, k: CGFloat) -> some View {
        ZStack {
            Ellipse()
                .fill(RadialGradient(colors: [.black.opacity(0.6), .clear], center: .center, startRadius: s * 0.3, endRadius: s * 0.63))
                .frame(width: s * 1.27, height: s * 1.13).offset(y: s * 0.13)
            Circle().fill(LinearGradient(colors: [look.thickTop, look.thickBottom], startPoint: .top, endPoint: .bottom))
                .frame(width: s, height: s).offset(y: 18 * k)
            Circle().fill(LinearGradient(colors: [look.faceTop, look.faceBottom],
                                         startPoint: UnitPoint(x: 0.25, y: 0), endPoint: UnitPoint(x: 0.75, y: 1)))
                .frame(width: s, height: s)
            Circle().stroke(Color.white.opacity(0.2), lineWidth: 1.5).frame(width: s * 0.993, height: s * 0.993)
            Circle().stroke(Color(hex: 0x1B1F2B).opacity(0.55), lineWidth: 2).frame(width: s * 0.94, height: s * 0.94)

            // rotating card
            ZStack {
                ScaleRing(k: k, ink: look.ink, muted: look.muted, cardinal: look.cardinal, degree: look.degree)
                Circle().fill(look.inner).frame(width: 116 * k, height: 116 * k)
                Circle().stroke(Color(hex: 0x0E1118).opacity(0.8), lineWidth: 3).frame(width: 116 * k, height: 116 * k)
                if let sun { sunLayer(sun, k: k) }
                qiblaMark(k: k)
            }
            .frame(width: s, height: s)
            .rotationEffect(.degrees(-heading))

            core(k: k)

            // fixed pointer at the top
            ZStack {
                Poly([(139, -10), (161, -10), (150, 8)]).fill(aligned ? Theme.ok : Theme.mint)
                Poly([(139, -10), (161, -10), (150, 8)]).stroke(aligned ? Theme.ok : Theme.mint, style: StrokeStyle(lineWidth: 3 * k, lineJoin: .round))
            }
            .frame(width: s, height: s)
        }
        .frame(width: s, height: s)
    }

    // MARK: sun

    private func sunLayer(_ sun: SunInfo, k: CGFloat) -> some View {
        let span = sun.northern ? fixd(sun.setAz - sun.riseAz) : fixd(sun.riseAz - sun.setAz)
        let start = sun.northern ? sun.riseAz : sun.setAz
        let r = 70 * k
        return ZStack {
            Circle().trim(from: 0, to: span / 360)
                .stroke(Theme.sunOrange, style: StrokeStyle(lineWidth: 3 * k, lineCap: .round, dash: [0.1, 7 * k]))
                .frame(width: 2 * r, height: 2 * r)
                .rotationEffect(.degrees(start - 90))
            ForEach([sun.riseAz, sun.setAz], id: \.self) { az in
                Circle().fill(Theme.sunOrange).frame(width: 8 * k, height: 8 * k)
                    .offset(x: r * sin(az * .pi / 180), y: -r * cos(az * .pi / 180))
            }
            ZStack {
                Circle().fill(RadialGradient(colors: [Theme.sunOrange.opacity(0.7), Theme.sunOrange.opacity(0)],
                                             center: .center, startRadius: 0, endRadius: 28 * k))
                    .frame(width: 56 * k, height: 56 * k)
                Circle().fill(Color(hex: 0x8A4F00)).frame(width: 20 * k, height: 20 * k).offset(y: 4 * k)
                Circle().fill(Theme.sunOrange).frame(width: 20 * k, height: 20 * k)
                Circle().stroke(Color(hex: 0xFFD08A), lineWidth: 2 * k).frame(width: 20 * k, height: 20 * k)
            }
            .offset(x: r * sin(sun.az * .pi / 180), y: -r * cos(sun.az * .pi / 180))
            .opacity(sun.up ? 1 : 0.4)
        }
    }

    // MARK: Qibla ray, marker, core

    private func qiblaMark(k: CGFloat) -> some View {
        let blue = look.accent
        return ZStack {
            // ray
            Capsule().fill(LinearGradient(colors: [blue.opacity(0.0), blue], startPoint: .bottom, endPoint: .top))
                .frame(width: 5 * k, height: 60 * k).offset(y: -80 * k)
            // marker on the ring
            Circle().fill(look.inner).frame(width: 30 * k, height: 30 * k).offset(y: (-126 + 4) * k)
            Circle().fill(RadialGradient(colors: [look.accentLight, blue, look.accentDark],
                                         center: UnitPoint(x: 0.4, y: 0.3), startRadius: 0, endRadius: 22 * k))
                .frame(width: 30 * k, height: 30 * k).offset(y: -126 * k)
            Circle().stroke(Color.white.opacity(0.8), lineWidth: 1.5 * k).frame(width: 30 * k, height: 30 * k).offset(y: -126 * k)
            ZStack {
                RoundedRectangle(cornerRadius: 2 * k).fill(Color(hex: 0x10151F)).frame(width: 14 * k, height: 14 * k)
                Rectangle().fill(Color(hex: 0xFFB627)).frame(width: 14 * k, height: 2 * k).offset(y: -2 * k)
            }
            .rotationEffect(.degrees(heading - qibla))
            .offset(y: -126 * k)
        }
        .frame(width: 300 * k, height: 300 * k)
        .rotationEffect(.degrees(qibla))
    }

    private func core(k: CGFloat) -> some View {
        ZStack {
            Circle().fill(look.accentDark).frame(width: 74 * k, height: 74 * k).offset(y: 8 * k)
            Circle().fill(RadialGradient(colors: [look.accentLight, look.accent, look.accentDark],
                                         center: UnitPoint(x: 0.4, y: 0.28), startRadius: 0, endRadius: 80 * k))
                .frame(width: 74 * k, height: 74 * k)
            Circle().stroke(Color.white.opacity(0.7), lineWidth: 1.5 * k).frame(width: 74 * k, height: 74 * k)
            Ellipse().fill(Color.white.opacity(0.35)).frame(width: 42 * k, height: 18 * k).offset(y: -24 * k)
            if let turn {
                Circle().fill(turn.color).frame(width: 56 * k, height: 56 * k)
                    .overlay(Image(systemName: turn.icon).font(.system(size: 28 * k, weight: .bold)).foregroundStyle(Color.black.opacity(0.78)))
            } else if Self.showCenterArrow {
                // Islamic-style arrow in the centre, pointing at the Qibla; it glows when the phone faces it
                IslamicArrow(aligned: aligned, dark: look.inner, light: look.accentLight)
                    .frame(width: 26 * k, height: 80 * k)
                    .rotationEffect(.degrees(qibla - heading))
            } else if Self.showCube {
                cube().frame(width: 300 * k, height: 300 * k).offset(y: 0)
            }
        }
    }

    private func cube() -> some View {
        // isometric cube centred in 300x300 space (centre 150,150)
        ZStack {
            Poly([(128, 143), (150, 152), (150, 176), (128, 167)]).fill(Color(hex: 0xBFE7FF))
            Poly([(172, 143), (150, 152), (150, 176), (172, 167)]).fill(Color(hex: 0x8FD2FA))
            Poly([(150, 134), (172, 143), (150, 152), (128, 143)]).fill(Color(hex: 0xE4F6FF))
            Poly([(128, 148), (150, 157), (172, 148)], close: false)
                .stroke(Color(hex: 0xFFB627), style: StrokeStyle(lineWidth: 2.4, lineJoin: .round))
        }
        .offset(y: -17)
    }
}

/// Tick marks and the degree scale; drawn once, rotated by its parent.
struct ScaleRing: View {
    let k: CGFloat
    var ink = Color(hex: 0xEEF2F8)
    var muted = Color(hex: 0x8E98AE)
    var cardinal = Color(hex: 0x7AD0FF)
    var degree = Color(hex: 0xD0D6E3)
    var body: some View {
        Canvas { ctx, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            for i in 0..<72 {
                let major = i % 6 == 0
                let r0 = (major ? 108 : 115) * k
                let r1 = (major ? 131 : 128) * k
                let a = Double(i) * 5 * .pi / 180
                var p = Path()
                p.move(to: CGPoint(x: c.x + r0 * CGFloat(sin(a)), y: c.y - r0 * CGFloat(cos(a))))
                p.addLine(to: CGPoint(x: c.x + r1 * CGFloat(sin(a)), y: c.y - r1 * CGFloat(cos(a))))
                ctx.stroke(p, with: .color(major ? ink : muted),
                           style: StrokeStyle(lineWidth: (major ? 3.2 : 1.6) * k, lineCap: .butt))
            }
            for deg in stride(from: 0, to: 360, by: 30) {
                let isCard = deg % 90 == 0
                let text = deg == 0 ? "N" : deg == 90 ? "E" : deg == 180 ? "S" : deg == 270 ? "W" : "\(deg)°"
                var t = ctx
                t.translateBy(x: c.x, y: c.y)
                t.rotate(by: .degrees(Double(deg)))
                let label = Text(text)
                    .font(.system(size: (isCard ? 25 : 14) * k, weight: isCard ? .heavy : .bold))
                    .foregroundColor(isCard ? cardinal : degree)
                t.draw(label, at: CGPoint(x: 0, y: -(isCard ? 92 : 88) * k))
            }
        }
        .frame(width: 300 * k, height: 300 * k)
    }
}


extension Color {
    /// Blend towards `other` by `t` (0 = this colour, 1 = other).
    func mix(_ other: Color, _ t: Double) -> Color {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        UIColor(self).getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        UIColor(other).getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let u = CGFloat(t)
        return Color(red: Double(r1 + (r2 - r1) * u), green: Double(g1 + (g2 - g1) * u), blue: Double(b1 + (b2 - b1) * u))
    }
}


// MARK: Islamic arrow

/// Barbed arrow head with an inner notch, drawn in a 100 × 100 box (tip at the top).
private struct ArrowHeadShape: Shape {
    func path(in r: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + r.width * x / 100, y: r.minY + r.height * y / 100) }
        var path = Path()
        path.move(to: p(50, 0))
        path.addLine(to: p(78, 46))
        path.addLine(to: p(50, 36))
        path.addLine(to: p(22, 46))
        path.closeSubpath()
        return path
    }
}

/// Feathered tail with a split end.
private struct ArrowTailShape: Shape {
    func path(in r: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + r.width * x / 100, y: r.minY + r.height * y / 100) }
        var path = Path()
        path.move(to: p(50, 100))
        path.addLine(to: p(76, 62))
        path.addLine(to: p(50, 70))
        path.addLine(to: p(24, 62))
        path.closeSubpath()
        return path
    }
}

/// Eight-pointed star (two squares, one turned 45°) used at the hub.
private struct Star8: Shape {
    func path(in r: CGRect) -> Path {
        var path = Path()
        let c = CGPoint(x: r.midX, y: r.midY), a = r.width / 2
        for i in 0..<16 {
            let rad = i % 2 == 0 ? a : a * 0.62
            let ang = Double(i) * .pi / 8 - .pi / 2
            let pt = CGPoint(x: c.x + rad * CGFloat(cos(ang)), y: c.y + rad * CGFloat(sin(ang)))
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        return path
    }
}

struct IslamicArrow: View {
    let aligned: Bool
    let dark: Color
    let light: Color

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: !aligned)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            let pulse = aligned ? 0.5 + 0.5 * sin(t * 4) : 0
            let glow = Theme.ok
            GeometryReader { g in
                let w = g.size.width, h = g.size.height
                ZStack {
                    // tail
                    ArrowTailShape().fill(dark.opacity(0.55))
                        .frame(width: w, height: h * 0.5).offset(y: h * 0.25)
                    // shaft
                    Capsule().fill(aligned ? glow : dark).frame(width: w * 0.12, height: h * 0.7)
                    // head
                    ArrowHeadShape().fill(LinearGradient(colors: [aligned ? glow.mix(.white, 0.35) : dark, aligned ? glow : dark],
                                                         startPoint: .top, endPoint: .bottom))
                        .overlay(ArrowHeadShape().stroke(aligned ? Color.white.opacity(0.9) : light.opacity(0.7), lineWidth: 1))
                        .frame(width: w, height: h * 0.5).offset(y: -h * 0.25)
                    // hub star
                    Star8().fill(aligned ? glow.mix(.white, 0.5) : light)
                        .overlay(Star8().stroke(dark, lineWidth: 1))
                        .frame(width: w * 0.62, height: w * 0.62)
                }
                .frame(width: w, height: h)
                .shadow(color: glow.opacity(aligned ? 0.9 : 0), radius: 8 + 8 * pulse)
                .shadow(color: glow.opacity(aligned ? 0.7 : 0), radius: 18 + 10 * pulse)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: aligned)
    }
}
