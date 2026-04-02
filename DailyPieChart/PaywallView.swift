import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var store: StoreManager
    @Environment(\.dismiss) var dismiss

    var priceLabel: String {
        guard let product = store.proProduct else { return "" }
        return product.displayPrice
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                VStack(spacing: 0) {
                    header
                    featureList
                    purchaseSection
                }
            }
            .background(Theme.background)
            .onAppear {
                if store.proProduct == nil {
                    Task { await store.loadProducts() }
                }
            }

            // Close button
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Theme.accent1.opacity(0.25), Theme.accent2.opacity(0.25)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 100)
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 46))
                    .foregroundStyle(Theme.accentGradient)
            }
            .padding(.top, 48)

            Text("DailyPieChart Pro")
                .font(.title2.bold())
                .foregroundColor(Theme.textWarm)

            Text("偉人の習慣をもっと深く学び\n自分だけのスケジュールを作ろう")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.horizontal)
        .padding(.bottom, 32)
    }

    // MARK: - Features

    private var featureList: some View {
        VStack(spacing: 12) {
            featureRow(
                icon: "person.3.fill",
                color: Color(red: 0.22, green: 0.42, blue: 0.85),
                title: "全偉人データを閲覧",
                subtitle: "無料版3人 → 全\(samplePersons.count)人に拡張"
            )
            featureRow(
                icon: "calendar.badge.plus",
                color: Theme.accent1,
                title: "スケジュールを無制限に作成",
                subtitle: "平日・週末・旅行中など使い分け自由"
            )
            featureRow(
                icon: "sparkles",
                color: Color(red: 0.60, green: 0.28, blue: 0.70),
                title: "今後追加される偉人も利用可能",
                subtitle: "アップデートで随時追加予定"
            )
        }
        .padding(.horizontal)
        .padding(.bottom, 32)
    }

    private func featureRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.body.weight(.semibold))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Theme.textWarm)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color(red: 0.28, green: 0.62, blue: 0.40))
        }
        .padding()
        .background(Theme.card)
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.cardBorder, lineWidth: 1))
        .cornerRadius(14)
        .shadow(color: Theme.cardShadow.opacity(0.10), radius: 6, x: 0, y: 2)
    }

    // MARK: - Purchase

    private var purchaseSection: some View {
        VStack(spacing: 14) {
            // Buy button
            Button {
                Task {
                    if store.proProduct == nil {
                        await store.loadProducts()
                    } else {
                        await store.purchase()
                    }
                }
            } label: {
                Group {
                    if store.isLoading {
                        ProgressView().tint(.white)
                    } else if store.proProduct == nil {
                        Label("再試行する", systemImage: "arrow.clockwise")
                            .font(.body.weight(.bold))
                    } else {
                        Text("買い切り \(priceLabel) で解放する")
                            .font(.body.weight(.bold))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(store.proProduct == nil ? AnyShapeStyle(Color.gray.opacity(0.3)) : AnyShapeStyle(Theme.accentGradient))
                .foregroundColor(store.proProduct == nil ? .secondary : .white)
                .cornerRadius(16)
                .shadow(color: store.proProduct == nil ? .clear : Theme.accent1.opacity(0.40), radius: 12, x: 0, y: 4)
            }
            .disabled(store.isLoading || store.proProduct == nil)

            // Restore
            Button {
                Task { await store.restorePurchases() }
            } label: {
                Text("購入を復元する")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .disabled(store.isLoading)

            if let error = store.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(Theme.accent2)
                    .multilineTextAlignment(.center)
            }

            Text("一度購入すれば永久に利用できます。\nサブスクリプションではありません。")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
        .padding(.bottom, 40)
    }
}
