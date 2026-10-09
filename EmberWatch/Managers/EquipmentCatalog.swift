import Foundation
import SwiftUI

enum EquipmentSlot: String, CaseIterable, Codable, Sendable, Identifiable {
    case head
    case chest
    case hands
    case legs
    case feet
    case accessory

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .head: return "Head"
        case .chest: return "Chest"
        case .hands: return "Hands"
        case .legs: return "Legs"
        case .feet: return "Feet"
        case .accessory: return "Accessory"
        }
    }

    var iconName: String {
        switch self {
        case .head: return "crown.fill"
        case .chest: return "shield.fill"
        case .hands: return "hand.raised.fill"
        case .legs: return "figure.walk"
        case .feet: return "shoe.fill"
        case .accessory: return "sparkle"
        }
    }
}

enum ItemRarity: String, CaseIterable, Codable, Sendable, Identifiable, Comparable {
    case common
    case uncommon
    case rare
    case epic
    case legendary
    case mythic

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .common: return "Common"
        case .uncommon: return "Uncommon"
        case .rare: return "Rare"
        case .epic: return "Epic"
        case .legendary: return "Legendary"
        case .mythic: return "Mythic"
        }
    }

    var rank: Int {
        switch self {
        case .common: return 0
        case .uncommon: return 1
        case .rare: return 2
        case .epic: return 3
        case .legendary: return 4
        case .mythic: return 5
        }
    }

    /// Standard rarity colors: gray, green, blue, purple, orange, red/pink.
    var hex: String {
        switch self {
        case .common: return "#9CA3AF"
        case .uncommon: return "#22C55E"
        case .rare: return "#3B82F6"
        case .epic: return "#A855F7"
        case .legendary: return "#F97316"
        case .mythic: return "#F43F5E"
        }
    }

    var color: Color {
        Color(hex: hex)
    }

    static func < (lhs: ItemRarity, rhs: ItemRarity) -> Bool {
        lhs.rank < rhs.rank
    }
}

/// Cosmetic-only gear. Never grants XP, stats, or health bonuses.
struct EquipmentItem: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let slot: EquipmentSlot
    let rarity: ItemRarity
    let iconName: String
    let detail: String
    /// When set, the item is granted for free once the player reaches this level.
    let freeAtLevel: Int?
    let price: Int
    let currency: ShopCurrency

    var isBuyable: Bool {
        price > 0 && freeAtLevel == nil
    }

    func isGranted(atLevel level: Int) -> Bool {
        guard let freeAtLevel else { return false }
        return level >= freeAtLevel
    }
}

enum EquipmentCatalog: Sendable {
    static let allItems: [EquipmentItem] = head + chest + hands + legs + feet + accessory

    static func items(for slot: EquipmentSlot) -> [EquipmentItem] {
        allItems.filter { $0.slot == slot }
    }

    static func item(id: String) -> EquipmentItem? {
        allItems.first { $0.id == id }
    }

    static func freeUnlocks(atLevel level: Int) -> [EquipmentItem] {
        allItems.filter { $0.isGranted(atLevel: level) }
    }

    // MARK: - Head (8)

    static let head: [EquipmentItem] = [
        EquipmentItem(
            id: "head.soft_cap",
            name: "Soft Cap",
            slot: .head,
            rarity: .common,
            iconName: "graduationcap.fill",
            detail: "A cozy starter hat.",
            freeAtLevel: 1,
            price: 0,
            currency: .coins
        ),
        EquipmentItem(
            id: "head.knit_beanie",
            name: "Knit Beanie",
            slot: .head,
            rarity: .common,
            iconName: "cloud.fill",
            detail: "Warm knit for chilly mornings.",
            freeAtLevel: nil,
            price: 80,
            currency: .coins
        ),
        EquipmentItem(
            id: "head.scout_hood",
            name: "Scout Hood",
            slot: .head,
            rarity: .uncommon,
            iconName: "theatermasks.fill",
            detail: "Light hood for the trail.",
            freeAtLevel: 20,
            price: 0,
            currency: .coins
        ),
        EquipmentItem(
            id: "head.iron_helm",
            name: "Iron Helm",
            slot: .head,
            rarity: .rare,
            iconName: "shield.lefthalf.filled",
            detail: "Sturdy and a little shiny.",
            freeAtLevel: nil,
            price: 220,
            currency: .coins
        ),
        EquipmentItem(
            id: "head.rune_circlet",
            name: "Rune Circlet",
            slot: .head,
            rarity: .epic,
            iconName: "circle.hexagongrid.fill",
            detail: "Etched with idle sparks.",
            freeAtLevel: 40,
            price: 0,
            currency: .coins
        ),
        EquipmentItem(
            id: "head.storm_crown",
            name: "Storm Crown",
            slot: .head,
            rarity: .epic,
            iconName: "crown.fill",
            detail: "A crystal-cut circlet.",
            freeAtLevel: nil,
            price: 60,
            currency: .crystals
        ),
        EquipmentItem(
            id: "head.phoenix_crest",
            name: "Phoenix Crest",
            slot: .head,
            rarity: .legendary,
            iconName: "flame.fill",
            detail: "Prestige headpiece.",
            freeAtLevel: 80,
            price: 0,
            currency: .coins
        ),
        EquipmentItem(
            id: "head.mythic_halo",
            name: "Mythic Halo",
            slot: .head,
            rarity: .mythic,
            iconName: "sun.max.fill",
            detail: "Final-form crown of light.",
            freeAtLevel: 100,
            price: 0,
            currency: .coins
        )
    ]

    // MARK: - Chest (8)

    static let chest: [EquipmentItem] = [
        EquipmentItem(
            id: "chest.cotton_shirt",
            name: "Cotton Shirt",
            slot: .chest,
            rarity: .common,
            iconName: "tshirt.fill",
            detail: "Simple starter layer.",
            freeAtLevel: 1,
            price: 0,
            currency: .coins
        ),
        EquipmentItem(
            id: "chest.travel_vest",
            name: "Travel Vest",
            slot: .chest,
            rarity: .uncommon,
            iconName: "backpack.fill",
            detail: "Pockets for snacks.",
            freeAtLevel: nil,
            price: 110,
            currency: .coins
        ),
        EquipmentItem(
            id: "chest.scale_mail",
            name: "Scale Mail",
            slot: .chest,
            rarity: .rare,
            iconName: "square.grid.3x3.fill",
            detail: "Better everyday armor.",
            freeAtLevel: 20,
            price: 0,
            currency: .coins
        ),
        EquipmentItem(
            id: "chest.ember_plate",
            name: "Ember Plate",
            slot: .chest,
            rarity: .epic,
            iconName: "shield.fill",
            detail: "Warm plates with a glow.",
            freeAtLevel: 40,
            price: 0,
            currency: .coins
        ),
        EquipmentItem(
            id: "chest.pulse_jacket",
            name: "Pulse Jacket",
            slot: .chest,
            rarity: .epic,
            iconName: "waveform.path.ecg",
            detail: "A faint animated shimmer.",
            freeAtLevel: 60,
            price: 0,
            currency: .coins
        ),
        EquipmentItem(
            id: "chest.crystal_mail",
            name: "Crystal Mail",
            slot: .chest,
            rarity: .legendary,
            iconName: "diamond.fill",
            detail: "Premium chest glow.",
            freeAtLevel: nil,
            price: 90,
            currency: .crystals
        ),
        EquipmentItem(
            id: "chest.prestige_cuirass",
            name: "Prestige Cuirass",
            slot: .chest,
            rarity: .legendary,
            iconName: "star.circle.fill",
            detail: "Ceremonial prestige armor.",
            freeAtLevel: 80,
            price: 0,
            currency: .coins
        ),
        EquipmentItem(
            id: "chest.iron_legend_plate",
            name: "Iron Legend Plate",
            slot: .chest,
            rarity: .mythic,
            iconName: "seal.fill",
            detail: "Unique L100 chest.",
            freeAtLevel: 100,
            price: 0,
            currency: .coins
        )
    ]

    // MARK: - Hands (7)

    static let hands: [EquipmentItem] = [
        EquipmentItem(
            id: "hands.cloth_wraps",
            name: "Cloth Wraps",
            slot: .hands,
            rarity: .common,
            iconName: "bandage.fill",
            detail: "Soft starter wraps.",
            freeAtLevel: 1,
            price: 0,
            currency: .coins
        ),
        EquipmentItem(
            id: "hands.work_gloves",
            name: "Work Gloves",
            slot: .hands,
            rarity: .uncommon,
            iconName: "hand.raised.fill",
            detail: "Everyday training gloves.",
            freeAtLevel: nil,
            price: 70,
            currency: .coins
        ),
        EquipmentItem(
            id: "hands.iron_gauntlets",
            name: "Iron Gauntlets",
            slot: .hands,
            rarity: .rare,
            iconName: "hammer.fill",
            detail: "Heavier hand armor.",
            freeAtLevel: 20,
            price: 0,
            currency: .coins
        ),
        EquipmentItem(
            id: "hands.ember_bracers",
            name: "Ember Bracers",
            slot: .hands,
            rarity: .epic,
            iconName: "flame.fill",
            detail: "Warm etched cuffs.",
            freeAtLevel: 40,
            price: 0,
            currency: .coins
        ),
        EquipmentItem(
            id: "hands.pulse_grips",
            name: "Pulse Grips",
            slot: .hands,
            rarity: .epic,
            iconName: "bolt.fill",
            detail: "Subtle pulse along the wrists.",
            freeAtLevel: 60,
            price: 0,
            currency: .coins
        ),
        EquipmentItem(
            id: "hands.prestige_gauntlets",
            name: "Prestige Gauntlets",
            slot: .hands,
            rarity: .legendary,
            iconName: "star.fill",
            detail: "Gold-trimmed prestige pair.",
            freeAtLevel: 80,
            price: 0,
            currency: .coins
        ),
        EquipmentItem(
            id: "hands.mythic_claws",
            name: "Mythic Claws",
            slot: .hands,
            rarity: .mythic,
            iconName: "sparkles",
            detail: "Crystal-cut claws.",
            freeAtLevel: nil,
            price: 80,
            currency: .crystals
        )
    ]

    // MARK: - Legs (7)

    static let legs: [EquipmentItem] = [
        EquipmentItem(
            id: "legs.simple_pants",
            name: "Simple Pants",
            slot: .legs,
            rarity: .common,
            iconName: "rectangle.fill",
            detail: "Comfortable starter pair.",
            freeAtLevel: 1,
            price: 0,
            currency: .coins
        ),
        EquipmentItem(
            id: "legs.trail_shorts",
            name: "Trail Shorts",
            slot: .legs,
            rarity: .uncommon,
            iconName: "leaf.fill",
            detail: "Light for long walks.",
            freeAtLevel: nil,
            price: 70,
            currency: .coins
        ),
        EquipmentItem(
            id: "legs.guard_greaves",
            name: "Guard Greaves",
            slot: .legs,
            rarity: .rare,
            iconName: "shield.fill",
            detail: "Better everyday greaves.",
            freeAtLevel: 20,
            price: 0,
            currency: .coins
        ),
        EquipmentItem(
            id: "legs.ember_leggings",
            name: "Ember Leggings",
            slot: .legs,
            rarity: .epic,
            iconName: "flame.fill",
            detail: "Warm stitched runes.",
            freeAtLevel: 40,
            price: 0,
            currency: .coins
        ),
        EquipmentItem(
            id: "legs.pulse_treads",
            name: "Pulse Treads",
            slot: .legs,
            rarity: .epic,
            iconName: "waveform",
            detail: "A faint shimmer at the knees.",
            freeAtLevel: 60,
            price: 0,
            currency: .coins
        ),
        EquipmentItem(
            id: "legs.prestige_greaves",
            name: "Prestige Greaves",
            slot: .legs,
            rarity: .legendary,
            iconName: "star.fill",
            detail: "Ceremonial gold plates.",
            freeAtLevel: 80,
            price: 0,
            currency: .coins
        ),
        EquipmentItem(
            id: "legs.mythic_striders",
            name: "Mythic Striders",
            slot: .legs,
            rarity: .mythic,
            iconName: "sparkles",
            detail: "Final-form stride.",
            freeAtLevel: 100,
            price: 0,
            currency: .coins
        )
    ]

    // MARK: - Feet (7)

    static let feet: [EquipmentItem] = [
        EquipmentItem(
            id: "feet.soft_slippers",
            name: "Soft Slippers",
            slot: .feet,
            rarity: .common,
            iconName: "shoe.fill",
            detail: "Quiet starter shoes.",
            freeAtLevel: 1,
            price: 0,
            currency: .coins
        ),
        EquipmentItem(
            id: "feet.trail_shoes",
            name: "Trail Shoes",
            slot: .feet,
            rarity: .uncommon,
            iconName: "figure.walk",
            detail: "Everyday trainers.",
            freeAtLevel: nil,
            price: 60,
            currency: .coins
        ),
        EquipmentItem(
            id: "feet.iron_boots",
            name: "Iron Boots",
            slot: .feet,
            rarity: .rare,
            iconName: "lock.fill",
            detail: "Heavier better boots.",
            freeAtLevel: 20,
            price: 0,
            currency: .coins
        ),
        EquipmentItem(
            id: "feet.ember_soles",
            name: "Ember Soles",
            slot: .feet,
            rarity: .epic,
            iconName: "flame.fill",
            detail: "Warm glowing tread.",
            freeAtLevel: 40,
            price: 0,
            currency: .coins
        ),
        EquipmentItem(
            id: "feet.pulse_runners",
            name: "Pulse Runners",
            slot: .feet,
            rarity: .epic,
            iconName: "bolt.fill",
            detail: "A subtle pulse at the heel.",
            freeAtLevel: 60,
            price: 0,
            currency: .coins
        ),
        EquipmentItem(
            id: "feet.prestige_sabatons",
            name: "Prestige Sabatons",
            slot: .feet,
            rarity: .legendary,
            iconName: "star.fill",
            detail: "Gold-trimmed prestige pair.",
            freeAtLevel: 80,
            price: 0,
            currency: .coins
        ),
        EquipmentItem(
            id: "feet.mythic_stompers",
            name: "Mythic Stompers",
            slot: .feet,
            rarity: .mythic,
            iconName: "sparkles",
            detail: "Crystal-cut boots.",
            freeAtLevel: nil,
            price: 75,
            currency: .crystals
        )
    ]

    // MARK: - Accessory (8)

    static let accessory: [EquipmentItem] = [
        EquipmentItem(
            id: "acc.lucky_charm",
            name: "Lucky Charm",
            slot: .accessory,
            rarity: .common,
            iconName: "hare.fill",
            detail: "A tiny token.",
            freeAtLevel: nil,
            price: 50,
            currency: .coins
        ),
        EquipmentItem(
            id: "acc.ember_scarf",
            name: "Ember Scarf",
            slot: .accessory,
            rarity: .uncommon,
            iconName: "wind",
            detail: "Soft orange wrap.",
            freeAtLevel: 20,
            price: 0,
            currency: .coins
        ),
        EquipmentItem(
            id: "acc.crystal_pendant",
            name: "Crystal Pendant",
            slot: .accessory,
            rarity: .rare,
            iconName: "diamond.fill",
            detail: "A small hanging gem.",
            freeAtLevel: nil,
            price: 180,
            currency: .coins
        ),
        EquipmentItem(
            id: "acc.rune_brooch",
            name: "Rune Brooch",
            slot: .accessory,
            rarity: .epic,
            iconName: "hexagon.fill",
            detail: "Pinned spark rune.",
            freeAtLevel: 40,
            price: 0,
            currency: .coins
        ),
        EquipmentItem(
            id: "acc.pulse_amulet",
            name: "Pulse Amulet",
            slot: .accessory,
            rarity: .epic,
            iconName: "circle.circle.fill",
            detail: "A faint beating glow.",
            freeAtLevel: 60,
            price: 0,
            currency: .coins
        ),
        EquipmentItem(
            id: "acc.aurora_ribbon",
            name: "Aurora Ribbon",
            slot: .accessory,
            rarity: .legendary,
            iconName: "ribbon.fill",
            detail: "Premium aurora sash.",
            freeAtLevel: nil,
            price: 70,
            currency: .crystals
        ),
        EquipmentItem(
            id: "acc.prestige_cape_pin",
            name: "Prestige Cape Pin",
            slot: .accessory,
            rarity: .legendary,
            iconName: "pin.fill",
            detail: "Holds a ceremonial cape.",
            freeAtLevel: 80,
            price: 0,
            currency: .coins
        ),
        EquipmentItem(
            id: "acc.iron_legend_sigil",
            name: "Iron Legend Sigil",
            slot: .accessory,
            rarity: .mythic,
            iconName: "seal.fill",
            detail: "Unique L100 mark.",
            freeAtLevel: 100,
            price: 0,
            currency: .coins
        )
    ]
}
