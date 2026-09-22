import Foundation
import StoreKit

/// StoreKit 2 shop for consumable Sparks packs.
/// Credits the wallet only after a verified App Store transaction — never on a
/// placeholder tap when products are missing from App Store Connect.
@MainActor
final class SparksShopStore: ObservableObject {
    @Published private(set) var storeProducts: [Product] = []
    @Published private(set) var isLoading = false
    @Published var statusMessage: String?
    @Published var purchasingProductID: String?

    weak var sparksManager: SparksManager?

    private var updatesTask: Task<Void, Never>?

    private enum Keys {
        static let processedTransactions = "sparksShop.processedTransactionIDs"
    }

    func bind(_ sparks: SparksManager) {
        sparksManager = sparks
        guard updatesTask == nil else { return }
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { break }
                await self.handle(update: result)
            }
        }
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let ids = Set(SparksManager.sparkPacks.map(\.productID))
            storeProducts = try await Product.products(for: ids)
                .sorted { $0.price < $1.price }
        } catch {
            storeProducts = []
            statusMessage = "Unable to load App Store prices right now."
        }
    }

    func product(for pack: SparkPack) -> Product? {
        storeProducts.first { $0.id == pack.productID }
    }

    func purchase(_ pack: SparkPack) async {
        guard let product = product(for: pack) else {
            statusMessage = "This pack isn’t available to purchase yet. App Store products haven’t been configured."
            return
        }
        purchasingProductID = pack.productID
        defer { purchasingProductID = nil }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try Self.verified(verification)
                await fulfill(transaction, expectedPack: pack)
            case .userCancelled:
                break
            case .pending:
                statusMessage = "Purchase is pending approval."
            @unknown default:
                break
            }
        } catch {
            statusMessage = "Purchase couldn’t be completed."
        }
    }

    // MARK: - Internals

    private func handle(update result: VerificationResult<Transaction>) async {
        guard let transaction = try? Self.verified(result) else { return }
        await fulfill(transaction)
    }

    private func fulfill(_ transaction: Transaction, expectedPack: SparkPack? = nil) async {
        if Self.isProcessed(transaction.id) {
            await transaction.finish()
            return
        }

        let pack = expectedPack ?? SparksManager.sparkPacks.first {
            $0.productID == transaction.productID
        }
        guard let pack else {
            await transaction.finish()
            return
        }
        guard let sparksManager else { return }

        sparksManager.creditPurchasedSparks(pack.sparks)
        Self.markProcessed(transaction.id)
        await transaction.finish()
        statusMessage = "+\(pack.sparks) Sparks added"
    }

    private static func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let value):
            return value
        }
    }

    private static func isProcessed(_ id: Transaction.ID) -> Bool {
        let stored = UserDefaults.standard.stringArray(forKey: Keys.processedTransactions) ?? []
        return stored.contains(String(describing: id))
    }

    private static func markProcessed(_ id: Transaction.ID) {
        var stored = UserDefaults.standard.stringArray(forKey: Keys.processedTransactions) ?? []
        let key = String(describing: id)
        guard !stored.contains(key) else { return }
        stored.append(key)
        UserDefaults.standard.set(stored, forKey: Keys.processedTransactions)
    }

    private enum StoreError: Error {
        case failedVerification
    }
}
