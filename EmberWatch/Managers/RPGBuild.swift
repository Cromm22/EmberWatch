import Foundation

/// The five playable builds. File-level / Sendable so Swift 6 does not isolate
/// this catalog on MainActor.
enum BuildKind: String, CaseIterable, Codable, Sendable, Identifiable {
    case warrior
    case assassin
    case tank
    case ranger
    case mage

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .warrior: return "Warrior"
        case .assassin: return "Assassin"
        case .tank: return "Tank"
        case .ranger: return "Ranger"
        case .mage: return "Mage"
        }
    }

    var uppercaseName: String {
        displayName.uppercased()
    }

    /// One-line goal shown on picker cards and the Character sheet.
    var goalLine: String {
        switch self {
        case .warrior: return "Muscle + athleticism"
        case .assassin: return "Lean / athletic"
        case .tank: return "Gain strength"
        case .ranger: return "Endurance"
        case .mage: return "General health"
        }
    }

    var summary: String {
        switch self {
        case .warrior:
            return "Moderate surplus. Strength and conditioning with protein adherence and recovery."
        case .assassin:
            return "Get lean, keep muscle. High steps and cardio in a calorie deficit."
        case .tank:
            return "Higher protein, heavy lifting, progressive overload, and strength milestones."
        case .ranger:
            return "Cardio-forward training with steps, recovery, and steady nutrition."
        case .mage:
            return "Mobility, sleep and recovery, plus moderate training. All stats grow evenly."
        }
    }

    var iconName: String {
        switch self {
        case .warrior: return "shield.fill"
        case .assassin: return "bolt.fill"
        case .tank: return "dumbbell.fill"
        case .ranger: return "figure.run"
        case .mage: return "sparkles"
        }
    }

    /// Asset catalog name for this build's hero portrait. `nil` falls back to
    /// the Ember flame or chosen companion. Extra builds can ship art later.
    var heroImageName: String? {
        switch self {
        case .warrior: return "WarriorHero"
        case .assassin: return "AssassinHero"
        case .tank: return "TankHero"
        case .ranger: return "RangerHero"
        case .mage: return "MageHero"
        }
    }

    /// Primary stats receive the build bonus multiplier. Mage has none (even growth).
    var primaryStats: [CharacterStat] {
        switch self {
        case .warrior: return [.strength, .vitality]
        case .assassin: return [.agility, .endurance]
        case .tank: return [.strength, .vitality]
        case .ranger: return [.endurance, .agility]
        case .mage: return []
        }
    }

    var recommendedBehaviors: [String] {
        switch self {
        case .warrior:
            return ["Strength + conditioning", "Protein adherence", "Recovery"]
        case .assassin:
            return ["Calorie adherence", "Movement", "Conditioning", "Strength"]
        case .tank:
            return ["Protein", "Heavy lifting", "Recovery"]
        case .ranger:
            return ["Cardio", "Steps", "Recovery", "Nutrition"]
        case .mage:
            return ["Mobility", "Sleep / recovery", "Moderate training"]
        }
    }

    func isPrimary(_ stat: CharacterStat) -> Bool {
        if self == .mage { return false }
        return primaryStats.contains(stat)
    }

    /// Build primary stats gain 1.5×. Mage grows every stat at 1.0×.
    func multiplier(for stat: CharacterStat) -> Double {
        if self == .mage { return 1.0 }
        return isPrimary(stat) ? StatRules.primaryStatMultiplier : 1.0
    }

    static func parse(_ raw: String?) -> BuildKind? {
        guard let raw, !raw.isEmpty else { return nil }
        return BuildKind(rawValue: raw)
    }
}
