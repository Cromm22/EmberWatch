import CoreGraphics
import Foundation

/// Six playable Ember companions. File-level / Sendable so Swift 6 does not
/// isolate this catalog on MainActor.
enum CompanionSpecies: String, CaseIterable, Codable, Sendable, Identifiable {
    case babyDragon
    case robot
    case wolf
    case slime
    case phoenix
    case cyberCat

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .babyDragon: return "Baby Dragon"
        case .robot: return "Robot"
        case .wolf: return "Wolf"
        case .slime: return "Slime"
        case .phoenix: return "Phoenix"
        case .cyberCat: return "Cyber Cat"
        }
    }

    var tagline: String {
        switch self {
        case .babyDragon: return "A tiny ember that grows into a legend"
        case .robot: return "Loyal circuits, warm heart"
        case .wolf: return "Pack-minded and fierce"
        case .slime: return "Bouncy, bright, and brave"
        case .phoenix: return "Rises higher with every streak"
        case .cyberCat: return "Sleek, curious, always watching"
        }
    }

    var iconName: String {
        switch self {
        case .babyDragon: return "flame.fill"
        case .robot: return "cpu.fill"
        case .wolf: return "pawprint.fill"
        case .slime: return "drop.fill"
        case .phoenix: return "bird.fill"
        case .cyberCat: return "cat.fill"
        }
    }

    /// Primary fill used by vector art and Board icons.
    var auraHex: String {
        switch self {
        case .babyDragon: return "#ff7a3c"
        case .robot: return "#38bdf8"
        case .wolf: return "#64748b"
        case .slime: return "#4ade80"
        case .phoenix: return "#f43f5e"
        case .cyberCat: return "#a855f7"
        }
    }

    var bodyHex: String {
        switch self {
        case .babyDragon: return "#ff9a3c"
        case .robot: return "#7dd3fc"
        case .wolf: return "#94a3b8"
        case .slime: return "#86efac"
        case .phoenix: return "#fb7185"
        case .cyberCat: return "#c084fc"
        }
    }

    var bellyHex: String {
        switch self {
        case .babyDragon: return "#ffe08a"
        case .robot: return "#e0f2fe"
        case .wolf: return "#e2e8f0"
        case .slime: return "#dcfce7"
        case .phoenix: return "#fecdd3"
        case .cyberCat: return "#e9d5ff"
        }
    }

    var accentHex: String {
        switch self {
        case .babyDragon: return "#d9480f"
        case .robot: return "#075985"
        case .wolf: return "#334155"
        case .slime: return "#15803d"
        case .phoenix: return "#fbbf24"
        case .cyberCat: return "#22d3ee"
        }
    }

    static func parse(_ raw: String?) -> CompanionSpecies? {
        guard let raw, !raw.isEmpty else { return nil }
        return CompanionSpecies(rawValue: raw)
    }

    /// Map a Phase 1 flame style to the closest companion so existing users
    /// get a sensible default they can still change.
    static func suggested(fromAvatarId id: String) -> CompanionSpecies {
        switch id {
        case "classic", "crimson", "rose":
            return .babyDragon
        case "glacier", "cobalt", "sapphire", "seafoam":
            return .robot
        case "ink", "moss", "lagoon":
            return .wolf
        case "mint", "lime", "pearl":
            return .slime
        case "plasma", "orchid", "ultraviolet", "neon":
            return .phoenix
        case "aurora", "nebula", "silver":
            return .cyberCat
        default:
            return .babyDragon
        }
    }
}

enum CompanionStage: String, CaseIterable, Codable, Sendable, Identifiable, Comparable {
    case baby
    case juvenile
    case adult
    case elite
    case majestic

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .baby: return "Tiny baby"
        case .juvenile: return "Juvenile"
        case .adult: return "Adult"
        case .elite: return "Elite"
        case .majestic: return "Majestic"
        }
    }

    var shortLabel: String {
        switch self {
        case .baby: return "Baby"
        case .juvenile: return "Juv"
        case .adult: return "Adult"
        case .elite: return "Elite"
        case .majestic: return "Final"
        }
    }

    var unlockLevel: Int {
        switch self {
        case .baby: return 1
        case .juvenile: return 25
        case .adult: return 50
        case .elite: return 75
        case .majestic: return 100
        }
    }

    var rank: Int {
        switch self {
        case .baby: return 0
        case .juvenile: return 1
        case .adult: return 2
        case .elite: return 3
        case .majestic: return 4
        }
    }

    /// Scale the creature body. Computed once so views do not nest arithmetic
    /// inside long modifier chains.
    var bodyScale: CGFloat {
        switch self {
        case .baby: return 0.62
        case .juvenile: return 0.78
        case .adult: return 0.90
        case .elite: return 1.00
        case .majestic: return 1.10
        }
    }

    static func current(forLevel level: Int) -> CompanionStage {
        if level >= 100 { return .majestic }
        if level >= 75 { return .elite }
        if level >= 50 { return .adult }
        if level >= 25 { return .juvenile }
        return .baby
    }

    static func parse(_ raw: String?) -> CompanionStage? {
        guard let raw, !raw.isEmpty else { return nil }
        return CompanionStage(rawValue: raw)
    }

    static func < (lhs: CompanionStage, rhs: CompanionStage) -> Bool {
        lhs.rank < rhs.rank
    }
}

/// Visual gear tier. Independent of equipped inventory — purely a level look.
enum ProgressionTier: String, CaseIterable, Sendable, Identifiable {
    case basic
    case better
    case epic
    case animated
    case prestige
    case legend

    var id: String { rawValue }

    var unlockLevel: Int {
        switch self {
        case .basic: return 1
        case .better: return 20
        case .epic: return 40
        case .animated: return 60
        case .prestige: return 80
        case .legend: return 100
        }
    }

    var gearLabel: String {
        switch self {
        case .basic: return "Basic clothes"
        case .better: return "Better equipment"
        case .epic: return "Epic gear"
        case .animated: return "Animated items"
        case .prestige: return "Prestige armor"
        case .legend: return "IRON LEGEND"
        }
    }

    var showsShimmer: Bool {
        switch self {
        case .animated, .prestige, .legend:
            return true
        case .basic, .better, .epic:
            return false
        }
    }

    var showsPrestigePlates: Bool {
        switch self {
        case .prestige, .legend:
            return true
        case .basic, .better, .epic, .animated:
            return false
        }
    }

    var showsLegendAura: Bool {
        self == .legend
    }

    static func current(forLevel level: Int) -> ProgressionTier {
        if level >= 100 { return .legend }
        if level >= 80 { return .prestige }
        if level >= 60 { return .animated }
        if level >= 40 { return .epic }
        if level >= 20 { return .better }
        return .basic
    }
}
