import SwiftUI

struct EditBlockView: View {
    var existingBlock: TimeBlock? = nil
    var currentTotal: Double = 0
    var onSave: (TimeBlock) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var name: String
    @State private var hours: Double
    @State private var colorIndex: Int

    init(existingBlock: TimeBlock? = nil, currentTotal: Double = 0, onSave: @escaping (TimeBlock) -> Void) {
        self.existingBlock = existingBlock
        self.currentTotal = currentTotal
        self.onSave = onSave
        self._name = State(initialValue: existingBlock?.name ?? "")
        self._hours = State(initialValue: existingBlock?.hours ?? 1.0)
        self._colorIndex = State(initialValue: existingBlock?.colorIndex ?? 0)
    }

    var otherHours: Double { currentTotal - (existingBlock?.hours ?? 0) }
    var maxHours: Double { max(0.5, 24.0 - otherHours) }
    var remaining: Double { 24.0 - otherHours - hours }
    var isOverLimit: Bool { remaining < -0.001 }

    var selectedColor: Color { blockColors[colorIndex % blockColors.count] }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {

                    // Name
                    fieldSection(label: "活動名", icon: "pencil") {
                        TextField("例：睡眠、仕事、運動", text: $name)
                            .font(.body)
                    }

                    // Hours
                    fieldSection(label: "時間", icon: "clock") {
                        VStack(spacing: 0) {
                            Stepper(formatHours(hours), value: $hours, in: 0.5...max(0.5, maxHours), step: 0.5)
                            Divider()
                                .background(Color.white.opacity(0.08))
                                .padding(.vertical, 10)
                            HStack {
                                Text("残り")
                                    .foregroundColor(.secondary)
                                Spacer()
                                if isOverLimit {
                                    Label("\(formatHours(abs(remaining)))オーバー", systemImage: "exclamationmark.triangle.fill")
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

                    // Color
                    fieldSection(label: "カラー", icon: "paintpalette") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                            ForEach(0..<blockColors.count, id: \.self) { index in
                                colorSwatch(index: index)
                            }
                        }
                    }

                    // Save button
                    Button(action: save) {
                        Text("保存")
                            .font(.body.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background {
                                if isOverLimit {
                                    Color.black.opacity(0.06)
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
            .navigationTitle(existingBlock == nil ? "活動を追加" : "活動を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private func fieldSection<Content: View>(
        label: String,
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
        block.name = name.isEmpty ? "活動" : name
        block.hours = hours
        block.colorIndex = colorIndex
        onSave(block)
        dismiss()
    }

    func formatHours(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        if m == 0 { return "\(h)時間" }
        if h == 0 { return "\(m)分" }
        return "\(h)時間\(m)分"
    }
}
