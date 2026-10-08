import Foundation
import SwiftUI
import UIKit

/// Crystals (premium, formerly Sparks) + Coins (gameplay). Cosmetics / status only —
/// never gates food, water, HealthKit, macros, or calorie tracking.
/// Existing Sparks balances migrate 1:1 to Crystals via the same UserDefaults key.
@MainActor
final class SparksManager: ObservableObject {
    static let challengeCoins = XPRules.challengeCoins
    static let boardFirstCoins = XPRules.boardFirstCoins
    static let avatarUnlockPrice = XPRules.avatarUnlockCoins
    static let avatarUnlockCurrency = ShopCurrency.coins

    static let freeAvatarIds: Set<String> = [
        "classic", "glacier", "aurora", "cobalt", "mint", "ink", "rose", "seafoam", "moss", "lagoon"
    ]

    /// Premium cosmetics priced in Crystals.
    static let cosmetics: [SparkCosmetic] = [
        SparkCosmetic(id: "glow", name: "Ember Glow", detail: "Extra aura bloom on Home", price: 75, currency: .crystals, icon: "sparkles"),
        SparkCosmetic(id: "nameplate_gold", name: "Gold Nameplate", detail: "Gold companion name tint", price: 50, currency: .crystals, icon: "tag.fill"),
        SparkCosmetic(id: "nameplate_aurora", name: "Aurora Nameplate", detail: "Aurora gradient name tint", price: 150, currency: .crystals, icon: "paintpalette.fill")
    ]

    /// StoreKit product IDs must match App Store Connect; UI still lists packs when products are missing.
    static let crystalPacks: [CrystalPack] = [
        CrystalPack(
            productID: "com.ember.watch.crystals.500",
            name: "Crystal Cache",
            detail: "A handful of premium sparkle",
            crystals: 500,
            placeholderPrice: "$4.99",
            badge: nil,
            icon: "diamond"
        ),
        CrystalPack(
            productID: "com.ember.watch.crystals.1100",
            name: "Crystal Vault",
            detail: "Best for a new prestige look",
            crystals: 1_100,
            placeholderPrice: "$9.99",
            badge: "Popular",
            icon: "diamond.fill"
        ),
        CrystalPack(
            productID: "com.ember.watch.crystals.2400",
            name: "Crystal Crown",
            detail: "Best crystals per dollar",
            crystals: 2_400,
            placeholderPrice: "$19.99",
            badge: "Best Value",
            icon: "crown.fill"
        )
    ]

    /// Crystals balance. Same key as the former Sparks wallet (1:1 migrate).
    @Published private(set) var balance: Int {
        didSet { UserDefaults.standard.set(balance, forKey: Keys.crystals) }
    }

    var crystals: Int { balance }

    @Published private(set) var coins: Int {
        didSet { UserDefaults.standard.set(coins, forKey: Keys.coins) }
    }

    @Published var toast: String? = nil

    @Published private(set) var unlockedAvatarIds: Set<String> {
        didSet {
            UserDefaults.standard.set(Array(unlockedAvatarIds), forKey: Keys.unlockedAvatars)
        }
    }

    @Published private(set) var unlockedCosmeticIds: Set<String> {
        didSet {
            UserDefaults.standard.set(Array(unlockedCosmeticIds), forKey: Keys.unlockedCosmetics)
        }
    }

    @Published var activeNameplateId: String? {
        didSet {
            if let id = activeNameplateId {
                UserDefaults.standard.set(id, forKey: Keys.activeNameplate)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.activeNameplate)
            }
        }
    }

    @Published var glowEnabled: Bool {
        didSet { UserDefaults.standard.set(glowEnabled, forKey: Keys.glowEnabled) }
    }

    private var challengeAwards: [String: String] {
        didSet {
            if let data = try? JSONEncoder().encode(challengeAwards) {
                UserDefaults.standard.set(data, forKey: Keys.challengeAwards)
            }
        }
    }

    private var lastBoardFirstDay: String {
        didSet { UserDefaults.standard.set(lastBoardFirstDay, forKey: Keys.lastBoardFirstDay) }
    }

    private enum Keys {
        static let crystals = "sparksManager.balance"
        static let coins = "sparksManager.coins"
        static let unlockedAvatars = "sparksManager.unlockedAvatars"
        static let unlockedCosmetics = "sparksManager.unlockedCosmetics"
        static let activeNameplate = "sparksManager.activeNameplate"
        static let glowEnabled = "sparksManager.glowEnabled"
        static let challengeAwards = "sparksManager.challengeAwards"
        static let lastBoardFirstDay = "sparksManager.lastBoardFirstDay"
    }

    init() {
        let defaults = UserDefaults.standard
        self.balance = max(0, defaults.integer(forKey: Keys.crystals))
        self.coins = max(0, defaults.integer(forKey: Keys.coins))
        let unlocked = defaults.stringArray(forKey: Keys.unlockedAvatars) ?? []
        self.unlockedAvatarIds = Set(unlocked)
        let cosmetics = defaults.stringArray(forKey: Keys.unlockedCosmetics) ?? []
        self.unlockedCosmeticIds = Set(cosmetics)
        self.activeNameplateId = defaults.string(forKey: Keys.activeNameplate)
        self.glowEnabled = defaults.bool(forKey: Keys.glowEnabled)
        self.lastBoardFirstDay = defaults.string(forKey: Keys.lastBoardFirstDay) ?? ""
        if let data = defaults.data(forKey: Keys.challengeAwards),
           let map = try? JSONDecoder().decode([String: String].self, from: data) {
            self.challengeAwards = map
        } else {
            self.challengeAwards = [:]
        }

        let selected = defaults.string(forKey: "selectedAvatarId") ?? "classic"
        if !Self.freeAvatarIds.contains(selected) {
            unlockedAvatarIds.insert(selected)
        }
    }

    func isAvatarUnlocked(_ id: String) -> Bool {
        Self.freeAvatarIds.contains(id) || unlockedAvatarIds.contains(id)
    }

    func isCosmeticUnlocked(_ id: String) -> Bool {
        unlockedCosmeticIds.contains(id)
    }

    var hasGlow: Bool {
        isCosmeticUnlocked("glow") && glowEnabled
    }

    var nameplateColor: Color? {
        switch activeNameplateId {
        case "nameplate_gold" where isCosmeticUnlocked("nameplate_gold"):
            return EmberColors.gold
        case "nameplate_aurora" where isCosmeticUnlocked("nameplate_aurora"):
            return Color(hex: "#34d399")
        default:
            return nil
        }
    }

    func canChallenge(friendId: String) -> Bool {
        challengeAwards[friendId] != Self.todayKey()
    }

    /// Coins for a friend challenge; once per friend per calendar day. No XP.
    @discardableResult
    func earnChallenge(friendId: String) -> Int {
        let today = Self.todayKey()
        if challengeAwards[friendId] == today { return 0 }
        challengeAwards[friendId] = today
        return earnCoins(Self.challengeCoins, reason: "challenge")
    }

    /// Coins once per day when first detected as board rank #1.
    @discardableResult
    func earnBoardFirstIfEligible(rank: Int) -> Int {
        guard rank == 1 else { return 0 }
        let today = Self.todayKey()
        guard lastBoardFirstDay != today else { return 0 }
        lastBoardFirstDay = today
        return earnCoins(Self.boardFirstCoins, reason: "boardFirst")
    }

    @discardableResult
    func earnLevelUpCoins(toLevel newLevel: Int) -> Int {
        earnCoins(XPRules.coinsForLevelUp(to: newLevel), reason: "levelUp", toast: false)
    }

    @discardableResult
    func earnMilestoneCrystals(forLevel level: Int) -> Int {
        let amount = XPRules.milestoneCrystals(forLevel: level)
        guard amount > 0 else { return 0 }
        return creditCrystals(amount, reason: "milestone", toast: false)
    }

    @discardableResult
    func earnCoins(_ amount: Int, reason: String, toast: Bool = true) -> Int {
        guard amount > 0 else { return 0 }
        coins += amount
        if toast {
            showToast("+\(amount) Coins")
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        _ = reason
        return amount
    }

    @discardableResult
    func unlockAvatar(_ id: String) -> Bool {
        if isAvatarUnlocked(id) { return true }
        guard AvatarStyle.presets.contains(where: { $0.id == id }) else { return false }
        guard spendCoins(Self.avatarUnlockPrice, label: "avatar") else { return false }
        unlockedAvatarIds.insert(id)
        return true
    }

    @discardableResult
    func unlockCosmetic(_ id: String) -> Bool {
        if isCosmeticUnlocked(id) { return true }
        guard let item = Self.cosmetics.first(where: { $0.id == id }) else { return false }
        let spent: Bool
        switch item.currency {
        case .crystals:
            spent = spendCrystals(item.price, label: item.name)
        case .coins:
            spent = spendCoins(item.price, label: item.name)
        }
        guard spent else { return false }
        unlockedCosmeticIds.insert(id)
        if id == "glow" {
            glowEnabled = true
        } else if id.hasPrefix("nameplate_") {
            activeNameplateId = id
        }
        return true
    }

    func toggleGlow() {
        guard isCosmeticUnlocked("glow") else { return }
        glowEnabled.toggle()
    }

    func selectNameplate(_ id: String?) {
        if let id {
            guard isCosmeticUnlocked(id) else { return }
        }
        activeNameplateId = id
    }

    /// Credit Crystals after a verified StoreKit purchase. Never call from a placeholder tap.
    @discardableResult
    func creditPurchasedCrystals(_ amount: Int) -> Int {
        creditCrystals(amount, reason: "iap")
    }

    // MARK: - Internals

    @discardableResult
    private func creditCrystals(_ amount: Int, reason: String, toast: Bool = true) -> Int {
        guard amount > 0 else { return 0 }
        balance += amount
        if toast {
            showToast("+\(amount) Crystals")
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        _ = reason
        return amount
    }

    @discardableResult
    private func spendCrystals(_ amount: Int, label: String) -> Bool {
        guard amount > 0 else { return true }
        guard balance >= amount else {
            let need = amount - balance
            showToast("Need \(need) more Crystals")
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            return false
        }
        balance -= amount
        showToast("Unlocked — \(amount) Crystals")
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        _ = label
        return true
    }

    @discardableResult
    private func spendCoins(_ amount: Int, label: String) -> Bool {
        guard amount > 0 else { return true }
        guard coins >= amount else {
            let need = amount - coins
            showToast("Need \(need) more Coins")
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            return false
        }
        coins -= amount
        showToast("Unlocked — \(amount) Coins")
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        _ = label
        return true
    }

    private func showToast(_ message: String) {
        toast = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) { [weak self] in
            if self?.toast == message {
                self?.toast = nil
            }
        }
    }

    private static func todayKey() -> String {
        XPRules.dayKey()
    }
}

struct SparkCosmetic: Identifiable, Hashable {
    let id: String
    let name: String
    let detail: String
    let price: Int
    let currency: ShopCurrency
    let icon: String
}

struct CrystalPack: Identifiable, Hashable {
    var id: String { productID }
    let productID: String
    let name: String
    let detail: String
    let crystals: Int
    let placeholderPrice: String
    let badge: String?
    let icon: String
}
