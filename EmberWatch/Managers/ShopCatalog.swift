import Foundation

enum ShopCategory: String, CaseIterable, Sendable, Identifiable {
    case equipment
    case backgrounds
    case skins
    case emotes
    case themes
    case effects
    case premium

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .equipment: return "Equipment"
        case .backgrounds: return "Backgrounds"
        case .skins: return "Companion skins"
        case .emotes: return "Emotes"
        case .themes: return "Themes"
        case .effects: return "Character effects"
        case .premium: return "Premium"
        }
    }

    var subtitle: String {
        switch self {
        case .equipment: return "Cosmetic gear for every slot"
        case .backgrounds: return "Profile card backdrops"
        case .skins: return "Colorways for your Ember"
        case .emotes: return "Little reactions on Home"
        case .themes: return "Accent palettes"
        case .effects: return "Soft particle flair"
        case .premium: return "Crystal-only prestige looks"
        }
    }

    var iconName: String {
        switch self {
        case .equipment: return "shield.fill"
        case .backgrounds: return "photo.fill"
        case .skins: return "paintpalette.fill"
        case .emotes: return "face.smiling.fill"
        case .themes: return "paintpalette.fill"
        case .effects: return "sparkles"
        case .premium: return "diamond.fill"
        }
    }
}

/// Non-equipment cosmetics. Never sell XP, levels, workouts, or boosters.
struct CosmeticShopItem: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let detail: String
    let category: ShopCategory
    let price: Int
    let currency: ShopCurrency
    let iconName: String
}

enum ShopCatalog: Sendable {
    static let backgrounds: [CosmeticShopItem] = [
        CosmeticShopItem(id: "bg.dawn", name: "Dawn Sky", detail: "Soft morning wash", category: .backgrounds, price: 80, currency: .coins, iconName: "sunrise.fill"),
        CosmeticShopItem(id: "bg.forest", name: "Forest Glade", detail: "Quiet green backdrop", category: .backgrounds, price: 80, currency: .coins, iconName: "leaf.fill"),
        CosmeticShopItem(id: "bg.city", name: "Night City", detail: "Cool dusk skyline", category: .backgrounds, price: 100, currency: .coins, iconName: "building.2.fill"),
        CosmeticShopItem(id: "bg.hearth", name: "Ember Hearth", detail: "Warm firelight", category: .backgrounds, price: 100, currency: .coins, iconName: "flame.fill"),
        CosmeticShopItem(id: "bg.glacier", name: "Glacier Peak", detail: "Icy blue wash", category: .backgrounds, price: 120, currency: .coins, iconName: "snowflake"),
        CosmeticShopItem(id: "bg.studio", name: "Soft Studio", detail: "Clean cream card", category: .backgrounds, price: 60, currency: .coins, iconName: "square.fill")
    ]

    static let emotes: [CosmeticShopItem] = [
        CosmeticShopItem(id: "emote.wave", name: "Wave", detail: "A friendly hello", category: .emotes, price: 40, currency: .coins, iconName: "hand.wave.fill"),
        CosmeticShopItem(id: "emote.cheer", name: "Cheer", detail: "Both paws up", category: .emotes, price: 40, currency: .coins, iconName: "hands.clap.fill"),
        CosmeticShopItem(id: "emote.flex", name: "Flex", detail: "Tiny show-off", category: .emotes, price: 50, currency: .coins, iconName: "figure.strengthtraining.traditional"),
        CosmeticShopItem(id: "emote.sparkle", name: "Sparkle", detail: "A burst of glitter", category: .emotes, price: 50, currency: .coins, iconName: "sparkle"),
        CosmeticShopItem(id: "emote.sleepy", name: "Sleepy", detail: "Recovery mode", category: .emotes, price: 40, currency: .coins, iconName: "moon.zzz.fill"),
        CosmeticShopItem(id: "emote.heart", name: "Heart", detail: "A warm pulse", category: .emotes, price: 50, currency: .coins, iconName: "heart.fill")
    ]

    static let themes: [CosmeticShopItem] = [
        CosmeticShopItem(id: "theme.classic", name: "Ember Classic", detail: "Default orange accent", category: .themes, price: 0, currency: .coins, iconName: "flame.fill"),
        CosmeticShopItem(id: "theme.midnight", name: "Midnight", detail: "Ink and gold", category: .themes, price: 150, currency: .coins, iconName: "moon.stars.fill"),
        CosmeticShopItem(id: "theme.meadow", name: "Meadow", detail: "Soft green accent", category: .themes, price: 150, currency: .coins, iconName: "leaf.fill"),
        CosmeticShopItem(id: "theme.ocean", name: "Ocean", detail: "Teal accent", category: .themes, price: 150, currency: .coins, iconName: "water.waves"),
        CosmeticShopItem(id: "theme.candy", name: "Candy", detail: "Pink accent", category: .themes, price: 150, currency: .coins, iconName: "birthday.cake.fill")
    ]

    static let effects: [CosmeticShopItem] = [
        CosmeticShopItem(id: "fx.sparkles", name: "Soft Sparkles", detail: "Idle glitter around your Ember", category: .effects, price: 90, currency: .coins, iconName: "sparkles"),
        CosmeticShopItem(id: "fx.trail", name: "Ember Trail", detail: "A faint ember dust", category: .effects, price: 110, currency: .coins, iconName: "wind"),
        CosmeticShopItem(id: "fx.leaves", name: "Leaf Fall", detail: "Slow drifting leaves", category: .effects, price: 110, currency: .coins, iconName: "leaf.fill")
    ]

    static let premium: [CosmeticShopItem] = [
        CosmeticShopItem(id: "glow", name: "Ember Glow", detail: "Extra aura bloom on Home", category: .premium, price: 75, currency: .crystals, iconName: "sparkles"),
        CosmeticShopItem(id: "nameplate_gold", name: "Gold Nameplate", detail: "Gold companion name tint", category: .premium, price: 50, currency: .crystals, iconName: "tag.fill"),
        CosmeticShopItem(id: "nameplate_aurora", name: "Aurora Nameplate", detail: "Aurora gradient name tint", category: .premium, price: 150, currency: .crystals, iconName: "paintpalette.fill"),
        CosmeticShopItem(id: "skin.golden", name: "Golden Ember", detail: "Prestige gold skin", category: .premium, price: 120, currency: .crystals, iconName: "star.fill"),
        CosmeticShopItem(id: "skin.void", name: "Void Flame", detail: "Deep ink prestige skin", category: .premium, price: 140, currency: .crystals, iconName: "circle.lefthalf.filled"),
        CosmeticShopItem(id: "skin.prism", name: "Prism Core", detail: "Shifting prestige skin", category: .premium, price: 180, currency: .crystals, iconName: "circle.hexagongrid.fill")
    ]

    /// Paid flame colorways kept as companion skins (Coins).
    static let paidSkinIds: [String] = [
        "nebula", "plasma", "lime", "sapphire", "orchid",
        "silver", "crimson", "ultraviolet", "neon", "pearl"
    ]

    static var allCosmetics: [CosmeticShopItem] {
        backgrounds + emotes + themes + effects + premium
    }

    static func item(id: String) -> CosmeticShopItem? {
        allCosmetics.first { $0.id == id }
    }

    static func items(in category: ShopCategory) -> [CosmeticShopItem] {
        allCosmetics.filter { $0.category == category }
    }
}
