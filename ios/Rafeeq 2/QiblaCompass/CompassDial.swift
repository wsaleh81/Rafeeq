import SwiftUI

struct CompassDial: View {
    var heading: Double      // current device heading (deg)
    var qibla: Double        // bearing to Kaaba (deg)
    var aligned: Bool
    var sun: SunInfo? = nil
    var turn: (icon: String, color: Color)? = nil

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                Circle().fill(Theme.card)
                    .shadow(color: .black.opacity(0.14), radius: 24, y: 16)
                Circle().stroke(Theme.bg, lineWidth: 2).frame(width: s * 0.79, height: s * 0.79)

                // rotating card
                ZStack {
                    TickRing(count: 72, length: s * 0.025, color: Theme.tick, width: 1.4, radius: s * 0.5 - s * 0.045)
                    TickRing(count: 12, length: s * 0.05, color: Theme.ink, width: 2.4, radius: s * 0.5 - s * 0.045)
                    Cardinal(text: "N", color: Theme.mintDeep, s: s, angle: 0)
                    Cardinal(text: "E", color: Theme.muted, s: s, angle: 90)
                    Cardinal(text: "S", color: Theme.muted, s: s, angle: 180)
                    Cardinal(text: "W", color: Theme.muted, s: s, angle: 270)
                    if let sun {
                        let r = s * 0.29
                        let span = sun.northern ? (sun.setAz - sun.riseAz + 360).truncatingRemainder(dividingBy: 360) : (sun.riseAz - sun.setAz + 360).truncatingRemainder(dividingBy: 360)
                        let start = sun.northern ? sun.riseAz : sun.setAz
                        Circle().trim(from: 0, to: span / 360)
                            .stroke(Theme.sunOrange, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [0.1, 6]))
                            .frame(width: 2 * r, height: 2 * r)
                            .rotationEffect(.degrees(start - 90))
                        Circle().fill(Theme.sunOrange).frame(width: s * 0.05, height: s * 0.05)
                            .offset(x: r * CGFloat(sin(sun.az * .pi / 180)), y: -r * CGFloat(cos(sun.az * .pi / 180)))
                            .opacity(sun.up ? 1 : 0.4)
                    }
                    KaabaMarker(s: s)
                        .rotationEffect(.degrees(qibla))
                }
                .frame(width: s, height: s)
                .rotationEffect(.degrees(-heading))

                // lubber pointer
                Triangle()
                    .fill(aligned ? Theme.ok : Theme.mint)
                    .frame(width: s * 0.067, height: s * 0.06)
                    .offset(y: -s * 0.5 - s * 0.02)
                if let turn {
                    Circle().fill(turn.color).frame(width: s * 0.2, height: s * 0.2)
                        .overlay(Image(systemName: turn.icon).font(.system(size: s * 0.1, weight: .bold)).foregroundStyle(Color.black.opacity(0.78)))
                } else {
                    Circle().fill(Theme.ink).frame(width: s * 0.06, height: s * 0.06)
                    Circle().fill(Theme.mint).frame(width: s * 0.023, height: s * 0.023)
                }
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

struct Triangle: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

struct TickRing: View {
    let count: Int, length: CGFloat, color: Color, width: CGFloat, radius: CGFloat
    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                Capsule().fill(color)
                    .frame(width: width, height: length)
                    .offset(y: -radius + length / 2)
                    .rotationEffect(.degrees(Double(i) * 360 / Double(count)))
            }
        }
    }
}

struct Cardinal: View {
    let text: String, color: Color, s: CGFloat, angle: Double
    var body: some View {
        Text(text)
            .font(.system(size: s * 0.06, weight: .heavy, design: Theme.design))
            .foregroundStyle(color)
            .offset(y: -s * 0.5 + s * 0.12)
            .rotationEffect(.degrees(angle))
    }
}

struct KaabaMarker: View {
    let s: CGFloat
    var body: some View {
        ZStack {
            Capsule().fill(Theme.mint).frame(width: 4, height: s * 0.2)
                .offset(y: -s * 0.1)
            ZStack {
                Circle().fill(Theme.mint)
                RoundedRectangle(cornerRadius: 2).fill(Theme.night)
                    .frame(width: s * 0.053, height: s * 0.06)
                Rectangle().fill(Theme.sun).frame(width: s * 0.053, height: 2.2)
                    .offset(y: -s * 0.02)
                Rectangle().fill(Theme.sun).frame(width: s * 0.013, height: s * 0.03)
                    .offset(y: s * 0.015)
            }
            .frame(width: s * 0.147, height: s * 0.147)
            .offset(y: -s * 0.5 + s * 0.2)
        }
    }
}
