import SwiftUI
import UIKit

/// ライト／ダークで解決が変わる色。色アセットにするとウィジェット拡張側にも
/// アセットカタログを持たせる必要があるため、コード側で動的に解決する。
private func adaptive(
    light: (r: Double, g: Double, b: Double, a: Double),
    dark: (r: Double, g: Double, b: Double, a: Double)
) -> Color {
    Color(UIColor { traits in
        let c = traits.userInterfaceStyle == .dark ? dark : light
        return UIColor(red: c.r, green: c.g, blue: c.b, alpha: c.a)
    })
}

// MARK: - Theme
enum Theme {
    /// ダーク側は共有カードの「ミッドナイト」テーマと同じ系統に揃えている。
    static let background = adaptive(
        light: (0.99, 0.96, 0.85, 1),
        dark:  (0.09, 0.10, 0.16, 1))
    static let card = adaptive(
        light: (1.00, 0.99, 0.93, 1),
        dark:  (0.15, 0.16, 0.24, 1))
    static let cardBorder = adaptive(
        light: (0.82, 0.75, 0.58, 0.45),
        dark:  (1.00, 1.00, 1.00, 0.12))
    static let cardShadow = adaptive(
        light: (0.70, 0.58, 0.35, 1),
        dark:  (0.00, 0.00, 0.00, 1))
    static let ringBg = adaptive(
        light: (0.91, 0.87, 0.76, 1),
        dark:  (0.24, 0.25, 0.34, 1))
    static let textWarm = adaptive(
        light: (0.25, 0.18, 0.10, 1),
        dark:  (0.95, 0.95, 0.98, 1))

    /// 埋まっていない時間。活動の色と取り違えられないよう、彩度を落とした灰色にする。
    static let bufferFill = adaptive(
        light: (0.80, 0.77, 0.70, 0.55),
        dark:  (0.42, 0.44, 0.52, 0.45))

    /// アクセントは共有カードの書き出しにも使うため、両モードで同じ色にする。
    static let accent1 = Color(red: 0.88, green: 0.55, blue: 0.12)   // amber
    static let accent2 = Color(red: 0.82, green: 0.32, blue: 0.42)   // rose
    static let accentGradient = LinearGradient(
        colors: [accent1, accent2],
        startPoint: .leading, endPoint: .trailing
    )
}

// MARK: - Block colors (warm palette for light background)
let blockColors: [Color] = [
    Color(red: 0.22, green: 0.42, blue: 0.85),  // Indigo
    Color(red: 0.88, green: 0.38, blue: 0.25),  // Terracotta
    Color(red: 0.28, green: 0.62, blue: 0.40),  // Forest Green
    Color(red: 0.90, green: 0.58, blue: 0.10),  // Amber
    Color(red: 0.60, green: 0.28, blue: 0.70),  // Plum
    Color(red: 0.85, green: 0.30, blue: 0.52),  // Rose
    Color(red: 0.18, green: 0.60, blue: 0.65),  // Teal
    Color(red: 0.50, green: 0.72, blue: 0.25),  // Lime
    Color(red: 0.75, green: 0.20, blue: 0.30),  // Crimson
    Color(red: 0.38, green: 0.58, blue: 0.88),  // Sky Blue
]

struct TimeBlock: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var hours: Double
    var colorIndex: Int

    /// この活動の後ろに空ける余白（時間）。移動・片付け・切り替えのための時間。
    /// 既存の保存データにこのキーは無いのでOptionalで受ける
    /// (非Optionalで足すとデコードが丸ごと失敗し、保存済みの予定が消える)。
    private var bufferAfterRaw: Double?

    /// private な保存プロパティを足すと自動生成の初期化子も private になるため明示する。
    init(id: UUID = UUID(), name: String, hours: Double, colorIndex: Int, bufferAfter: Double = 0) {
        self.id = id
        self.name = name
        self.hours = hours
        self.colorIndex = colorIndex
        self.bufferAfterRaw = bufferAfter
    }

    var bufferAfter: Double {
        get { max(0, bufferAfterRaw ?? 0) }
        set { bufferAfterRaw = max(0, newValue) }
    }

    /// 活動そのものと、その後ろの余白を足した長さ。円を進める単位。
    var span: Double { hours + bufferAfter }
}

struct Schedule: Identifiable, Codable {
    var id = UUID()
    var name: String
    var timeBlocks: [TimeBlock]

    /// 1日の始まり。既存の保存データにこのキーは無いのでOptionalで受ける
    /// (非Optionalで足すとデコードが丸ごと失敗し、保存済みの予定が消える)。
    private var startHourRaw: Double?

    /// private な保存プロパティを足すと自動生成の初期化子も private になり、
    /// ウィジェット側など他から作れなくなるため、明示的に用意する。
    init(id: UUID = UUID(), name: String, timeBlocks: [TimeBlock], startHour: Double = 0) {
        self.id = id
        self.name = name
        self.timeBlocks = timeBlocks
        self.startHourRaw = startHour
    }

    /// 0..<24。ここを起点に区画を並べる。0なら従来どおり深夜0時始まり。
    var startHour: Double {
        get { min(max(startHourRaw ?? 0, 0), 23.9999) }
        set { startHourRaw = min(max(newValue, 0), 23.9999) }
    }

    /// 活動そのものの合計
    var activityHours: Double {
        timeBlocks.reduce(0) { $0 + $1.hours }
    }

    /// 活動の間に挟んだ余白の合計
    var bufferBetweenHours: Double {
        timeBlocks.reduce(0) { $0 + $1.bufferAfter }
    }

    /// 活動と余白を並べて埋まる長さ
    var filledHours: Double {
        timeBlocks.reduce(0) { $0 + $1.span }
    }

    /// 並べ終えたあとに余る時間。ここも灰色で出す。
    var trailingBufferHours: Double {
        max(0, 24.0 - filledHours)
    }

    /// 灰色で出る時間の合計（活動の間の余白＋末尾の余り）
    var bufferHours: Double {
        bufferBetweenHours + trailingBufferHours
    }

    /// `hour`(0..<24)がどの区画に入るか。余白に入っていれば nil。
    func block(at hour: Double) -> TimeBlock? {
        var elapsed = hour - startHour
        if elapsed < 0 { elapsed += 24 }
        var cursor = 0.0
        for block in timeBlocks {
            if elapsed >= cursor && elapsed < cursor + block.hours { return block }
            cursor += block.span   // 余白のぶんも進める
        }
        return nil
    }
}

struct Person: Identifiable {
    let id = UUID()
    let name: String
    let era: String
    let bio: String
    var timeBlocks: [TimeBlock]

    var totalHours: Double {
        timeBlocks.reduce(0) { $0 + $1.hours }
    }
}
