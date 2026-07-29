import Foundation

/// 動的にキーを組み立てる箇所（SampleData など）用のローカライズヘルパー。
/// SwiftUI の `Text("key")` は LocalizedStringKey として自動解決されるため、
/// そちらで済む場所ではこの関数は使わない。
func L(_ key: String) -> String {
    NSLocalizedString(key, comment: "")
}

func L(_ key: String, _ args: CVarArg...) -> String {
    String(format: NSLocalizedString(key, comment: ""), arguments: args)
}

/// 時間の長さ（1.5 → "1時間30分" / "1h 30m"）。
/// 以前は MyScheduleView と EditBlockView に同じ実装が重複していた。
func formatHours(_ hours: Double) -> String {
    let totalMinutes = lround(hours * 60)
    let h = totalMinutes / 60
    let m = totalMinutes % 60
    if m == 0 { return L("format.hours", h) }
    if h == 0 { return L("format.minutes", m) }
    return L("format.hours_minutes", h, m)
}
