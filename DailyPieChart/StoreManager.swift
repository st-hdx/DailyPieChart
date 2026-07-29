import StoreKit

@MainActor
class StoreManager: ObservableObject {
    static let proProductID = "com.dailypiechart.pro"

    // 無料枠が3人だと一覧の半分がロックで埋まり、体験する前に出し渋りの印象が出る。
    // 課金理由は偉人の追加ではなく複数スケジュールと共有カードのテーマ側に置く。
    static let freePersonLimit    = 5
    static let freeScheduleLimit  = 1

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
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = L("error.purchase_failed")
        }
    }

    func restorePurchases() async {
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
