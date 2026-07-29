import AppKit
import Foundation

// App Store 用スクリーンショット合成。
// 素の端末キャプチャの上下に、背景とキャッチコピーを乗せた 1290x2796 を書き出す。

let canvasW: CGFloat = 1290
let canvasH: CGFloat = 2796

let bgTop    = NSColor(red: 0.99, green: 0.96, blue: 0.85, alpha: 1)
let bgBottom = NSColor(red: 0.97, green: 0.88, blue: 0.70, alpha: 1)
let textCol  = NSColor(red: 0.22, green: 0.15, blue: 0.08, alpha: 1)
let accent   = NSColor(red: 0.86, green: 0.45, blue: 0.20, alpha: 1)

struct Spec {
    let source: String     // 素材ファイル
    let out: String        // 出力ファイル
    let line1: String
    let line2: String
    let accentWord: String // line1 のうち強調する語（空なら無し）
    let widthRatio: CGFloat
    let topOffset: CGFloat
    let rounded: Bool
}

func roundedPath(_ rect: NSRect, _ radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func draw(_ spec: Spec, rawDir: String, outDir: String) {
    guard let src = NSImage(contentsOfFile: "\(rawDir)/\(spec.source)") else {
        print("MISSING \(spec.source)"); return
    }

    // NSImage.lockFocus は Retina だと 2x で確保されてしまうため、
    // ピクセル数を指定した bitmap rep に直接描く。
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(canvasW), pixelsHigh: Int(canvasH),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0
    ) else { return }
    rep.size = NSSize(width: canvasW, height: canvasH)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    guard let ctx = NSGraphicsContext.current?.cgContext else { return }

    // 背景グラデーション
    let gradient = NSGradient(starting: bgTop, ending: bgBottom)!
    gradient.draw(in: NSRect(x: 0, y: 0, width: canvasW, height: canvasH), angle: -90)

    // キャッチコピー（AppKit は原点が左下なので上から数えて配置する）
    let para = NSMutableParagraphStyle()
    para.alignment = .center
    para.lineSpacing = 14

    func drawLine(_ text: String, fontSize: CGFloat, topY: CGFloat, color: NSColor) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: fontSize, weight: .bold),
            .foregroundColor: color,
            .paragraphStyle: para,
        ]
        let s = NSAttributedString(string: text, attributes: attrs)
        let h = s.size().height
        s.draw(in: NSRect(x: 60, y: canvasH - topY - h, width: canvasW - 120, height: h + 20))
    }

    if spec.accentWord.isEmpty {
        drawLine(spec.line1, fontSize: 84, topY: 150, color: textCol)
    } else {
        drawLine(spec.line1, fontSize: 84, topY: 150, color: accent)
    }
    if !spec.line2.isEmpty {
        drawLine(spec.line2, fontSize: 84, topY: 150 + 108, color: textCol)
    }

    // 端末キャプチャ
    let targetW = canvasW * spec.widthRatio
    let scale = targetW / src.size.width
    let targetH = src.size.height * scale
    let x = (canvasW - targetW) / 2
    let y = canvasH - spec.topOffset - targetH
    let rect = NSRect(x: x, y: y, width: targetW, height: targetH)

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -18), blur: 46,
                  color: NSColor(red: 0.45, green: 0.32, blue: 0.15, alpha: 0.35).cgColor)
    let radius: CGFloat = spec.rounded ? 62 : 28
    let path = roundedPath(rect, radius)
    NSColor.white.setFill()
    path.fill()
    ctx.restoreGState()

    ctx.saveGState()
    path.addClip()
    src.draw(in: rect)
    ctx.restoreGState()

    NSGraphicsContext.restoreGraphicsState()

    guard let png = rep.representation(using: .png, properties: [:]) else { return }
    try? png.write(to: URL(fileURLWithPath: "\(outDir)/\(spec.out)"))
    print("WROTE \(spec.out)")
}

let rawDir = CommandLine.arguments[1]
let outDir = CommandLine.arguments[2]
let lang = CommandLine.arguments.count > 3 ? CommandLine.arguments[3] : "ja"

let jaSpecs: [Spec] = [
    Spec(source: "schedule.png", out: "01_schedule.png",
         line1: "自分の24時間を、", line2: "円グラフで設計する",
         accentWord: "", widthRatio: 0.80, topOffset: 430, rounded: true),
    Spec(source: "list.png", out: "02_persons.png",
         line1: "偉人たちは一日を", line2: "どう使っていたのか",
         accentWord: "", widthRatio: 0.80, topOffset: 430, rounded: true),
    Spec(source: "detail.png", out: "03_detail.png",
         line1: "何にどれだけ使ったかが", line2: "ひと目でわかる",
         accentWord: "", widthRatio: 0.80, topOffset: 430, rounded: true),
    Spec(source: "sharecard.png", out: "04_share.png",
         line1: "作った一日は", line2: "1枚の画像でシェア",
         accentWord: "", widthRatio: 0.92, topOffset: 700, rounded: false),
    Spec(source: "paywall.png", out: "05_pro.png",
         line1: "買い切り。", line2: "サブスクではありません",
         accentWord: "", widthRatio: 0.80, topOffset: 430, rounded: true),
]

let enSpecs: [Spec] = [
    Spec(source: "schedule.png", out: "01_schedule.png",
         line1: "Design your 24 hours", line2: "as one clear chart",
         accentWord: "", widthRatio: 0.80, topOffset: 430, rounded: true),
    Spec(source: "list.png", out: "02_persons.png",
         line1: "How the greats", line2: "spent their day",
         accentWord: "", widthRatio: 0.80, topOffset: 430, rounded: true),
    Spec(source: "detail.png", out: "03_detail.png",
         line1: "See where every hour", line2: "actually goes",
         accentWord: "", widthRatio: 0.80, topOffset: 430, rounded: true),
    Spec(source: "sharecard.png", out: "04_share.png",
         line1: "Share your day", line2: "as a single image",
         accentWord: "", widthRatio: 0.92, topOffset: 700, rounded: false),
    Spec(source: "paywall.png", out: "05_pro.png",
         line1: "One-time purchase.", line2: "Never a subscription.",
         accentWord: "", widthRatio: 0.80, topOffset: 430, rounded: true),
]

for spec in (lang == "en" ? enSpecs : jaSpecs) {
    draw(spec, rawDir: rawDir, outDir: outDir)
}
