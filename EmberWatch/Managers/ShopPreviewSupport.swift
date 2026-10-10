import Foundation
import SwiftUI

/// Try-before-you-buy target. IDs only so this stays Sendable / Hashable
/// without copying `AvatarStyle`.
enum ShopPreviewSubject: Hashable, Identifiable, Sendable {
    case cosmetic(String)
    case avatar(String)
    case equipment(String)

    var id: String {
        switch self {
        case .cosmetic(let id):
            return "cosmetic.\(id)"
        case .avatar(let id):
            return "avatar.\(id)"
        case .equipment(let id):
            return "equipment.\(id)"
        }
    }
}

extension ShopCurrency {
    var displayName: String {
        switch self {
        case .coins: return "Coins"
        case .crystals: return "Crystals"
        }
    }
}

/// Shared cosmetic look-up tables. File-level so Swift 6 does not isolate
/// these on MainActor with the shop views. Never writes UserDefaults.
enum ShopLookTokens {
    static func backgroundHex(for id: String?) -> String? {
        switch id {
        case ShopCatalog.noneBackgroundId:
            return nil
        case "bg.dawn": return "#FFE4C8"
        case "bg.forest": return "#DCFCE7"
        case "bg.city": return "#DBEAFE"
        case "bg.hearth": return "#FFEDD5"
        case "bg.glacier": return "#E0F2FE"
        case "bg.studio": return "#F5F5F4"
        default:
            return nil
        }
    }

    static func themeAccentHex(for id: String) -> String {
        switch id {
        case "theme.midnight": return "#F59E0B"
        case "theme.meadow": return "#22C55E"
        case "theme.ocean": return "#14B8A6"
        case "theme.candy": return "#F472B6"
        default: return "#FF7A3C"
        }
    }

    static func themeAccent(for id: String) -> Color {
        Color(hex: themeAccentHex(for: id))
    }

    static func emoteIconName(for id: String?) -> String? {
        switch id {
        case "emote.wave": return "hand.wave.fill"
        case "emote.cheer": return "hands.clap.fill"
        case "emote.flex": return "figure.strengthtraining.traditional"
        case "emote.sparkle": return "sparkle"
        case "emote.sleepy": return "moon.zzz.fill"
        case "emote.heart": return "heart.fill"
        default: return nil
        }
    }

    /// Preview tint. Ownership is enforced by the shop, not this table.
    static func nameplateColor(for id: String?) -> Color? {
        switch id {
        case "nameplate_gold":
            return EmberColors.gold
        case "nameplate_aurora":
            return Color(hex: "#34d399")
        default:
            return nil
        }
    }

    static func cardFill(backgroundId: String?, themeId: String) -> Color {
        if backgroundId == ShopCatalog.noneBackgroundId {
            return .clear
        }
        if let hex = backgroundHex(for: backgroundId) {
            return Color(hex: hex)
        }
        switch themeId {
        case "theme.midnight":
            return Color(hex: "#1E1B16")
        case "theme.meadow":
            return Color(hex: "#ECFDF5")
        case "theme.ocean":
            return Color(hex: "#ECFEFF")
        case "theme.candy":
            return Color(hex: "#FDF2F8")
        default:
            return EmberColors.lightPlum
        }
    }

    static func usesLightFill(backgroundId: String?, themeId: String) -> Bool {
        if backgroundId == ShopCatalog.noneBackgroundId { return true }
        if backgroundHex(for: backgroundId) != nil { return true }
        switch themeId {
        case "theme.meadow", "theme.ocean", "theme.candy":
            return true
        default:
            return false
        }
    }

    static func identityColor(
        nameplateId: String?,
        backgroundId: String?,
        themeId: String
    ) -> Color {
        if let plate = nameplateColor(for: nameplateId) {
            return plate
        }
        if usesLightFill(backgroundId: backgroundId, themeId: themeId) {
            return EmberColors.ink
        }
        if themeId == "theme.midnight" {
            return Color(hex: themeAccentHex(for: themeId))
        }
        return EmberColors.cream
    }

    static func rarity(forCosmetic item: CosmeticShopItem) -> ItemRarity {
        if item.currency == .crystals {
            if item.price >= 150 { return .legendary }
            if item.price >= 120 { return .epic }
            if item.price >= 70 { return .rare }
            return .uncommon
        }
        if item.price <= 0 { return .common }
        if item.price <= 50 { return .common }
        if item.price <= 90 { return .uncommon }
        if item.price <= 120 { return .rare }
        return .epic
    }

    @MainActor
    static func rarity(forAvatarId id: String) -> ItemRarity {
        SparksManager.freeAvatarIds.contains(id) ? .common : .uncommon
    }
}

struct ShopPreviewDetails: Equatable {
    let name: String
    let rarity: ItemRarity
    let price: Int
    let currency: ShopCurrency
    let detail: String

    @MainActor
    static func resolve(_ subject: ShopPreviewSubject) -> ShopPreviewDetails? {
        switch subject {
        case .cosmetic(let id):
            guard let item = ShopCatalog.item(id: id) else { return nil }
            return ShopPreviewDetails(
                name: item.name,
                rarity: ShopLookTokens.rarity(forCosmetic: item),
                price: item.price,
                currency: item.currency,
                detail: item.detail
            )
        case .avatar(let id):
            guard let style = AvatarStyle.presets.first(where: { $0.id == id }) else {
                return nil
            }
            let free = SparksManager.freeAvatarIds.contains(id)
            return ShopPreviewDetails(
                name: style.name,
                rarity: ShopLookTokens.rarity(forAvatarId: id),
                price: free ? 0 : SparksManager.avatarUnlockPrice,
                currency: SparksManager.avatarUnlockCurrency,
                detail: "Basic companion colorway"
            )
        case .equipment(let id):
            guard let item = EquipmentCatalog.item(id: id) else { return nil }
            return ShopPreviewDetails(
                name: item.name,
                rarity: item.rarity,
                price: item.price,
                currency: item.currency,
                detail: item.detail
            )
        }
    }
}

/// Value snapshot of the Home hero. Overlaying a shop item mutates only
/// this copy — never `CompanionManager` / `SparksManager` persistence.
struct HomeHeroLook {
    var heroImageName: String?
    var heroAccessibilityName: String
    var extraGlow: Bool
    var hasChosenCompanion: Bool
    var species: CompanionSpecies
    var stage: CompanionStage
    var tier: ProgressionTier
    var equipped: [EquipmentSlot: EquipmentItem]
    var effectId: String?
    var prestigeSkinId: String?
    var level: Int
    var progressFraction: Double
    var style: AvatarStyle
    var backgroundId: String?
    var themeId: String
    var emoteId: String?
    var nameplateId: String?
    var displayName: String

    @MainActor
    static func snapshot(
        avatar: AvatarManager,
        companion: CompanionManager,
        sparks: SparksManager,
        level: LevelManager,
        character: CharacterManager
    ) -> HomeHeroLook {
        HomeHeroLook(
            heroImageName: character.selectedBuild?.heroImageName,
            heroAccessibilityName: character.selectedBuild?.displayName ?? "Hero",
            extraGlow: sparks.hasGlow,
            hasChosenCompanion: companion.hasChosenCompanion,
            species: companion.resolvedSpecies,
            stage: companion.stage(forLevel: level.level),
            tier: companion.tier(forLevel: level.level),
            equipped: companion.equippedMap(),
            effectId: companion.activeEffectId,
            prestigeSkinId: companion.activePrestigeSkinId,
            level: level.level,
            progressFraction: level.progressFraction,
            style: avatar.selectedStyle,
            backgroundId: companion.activeBackgroundId,
            themeId: companion.activeThemeId,
            emoteId: companion.activeEmoteId,
            nameplateId: sparks.activeNameplateId,
            displayName: avatar.displayName
        )
    }

    func applying(_ subject: ShopPreviewSubject) -> HomeHeroLook {
        var next = self
        next.apply(subject)
        return next
    }

    private mutating func apply(_ subject: ShopPreviewSubject) {
        switch subject {
        case .cosmetic(let id):
            applyCosmetic(id)
        case .avatar(let id):
            if let style = AvatarStyle.presets.first(where: { $0.id == id }) {
                self.style = style
            }
            revealFlameBody()
        case .equipment(let id):
            if let item = EquipmentCatalog.item(id: id) {
                equipped[item.slot] = item
            }
            revealCompanionBody()
        }
    }

    private mutating func applyCosmetic(_ id: String) {
        guard let item = ShopCatalog.item(id: id) else { return }
        switch item.category {
        case .backgrounds:
            backgroundId = item.id
        case .themes:
            themeId = item.id
        case .emotes:
            emoteId = item.id
        case .effects:
            effectId = item.id
            revealCompanionBody()
        case .premium:
            applyPremium(item)
        case .equipment, .skins:
            break
        }
    }

    private mutating func applyPremium(_ item: CosmeticShopItem) {
        if item.id == "glow" {
            extraGlow = true
            revealCompanionBody()
            return
        }
        if item.id.hasPrefix("nameplate_") {
            nameplateId = item.id
            return
        }
        if item.id.hasPrefix("skin.") {
            prestigeSkinId = item.id
            revealCompanionBody()
        }
    }

    /// Hero art hides companion cosmetics. Drop it so the preview can show
    /// the item on `CompanionAvatarView` — same renderer Home uses.
    private mutating func revealCompanionBody() {
        heroImageName = nil
        hasChosenCompanion = true
    }

    /// Basic colorways paint `EmberFlameAvatar`. Hide hero / companion so
    /// the skin is visible.
    private mutating func revealFlameBody() {
        heroImageName = nil
        hasChosenCompanion = false
    }
}
