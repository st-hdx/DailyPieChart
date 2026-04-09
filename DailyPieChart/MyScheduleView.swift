import SwiftUI

struct MyScheduleView: View {
    @EnvironmentObject var store: StoreManager
    @AppStorage("allSchedules") private var schedulesData: Data = Data()
    @AppStorage("activeScheduleId") private var activeScheduleId: String = ""

    @State private var schedules: [Schedule] = []
    @State private var showAddBlockSheet = false
    @State private var editingBlock: TimeBlock? = nil
    @State private var editMode: EditMode = .inactive
    @State private var showPaywall = false

    var canAddSchedule: Bool {
        store.isPro || schedules.count < StoreManager.freeScheduleLimit
    }
    @State private var showAddScheduleSheet = false
    @State private var showRenameSheet = false
    @State private var renamingScheduleId: String = ""
    @State private var renameText: String = ""

    // MARK: - Computed

    var activeIndex: Int? {
        schedules.firstIndex { $0.id.uuidString == activeScheduleId }
    }

    var timeBlocks: [TimeBlock] {
        activeIndex.map { schedules[$0].timeBlocks } ?? []
    }

    var totalHours: Double { timeBlocks.reduce(0) { $0 + $1.hours } }
    var isExact24: Bool { abs(totalHours - 24) < 0.01 }

    // MARK: - Body

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if !schedules.isEmpty {
                    schedulePicker
                        .padding(.vertical, 12)
                }

                Group {
                    if schedules.isEmpty {
                        noSchedulesView
                    } else if timeBlocks.isEmpty {
                        emptyBlocksView
                    } else {
                        contentList
                    }
                }
            }
            .background(Theme.background)
            .navigationTitle("マイスケジュール")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !timeBlocks.isEmpty {
                        Button(editMode.isEditing ? "完了" : "並び替え") {
                            withAnimation { editMode = editMode.isEditing ? .inactive : .active }
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 8) {
                        if !timeBlocks.isEmpty {
                            Text("\(timeBlocks.count)/24")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(timeBlocks.count >= 24 ? Theme.accent2 : .secondary)
                        }
                        Button { showAddBlockSheet = true } label: {
                            Image(systemName: "plus")
                        }
                        .disabled(activeIndex == nil || timeBlocks.count >= 24)
                    }
                }
            }
            .sheet(isPresented: $showAddBlockSheet) {
                EditBlockView(currentTotal: totalHours) { block in
                    appendBlock(block)
                }
            }
            .sheet(item: $editingBlock) { block in
                if let si = activeIndex,
                   let bi = schedules[si].timeBlocks.firstIndex(where: { $0.id == block.id }) {
                    EditBlockView(existingBlock: schedules[si].timeBlocks[bi], currentTotal: totalHours) { newBlock in
                        schedules[si].timeBlocks[bi] = newBlock
                        saveSchedules()
                    }
                }
            }
            .sheet(isPresented: $showAddScheduleSheet) {
                AddScheduleSheet { name in addSchedule(name: name) }
            }
            .sheet(isPresented: $showRenameSheet) {
                RenameScheduleSheet(name: $renameText) {
                    if let idx = schedules.firstIndex(where: { $0.id.uuidString == renamingScheduleId }) {
                        schedules[idx].name = renameText.trimmingCharacters(in: .whitespaces)
                        saveSchedules()
                    }
                }
            }
            .onAppear(perform: loadSchedules)
            .onChange(of: schedulesData) { _ in loadSchedules() }
            .sheet(isPresented: $showPaywall) {
                PaywallView().environmentObject(store)
            }
        }
    }

    // MARK: - Sub views

    private var schedulePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(schedules) { schedule in
                    SchedulePillView(
                        schedule: schedule,
                        isActive: schedule.id.uuidString == activeScheduleId,
                        canDelete: schedules.count > 1,
                        onTap: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                activeScheduleId = schedule.id.uuidString
                                editMode = .inactive
                            }
                        },
                        onRename: {
                            renamingScheduleId = schedule.id.uuidString
                            renameText = schedule.name
                            showRenameSheet = true
                        },
                        onDelete: {
                            deleteSchedule(id: schedule.id.uuidString)
                        }
                    )
                }

                // Add schedule button
                Button {
                    if canAddSchedule { showAddScheduleSheet = true } else { showPaywall = true }
                } label: {
                    Image(systemName: canAddSchedule ? "plus" : "lock.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(canAddSchedule ? Theme.accent1 : Theme.accent2)
                        .frame(width: 36, height: 36)
                        .background(Theme.card)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(Theme.cardBorder, lineWidth: 1))
                }
            }
            .padding(.horizontal)
        }
    }

    private var noSchedulesView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Theme.accent1.opacity(0.18), Theme.accent2.opacity(0.18)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 100)
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 42))
                    .foregroundStyle(Theme.accentGradient)
            }
            VStack(spacing: 6) {
                Text("スケジュールがありません")
                    .font(.headline)
                    .foregroundColor(Theme.textWarm)
                Text("まずスケジュールを作成しましょう")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Button { if canAddSchedule { showAddScheduleSheet = true } else { showPaywall = true } } label: {
                Label("スケジュールを作成", systemImage: "plus.circle.fill")
                    .font(.body.weight(.semibold))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Theme.accentGradient)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                    .shadow(color: Theme.accent1.opacity(0.35), radius: 8, x: 0, y: 3)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
    }

    private var emptyBlocksView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Theme.accent1.opacity(0.18), Theme.accent2.opacity(0.18)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 100)
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Theme.accentGradient)
            }
            VStack(spacing: 6) {
                Text("活動がありません")
                    .font(.headline)
                    .foregroundColor(Theme.textWarm)
                Text("偉人タブからコピーするか\n「+」ボタンで追加してください")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
    }

    private var contentList: some View {
        List {
            Section {
                PieChartView(timeBlocks: timeBlocks)
                    .padding(.vertical, 8)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                HStack {
                    Text("合計時間")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatHours(totalHours))
                        .fontWeight(.semibold)
                        .foregroundColor(isExact24 ? Color(red: 0.28, green: 0.62, blue: 0.40) : Theme.accent1)
                    if isExact24 {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(red: 0.28, green: 0.62, blue: 0.40))
                    }
                }
            }

            Section("活動一覧") {
                ForEach(timeBlocks) { block in
                    blockRow(block)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if !editMode.isEditing { openEdit(for: block) }
                        }
                }
                .onDelete { offsets in
                    if let si = activeIndex {
                        schedules[si].timeBlocks.remove(atOffsets: offsets)
                        saveSchedules()
                    }
                }
                .onMove { source, dest in
                    if let si = activeIndex {
                        schedules[si].timeBlocks.move(fromOffsets: source, toOffset: dest)
                        saveSchedules()
                    }
                }
            }
        }
        .environment(\.editMode, $editMode)
    }

    private func blockRow(_ block: TimeBlock) -> some View {
        let color = blockColors[block.colorIndex % blockColors.count]
        return HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
                .shadow(color: color.opacity(0.5), radius: 3, x: 0, y: 0)
            Text(block.name)
                .font(.body)
            Spacer()
            Text(formatHours(block.hours))
                .font(.caption.weight(.semibold))
                .foregroundColor(color)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(color.opacity(0.12))
                .cornerRadius(8)
            if !editMode.isEditing {
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.secondary.opacity(0.5))
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Actions

    private func appendBlock(_ block: TimeBlock) {
        if let si = activeIndex {
            schedules[si].timeBlocks.append(block)
            saveSchedules()
        }
    }

    private func openEdit(for block: TimeBlock) { editingBlock = block }

    private func addSchedule(name: String) {
        let s = Schedule(name: name, timeBlocks: [])
        schedules.append(s)
        activeScheduleId = s.id.uuidString
        saveSchedules()
    }

    private func deleteSchedule(id: String) {
        schedules.removeAll { $0.id.uuidString == id }
        if activeScheduleId == id {
            activeScheduleId = schedules.first?.id.uuidString ?? ""
        }
        saveSchedules()
    }

    func loadSchedules() {
        guard let decoded = try? JSONDecoder().decode([Schedule].self, from: schedulesData) else { return }
        schedules = decoded
        if !schedules.contains(where: { $0.id.uuidString == activeScheduleId }) {
            activeScheduleId = schedules.first?.id.uuidString ?? ""
        }
    }

    func saveSchedules() {
        if let data = try? JSONEncoder().encode(schedules) {
            schedulesData = data
        }
    }

    func formatHours(_ hours: Double) -> String {
        let totalMinutes = lround(hours * 60)
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        if m == 0 { return "\(h)時間" }
        if h == 0 { return "\(m)分" }
        return "\(h)時間\(m)分"
    }
}

// MARK: - Add Schedule Sheet

struct AddScheduleSheet: View {
    @State private var name = ""
    var onSave: (String) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Label("スケジュール名", systemImage: "calendar")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                    TextField("例：平日、週末、休日", text: $name)
                        .font(.body)
                        .padding()
                        .background(Theme.card)
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.cardBorder, lineWidth: 1))
                        .cornerRadius(14)
                }
                .padding(.horizontal)

                Button {
                    onSave(name.trimmingCharacters(in: .whitespaces))
                    dismiss()
                } label: {
                    Text("作成")
                        .font(.body.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.accentGradient)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: Theme.accent1.opacity(0.4), radius: 12, x: 0, y: 4)
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal)

                Spacer()
            }
            .padding(.vertical, 24)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("スケジュールを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }.foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Schedule Pill View

struct SchedulePillView: View {
    let schedule: Schedule
    let isActive: Bool
    let canDelete: Bool
    let onTap: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void

    var pillBackground: some View {
        Group {
            if isActive {
                Theme.accentGradient.cornerRadius(20)
            } else {
                Theme.card.cornerRadius(20)
            }
        }
    }

    var body: some View {
        Text(schedule.name)
            .font(.subheadline.weight(isActive ? .bold : .medium))
            .foregroundColor(isActive ? .white : Theme.textWarm)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(pillBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(isActive ? Color.clear : Theme.cardBorder, lineWidth: 1)
            )
            .shadow(
                color: isActive ? Theme.accent1.opacity(0.30) : Theme.cardShadow.opacity(0.10),
                radius: isActive ? 6 : 3, x: 0, y: 2
            )
            .onTapGesture(perform: onTap)
            .contextMenu {
                Button { onRename() } label: {
                    Label("名前を変更", systemImage: "pencil")
                }
                if canDelete {
                    Button(role: .destructive) { onDelete() } label: {
                        Label("削除", systemImage: "trash")
                    }
                }
            }
    }
}

// MARK: - Rename Schedule Sheet

struct RenameScheduleSheet: View {
    @Binding var name: String
    var onSave: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Label("新しい名前", systemImage: "pencil")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                    TextField("スケジュール名", text: $name)
                        .font(.body)
                        .padding()
                        .background(Theme.card)
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.cardBorder, lineWidth: 1))
                        .cornerRadius(14)
                }
                .padding(.horizontal)

                Button {
                    onSave()
                    dismiss()
                } label: {
                    Text("保存")
                        .font(.body.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.accentGradient)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: Theme.accent1.opacity(0.4), radius: 12, x: 0, y: 4)
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal)

                Spacer()
            }
            .padding(.vertical, 24)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("名前を変更")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }.foregroundColor(.secondary)
                }
            }
        }
    }
}
