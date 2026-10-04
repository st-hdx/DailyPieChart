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

/// 開始時刻と長さから「6:00〜6:30」のような範囲表示を作る。
/// 以前は PieChartView の凡例グリッドにしか無かったが、マイスケジュールの
/// 活動一覧にも同じ表示を出すため、共有の自由関数にした。
func formatTimeRange(start: Double, duration: Double) -> String {
    func fmt(_ h: Double) -> String {
        // 分を切り捨てると、10分刻み(1/6時間)が2進数で割り切れないために
        // 「10分」が「9分」として出る。分に直してから丸める。
        let totalMinutes = lround(h * 60)
        let hour = (totalMinutes / 60) % 24
        let min = ((totalMinutes % 60) + 60) % 60
        return String(format: "%d:%02d", hour, min)
    }
    return L("format.time_range", fmt(start), fmt(start + duration))
}
