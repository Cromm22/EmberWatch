import Foundation
import SwiftUI
import UIKit

/// Soft-currency economy (Sparks). Cosmetics / status only — never gates food, water,
/// HealthKit, macros, or calorie tracking. Earn-only in v1 (no IAP packs).
@MainActor
final class SparksManager: ObservableObject {
    // MARK: - Tunable constants (single place)

    static let dailyLoginSparks = 10
    static let levelUpSparks = 25          // per level gained
    static let challengeSparks = 15       // once / friend / day (same cadence as challenge XP)
    static let boardFirstSparks = 50      // once / day when first detected as #1

    /// Premium avatar unlock price (locked styles below).
    static let avatarUnlockPrice = 100

    /// Free styles always available. All others require Sparks unlock.
    static let freeAvatarIds: Set<String> = [
        "classic", "glacier", "aurora", "cobalt", "mint", "ink", "rose", "seafoam", "moss", "lagoon"
    ]

    /// Cosmetic sinks (status only).
    static let cosmetics: [SparkCosmetic] = [
        SparkCosmetic(id: "glow", name: "Ember Glow", detail: "Extra aura bloom on Home", price: 75, icon: "sparkles"),
        SparkCosmetic(id: "nameplate_gold", name: "Gold Nameplate", detail: "Gold companion name tint", price: 50, icon: "tag.fill"),
        SparkCosmetic(id: "nameplate_aurora", name: "Aurora Nameplate", detail: "Aurora gradient name tint", price: 150, icon: "paintpalette.fill")
    ]

    // MARK: - Published state

    @Published private(set) var balance: Int {
        didSet { UserDefaults.standard.set(balance, forKey: Keys.balance) }
    }

    /// Brief toast e.g. "+10 Sparks" or "Need 50 more Sparks".
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

    /// Active nameplate cosmetic id (nil = default cream).
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

    // MARK: - Earn dedupe

    /// yyyy-MM-dd of last daily-login Sparks award
    private var lastDailyLoginDay: String {
        didSet { UserDefaults.standard.set(lastDailyLoginDay, forKey: Keys.lastDailyLoginDay) }
    }

    /// friendId → yyyy-MM-dd of last challenge Sparks award
    private var challengeAwards: [String: String] {
        didSet {
            if let data = try? JSONEncoder().encode(challengeAwards) {
                UserDefaults.standard.set(data, forKey: Keys.challengeAwards)
            }
        }
    }

    /// yyyy-MM-dd of last board-#1 Sparks award
    private var lastBoardFirstDay: String {
        didSet { UserDefaults.standard.set(lastBoardFirstDay, forKey: Keys.lastBoardFirstDay) }
    }

    private enum Keys {
        static let balance = "sparksManager.balance"
        static let unlockedAvatars = "sparksManager.unlockedAvatars"
        static let unlockedCosmetics = "sparksManager.unlockedCosmetics"
        static let activeNameplate = "sparksManager.activeNameplate"
        static let glowEnabled = "sparksManager.glowEnabled"
        static let lastDailyLoginDay = "sparksManager.lastDailyLoginDay"
        static let challengeAwards = "sparksManager.challengeAwards"
        static let lastBoardFirstDay = "sparksManager.lastBoardFirstDay"
    }

    init() {
        let defaults = UserDefaults.standard
        self.balance = max(0, defaults.integer(forKey: Keys.balance))
        let unlocked = defaults.stringArray(forKey: Keys.unlockedAvatars) ?? []
        self.unlockedAvatarIds = Set(unlocked)
        let cosmetics = defaults.stringArray(forKey: Keys.unlockedCosmetics) ?? []
        self.unlockedCosmeticIds = Set(cosmetics)
        self.activeNameplateId = defaults.string(forKey: Keys.activeNameplate)
        self.glowEnabled = defaults.bool(forKey: Keys.glowEnabled)
        self.lastDailyLoginDay = defaults.string(forKey: Keys.lastDailyLoginDay) ?? ""
        self.lastBoardFirstDay = defaults.string(forKey: Keys.lastBoardFirstDay) ?? ""
        if let data = defaults.data(forKey: Keys.challengeAwards),
           let map = try? JSONDecoder().decode([String: String].self, from: data) {
            self.challengeAwards = map
        } else {
            self.challengeAwards = [:]
        }
        
        // Grandfather currently selected avatar so existing picks stay usable.
        let selected = defaults.string(forKey: "selectedAvatarId") ?? "classic"
        if !Self.freeAvatarIds.contains(selected) {
            unlockedAvatarIds.insert(selected)
        }
    }

    // MARK: - Accessors

    func isAvatarUnlocked(_ id: String) -> Bool {
        Self.freeAvatarIds.contains(id) || unlockedAvatarIds.contains(id)
    }

    func isCosmeticUnlocked(_ id: String) -> Bool {
        unlockedCosmeticIds.contains(id)
    }

    var hasGlow: Bool {
        isCosmeticUnlocked("glow") && glowEnabled
    }

    /// Name tint for Home companion label (nil → default cream).
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

    // MARK: - Earn (flat — board XP multiplier does NOT apply)

    @discardableResult
    func earnDailyLogin() -> Int {
        let today = Self.todayKey()
        guard lastDailyLoginDay != today else { return 0 }
        lastDailyLoginDay = today
        return credit(Self.dailyLoginSparks, reason: "dailyLogin")
    }

    /// Award Sparks for each level gained (multi-level = per level).
    @discardableResult
    func earnLevelUp(levelsGained: Int) -> Int {
        let n = max(0, levelsGained)
        guard n > 0 else { return 0 }
        return credit(Self.levelUpSparks * n, reason: "levelUp")
    }

    /// Same rate-limit as challenge XP: once per friend per calendar day.
    @discardableResult
    func earnChallenge(friendId: String) -> Int {
        let today = Self.todayKey()
        if challengeAwards[friendId] == today { return 0 }
        challengeAwards[friendId] = today
        return credit(Self.challengeSparks, reason: "challenge")
    }

    /// Once per day max when first detected as board rank #1 that day.
    @discardableResult
    func earnBoardFirstIfEligible(rank: Int) -> Int {
        guard rank == 1 else { return 0 }
        let today = Self.todayKey()
        guard lastBoardFirstDay != today else { return 0 }
        lastBoardFirstDay = today
        return credit(Self.boardFirstSparks, reason: "boardFirst")
    }

    // MARK: - Spend

    @discardableResult
    func unlockAvatar(_ id: String) -> Bool {
        if isAvatarUnlocked(id) { return true }
        guard AvatarStyle.presets.contains(where: { $0.id == id }) else { return false }
        guard spend(Self.avatarUnlockPrice, label: "avatar") else { return false }
        unlockedAvatarIds.insert(id)
        return true
    }

    @discardableResult
    func unlockCosmetic(_ id: String) -> Bool {
        if isCosmeticUnlocked(id) { return true }
        guard let item = Self.cosmetics.first(where: { $0.id == id }) else { return false }
        guard spend(item.price, label: item.name) else { return false }
        unlockedCosmeticIds.insert(id)
        // Auto-enable on unlock
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

    // MARK: - Internals

    @discardableResult
    private func credit(_ amount: Int, reason: String) -> Int {
        guard amount > 0 else { return 0 }
        balance += amount
        showToast("+\(amount) Sparks")
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        _ = reason
        return amount
    }

    @discardableResult
    private func spend(_ amount: Int, label: String) -> Bool {
        guard amount > 0 else { return true }
        guard balance >= amount else {
            let need = amount - balance
            showToast("Need \(need) more Sparks")
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            return false
        }
        balance -= amount
        showToast("Unlocked — \(amount) Sparks")
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
        let f = DateFormatter()
        f.calendar = Calendar.current
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}

struct SparkCosmetic: Identifiable, Hashable {
    let id: String
    let name: String
    let detail: String
    let price: Int
    let icon: String
}
