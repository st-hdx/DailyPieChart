import WidgetKit
import SwiftUI

// MARK: - Timeline

struct ScheduleEntry: TimelineEntry {
    let date: Date
    let schedule: Schedule?
}

struct Provider: TimelineProvider {
    /// ウィジェットギャラリーやプレビューで見せるダミー。
    private var sampleSchedule: Schedule {
        Schedule(name: L("template.weekday.name"), timeBlocks: [
            TimeBlock(name: L("activity.sleep"),        hours: 7, colorIndex: 0),
            TimeBlock(name: L("activity.morning_prep"), hours: 1, colorIndex: 6),
            TimeBlock(name: L("activity.commute"),      hours: 1, colorIndex: 4),
            TimeBlock(name: L("activity.work"),         hours: 8, colorIndex: 1),
            TimeBlock(name: L("activity.lunch_break"),  hours: 1, colorIndex: 3),
            TimeBlock(name: L("activity.commute_home"), hours: 1, colorIndex: 4),
            TimeBlock(name: L("activity.dinner"),       hours: 1, colorIndex: 5),
            TimeBlock(name: L("activity.free_time"),    hours: 3, colorIndex: 2),
            TimeBlock(name: L("activity.bedtime_prep"), hours: 1, colorIndex: 7),
        ])
    }

    func placeholder(in context: Context) -> ScheduleEntry {
        ScheduleEntry(date: Date(), schedule: sampleSchedule)
    }

    func getSnapshot(in context: Context, completion: @escaping (ScheduleEntry) -> Void) {
        let schedule = context.isPreview ? sampleSchedule : (AppGroup.activeSchedule() ?? sampleSchedule)
        completion(ScheduleEntry(date: Date(), schedule: schedule))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ScheduleEntry>) -> Void) {
        let schedule = AppGroup.activeSchedule()
        let now = Date()

        // 「今」の針と現在の活動表示を進めるため、15分刻みで6時間ぶん用意する。
        let entries = (0..<24).map { step -> ScheduleEntry in
            let date = Calendar.current.date(byAdding: .minute, value: step * 15, to: now) ?? now
            return ScheduleEntry(date: date, schedule: schedule)
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// MARK: - Views

struct DailyPieChartWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: ScheduleEntry

    private var nowHour: Double {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: entry.date)
        return Double(comps.hour ?? 0) + Double(comps.minute ?? 0) / 60.0
    }

    var body: some View {
        Group {
            if let schedule = entry.schedule, !schedule.timeBlocks.isEmpty {
                switch family {
                case .systemMedium: mediumBody(schedule)
                default:            smallBody(schedule)
                }
            } else {
                emptyBody
            }
        }
        .background(Theme.background)
    }

    private func chart(_ schedule: Schedule) -> some View {
        ClockChartView(
            timeBlocks: schedule.timeBlocks,
            showHourLabels: false,
            showActivityLabels: false,
            animated: false,
            nowHour: nowHour
        )
    }

    private func smallBody(_ schedule: Schedule) -> some View {
        ZStack {
            chart(schedule).padding(8)
            if let current = schedule.block(at: entry.date) {
                VStack(spacing: 1) {
                    Text(current.name)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Theme.textWarm)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.7)
                    if let remaining = schedule.remainingHours(at: entry.date) {
                        Text(L("widget.remaining", formatHours(remaining)))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(Theme.textWarm.opacity(0.5))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                .padding(.horizontal, 22)
            }
        }
    }

    private func mediumBody(_ schedule: Schedule) -> some View {
        HStack(spacing: 14) {
            chart(schedule)
                .frame(width: 118, height: 118)

            VStack(alignment: .leading, spacing: 6) {
                Text(schedule.name)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Theme.textWarm)
                    .lineLimit(1)

                if let current = schedule.block(at: entry.date) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(blockColors[current.colorIndex % blockColors.count])
                            .frame(width: 8, height: 8)
                        Text(current.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Theme.textWarm)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    if let remaining = schedule.remainingHours(at: entry.date) {
                        Text(L("widget.remaining", formatHours(remaining)))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Theme.textWarm.opacity(0.5))
                    }
                }

                Spacer(minLength: 0)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
    }

    private var emptyBody: some View {
        VStack(spacing: 5) {
            Image(systemName: "chart.pie")
                .font(.title2)
                .foregroundStyle(Theme.accentGradient)
            Text("widget.no_data")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textWarm)
            Text("widget.no_data_hint")
                .font(.system(size: 10))
                .foregroundColor(Theme.textWarm.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .padding(8)
    }
}

// MARK: - Widget

struct DailyPieChartWidget: Widget {
    let kind = "DailyPieChartWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            DailyPieChartWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(L("widget.display_name"))
        .description(L("widget.description"))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct DailyPieChartWidgetBundle: WidgetBundle {
    var body: some Widget {
        DailyPieChartWidget()
    }
}
