import SwiftUI

// MARK: - Theme

/// 共有カードの見た目。スライスの色（＝データの色）は変えず、
/// 背景と文字色だけを差し替える。
struct ShareCardTheme: Identifiable {
    let id: String
    let nameKey: String
    let isPro: Bool
    let background: Color
    let swatch: Color
    let text: Color
    let ring: Color
    let cardSurface: Color

    var name: String { L(nameKey) }
}

extension ShareCardTheme {
    static let cream = ShareCardTheme(
        id: "cream",
        nameKey: "cardtheme.cream",
        isPro: false,
        background: Color(red: 0.99, green: 0.96, blue: 0.85),
        swatch: Color(red: 0.99, green: 0.95, blue: 0.83),
        text: Color(red: 0.25, green: 0.18, blue: 0.10),
        ring: Color(red: 0.91, green: 0.87, blue: 0.76),
        cardSurface: Color(red: 1.00, green: 0.99, blue: 0.93)
    )

    static let midnight = ShareCardTheme(
        id: "midnight",
        nameKey: "cardtheme.midnight",
        isPro: true,
        background: Color(red: 0.09, green: 0.10, blue: 0.16),
        swatch: Color(red: 0.12, green: 0.13, blue: 0.20),
        text: Color(red: 0.95, green: 0.95, blue: 0.98),
        ring: Color(red: 0.24, green: 0.25, blue: 0.34),
        cardSurface: Color(red: 0.14, green: 0.15, blue: 0.23)
    )

    static let paper = ShareCardTheme(
        id: "paper",
        nameKey: "cardtheme.paper",
        isPro: true,
        background: Color(white: 0.98),
        swatch: Color(white: 0.96),
        text: Color(white: 0.16),
        ring: Color(white: 0.88),
        cardSurface: Color(white: 1.0)
    )

    static let forest = ShareCardTheme(
        id: "forest",
        nameKey: "cardtheme.forest",
        isPro: true,
        background: Color(red: 0.11, green: 0.22, blue: 0.19),
        swatch: Color(red: 0.13, green: 0.26, blue: 0.22),
        text: Color(red: 0.93, green: 0.96, blue: 0.93),
        ring: Color(red: 0.24, green: 0.40, blue: 0.34),
        cardSurface: Color(red: 0.15, green: 0.29, blue: 0.24)
    )

    static let all: [ShareCardTheme] = [.cream, .midnight, .paper, .forest]
}

// MARK: - Card

/// SNS 共有用に書き出す1枚絵。ImageRenderer でラスタライズする前提なので、
/// サイズを固定し、アニメーションを持たせない。
struct ShareCardView: View {
    let title: String
    let subtitle: String
    let timeBlocks: [TimeBlock]
    var theme: ShareCardTheme = .cream

    static let cardWidth: CGFloat = 540

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(theme.text)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(theme.text.opacity(0.55))
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 44)

            ClockChartView(
                timeBlocks: timeBlocks,
                animated: false,
                labelColor: theme.text,
                ringColor: theme.ring
            )
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
        .background(theme.background)
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
                        .foregroundColor(theme.text.opacity(0.9))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer(minLength: 4)
                    Text(formatHours(block.hours))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(theme.text.opacity(0.5))
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
                .foregroundColor(theme.text.opacity(0.45))
            Text("DailyPieChart")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.accentGradient)
        }
    }
}

// MARK: - Share sheet

/// 共有前にカードを確認し、テーマを選べるシート。
/// Pro テーマはここが自然なアップセル面になる。
struct ShareCardSheet: View {
    let title: String
    let subtitle: String
    let timeBlocks: [TimeBlock]

    @EnvironmentObject var store: StoreManager
    @Environment(\.dismiss) var dismiss
    @AppStorage("shareCardThemeId") private var themeId: String = ShareCardTheme.cream.id
    @State private var rendered: Image?
    @State private var showPaywall = false

    private var selectedTheme: ShareCardTheme {
        let theme = ShareCardTheme.all.first { $0.id == themeId } ?? .cream
        // Pro を解約・未購入の状態で Pro テーマが残っていても無料テーマに戻す。
        return (theme.isPro && !store.isPro) ? .cream : theme
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 実ビューを scaleEffect で縮めるとレイアウトサイズが変わらず
                // クリップされるため、書き出した画像をそのまま出す（＝WYSIWYG）。
                ScrollView {
                    if let rendered {
                        rendered
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(14)
                            .shadow(color: Theme.cardShadow.opacity(0.25), radius: 14, x: 0, y: 4)
                            .padding(.horizontal, 44)
                            .padding(.vertical, 16)
                    } else {
                        ProgressView().padding(60)
                    }
                }

                themePicker
                    .padding(.horizontal)
                    .padding(.bottom, 12)

                shareButton
                    .padding(.horizontal)
                    .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("share.button")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.cancel") { dismiss() }.foregroundColor(.secondary)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView().environmentObject(store)
            }
            .onAppear(perform: render)
            .onChange(of: themeId) { _ in render() }
            .onChange(of: store.isPro) { _ in render() }
        }
    }

    private var themePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ShareCardTheme.all) { theme in
                    let locked = theme.isPro && !store.isPro
                    Button {
                        if locked { showPaywall = true } else { themeId = theme.id }
                    } label: {
                        VStack(spacing: 5) {
                            ZStack {
                                Circle()
                                    .fill(theme.swatch)
                                    .frame(width: 42, height: 42)
                                    .overlay(
                                        Circle().strokeBorder(
                                            selectedTheme.id == theme.id ? Theme.accent1 : Theme.cardBorder,
                                            lineWidth: selectedTheme.id == theme.id ? 2.5 : 1)
                                    )
                                if locked {
                                    Image(systemName: "lock.fill")
                                        .font(.caption2.weight(.bold))
                                        .foregroundColor(theme.text.opacity(0.7))
                                }
                            }
                            Text(theme.name)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 4)
        }
    }

    @ViewBuilder
    private var shareButton: some View {
        if let rendered {
            ShareLink(
                item: rendered,
                preview: SharePreview(L("share.preview_title", title), image: rendered)
            ) {
                Label("share.button", systemImage: "square.and.arrow.up")
                    .font(.body.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.accentGradient)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: Theme.accent1.opacity(0.35), radius: 10, x: 0, y: 4)
            }
        } else {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
    }

    @MainActor
    private func render() {
        guard !timeBlocks.isEmpty else { rendered = nil; return }
        let renderer = ImageRenderer(
            content: ShareCardView(title: title, subtitle: subtitle,
                                   timeBlocks: timeBlocks, theme: selectedTheme)
        )
        renderer.scale = 3
        if let uiImage = renderer.uiImage {
            rendered = Image(uiImage: uiImage)
        }
    }
}

// MARK: - Toolbar button

struct ShareChartButton: View {
    let title: String
    let subtitle: String
    let timeBlocks: [TimeBlock]

    @EnvironmentObject var store: StoreManager
    @State private var showSheet = false

    var body: some View {
        Button { showSheet = true } label: {
            Image(systemName: "square.and.arrow.up")
        }
        .disabled(timeBlocks.isEmpty)
        .sheet(isPresented: $showSheet) {
            ShareCardSheet(title: title, subtitle: subtitle, timeBlocks: timeBlocks)
                .environmentObject(store)
        }
    }
}
