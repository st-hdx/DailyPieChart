import StoreKit

// MARK: - Review prompt

/// レビュー依頼を出す場面の管理。OS 側でも年3回までに制限されるが、
/// 「いつ声をかけるか」はこちらで選ぶ必要がある。
/// 作成作業の途中で割り込まないよう、数回使ってからにしている。
enum ReviewPrompt {
    private static let launchCountKey = "reviewLaunchCount"
    private static let promptedVersionKey = "reviewPromptedVersion"
    private static let minimumLaunches = 3

    static var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    static func registerLaunch() {
        let count = UserDefaults.standard.integer(forKey: launchCountKey)
        UserDefaults.standard.set(count + 1, forKey: launchCountKey)
    }

    /// 一日が24時間ちょうどで完成した＝成功体験の直後だけ声をかける。
    static var shouldAsk: Bool {
        UserDefaults.standard.integer(forKey: launchCountKey) >= minimumLaunches
            && UserDefaults.standard.string(forKey: promptedVersionKey) != currentVersion
    }

    static func markAsked() {
        UserDefaults.standard.set(currentVersion, forKey: promptedVersionKey)
    }
}

// MARK: - Purchases

@MainActor
class StoreManager: ObservableObject {
    static let proProductID = "com.dailypiechart.pro"

    // 無料枠が3人だと一覧の半分がロックで埋まり、体験する前に出し渋りの印象が出る。
    // 課金理由は偉人の追加ではなく複数スケジュールと共有カードのテーマ側に置く。
    static let freePersonLimit    = 5
    // スケジュールが1件だけだと、2件目を作ろうとした瞬間に壁が出る。
    // このアプリの価値は「平日と週末を切り替えて持てる」ことなので、
    // それを体験する前に課金を求める形になっていた。計測でも、実ユーザー2人が
    // 日をまたいで無料枠に当たり続けながら購入ボタンに一度も触れていない。
    // 2件持てれば切り替えが成立し、3件目の壁では価値を知った状態になる。
    static let freeScheduleLimit  = 2

    @Published var isPro: Bool = false
    @Published var proProduct: Product? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private var transactionListener: Task<Void, Never>?

    init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await refreshPurchaseStatus()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Load

    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let fetched = try await Product.products(for: [Self.proProductID])
            proProduct = fetched.first
            if proProduct == nil {
                errorMessage = L("error.product_not_found")
            }
        } catch {
            errorMessage = L("error.product_load_failed")
        }
    }

    // MARK: - Purchase

    func purchase() async {
        guard let product = proProduct else { return }
        Analytics.shared.track(AnalyticsEvent.paywallTapped)
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let tx = try checkVerified(verification)
                await refreshPurchaseStatus()
                await tx.finish()
                Analytics.shared.track(AnalyticsEvent.purchaseSucceeded)
            case .userCancelled, .pending:
                // やめたと失敗は分けて数える。一緒にすると、値段の問題なのか
                // 迷いなのか、あとから区別できない。
                Analytics.shared.track(AnalyticsEvent.purchaseCancelled)
            @unknown default:
                break
            }
        } catch {
            Analytics.shared.track(AnalyticsEvent.purchaseFailed)
            errorMessage = L("error.purchase_failed")
        }
    }

    func restorePurchases() async {
        Analytics.shared.track(AnalyticsEvent.restoreTapped)
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await refreshPurchaseStatus()
        } catch {
            errorMessage = L("error.restore_failed")
        }
    }

    // MARK: - Status

    func refreshPurchaseStatus() async {
        var hasPro = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result,
               tx.productID == Self.proProductID,
               tx.revocationDate == nil {
                hasPro = true
            }
        }
        isPro = hasPro
    }

    // MARK: - Helpers

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error): throw error
        case .verified(let value): return value
        }
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task {
            for await result in Transaction.updates {
                if case .verified(let tx) = result {
                    await refreshPurchaseStatus()
                    await tx.finish()
                }
            }
        }
    }
}
