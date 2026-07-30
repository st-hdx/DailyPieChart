import AppKit
import Foundation

// App Store 用スクリーンショット合成。
// 素の端末キャプチャに、背景とキャッチコピーを乗せて書き出す。
//
//   swift tools/make-screenshots.swift <素材ディレクトリ> <出力先> <ja|en> <iphone67|ipad129>
//
// 素材ディレクトリには list.png / detail.png / schedule.png / paywall.png /
// sharecard.png を置いておく。

let rawDir = CommandLine.arguments[1]
let outDir = CommandLine.arguments[2]
let lang = CommandLine.arguments.count > 3 ? CommandLine.arguments[3] : "ja"
let device = CommandLine.arguments.count > 4 ? CommandLine.arguments[4] : "iphone67"

/// App Store Connect が要求する解像度。
let canvasW: CGFloat
let canvasH: CGFloat
switch device {
case "ipad129": canvasW = 2048; canvasH = 2732   // 12.9インチ iPad Pro
default:        canvasW = 1290; canvasH = 2796   // 6.7インチ iPhone
}

/// 寸法は 6.7インチを基準に決めてあるので、他端末では横幅比で拡縮する。
let k = canvasW / 1290

let bgTop    = NSColor(red: 0.99, green: 0.96, blue: 0.85, alpha: 1)
let bgBottom = NSColor(red: 0.97, green: 0.88, blue: 0.70, alpha: 1)
let textCol  = NSColor(red: 0.22, green: 0.15, blue: 0.08, alpha: 1)

struct Spec {
    let source: String
    let out: String
    let line1: String
    let line2: String
    /// 端末画像の幅（キャンバス幅に対する比）
    let widthRatio: CGFloat
    /// 端末画像の上端位置（キャンバス高さに対する比）
    let topRatio: CGFloat
    let rounded: Bool
}

func roundedPath(_ rect: NSRect, _ radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func draw(_ spec: Spec) {
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

    NSGradient(starting: bgTop, ending: bgBottom)!
        .draw(in: NSRect(x: 0, y: 0, width: canvasW, height: canvasH), angle: -90)

    // キャッチコピー（AppKit は原点が左下なので上から数えて配置する）
    let para = NSMutableParagraphStyle()
    para.alignment = .center
    para.lineSpacing = 14 * k

    let fontSize = 84 * k
    let lineGap = 108 * k

    func drawLine(_ text: String, topY: CGFloat) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: fontSize, weight: .bold),
            .foregroundColor: textCol,
            .paragraphStyle: para,
        ]
        let s = NSAttributedString(string: text, attributes: attrs)
        let h = s.size().height
        s.draw(in: NSRect(x: 60 * k, y: canvasH - topY - h,
                          width: canvasW - 120 * k, height: h + 20 * k))
    }

    let firstLineTop = canvasH * 0.0536
    drawLine(spec.line1, topY: firstLineTop)
    if !spec.line2.isEmpty {
        drawLine(spec.line2, topY: firstLineTop + lineGap)
    }

    // 端末キャプチャ
    let targetW = canvasW * spec.widthRatio
    let scale = targetW / src.size.width
    let targetH = src.size.height * scale
    let x = (canvasW - targetW) / 2
    let y = canvasH - canvasH * spec.topRatio - targetH
    let rect = NSRect(x: x, y: y, width: targetW, height: targetH)

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -18 * k), blur: 46 * k,
                  color: NSColor(red: 0.45, green: 0.32, blue: 0.15, alpha: 0.35).cgColor)
    let radius: CGFloat = (spec.rounded ? 62 : 28) * k
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
    print("WROTE \(spec.out) (\(Int(canvasW))x\(Int(canvasH)))")
}

// iPad は画面が横に広いぶん端末画像が大きくなるので、小さめに置く。
let deviceWidthRatio: CGFloat = device == "ipad129" ? 0.70 : 0.80
let deviceTopRatio: CGFloat   = device == "ipad129" ? 0.185 : 0.1538
let cardWidthRatio: CGFloat   = device == "ipad129" ? 0.52 : 0.92
let cardTopRatio: CGFloat     = device == "ipad129" ? 0.235 : 0.2504

let jaSpecs: [Spec] = [
    Spec(source: "schedule.png", out: "01_schedule.png",
         line1: "自分の24時間を、", line2: "円グラフで設計する",
         widthRatio: deviceWidthRatio, topRatio: deviceTopRatio, rounded: true),
    Spec(source: "list.png", out: "02_persons.png",
         line1: "偉人たちは一日を", line2: "どう使っていたのか",
         widthRatio: deviceWidthRatio, topRatio: deviceTopRatio, rounded: true),
    Spec(source: "detail.png", out: "03_detail.png",
         line1: "何にどれだけ使ったかが", line2: "ひと目でわかる",
         widthRatio: deviceWidthRatio, topRatio: deviceTopRatio, rounded: true),
    Spec(source: "sharecard.png", out: "04_share.png",
         line1: "作った一日は", line2: "1枚の画像でシェア",
         widthRatio: cardWidthRatio, topRatio: cardTopRatio, rounded: false),
    Spec(source: "paywall.png", out: "05_pro.png",
         line1: "買い切り。", line2: "サブスクではありません",
         widthRatio: deviceWidthRatio, topRatio: deviceTopRatio, rounded: true),
]

let enSpecs: [Spec] = [
    Spec(source: "schedule.png", out: "01_schedule.png",
         line1: "Design your 24 hours", line2: "as one clear chart",
         widthRatio: deviceWidthRatio, topRatio: deviceTopRatio, rounded: true),
    Spec(source: "list.png", out: "02_persons.png",
         line1: "How the greats", line2: "spent their day",
         widthRatio: deviceWidthRatio, topRatio: deviceTopRatio, rounded: true),
    Spec(source: "detail.png", out: "03_detail.png",
         line1: "See where every hour", line2: "actually goes",
         widthRatio: deviceWidthRatio, topRatio: deviceTopRatio, rounded: true),
    Spec(source: "sharecard.png", out: "04_share.png",
         line1: "Share your day", line2: "as a single image",
         widthRatio: cardWidthRatio, topRatio: cardTopRatio, rounded: false),
    Spec(source: "paywall.png", out: "05_pro.png",
         line1: "One-time purchase.", line2: "Never a subscription.",
         widthRatio: deviceWidthRatio, topRatio: deviceTopRatio, rounded: true),
]

for spec in (lang == "en" ? enSpecs : jaSpecs) { draw(spec) }
