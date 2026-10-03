import SwiftUI

struct EditBlockView: View {
    var existingBlock: TimeBlock? = nil
    var currentTotal: Double = 0
    var onSave: (TimeBlock) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var name: String
    /// 分で持つ。Double の時間に 1/6 を足し引きすると誤差が溜まって
    /// 「9分」「11分」のような半端な値になるため、整数の分を正とする。
    @State private var minutes: Int
    @State private var colorIndex: Int
    /// 後ろの余白も分で持つ（時間の Double で持つと10分刻みの誤差が溜まる）
    @State private var bufferMinutes: Int
    /// 表示と同時にフォーカスを当てる。キーボードが出きる前に入力が始まると、
    /// 日本語入力の最初の変換が取りこぼされることがあるため。
    @FocusState private var nameFocused: Bool

    init(existingBlock: TimeBlock? = nil, currentTotal: Double = 0, onSave: @escaping (TimeBlock) -> Void) {
        self.existingBlock = existingBlock
        self.currentTotal = currentTotal
        self.onSave = onSave
        self._name = State(initialValue: existingBlock?.name ?? "")
        self._minutes = State(initialValue: Self.snap(existingBlock?.hours ?? 1.0))
        self._colorIndex = State(initialValue: existingBlock?.colorIndex ?? 0)
        self._bufferMinutes = State(initialValue: Int(((existingBlock?.bufferAfter ?? 0) * 60).rounded()))
    }

    /// 10分刻みの最小単位
    static let stepMinutes = 10
    static func snap(_ hours: Double) -> Int {
        max(stepMinutes, Int((hours * 60.0 / Double(stepMinutes)).rounded()) * stepMinutes)
    }

    var hours: Double { Double(minutes) / 60.0 }
    var bufferHours: Double { Double(bufferMinutes) / 60.0 }
    /// この活動（と余白）を除いた他の合計
    var otherHours: Double { currentTotal - (existingBlock?.span ?? 0) }
    var maxHours: Double { max(0.5, 24.0 - otherHours - bufferHours) }
    var remaining: Double { 24.0 - otherHours - hours - bufferHours }
    var isOverLimit: Bool { remaining < -0.001 }

    var selectedColor: Color { blockColors[colorIndex % blockColors.count] }

    /// 三項演算子のままだと String オーバーロードに解決されうるため、型を明示する。
    var titleKey: LocalizedStringKey {
        existingBlock == nil ? "edit_block.title_add" : "edit_block.title_edit"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // Name
                    fieldSection(label: "edit_block.name_label", icon: "pencil") {
                        TextField("edit_block.name_placeholder", text: $name)
                            .font(.body)
                            .focused($nameFocused)
                    }

                    // Hours
                    fieldSection(label: "edit_block.hours_label", icon: "clock") {
                        VStack(spacing: 0) {
                            Stepper(formatHours(hours),
                                    value: $minutes,
                                    in: Self.stepMinutes...max(Self.stepMinutes, Int((maxHours * 60).rounded())),
                                    step: Self.stepMinutes)
                                .accessibilityIdentifier("stepper_hours")
                            Divider()
                                .background(Theme.cardBorder)
                                .padding(.vertical, 10)
                            HStack {
                                Text("edit_block.remaining")
                                    .foregroundColor(.secondary)
                                Spacer()
                                if isOverLimit {
                                    Label(L("edit_block.over", formatHours(abs(remaining))), systemImage: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                        .font(.subheadline)
                                } else {
                                    Text(formatHours(remaining))
                                        .foregroundColor(remaining < 0.001 ? Color(red: 0.18, green: 0.85, blue: 0.65) : .secondary)
                                        .fontWeight(remaining < 0.001 ? .semibold : .regular)
                                }
                            }
                        }
                    }

                    // 後ろの余白
                    fieldSection(label: "edit_block.buffer_label", icon: "arrow.right.to.line") {
                        VStack(alignment: .leading, spacing: 8) {
                            Stepper(formatHours(bufferHours),
                                    value: $bufferMinutes,
                                    in: 0...max(0, Int(((24.0 - otherHours - hours) * 60).rounded())),
                                    step: Self.stepMinutes)
                                .accessibilityIdentifier("stepper_buffer")
                            Text("edit_block.buffer_footer")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Color
                    fieldSection(label: "edit_block.color_label", icon: "paintpalette") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                            ForEach(0..<blockColors.count, id: \.self) { index in
                                colorSwatch(index: index)
                            }
                        }
                    }

                    // Save button
                    Button(action: save) {
                        Text("common.save")
                            .font(.body.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background {
                                if isOverLimit {
                                    Theme.cardBorder
                                } else {
                                    Theme.accentGradient
                                }
                            }
                            .foregroundColor(isOverLimit ? .secondary : .white)
                            .cornerRadius(16)
                            .shadow(
                                color: isOverLimit ? .clear : Theme.accent1.opacity(0.4),
                                radius: 12, x: 0, y: 4
                            )
                    }
                    .disabled(isOverLimit)
                    .padding(.horizontal)
                }
                .padding(.vertical, 24)
            }
            .background(Theme.background.ignoresSafeArea())
            .task {
                // 直後に当てるとシートの表示アニメーションに食われるので、少しだけ待つ。
                // この画面はScrollView+Stepper×2+色スウォッチのLazyVGridを抱えて他の2つの
                // 入力シート（スケジュール追加・リネーム）より初期レイアウトが重く、350msでは
                // 機種やタイミングによってまだ確定し切っておらず、日本語入力の最初の変換が
                // 取りこぼされることがある。余裕を持たせる。
                try? await Task.sleep(nanoseconds: 600_000_000)
                nameFocused = true
            }
            .navigationTitle(titleKey)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.cancel") { dismiss() }
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private func fieldSection<Content: View>(
        label: LocalizedStringKey,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(label, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal)

            content()
                .padding()
                .background(Theme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Theme.cardBorder, lineWidth: 1)
                )
                .cornerRadius(14)
                .shadow(color: Theme.cardShadow.opacity(0.10), radius: 8, x: 0, y: 2)
                .padding(.horizontal)
        }
    }

    private func colorSwatch(index: Int) -> some View {
        let color = blockColors[index]
        let selected = colorIndex == index
        return ZStack {
            Circle()
                .fill(color)
                .frame(width: 46, height: 46)
                .shadow(color: color.opacity(selected ? 0.8 : 0.15), radius: selected ? 10 : 3, x: 0, y: 0)
            if selected {
                Circle()
                    .strokeBorder(Color.white, lineWidth: 2.5)
                    .frame(width: 46, height: 46)
                Image(systemName: "checkmark")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white)
            }
        }
        .onTapGesture { colorIndex = index }
    }

    private func save() {
        var block = existingBlock ?? TimeBlock(name: "", hours: 1, colorIndex: 0)
        block.name = name.isEmpty ? L("edit_block.default_name") : name
        block.hours = hours
        block.bufferAfter = bufferHours
        block.colorIndex = colorIndex
        onSave(block)
        dismiss()
    }
}
