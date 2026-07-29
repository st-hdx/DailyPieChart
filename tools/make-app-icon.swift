import AppKit
import Foundation

// アプリアイコン候補の生成。アプリ本体と同じ「24時間を色で分割したドーナツ」を描く。

let size: CGFloat = 1024

let blockColors: [NSColor] = [
    NSColor(srgbRed: 0.22, green: 0.42, blue: 0.85, alpha: 1),  // 0 Indigo
    NSColor(srgbRed: 0.88, green: 0.38, blue: 0.25, alpha: 1),  // 1 Terracotta
    NSColor(srgbRed: 0.28, green: 0.62, blue: 0.40, alpha: 1),  // 2 Forest
    NSColor(srgbRed: 0.90, green: 0.58, blue: 0.10, alpha: 1),  // 3 Amber
    NSColor(srgbRed: 0.60, green: 0.28, blue: 0.70, alpha: 1),  // 4 Plum
    NSColor(srgbRed: 0.85, green: 0.30, blue: 0.52, alpha: 1),  // 5 Rose
    NSColor(srgbRed: 0.18, green: 0.60, blue: 0.65, alpha: 1),  // 6 Teal
    NSColor(srgbRed: 0.50, green: 0.72, blue: 0.25, alpha: 1),  // 7 Lime
]

// 平日テンプレートと同じ配分。睡眠と仕事の大きな塊があり「一日」に見える。
let blocks: [(hours: Double, colorIndex: Int)] = [
    (7, 0), (1, 6), (1, 4), (8, 1), (1, 3), (1, 4), (1, 5), (3, 2), (1, 7),
]

/// 60px まで縮むと細かい区画は潰れるので、アイコン用に塊を大きくした配分。
let boldBlocks: [(hours: Double, colorIndex: Int)] = [
    (8, 0),   // 睡眠
    (2, 6),   // 朝の支度
    (8, 1),   // 仕事
    (2, 3),   // 食事
    (4, 2),   // 自由時間
]

struct Variant {
    let name: String
    let top: NSColor
    let bottom: NSColor
    let gap: NSColor      // セグメント間の隙間
    let hole: NSColor?    // 中心の穴（nil なら背景を透過）
    var bold: Bool = false
}

let variants = [
    Variant(name: "icon_cream",
            top: NSColor(srgbRed: 0.99, green: 0.96, blue: 0.85, alpha: 1),
            bottom: NSColor(srgbRed: 0.97, green: 0.90, blue: 0.74, alpha: 1),
            gap: NSColor(srgbRed: 0.99, green: 0.96, blue: 0.85, alpha: 1),
            hole: nil),
    Variant(name: "icon_midnight",
            top: NSColor(srgbRed: 0.11, green: 0.12, blue: 0.20, alpha: 1),
            bottom: NSColor(srgbRed: 0.17, green: 0.18, blue: 0.29, alpha: 1),
            gap: NSColor(srgbRed: 0.11, green: 0.12, blue: 0.20, alpha: 1),
            hole: nil),
    Variant(name: "icon_brand",
            top: NSColor(srgbRed: 0.90, green: 0.56, blue: 0.14, alpha: 1),
            bottom: NSColor(srgbRed: 0.82, green: 0.32, blue: 0.44, alpha: 1),
            gap: NSColor(white: 1, alpha: 1),
            hole: NSColor(white: 1, alpha: 1)),
    Variant(name: "icon_midnight_bold",
            top: NSColor(srgbRed: 0.11, green: 0.12, blue: 0.20, alpha: 1),
            bottom: NSColor(srgbRed: 0.17, green: 0.18, blue: 0.29, alpha: 1),
            gap: NSColor(srgbRed: 0.11, green: 0.12, blue: 0.20, alpha: 1),
            hole: nil, bold: true),
    Variant(name: "icon_cream_bold",
            top: NSColor(srgbRed: 0.99, green: 0.96, blue: 0.85, alpha: 1),
            bottom: NSColor(srgbRed: 0.97, green: 0.90, blue: 0.74, alpha: 1),
            gap: NSColor(srgbRed: 0.99, green: 0.96, blue: 0.85, alpha: 1),
            hole: nil, bold: true),
]

func drawIcon(_ v: Variant, to path: String) {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0) else { return }
    rep.size = NSSize(width: size, height: size)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    guard let ctx = NSGraphicsContext.current?.cgContext else { return }

    NSGradient(starting: v.top, ending: v.bottom)!
        .draw(in: NSRect(x: 0, y: 0, width: size, height: size), angle: -90)

    let cx = size / 2, cy = size / 2
    let outerR: CGFloat = v.bold ? 390 : 372
    let innerR: CGFloat = v.bold ? 158 : 196
    let gapDeg: CGFloat = v.bold ? 3.0 : 2.2

    var startHour = 0.0
    for block in (v.bold ? boldBlocks : blocks) {
        // 12時位置から時計回り。CoreGraphics は反時計回り基準なので符号を反転する。
        let a0 = 90 - (startHour / 24.0 * 360.0)
        let a1 = 90 - ((startHour + block.hours) / 24.0 * 360.0)
        startHour += block.hours

        let path = CGMutablePath()
        path.addArc(center: CGPoint(x: cx, y: cy), radius: outerR,
                    startAngle: (a0 - gapDeg) * .pi / 180,
                    endAngle: (a1 + gapDeg) * .pi / 180,
                    clockwise: true)
        path.addArc(center: CGPoint(x: cx, y: cy), radius: innerR,
                    startAngle: (a1 + gapDeg) * .pi / 180,
                    endAngle: (a0 - gapDeg) * .pi / 180,
                    clockwise: false)
        path.closeSubpath()

        ctx.addPath(path)
        ctx.setFillColor(blockColors[block.colorIndex].cgColor)
        ctx.fillPath()
    }

    if let hole = v.hole {
        ctx.setFillColor(hole.cgColor)
        ctx.fillEllipse(in: CGRect(x: cx - innerR, y: cy - innerR, width: innerR * 2, height: innerR * 2))
    }

    NSGraphicsContext.restoreGraphicsState()

    if let png = rep.representation(using: .png, properties: [:]) {
        try? png.write(to: URL(fileURLWithPath: path))
        print("WROTE \(path)")
    }
}

let outDir = CommandLine.arguments[1]
for v in variants { drawIcon(v, to: "\(outDir)/\(v.name).png") }
