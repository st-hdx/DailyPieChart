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
}

struct Schedule: Identifiable, Codable {
    var id = UUID()
    var name: String
    var timeBlocks: [TimeBlock]
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
