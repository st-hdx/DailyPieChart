import SwiftUI

// MARK: - Theme
enum Theme {
    static let background   = Color(red: 0.99, green: 0.96, blue: 0.85)   // pale yellow
    static let card         = Color(red: 1.00, green: 0.99, blue: 0.93)   // cream white
    static let cardBorder   = Color(red: 0.82, green: 0.75, blue: 0.58).opacity(0.45)
    static let cardShadow   = Color(red: 0.70, green: 0.58, blue: 0.35)
    static let ringBg       = Color(red: 0.91, green: 0.87, blue: 0.76)   // warm tan
    static let accent1      = Color(red: 0.88, green: 0.55, blue: 0.12)   // amber
    static let accent2      = Color(red: 0.82, green: 0.32, blue: 0.42)   // rose
    static let textWarm     = Color(red: 0.25, green: 0.18, blue: 0.10)
    static let accentGradient = LinearGradient(
        colors: [Color(red: 0.88, green: 0.55, blue: 0.12), Color(red: 0.82, green: 0.32, blue: 0.42)],
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
