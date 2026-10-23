import SwiftUI
import UIKit

// Mushaf pages in the style of the Madinah Mushaf: the King Fahd Complex Uthmanic Hafs text and font inside a
// Zukhrufa (arabesque) border, with juz and surah tabs, framed surah titles and the page number.
// Every page is fitted to the screen, so it never scrolls.

// MARK: text

enum RichText {
    /// Arabic text with each ﴿n﴾ replaced by a rosette ayah number.
    /// `bold` thickens the strokes (as a percentage of the font size), for fonts without a bold face.
    static func make(_ text: String, font: UIFont, markSize: CGFloat, color: UIColor, align: NSTextAlignment,
                     lineSpacing: CGFloat, markColor: UIColor, bold: CGFloat = 0) -> NSAttributedString {
        let p = NSMutableParagraphStyle()
        p.alignment = align; p.baseWritingDirection = .rightToLeft; p.lineSpacing = lineSpacing
        var attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .paragraphStyle: p]
        if bold > 0 { attrs[.strokeWidth] = -bold; attrs[.strokeColor] = color }
        let out = NSMutableAttributedString(string: text, attributes: attrs)
        let re = try! NSRegularExpression(pattern: "\u{FD3F}([0-9\u{0660}-\u{0669}]+)\u{FD3E}")
        for m in re.matches(in: text, range: NSRange(text.startIndex..., in: text)).reversed() {
            let num = (text as NSString).substring(with: m.range(at: 1))
            let img = ayahMark(num, size: markSize, color: markColor)
            let att = NSTextAttachment()
            att.image = img
            att.bounds = CGRect(x: 0, y: (font.ascender + font.descender - img.size.height) / 2, width: img.size.width, height: img.size.height)
            let piece = NSMutableAttributedString(attachment: att)
            piece.addAttributes([.font: font, .paragraphStyle: p], range: NSRange(location: 0, length: piece.length))
            out.replaceCharacters(in: m.range, with: piece)
        }
        return out
    }

    /// Scalloped rosette with the ayah number, as in the printed Mushaf.
    static func ayahMark(_ num: String, size: CGFloat, color: UIColor) -> UIImage {
        let numFont = UIFont.systemFont(ofSize: size * 0.46, weight: .bold)
        let label = NSAttributedString(string: num, attributes: [.font: numFont, .foregroundColor: UIColor(Moshaf.navy)])
        let t = label.size()
        let h = ceil(size * 1.05)
        let w = max(h, ceil(t.width + h * 0.55))
        return UIGraphicsImageRenderer(size: CGSize(width: w, height: h)).image { _ in
            let c = CGPoint(x: w / 2, y: h / 2), r = h / 2 - 1
            let path = UIBezierPath()
            for i in 0...144 {
                let a = Double(i) / 144 * 2 * .pi
                let rr = r * (0.93 + 0.07 * CGFloat(cos(12 * a)))
                let pt = CGPoint(x: c.x + CGFloat(cos(a)) * rr * (w / h), y: c.y + CGFloat(sin(a)) * rr)
                if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
            }
            path.close()
            UIColor(Moshaf.tab).setFill(); path.fill()
            color.setStroke(); path.lineWidth = 1.1; path.stroke()
            let inner = UIBezierPath(ovalIn: CGRect(x: c.x - (r * 0.74) * (w / h), y: c.y - r * 0.74, width: 2 * r * 0.74 * (w / h), height: 2 * r * 0.74))
            color.withAlphaComponent(0.7).setStroke(); inner.lineWidth = 0.6; inner.stroke()
            label.draw(at: CGPoint(x: (w - t.width) / 2, y: (h - t.height) / 2))
        }
    }

    /// Height of laid-out text, measured the same way the text view lays it out.
    static func height(_ s: NSAttributedString, width: CGFloat) -> CGFloat {
        let storage = NSTextStorage(attributedString: s)
        let lm = NSLayoutManager(); storage.addLayoutManager(lm)
        let tc = NSTextContainer(size: CGSize(width: width, height: .greatestFiniteMagnitude)); tc.lineFragmentPadding = 0
        lm.addTextContainer(tc); lm.ensureLayout(for: tc)
        return ceil(lm.usedRect(for: tc).height)
    }
}

/// Draws text with the same TextKit 1 layout that `RichText.height` measures,
/// so the page always shows exactly the lines that were fitted.
private final class TextDrawView: UIView {
    var text = NSAttributedString() { didSet { setNeedsDisplay() } }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false; backgroundColor = .clear; contentMode = .redraw
    }
    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ rect: CGRect) {
        let storage = NSTextStorage(attributedString: text)
        let lm = NSLayoutManager(); storage.addLayoutManager(lm)
        let tc = NSTextContainer(size: CGSize(width: bounds.width, height: .greatestFiniteMagnitude))
        tc.lineFragmentPadding = 0
        lm.addTextContainer(tc)
        let range = lm.glyphRange(for: tc)
        lm.drawBackground(forGlyphRange: range, at: .zero)
        lm.drawGlyphs(forGlyphRange: range, at: .zero)
    }
}

private struct RichTextView: UIViewRepresentable {
    let text: NSAttributedString

    func makeUIView(context: Context) -> TextDrawView {
        let v = TextDrawView()
        v.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return v
    }

    func updateUIView(_ v: TextDrawView, context: Context) {
        v.text = text
        v.accessibilityLabel = text.string
        v.isAccessibilityElement = true
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: TextDrawView, context: Context) -> CGSize? {
        let w = proposal.width ?? UIScreen.main.bounds.width
        return CGSize(width: w, height: RichText.height(text, width: w))
    }
}

/// Arabic set from the right and justified to both edges (used by the Azkar cards).
struct JustifiedText: View {
    let text: String
    let size: CGFloat
    let color: UIColor
    var lineSpacing: CGFloat? = nil
    var markColor: UIColor = UIColor(Moshaf.frame)

    var body: some View {
        let s = size * Theme.textScale
        let font = UIFont.systemFont(ofSize: s, weight: Theme.boldText ? .semibold : .regular)
        RichTextView(text: RichText.make(text, font: font, markSize: s, color: color, align: .justified,
                                         lineSpacing: lineSpacing ?? s * 0.55, markColor: markColor))
    }
}


// MARK: zukhrufa

/// Arabesque (Zukhrufa) drawing: a repeating band tile of a flowing vine with gold split-palmette
/// leaves, tendrils and small flowers; khatam-star corners; and the thin interlaced inner band.
enum Zukhrufa {
    static let B: CGFloat = 24     // band depth
    static let L: CGFloat = 48     // tile length

    private static func path(_ build: (inout Path) -> Void) -> Path { var p = Path(); build(&p); return p }
    private static func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

    private static let vine = path { p in
        p.move(to: pt(0, 12))
        p.addCurve(to: pt(24, 12), control1: pt(12, 2), control2: pt(24, 2))
        p.addCurve(to: pt(48, 12), control1: pt(24, 22), control2: pt(36, 22))
    }
    private static let leaves = [
        path { p in
            p.move(to: pt(12, 6.2))
            p.addCurve(to: pt(14.2, 19.5), control1: pt(16.5, 8.5), control2: pt(17.5, 14))
            p.addCurve(to: pt(12, 15.2), control1: pt(13.6, 16.6), control2: pt(12.8, 15.4))
            p.addCurve(to: pt(9.8, 19.5), control1: pt(11.2, 15.4), control2: pt(10.4, 16.6))
            p.addCurve(to: pt(12, 6.2), control1: pt(6.5, 14), control2: pt(7.5, 8.5))
            p.closeSubpath()
        },
        path { p in
            p.move(to: pt(36, 17.8))
            p.addCurve(to: pt(38.2, 4.5), control1: pt(40.5, 15.5), control2: pt(41.5, 10))
            p.addCurve(to: pt(36, 8.8), control1: pt(37.6, 7.4), control2: pt(36.8, 8.6))
            p.addCurve(to: pt(33.8, 4.5), control1: pt(35.2, 8.6), control2: pt(34.4, 7.4))
            p.addCurve(to: pt(36, 17.8), control1: pt(30.5, 10), control2: pt(31.5, 15.5))
            p.closeSubpath()
        }
    ]
    private static let veins = path { p in
        p.move(to: pt(12, 8)); p.addLine(to: pt(12, 14.5))
        p.move(to: pt(36, 16)); p.addLine(to: pt(36, 9.5))
    }
    private static let tendrils = path { p in
        p.move(to: pt(19.5, 6.4))
        p.addCurve(to: pt(24.6, 8.6), control1: pt(22.5, 4.2), control2: pt(25.8, 6))
        p.addCurve(to: pt(22.2, 8), control1: pt(23.7, 10.4), control2: pt(21.4, 9.6))
        p.move(to: pt(4.5, 6.4))
        p.addCurve(to: pt(-0.6, 8.6), control1: pt(1.5, 4.2), control2: pt(-1.8, 6))
        p.move(to: pt(28.5, 17.6))
        p.addCurve(to: pt(23.4, 15.4), control1: pt(25.5, 19.8), control2: pt(22.2, 18))
        p.addCurve(to: pt(25.8, 16), control1: pt(24.3, 13.6), control2: pt(26.6, 14.4))
        p.move(to: pt(43.5, 17.6))
        p.addCurve(to: pt(48.6, 15.4), control1: pt(46.5, 19.8), control2: pt(49.8, 18))
        p.addCurve(to: pt(46.2, 16), control1: pt(47.7, 13.6), control2: pt(45.4, 14.4))
    }

    static func circle(_ c: CGPoint, _ r: CGFloat) -> Path { Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)) }

    /// Five-petal flower, drawn round whatever the tile's scale.
    static func flower(_ ctx: inout GraphicsContext, _ c: CGPoint, _ r: CGFloat) {
        for i in 0..<5 {
            let a = Double(i) * 72 * .pi / 180 - .pi / 2
            let petal = circle(CGPoint(x: c.x + CGFloat(cos(a)) * r * 0.62, y: c.y + CGFloat(sin(a)) * r * 0.62), r * 0.42)
            ctx.fill(petal, with: .color(.white)); ctx.stroke(petal, with: .color(Moshaf.navy), lineWidth: 0.6)
        }
        let mid = circle(c, r * 0.36)
        ctx.fill(mid, with: .color(Moshaf.gold)); ctx.stroke(mid, with: .color(Moshaf.navy), lineWidth: 0.5)
    }

    /// One band tile; `t` maps tile space (x along the band, y = 0 on the outer edge) to the canvas.
    static func tile(_ ctx: inout GraphicsContext, _ t: CGAffineTransform) {
        ctx.fill(Path(CGRect(x: 0, y: 0, width: L, height: B)).applying(t), with: .color(Moshaf.sky))
        let v = vine.applying(t)
        ctx.stroke(v, with: .color(.white), lineWidth: 3.6)
        ctx.stroke(v, with: .color(Moshaf.navy), lineWidth: 1.3)
        for leaf in leaves {
            let l = leaf.applying(t)
            ctx.fill(l, with: .color(Moshaf.gold))
            ctx.stroke(l, with: .color(Moshaf.navy), style: StrokeStyle(lineWidth: 0.9, lineJoin: .round))
        }
        ctx.stroke(veins.applying(t), with: .color(Moshaf.navy), lineWidth: 0.6)
        ctx.stroke(tendrils.applying(t), with: .color(Moshaf.navy), style: StrokeStyle(lineWidth: 1, lineCap: .round))
        let r = 4.2 * min(abs(t.a) + abs(t.b), abs(t.c) + abs(t.d))
        for x in [0, 24, 48] as [CGFloat] { flower(&ctx, CGPoint(x: x, y: 12).applying(t), r) }
        let edges = path { p in
            p.move(to: pt(0, 0.5)); p.addLine(to: pt(L, 0.5))
            p.move(to: pt(0, B - 0.5)); p.addLine(to: pt(L, B - 0.5))
        }
        let gold = path { p in
            p.move(to: pt(0, 2)); p.addLine(to: pt(L, 2))
            p.move(to: pt(0, B - 2)); p.addLine(to: pt(L, B - 2))
        }
        ctx.stroke(edges.applying(t), with: .color(Moshaf.navy), lineWidth: 1)
        ctx.stroke(gold.applying(t), with: .color(Moshaf.gold), lineWidth: 0.7)
    }

    /// Tiles along one side; `place(offset, stretch)` gives each tile's transform.
    static func side(_ ctx: inout GraphicsContext, length: CGFloat, tileLength: CGFloat, _ place: (CGFloat, CGFloat) -> CGAffineTransform) {
        let n = max(1, Int((length / tileLength).rounded()))
        let sx = length / (CGFloat(n) * tileLength)
        for i in 0..<n { tile(&ctx, place(CGFloat(i) * tileLength * sx, sx)) }
    }

    /// Eight-pointed khatam star on navy, at each corner of the band.
    static func corner(_ ctx: inout GraphicsContext, _ o: CGPoint, _ b: CGFloat) {
        ctx.fill(Path(CGRect(x: o.x, y: o.y, width: b, height: b)), with: .color(Moshaf.navy))
        ctx.stroke(Path(CGRect(x: o.x + 1.6, y: o.y + 1.6, width: b - 3.2, height: b - 3.2)), with: .color(Moshaf.gold), lineWidth: 0.7)
        let c = CGPoint(x: o.x + b / 2, y: o.y + b / 2), r = b * 0.42
        for (side, color) in [(r * 1.44, Moshaf.gold), (r, Moshaf.sky)] {
            for rot in [0.0, .pi / 4] {
                let sq = Path(CGRect(x: -side / 2, y: -side / 2, width: side, height: side))
                    .applying(CGAffineTransform(rotationAngle: rot).concatenating(CGAffineTransform(translationX: c.x, y: c.y)))
                ctx.fill(sq, with: .color(color))
            }
        }
        flower(&ctx, c, 4.4)
    }

    /// Thin interlaced band (two crossing waves) centred on `r`'s edges.
    static func guilloche(_ ctx: inout GraphicsContext, _ r: CGRect, width g: CGFloat = 7) {
        ctx.stroke(Path(r), with: .color(Moshaf.sky2), lineWidth: g)
        ctx.stroke(Path(r.insetBy(dx: -g / 2, dy: -g / 2)), with: .color(Moshaf.navy), lineWidth: 0.8)
        ctx.stroke(Path(r.insetBy(dx: g / 2, dy: g / 2)), with: .color(Moshaf.navy), lineWidth: 0.8)
        let sides = [(CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.maxX, y: r.minY)), (CGPoint(x: r.minX, y: r.maxY), CGPoint(x: r.maxX, y: r.maxY)),
                     (CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.minX, y: r.maxY)), (CGPoint(x: r.maxX, y: r.minY), CGPoint(x: r.maxX, y: r.maxY))]
        for (a, z) in sides {
            let len = hypot(z.x - a.x, z.y - a.y)
            guard len > 9 else { continue }
            let d = CGPoint(x: (z.x - a.x) / len, y: (z.y - a.y) / len), n = CGPoint(x: -d.y, y: d.x)
            let wl = len / (len / 9).rounded()
            for phase in [0.0, Double.pi] {
                var p = Path()
                var t: CGFloat = 0
                while t <= len {
                    let off = 2.1 * CGFloat(sin(Double(t / wl) * 2 * .pi + phase))
                    let q = CGPoint(x: a.x + d.x * t + n.x * off, y: a.y + d.y * t + n.y * off)
                    if t == 0 { p.move(to: q) } else { p.addLine(to: q) }
                    t += 1
                }
                ctx.stroke(p, with: .color(.white), lineWidth: 1.8)
                ctx.stroke(p, with: .color(Moshaf.navy), lineWidth: 0.7)
            }
        }
    }
}

/// The page border: outer rules, the arabesque band with khatam corners, the paper and the inner interlace.
private struct ZukhrufaFrame: View {
    static let k: CGFloat = 0.62                           // border scale (1 = original size)
    static let outer: CGFloat = 4                          // gap between the edge and the band
    static var band: CGFloat { Zukhrufa.B * k }
    static var paperInset: CGFloat { outer + band }
    static let textSide: CGFloat = 30
    static let textTop: CGFloat = 38

    var body: some View {
        Canvas { ctx, size in
            let W = size.width, H = size.height, o = Self.outer, B = Self.band, k = Self.k
            ctx.stroke(Path(CGRect(x: 0.75, y: 0.75, width: W - 1.5, height: H - 1.5)), with: .color(Moshaf.navy), lineWidth: 1.2)
            ctx.stroke(Path(CGRect(x: 2.5, y: 2.5, width: W - 5, height: H - 5)), with: .color(Moshaf.gold), lineWidth: 0.7)
            let inner = CGRect(x: o + B, y: o + B, width: W - 2 * (o + B), height: H - 2 * (o + B))
            ctx.fill(Path(inner), with: .color(Moshaf.paper))
            let L = Zukhrufa.L * k
            Zukhrufa.side(&ctx, length: inner.width, tileLength: L) { t, sx in CGAffineTransform(a: sx * k, b: 0, c: 0, d: k, tx: o + B + t, ty: o) }
            Zukhrufa.side(&ctx, length: inner.width, tileLength: L) { t, sx in CGAffineTransform(a: sx * k, b: 0, c: 0, d: -k, tx: o + B + t, ty: H - o) }
            Zukhrufa.side(&ctx, length: inner.height, tileLength: L) { t, sx in CGAffineTransform(a: 0, b: sx * k, c: k, d: 0, tx: o, ty: o + B + t) }
            Zukhrufa.side(&ctx, length: inner.height, tileLength: L) { t, sx in CGAffineTransform(a: 0, b: sx * k, c: -k, d: 0, tx: W - o, ty: o + B + t) }
            for c in [CGPoint(x: o, y: o), CGPoint(x: W - o - B, y: o), CGPoint(x: o, y: H - o - B), CGPoint(x: W - o - B, y: H - o - B)] {
                Zukhrufa.corner(&ctx, c, B)
            }
            Zukhrufa.guilloche(&ctx, inner.insetBy(dx: 2.5, dy: 2.5), width: 5)
        }
    }
}

/// Lozenge cartouche with pointed ends, used for the tabs, page number and surah titles.
struct Cartouche: Shape {
    func path(in r: CGRect) -> Path {
        let e = min(r.height * 0.55, r.width / 4)
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.midY))
        p.addQuadCurve(to: CGPoint(x: r.minX + e, y: r.minY), control: CGPoint(x: r.minX + e * 0.1, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - e, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.midY), control: CGPoint(x: r.maxX - e * 0.1, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX - e, y: r.maxY), control: CGPoint(x: r.maxX - e * 0.1, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + e, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.midY), control: CGPoint(x: r.minX + e * 0.1, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

private struct InsetCartouche: Shape {
    func path(in r: CGRect) -> Path { Cartouche().path(in: r.insetBy(dx: 3.5, dy: 2.5)) }
}

private struct CartoucheLabel: View {
    var text: String = ""
    var font: UIFont = .systemFont(ofSize: 17)
    /// When set, the label shows this calligraphic header glyph (QBSML) instead of `text`.
    var glyph: String? = nil
    var glyphSize: CGFloat = 20
    var glyphLift: CGFloat = 0.16
    let width: CGFloat
    var height: CGFloat = 26
    /// Thickens the letters (the Madinah font has no bold face) by drawing them twice, slightly offset.
    var bold = false
    var body: some View {
        Group {
            if let glyph {
                let fit = QCFData.fit(glyph, width: width * 0.72, height: height * 0.66)
                let g = Text(glyph).font(Font(QCFData.font(0, size: fit.size))).foregroundStyle(Color.black).lineLimit(1).fixedSize()
                ZStack { g.offset(x: 0.3); g.offset(y: 0.2); g }   // black, slightly heavier
                    .offset(y: fit.dy)
            } else {
                Text(text).font(Font(font)).foregroundStyle(Moshaf.navy).lineLimit(1).minimumScaleFactor(0.5)
            }
        }
            .overlay { if bold && glyph == nil { Text(text).font(Font(font)).foregroundStyle(Moshaf.navy).lineLimit(1).minimumScaleFactor(0.5).offset(x: 0.45) } }
            .overlay { if bold && glyph == nil { Text(text).font(Font(font)).foregroundStyle(Moshaf.navy).lineLimit(1).minimumScaleFactor(0.5).offset(y: 0.3) } }
            .padding(.horizontal, 12)
            .frame(width: width, height: height)
            .background(Cartouche().fill(.white))
            .overlay(Cartouche().stroke(Moshaf.navy, lineWidth: 1.3))
            .background(InsetCartouche().fill(Moshaf.sky2))
            .overlay(InsetCartouche().stroke(Moshaf.gold, lineWidth: 0.8))
    }
}

// MARK: page content

/// The official Madinah line layout: for every page, its lines (1–15) with the words printed on each.
/// Line numbers with no words hold a surah title or the Bismillah.
enum MushafLines {
    /// Stored as [line number, surah of its first word, text].
    struct Line: Decodable {
        let number: Int, sura: Int, text: String
        init(from d: Decoder) throws {
            var c = try d.unkeyedContainer()
            number = try c.decode(Int.self); sura = try c.decode(Int.self); text = try c.decode(String.self)
        }
    }

    static let pages: [[Line]] = {
        struct File: Decodable { let pages: [[Line]] }
        guard let url = Bundle.main.url(forResource: "mushaf-lines", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(File.self, from: data) else { return [] }
        return file.pages
    }()
}

private enum Row {
    case banner(Int)
    case bismillah
    case text(String)
    case empty
}

/// Rows of a page, top to bottom, with each empty line identified as a surah title or Bismillah.
private func rows(_ page: Int) -> [Row] {
    guard MushafLines.pages.indices.contains(page - 1) else { return [] }
    let lines = MushafLines.pages[page - 1]
    let count = page <= 2 ? (lines.map(\.number).max() ?? 8) : 15
    var out = [Row](repeating: .empty, count: count)
    for l in lines where l.number <= count { out[l.number - 1] = .text(l.text) }
    // a run of empty lines introduces the surah that follows it (or the next surah, at the bottom of a page)
    var i = 0
    while i < count {
        guard case .empty = out[i] else { i += 1; continue }
        var j = i
        while j < count, case .empty = out[j] { j += 1 }
        let next = lines.first { $0.number > j }?.sura ?? ((lines.last?.sura ?? 0) + 1)
        let hasBismillah = next != 1 && next != 9
        let titleRow = (hasBismillah && j - i >= 2) ? j - 2 : j - 1
        if next <= 114 {
            out[titleRow] = .banner(next)
            if hasBismillah && titleRow + 1 < j { out[titleRow + 1] = .bismillah }
        }
        i = j
    }
    return out
}

/// One printed line, drawn with CoreText: justified to the full width, or centred.
private final class LineDrawView: UIView {
    var text = "" { didSet { setNeedsDisplay() } }
    var size: CGFloat = 20 { didSet { setNeedsDisplay() } }
    var centred = false { didSet { setNeedsDisplay() } }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false; backgroundColor = .clear; contentMode = .redraw
        isAccessibilityElement = true
    }
    required init?(coder: NSCoder) { fatalError() }

    static func attributed(_ text: String, _ size: CGFloat, spaceKern: CGFloat = 0) -> NSAttributedString {
        let s = NSMutableAttributedString(string: text, attributes: [
            .font: MadinahFont.font(size), .foregroundColor: UIColor(Moshaf.text),
            .strokeWidth: -2.2, .strokeColor: UIColor(Moshaf.text)
        ])
        if spaceKern != 0 {
            var r = (text as NSString).range(of: " ")
            while r.location != NSNotFound {
                s.addAttribute(.kern, value: spaceKern, range: r)
                let next = r.location + 1
                r = (text as NSString).range(of: " ", range: NSRange(location: next, length: (text as NSString).length - next))
            }
        }
        return s
    }

    /// Width of the line at `size` before justification.
    static func width(_ text: String, _ size: CGFloat) -> CGFloat {
        CGFloat(CTLineGetTypographicBounds(CTLineCreateWithAttributedString(attributed(text, size)), nil, nil, nil))
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext(), !text.isEmpty else { return }
        accessibilityLabel = text
        var line = CTLineCreateWithAttributedString(Self.attributed(text, size))
        var asc: CGFloat = 0, desc: CGFloat = 0
        var natural = CGFloat(CTLineGetTypographicBounds(line, &asc, &desc, nil))
        var squeeze: CGFloat = 1
        if natural > bounds.width {
            // a line longer than the page: first narrow its spaces (up to 60%), then compress it slightly
            let spaces = CGFloat(text.filter { $0 == " " }.count)
            let spaceW = CGFloat(CTLineGetTypographicBounds(CTLineCreateWithAttributedString(Self.attributed(" ", size)), nil, nil, nil))
            if spaces > 0 {
                let cut = min(natural - bounds.width, spaces * spaceW * 0.6)
                line = CTLineCreateWithAttributedString(Self.attributed(text, size, spaceKern: -cut / spaces))
                natural = CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
            }
            if natural > bounds.width { squeeze = bounds.width / natural }
        }
        var x: CGFloat = 0
        if centred || natural < bounds.width * 0.6 {
            x = (bounds.width - natural) / 2
        } else if squeeze == 1, let j = CTLineCreateJustifiedLine(line, 1.0, Double(bounds.width)) {
            line = j
        }
        ctx.saveGState()
        ctx.textMatrix = .identity
        ctx.translateBy(x: 0, y: bounds.height); ctx.scaleBy(x: squeeze, y: -1)
        ctx.textPosition = CGPoint(x: x, y: (bounds.height - (asc + desc)) / 2 + desc)
        CTLineDraw(line, ctx)
        ctx.restoreGState()
    }
}

private struct LineView: UIViewRepresentable {
    let text: String
    let size: CGFloat
    var centred = false
    func makeUIView(context: Context) -> LineDrawView { LineDrawView() }
    func updateUIView(_ v: LineDrawView, context: Context) { v.text = text; v.size = size; v.centred = centred }
}

/// Surah title: an arabesque panel with the name in a central cartouche.
private struct SurahBanner: View {
    let sura: Int
    let size: CGFloat

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            Canvas { ctx, _ in
                let k = h / Zukhrufa.B
                Zukhrufa.side(&ctx, length: w, tileLength: Zukhrufa.L * k) { t, sx in
                    CGAffineTransform(a: sx * k, b: 0, c: 0, d: k, tx: t, ty: 0)
                }
                ctx.stroke(Path(CGRect(x: 0.6, y: 0.6, width: w - 1.2, height: h - 1.2)), with: .color(Moshaf.navy), lineWidth: 1.2)
            }
            CartoucheLabel(glyph: QCFData.surahHeader(sura), width: min(w * 0.6, 270), height: h * 0.86)
                .position(x: w / 2, y: h / 2)
        }
    }
}

// MARK: Madinah Mushaf glyph fonts (King Fahd Complex QCF4)

/// Page data for the printed Madinah Mushaf: for each page its font number and its lines.
/// Every word is one glyph of that page's font, so the lines look exactly like the printed page.
enum QCFData {
    struct Line { let number: Int; let kind: Character; let text: String; let ends: Set<Int> }
    struct Page { let font: Int; let lines: [Line] }

    static let pages: [Page] = {
        guard let url = Bundle.main.url(forResource: "mushaf-qcf", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let raw = root["pages"] as? [[Any]] else { return [] }
        return raw.compactMap { p -> Page? in
            guard let f = p.first as? Int, let ls = p.last as? [[Any]] else { return nil }
            let lines = ls.compactMap { l -> Line? in
                guard l.count >= 3, let n = l[0] as? Int, let k = (l[1] as? String)?.first, let t = l[2] as? String else { return nil }
                return Line(number: n, kind: k, text: t, ends: Set((l.count > 3 ? l[3] as? [Int] : nil) ?? []))
            }
            return Page(font: f, lines: lines)
        }
    }()

    private static var registered = Set<String>()
    private static let lock = NSLock()

    /// Font file name for a page, registered the first time it is needed.
    static func fontName(_ n: Int) -> String { n == 0 ? "QCF4_QBSML" : String(format: "QCF4_Hafs_%02d_W", n) }

    /// Calligraphic headers of the printed Mushaf: "سورة <name>" and "الجزء <n>" (QBSML font).
    static func surahHeader(_ sura: Int) -> String { String(UnicodeScalar(0xF100 + max(sura, 1) - 1)!) }
    static func juzHeader(_ juz: Int) -> String { String(UnicodeScalar(0xF1D8 + min(max(juz, 1), 30) - 1)!) }

    /// Font size and vertical shift that make a header glyph fill a box (same look for every surah and juz).
    static func fit(_ glyph: String, width: CGFloat, height: CGFloat) -> (size: CGFloat, dy: CGFloat) {
        let ref: CGFloat = 100
        let f = font(0, size: ref)
        let ch = Array(glyph.utf16), n = ch.count
        var g = [CGGlyph](repeating: 0, count: n)
        CTFontGetGlyphsForCharacters(f, ch, &g, n)
        let r = CTFontGetBoundingRectsForGlyphs(f, .horizontal, g, nil, n)
        guard r.width > 0, r.height > 0 else { return (20, 0) }
        let k = min(width / r.width, height / r.height)
        let c = (CTFontGetAscent(f) - CTFontGetDescent(f)) / 2
        return (ref * k, -(c - r.midY) * k)
    }

    static func font(_ n: Int, size: CGFloat) -> CTFont {
        let name = fontName(n)
        lock.lock()
        if !registered.contains(name) {
            registered.insert(name)
            if let url = Bundle.main.url(forResource: name, withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
        lock.unlock()
        return CTFontCreateWithName(name as CFString, size, nil)
    }
}

/// One printed line made of Mushaf glyphs. Full lines are stretched by a few percent to the exact width, as in print.
private final class QCFLineDrawView: UIView {
    var text = "" { didSet { setNeedsDisplay() } }
    var fontNumber = 1 { didSet { setNeedsDisplay() } }
    var size: CGFloat = 20 { didSet { setNeedsDisplay() } }
    var centred = false { didSet { setNeedsDisplay() } }
    var ends: Set<Int> = [] { didSet { setNeedsDisplay() } }
    static let boldness: CGFloat = 0.03
    static let markScale: CGFloat = 1.3   // verse-end ornament, relative to the text

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false; backgroundColor = .clear; contentMode = .redraw
    }
    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext(), !text.isEmpty else { return }
        let font = QCFData.font(fontNumber, size: size)
        let chars = Array(text.utf16)
        var glyphs = [CGGlyph](repeating: 0, count: chars.count)
        CTFontGetGlyphsForCharacters(font, chars, &glyphs, chars.count)
        var adv = [CGSize](repeating: .zero, count: chars.count)
        CTFontGetAdvancesForGlyphs(font, .horizontal, glyphs, &adv, chars.count)
        let ms = Self.markScale
        for i in ends where adv.indices.contains(i) { adv[i].width *= ms }
        let natural = adv.reduce(0) { $0 + $1.width }
        guard natural > 0 else { return }
        var scale: CGFloat = 1
        if natural > bounds.width { scale = bounds.width / natural }                       // never wider than the page
        else if !centred, natural > bounds.width * 0.88 { scale = bounds.width / natural } // full lines: exact width
        let total = natural * scale
        var x = (bounds.width + total) / 2   // right edge of the line (RTL: the first word is drawn here)
        let asc = CTFontGetAscent(font), desc = CTFontGetDescent(font)
        let baseline = (bounds.height + (asc - desc)) / 2   // from the top
        ctx.saveGState()
        let ink = UIColor(Moshaf.text).cgColor
        ctx.setFillColor(ink); ctx.setStrokeColor(ink)
        ctx.setTextDrawingMode(.fillStroke)
        ctx.setLineWidth(size * QCFLineDrawView.boldness)   // thickens every stroke: raise for bolder text
        ctx.setLineJoin(.round)
        ctx.translateBy(x: 0, y: bounds.height); ctx.scaleBy(x: 1, y: -1)   // CoreText space: y up
        for i in 0..<chars.count {
            let w = adv[i].width * scale
            x -= w
            guard glyphs[i] != 0 else { continue }
            var g = glyphs[i]
            let isMark = ends.contains(i)
            var pos = CGPoint(x: x, y: bounds.height - baseline + (isMark ? -size * 0.04 : 0))
            ctx.saveGState()
            ctx.translateBy(x: pos.x, y: pos.y); ctx.scaleBy(x: scale * (isMark ? ms : 1), y: isMark ? ms : 1)
            if isMark {
                let c = UIColor(Moshaf.frame).cgColor
                ctx.setFillColor(c); ctx.setStrokeColor(c); ctx.setLineWidth(size * 0.012)
            }
            pos = .zero
            CTFontDrawGlyphs(font, &g, &pos, 1, ctx)
            ctx.restoreGState()
        }
        ctx.restoreGState()
    }
}

private struct QCFLineView: UIViewRepresentable {
    let text: String
    let font: Int
    let size: CGFloat
    var centred = false
    var ends: Set<Int> = []
    func makeUIView(context: Context) -> QCFLineDrawView { QCFLineDrawView() }
    func updateUIView(_ v: QCFLineDrawView, context: Context) {
        v.text = text; v.fontNumber = font; v.size = size; v.centred = centred; v.ends = ends
    }
}

private enum QRow {
    case banner(Int)
    case bismillah(String, Int)   // glyphs and the font number they come from
    case text(String, Set<Int>)
    case empty
}

/// Rows of a page as printed, top to bottom (surah title, Bismillah and verse lines).
private func qrows(_ page: Int) -> (font: Int, rows: [QRow]) {
    guard QCFData.pages.indices.contains(page - 1) else { return (1, []) }
    let p = QCFData.pages[page - 1]
    let count = page <= 2 ? (p.lines.map(\.number).max() ?? 8) : 15
    var out = [QRow](repeating: .empty, count: count)
    for l in p.lines where l.number >= 1 && l.number <= count {
        switch l.kind {
        case "h": out[l.number - 1] = .banner(Int(l.text) ?? 1)
        case "b":
            // most pages store a blank here; the printed Bismillah is built from its four words in the header font
            let blank = page > 2
            out[l.number - 1] = blank ? .bismillah("\u{FAD0}\u{FAD1}\u{FAD2}\u{FAD3}", 0) : .bismillah(l.text, p.font)
        default: out[l.number - 1] = .text(l.text, l.ends)
        }
    }
    return (p.font, out)
}

// MARK: page

/// One page of the Mushaf in the official Madinah line layout, fitted to the screen.
struct MushafPageView: View {
    let page: Int
    private let q = Quran.shared

    /// Surahs on this page, for the tabs: the first, and the last if another one starts here.
    private var suraTabs: [Int] {
        let ss = MushafLines.pages.indices.contains(page - 1) ? MushafLines.pages[page - 1].map(\.sura) : []
        guard let f = ss.first, let l = ss.last else { return [] }
        return f == l ? [f] : [f, l]
    }

    var body: some View {
        GeometryReader { g in
            let W = g.size.width, H = g.size.height
            let box = CGSize(width: W - 2 * ZukhrufaFrame.textSide, height: H - 2 * ZukhrufaFrame.textTop)
            let (fontNo, rs) = qrows(page)
            let opening = page <= 2
            let rowH = opening ? min(box.height / CGFloat(max(rs.count, 1)), box.height / 11) : box.height / CGFloat(max(rs.count, 1))
            // one fixed size for every page, as in print: a full line is about 16.3 times the font size
            let size = min(box.width / 16.3, rowH / 1.25)
            let bandY = ZukhrufaFrame.outer + ZukhrufaFrame.band / 2
            let tabs = [QCFData.juzHeader(q.juz(ofPage: page))] + suraTabs.map { QCFData.surahHeader($0) }
            let tabW = min(146, (W - 70) / CGFloat(tabs.count) - 6)
            ZStack(alignment: .topLeading) {
                ZukhrufaFrame()

                VStack(spacing: 0) {
                    ForEach(Array(rs.enumerated()), id: \.offset) { _, r in
                        Group {
                            switch r {
                            case .banner(let sx):
                                SurahBanner(sura: sx, size: size).frame(height: min(rowH * 0.86, size * 2.1))
                            case .bismillah(let t, let f):
                                QCFLineView(text: t, font: f, size: size * 1.12, centred: true)
                            case .text(let t, let e):
                                QCFLineView(text: t, font: fontNo, size: size, centred: opening, ends: e)
                            case .empty:
                                Color.clear
                            }
                        }
                        .frame(width: box.width, height: rowH)
                    }
                }
                .frame(width: box.width, height: box.height)
                .offset(x: ZukhrufaFrame.textSide, y: ZukhrufaFrame.textTop)

                // tabs on the top band: juz on the right, then the surahs
                ForEach(Array(tabs.enumerated()), id: \.offset) { i, t in
                    let slot = W - 34 - tabW / 2 - CGFloat(i) * (W - 68 - tabW) / CGFloat(max(1, tabs.count - 1))
                    CartoucheLabel(glyph: t, width: tabW, height: 36)
                        .position(x: tabs.count == 1 ? W / 2 : slot, y: max(bandY, 19))
                }
                CartoucheLabel(text: Moshaf.arabicDigits(page), font: .systemFont(ofSize: 14, weight: .bold), width: 64, height: 24)
                    .position(x: W / 2, y: H - bandY)
            }
            .environment(\.layoutDirection, .leftToRight)
        }
        .padding(.horizontal, 8).padding(.vertical, 6)
        .accessibilityElement(children: .contain)
    }
}

// MARK: zoom

/// Pinch to zoom (up to 4×), drag to move around, double-tap to zoom in or back out.
/// At normal size the scroll view does not scroll, so swiping still turns the page.
struct ZoomablePage<Content: View>: UIViewRepresentable {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    func makeCoordinator() -> Coordinator { Coordinator(UIHostingController(rootView: content)) }

    func makeUIView(context: Context) -> UIScrollView {
        let sv = UIScrollView()
        sv.minimumZoomScale = 1; sv.maximumZoomScale = 4
        sv.bouncesZoom = true
        sv.showsHorizontalScrollIndicator = false; sv.showsVerticalScrollIndicator = false
        sv.contentInsetAdjustmentBehavior = .never
        sv.delegate = context.coordinator
        let host = context.coordinator.host.view!
        host.backgroundColor = .clear
        host.translatesAutoresizingMaskIntoConstraints = true
        host.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        sv.addSubview(host)
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.doubleTap(_:)))
        tap.numberOfTapsRequired = 2
        sv.addGestureRecognizer(tap)
        return sv
    }

    func updateUIView(_ sv: UIScrollView, context: Context) {
        context.coordinator.host.rootView = content
        if sv.zoomScale == 1 { context.coordinator.host.view.frame = sv.bounds }
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        let host: UIHostingController<Content>
        init(_ host: UIHostingController<Content>) { self.host = host }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? { host.view }

        /// Redraw the text at the zoomed resolution so it stays sharp.
        func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
            let s = min(scale, 3) * (scrollView.window?.screen.scale ?? 3)
            func apply(_ v: UIView) {
                if v is TextDrawView || v is LineDrawView { v.contentScaleFactor = s; v.setNeedsDisplay() }
                v.subviews.forEach(apply)
            }
            apply(host.view)
        }

        @objc func doubleTap(_ g: UITapGestureRecognizer) {
            guard let sv = g.view as? UIScrollView else { return }
            if sv.zoomScale > 1 { sv.setZoomScale(1, animated: true); return }
            let p = g.location(in: host.view), s: CGFloat = 2.2
            let size = CGSize(width: sv.bounds.width / s, height: sv.bounds.height / s)
            sv.zoom(to: CGRect(x: p.x - size.width / 2, y: p.y - size.height / 2, width: size.width, height: size.height), animated: true)
        }
    }
}
