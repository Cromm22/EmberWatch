import Foundation
import SwiftUI

/// Persists companion species, equipped cosmetics, and shop ownership.
/// Does not write food, workout, or HealthKit data.
@MainActor
final class CompanionManager: ObservableObject {
    @Published private(set) var selectedSpecies: CompanionSpecies? {
        didSet {
            if let selectedSpecies {
                UserDefaults.standard.set(selectedSpecies.rawValue, forKey: Keys.species)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.species)
            }
        }
    }

    @Published private(set) var equippedBySlot: [EquipmentSlot: String] {
        didSet { persistEquipped() }
    }

    @Published private(set) var ownedItemIds: Set<String> {
        didSet {
            UserDefaults.standard.set(Array(ownedItemIds), forKey: Keys.ownedItems)
        }
    }

    @Published private(set) var ownedCosmeticIds: Set<String> {
        didSet {
            UserDefaults.standard.set(Array(ownedCosmeticIds), forKey: Keys.ownedCosmetics)
        }
    }

    @Published var activeBackgroundId: String? {
        didSet { persistOptional(activeBackgroundId, key: Keys.activeBackground) }
    }

    @Published var activeThemeId: String {
        didSet { UserDefaults.standard.set(activeThemeId, forKey: Keys.activeTheme) }
    }

    @Published var activeEmoteId: String? {
        didSet { persistOptional(activeEmoteId, key: Keys.activeEmote) }
    }

    @Published var activeEffectId: String? {
        didSet { persistOptional(activeEffectId, key: Keys.activeEffect) }
    }

    @Published var activePrestigeSkinId: String? {
        didSet { persistOptional(activePrestigeSkinId, key: Keys.activePrestigeSkin) }
    }

    @Published private(set) var lastCelebratedStage: CompanionStage? {
        didSet { persistOptional(lastCelebratedStage?.rawValue, key: Keys.lastCelebratedStage) }
    }

    @Published var pendingEvolution: CompanionStage?

    private enum Keys {
        static let species = "companionManager.species"
        static let equipped = "companionManager.equipped.v1"
        static let ownedItems = "companionManager.ownedItems.v1"
        static let ownedCosmetics = "companionManager.ownedCosmetics.v1"
        static let activeBackground = "companionManager.activeBackground"
        static let activeTheme = "companionManager.activeTheme"
        static let activeEmote = "companionManager.activeEmote"
        static let activeEffect = "companionManager.activeEffect"
        static let activePrestigeSkin = "companionManager.activePrestigeSkin"
        static let lastCelebratedStage = "companionManager.lastCelebratedStage"
    }

    init() {
        let defaults = UserDefaults.standard
        self.selectedSpecies = CompanionSpecies.parse(defaults.string(forKey: Keys.species))

        if let data = defaults.data(forKey: Keys.equipped),
           let raw = try? JSONDecoder().decode([String: String].self, from: data) {
            var map: [EquipmentSlot: String] = [:]
            for (key, value) in raw {
                if let slot = EquipmentSlot(rawValue: key) {
                    map[slot] = value
                }
            }
            self.equippedBySlot = map
        } else {
            self.equippedBySlot = [:]
        }

        let owned = defaults.stringArray(forKey: Keys.ownedItems) ?? []
        self.ownedItemIds = Set(owned)

        let cosmetics = defaults.stringArray(forKey: Keys.ownedCosmetics) ?? []
        self.ownedCosmeticIds = Set(cosmetics)

        self.activeBackgroundId = defaults.string(forKey: Keys.activeBackground)
        self.activeThemeId = defaults.string(forKey: Keys.activeTheme) ?? "theme.classic"
        self.activeEmoteId = defaults.string(forKey: Keys.activeEmote)
        self.activeEffectId = defaults.string(forKey: Keys.activeEffect)
        self.activePrestigeSkinId = defaults.string(forKey: Keys.activePrestigeSkin)
        self.lastCelebratedStage = CompanionStage.parse(defaults.string(forKey: Keys.lastCelebratedStage))

        if ownedCosmeticIds.contains("theme.classic") == false {
            ownedCosmeticIds.insert("theme.classic")
        }
    }

    var hasChosenCompanion: Bool {
        selectedSpecies != nil
    }

    var resolvedSpecies: CompanionSpecies {
        selectedSpecies ?? .babyDragon
    }

    func selectSpecies(_ species: CompanionSpecies, level: Int) {
        selectedSpecies = species
        if lastCelebratedStage == nil {
            lastCelebratedStage = CompanionStage.current(forLevel: level)
        }
        grantFreeUnlocks(level: level)
    }

    func stage(forLevel level: Int) -> CompanionStage {
        CompanionStage.current(forLevel: level)
    }

    func tier(forLevel level: Int) -> ProgressionTier {
        ProgressionTier.current(forLevel: level)
    }

    func equippedItem(for slot: EquipmentSlot) -> EquipmentItem? {
        guard let id = equippedBySlot[slot] else { return nil }
        return EquipmentCatalog.item(id: id)
    }

    func equippedMap() -> [EquipmentSlot: EquipmentItem] {
        var map: [EquipmentSlot: EquipmentItem] = [:]
        for slot in EquipmentSlot.allCases {
            if let item = equippedItem(for: slot) {
                map[slot] = item
            }
        }
        return map
    }

    func isItemOwned(_ id: String) -> Bool {
        ownedItemIds.contains(id)
    }

    func isCosmeticOwned(_ id: String) -> Bool {
        ownedCosmeticIds.contains(id)
    }

    func isEquipped(_ id: String) -> Bool {
        equippedBySlot.values.contains(id)
    }

    func grantFreeUnlocks(level: Int) {
        var next = ownedItemIds
        for item in EquipmentCatalog.freeUnlocks(atLevel: level) {
            next.insert(item.id)
        }
        if next != ownedItemIds {
            ownedItemIds = next
        }
        applyStarterLoadoutIfNeeded()
    }

    /// Existing users already past a stage should not get a backlog of
    /// evolution sheets. Seed quietly, then only celebrate later crossings.
    func noteCurrentStageWithoutCelebrating(level: Int) {
        guard lastCelebratedStage == nil else { return }
        lastCelebratedStage = CompanionStage.current(forLevel: level)
    }

    /// Returns a newly crossed stage so Home / ContentView can celebrate.
    @discardableResult
    func checkEvolution(level: Int) -> CompanionStage? {
        grantFreeUnlocks(level: level)
        let current = CompanionStage.current(forLevel: level)
        guard let last = lastCelebratedStage else {
            lastCelebratedStage = current
            return nil
        }
        if current > last {
            lastCelebratedStage = current
            pendingEvolution = current
            return current
        }
        return nil
    }

    func clearPendingEvolution() {
        pendingEvolution = nil
    }

    @discardableResult
    func purchaseEquipment(_ item: EquipmentItem, wallet: SparksManager, level: Int) -> Bool {
        if ownedItemIds.contains(item.id) { return true }
        if item.isGranted(atLevel: level) {
            ownedItemIds.insert(item.id)
            return true
        }
        guard item.isBuyable else { return false }
        guard wallet.spend(amount: item.price, currency: item.currency, label: item.name) else {
            return false
        }
        ownedItemIds.insert(item.id)
        return true
    }

    @discardableResult
    func purchaseCosmetic(_ item: CosmeticShopItem, wallet: SparksManager) -> Bool {
        if ownedCosmeticIds.contains(item.id) { return true }
        if item.price <= 0 {
            ownedCosmeticIds.insert(item.id)
            activateCosmetic(item)
            return true
        }
        guard wallet.spend(amount: item.price, currency: item.currency, label: item.name) else {
            return false
        }
        ownedCosmeticIds.insert(item.id)
        activateCosmetic(item)
        return true
    }

    func equip(_ item: EquipmentItem) {
        guard ownedItemIds.contains(item.id) else { return }
        var next = equippedBySlot
        next[item.slot] = item.id
        equippedBySlot = next
    }

    func unequip(slot: EquipmentSlot) {
        var next = equippedBySlot
        next[slot] = nil
        equippedBySlot = next
    }

    func toggleEquip(_ item: EquipmentItem) {
        guard ownedItemIds.contains(item.id) else { return }
        if equippedBySlot[item.slot] == item.id {
            unequip(slot: item.slot)
        } else {
            equip(item)
        }
    }

    func activateCosmetic(_ item: CosmeticShopItem) {
        guard ownedCosmeticIds.contains(item.id) else { return }
        switch item.category {
        case .backgrounds:
            activeBackgroundId = item.id
        case .themes:
            activeThemeId = item.id
        case .emotes:
            activeEmoteId = item.id
        case .effects:
            activeEffectId = item.id
        case .premium:
            if item.id.hasPrefix("skin.") {
                activePrestigeSkinId = item.id
            }
        case .equipment, .skins:
            break
        }
    }

    func clearPrestigeSkin() {
        activePrestigeSkinId = nil
    }

    func backgroundHex() -> String? {
        switch activeBackgroundId {
        case "bg.dawn": return "#FFE4C8"
        case "bg.forest": return "#DCFCE7"
        case "bg.city": return "#DBEAFE"
        case "bg.hearth": return "#FFEDD5"
        case "bg.glacier": return "#E0F2FE"
        case "bg.studio": return "#F5F5F4"
        default: return nil
        }
    }

    // MARK: - Internals

    private func applyStarterLoadoutIfNeeded() {
        guard equippedBySlot.isEmpty else { return }
        var next: [EquipmentSlot: String] = [:]
        let starters = [
            "head.soft_cap",
            "chest.cotton_shirt",
            "hands.cloth_wraps",
            "legs.simple_pants",
            "feet.soft_slippers"
        ]
        for id in starters {
            guard ownedItemIds.contains(id), let item = EquipmentCatalog.item(id: id) else { continue }
            next[item.slot] = id
        }
        if !next.isEmpty {
            equippedBySlot = next
        }
    }

    private func persistEquipped() {
        var raw: [String: String] = [:]
        for (slot, id) in equippedBySlot {
            raw[slot.rawValue] = id
        }
        if let data = try? JSONEncoder().encode(raw) {
            UserDefaults.standard.set(data, forKey: Keys.equipped)
        }
    }

    private func persistOptional(_ value: String?, key: String) {
        if let value, !value.isEmpty {
            UserDefaults.standard.set(value, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}
