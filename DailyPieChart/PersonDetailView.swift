import SwiftUI

struct PersonDetailView: View {
    let person: Person
    @AppStorage("allSchedules") private var schedulesData: Data = Data()
    @AppStorage("activeScheduleId") private var activeScheduleId: String = ""
    @State private var showCopied = false

    var activeScheduleName: String {
        let schedules = (try? JSONDecoder().decode([Schedule].self, from: schedulesData)) ?? []
        let name = schedules.first(where: { $0.id.uuidString == activeScheduleId })?.name
        return name.map { "\($0)にコピー" } ?? "スケジュールにコピー"
    }

    var copyButtonLabel: String {
        showCopied ? "コピーしました！" : activeScheduleName
    }

    var accentColor: Color {
        blockColors[(person.timeBlocks.first?.colorIndex ?? 0) % blockColors.count]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Bio card
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [accentColor, accentColor.opacity(0.35)],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                            .frame(width: 3, height: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("時代")
                                .font(.caption2.weight(.medium))
                                .foregroundColor(.secondary)
                            Text(person.era)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(accentColor)
                        }
                        Spacer()
                        Image(systemName: "person.fill")
                            .font(.title2)
                            .foregroundColor(accentColor.opacity(0.2))
                    }
                    Text(person.bio)
                        .font(.body)
                        .lineSpacing(5)
                        .foregroundColor(Theme.textWarm.opacity(0.85))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Theme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Theme.cardBorder, lineWidth: 1)
                )
                .cornerRadius(16)
                .shadow(color: Theme.cardShadow.opacity(0.12), radius: 10, x: 0, y: 3)
                .padding(.horizontal)

                // Chart card
                VStack {
                    PieChartView(timeBlocks: person.timeBlocks)
                        .padding(.vertical, 12)
                }
                .background(Theme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Theme.cardBorder, lineWidth: 1)
                )
                .cornerRadius(16)
                .shadow(color: Theme.cardShadow.opacity(0.12), radius: 10, x: 0, y: 3)
                .padding(.horizontal)

                // Copy button
                Button(action: copySchedule) {
                    HStack(spacing: 8) {
                        Image(systemName: showCopied ? "checkmark.circle.fill" : "doc.on.doc.fill")
                            .font(.body)
                        Text(copyButtonLabel)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background {
                        if showCopied {
                            LinearGradient(
                                colors: [Color(red: 0.28, green: 0.62, blue: 0.40), Color(red: 0.50, green: 0.72, blue: 0.25)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        } else {
                            Theme.accentGradient
                        }
                    }
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(
                        color: showCopied ? Color(red: 0.28, green: 0.62, blue: 0.40).opacity(0.35) : Theme.accent1.opacity(0.35),
                        radius: 10, x: 0, y: 4
                    )
                }
                .padding(.horizontal)
                .animation(.easeInOut(duration: 0.2), value: showCopied)
            }
            .padding(.vertical)
        }
        .background(Theme.background)
        .navigationTitle(person.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    func copySchedule() {
        var schedules = (try? JSONDecoder().decode([Schedule].self, from: schedulesData)) ?? []

        if schedules.isEmpty {
            // スケジュールがなければ自動作成
            let newSchedule = Schedule(name: "マイスケジュール", timeBlocks: person.timeBlocks)
            schedules.append(newSchedule)
            activeScheduleId = newSchedule.id.uuidString
        } else if let idx = schedules.firstIndex(where: { $0.id.uuidString == activeScheduleId }) {
            schedules[idx].timeBlocks = person.timeBlocks
        } else {
            schedules[0].timeBlocks = person.timeBlocks
            activeScheduleId = schedules[0].id.uuidString
        }

        if let data = try? JSONEncoder().encode(schedules) {
            schedulesData = data
        }
        showCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showCopied = false
        }
    }
}
