import SwiftUI

/// SNS 共有用に書き出す 1 枚絵。
/// 画面表示用ではなく ImageRenderer でラスタライズする前提なので、
/// サイズを固定し、アニメーションを持たせない。
struct ShareCardView: View {
    let title: String
    let subtitle: String
    let timeBlocks: [TimeBlock]

    static let cardWidth: CGFloat = 540

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textWarm)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(Theme.textWarm.opacity(0.55))
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 44)

            ClockChartView(timeBlocks: timeBlocks, animated: false)
                .frame(width: Self.cardWidth - 40, height: Self.cardWidth - 40)
                .padding(.top, 8)

            legend
                .padding(.horizontal, 36)
                .padding(.top, 4)

            footer
                .padding(.top, 28)
                .padding(.bottom, 30)
        }
        .frame(width: Self.cardWidth)
        .background(Theme.background)
    }

    private var legend: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
            spacing: 8
        ) {
            ForEach(timeBlocks) { block in
                HStack(spacing: 7) {
                    Circle()
                        .fill(blockColors[block.colorIndex % blockColors.count])
                        .frame(width: 9, height: 9)
                    Text(block.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.textWarm.opacity(0.9))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer(minLength: 4)
                    Text(formatHours(block.hours))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textWarm.opacity(0.5))
                }
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 4) {
            // ImageRenderer は独立した環境で描画するため Text(LocalizedStringKey) だと
            // アプリの言語ではなくシステムロケールで解決されてしまう。バンドル参照で引く。
            Text(L("share.card_tagline"))
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Theme.textWarm.opacity(0.45))
            Text("DailyPieChart")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.accentGradient)
        }
    }
}

// MARK: - Share button

/// カード画像を書き出して ShareLink に渡すボタン。
/// 書き出しが終わるまではボタンを無効化する。
struct ShareChartButton: View {
    let title: String
    let subtitle: String
    let timeBlocks: [TimeBlock]

    @State private var rendered: Image?

    var body: some View {
        Group {
            if let rendered {
                ShareLink(
                    item: rendered,
                    preview: SharePreview(L("share.preview_title", title), image: rendered)
                ) {
                    Image(systemName: "square.and.arrow.up")
                }
            } else {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.secondary.opacity(0.4))
            }
        }
        .onAppear(perform: render)
        .onChange(of: timeBlocks) { _ in render() }
        .onChange(of: title) { _ in render() }
    }

    @MainActor
    private func render() {
        guard !timeBlocks.isEmpty else {
            rendered = nil
            return
        }
        let renderer = ImageRenderer(
            content: ShareCardView(title: title, subtitle: subtitle, timeBlocks: timeBlocks)
        )
        renderer.scale = 3
        if let uiImage = renderer.uiImage {
            rendered = Image(uiImage: uiImage)
        }
    }
}
