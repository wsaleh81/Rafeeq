import SwiftUI

/// Compass in the style of the welcome screen: soft concentric rings, a dark centre with an arrow that points
/// to the Qibla, and the Kaaba marker on the outer ring. Uses the app palette, so it follows the chosen colour.
struct RingsDial: View {
    var heading: Double      // device heading (deg)
    var qibla: Double        // bearing to the Kaaba (deg)
    var aligned: Bool
    /// colour of the arrow (red / yellow / green by how far off the Qibla the phone points)
    var tint: Color? = nil

    static let showScale = false

    private var toQibla: Double { qibla - heading }

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                Circle().fill(Theme.mintTint).frame(width: s, height: s)
                    .shadow(color: .black.opacity(0.25), radius: 18, y: 10)
                Circle().fill(Theme.mint.opacity(0.28)).frame(width: s * 0.71, height: s * 0.71)
                Circle().fill(Theme.mint.opacity(0.55)).frame(width: s * 0.455, height: s * 0.455)
                Circle().fill(Theme.night).frame(width: s * 0.275, height: s * 0.275)

                // letters and ticks on the outer ring: hidden for now (set showScale to true to bring them back)
                if Self.showScale { ZStack {
                    ForEach(Array(["N", "E", "S", "W"].enumerated()), id: \.offset) { i, t in
                        Text(t).font(.system(size: s * 0.055, weight: .heavy, design: Theme.design))
                            .foregroundStyle(i == 0 ? Theme.mint : Theme.muted)
                            .offset(y: -s * 0.455)
                            .rotationEffect(.degrees(Double(i) * 90))
                    }
                    ForEach(0..<24, id: \.self) { i in
                        Capsule().fill(Theme.muted.opacity(i % 2 == 0 ? 0.5 : 0.25))
                            .frame(width: 1.4, height: s * (i % 6 == 0 ? 0.0 : 0.03))
                            .offset(y: -s * 0.485)
                            .rotationEffect(.degrees(Double(i) * 15))
                    }
                }
                .frame(width: s, height: s)
                .rotationEffect(.degrees(-heading)) }

                // a mihrab (prayer niche) arch in the centre; its top points to the Qibla. Gold, green when facing it.
                MihrabNeedle(color: aligned ? Theme.ok : Theme.mint, line: s * 0.01)
                    .frame(width: s * 0.1, height: s * 0.2133)
                    .rotationEffect(.degrees(toQibla))

                // Kaaba marker on the outer ring
                ZStack {
                    Circle().fill(Theme.mint)
                    RoundedRectangle(cornerRadius: 2).fill(Theme.night).frame(width: s * 0.045, height: s * 0.05)
                    Rectangle().fill(Theme.sun).frame(width: s * 0.045, height: 2).offset(y: -s * 0.015)
                }
                .frame(width: s * 0.13, height: s * 0.13)
                .overlay(Circle().stroke(aligned ? Theme.ok : Color.clear, lineWidth: 3))
                .offset(x: s * 0.385 * CGFloat(sin(toQibla * .pi / 180)), y: -s * 0.385 * CGFloat(cos(toQibla * .pi / 180)))

                // fixed marker: where the top of the phone points
                Triangle().fill(aligned ? Theme.ok : Theme.mint)
                    .frame(width: s * 0.06, height: s * 0.05)
                    .offset(y: -s * 0.5 - s * 0.01)
            }
            .frame(width: s, height: s)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement()
        .accessibilityLabel("Compass")
        .accessibilityValue(aligned ? "Facing the Qibla" : "Qibla is \(Int(QiblaMath.diff(qibla, heading).magnitude)) degrees away")
    }
}

/// Mihrab arch for the Rings dial. Drawn in a box whose centre is the pivot (the arch sits a little above it).
/// Same shape as the Android app: x from -15 to 15, y from -32 to 32 (bottom of the arch at 22).
struct MihrabNeedle: View {
    var color: Color
    var line: CGFloat
    var body: some View {
        ZStack {
            MihrabShape(inner: true).fill(color.opacity(0.4))
            MihrabShape(inner: false).stroke(color, style: StrokeStyle(lineWidth: line, lineJoin: .round))
        }
    }
}

struct MihrabShape: Shape {
    var inner: Bool
    func path(in r: CGRect) -> Path {
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.midX + x / 30 * r.width, y: r.midY + y / 64 * r.height) }
        var p = Path()
        if inner {
            p.move(to: pt(-7.5, 22)); p.addLine(to: pt(-7.5, 0))
            p.addQuadCurve(to: pt(0, -16), control: pt(-7.5, -9))
            p.addQuadCurve(to: pt(7.5, 0), control: pt(7.5, -9))
            p.addLine(to: pt(7.5, 22))
        } else {
            p.move(to: pt(-15, 22)); p.addLine(to: pt(-15, -5))
            p.addQuadCurve(to: pt(0, -32), control: pt(-15, -20))
            p.addQuadCurve(to: pt(15, -5), control: pt(15, -20))
            p.addLine(to: pt(15, 22))
        }
        p.closeSubpath()
        return p
    }
}
