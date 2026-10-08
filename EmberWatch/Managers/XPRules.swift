import Foundation

/// Pure RPG Phase 1 rules: XP awards, 1…100 curve, titles, safety, quests, currencies.
/// File-level / Sendable so Swift 6 does not isolate this table on MainActor.
enum XPRules: Sendable {
    static let maxLevel = 100
    static let typicalDailyXP = 350

    // MARK: - Daily action XP

    static let breakfastXP = 10
    static let lunchXP = 10
    static let dinnerXP = 10
    static let completeNutritionXP = 25
    static let proteinRangeXP = 40
    static let calorieRangeXP = 40
    static let workoutXP = 100
    static let maxWorkoutsPerDay = 2
    static let exerciseXPDailyCap = 200
    static let movementGoalXP = 40
    static let recoveryGoalXP = 25
    static let dailyQuestXP = 50
    static let streak3XP = 50
    static let streak7XP = 100

    /// Calories must sit in [90%, 105%] of goal.
    static let calorieRangeLow = 0.90
    static let calorieRangeHigh = 1.05
    /// Extreme deficit: no calorie XP at or below this fraction of goal.
    static let extremeDeficitFraction = 0.75
    /// Generic safe floor until profile sex exists (spec: ~1200 F / 1500 M).
    static let calorieSafeFloor = 1200.0

    static let proteinRangeLow = 0.90
    static let proteinRangeHigh = 1.20

    static let extremeWorkoutMinutes = 180
    static let extremeWorkoutCalories = 1500.0

    /// Fallback movement target when the workout goal toggle is off.
    static let defaultMovementMinutes = 30

    // MARK: - Coins (gameplay)

    static let dailyQuestCoins = 25
    static let streak3Coins = 50
    static let streak7Coins = 100
    static let challengeCoins = 20
    static let boardFirstCoins = 40
    static let avatarUnlockCoins = 250

    /// +50 Coins × tier, where tier = ceil(level / 10). L1–10 → 50, L11–20 → 100.
    static func coinsForLevelUp(to newLevel: Int) -> Int {
        let level = max(1, min(newLevel, maxLevel))
        let tier = (level + 9) / 10
        return 50 * max(1, tier)
    }

    // MARK: - Crystals (premium; occasional milestones)

    static func milestoneCrystals(forLevel level: Int) -> Int {
        switch level {
        case 20: return 25
        case 40: return 50
        case 60: return 75
        case 80: return 100
        case 100: return 200
        default: return 0
        }
    }

    // MARK: - Display

    static func groupedNumber(_ value: Int) -> String {
        let n = max(0, value)
        let digits = Array(String(n))
        var parts: [String] = []
        var i = digits.count
        while i > 0 {
            let start = max(0, i - 3)
            parts.insert(String(digits[start..<i]), at: 0)
            i = start
        }
        return parts.joined(separator: ",")
    }

    // MARK: - Level titles

    static func title(forLevel level: Int) -> String {
        let L = max(1, min(level, maxLevel))
        switch L {
        case 1...9: return "Ember Spark"
        case 10...19: return "Kindling"
        case 20...29: return "Emberling"
        case 30...39: return "Flamebearer"
        case 40...49: return "Blaze Adept"
        case 50...59: return "Inferno Knight"
        case 60...69: return "Ash Champion"
        case 70...79: return "Ember Lord"
        case 80...89: return "Phoenix Guard"
        case 90...99: return "Mythic Flame"
        default: return "IRON LEGEND"
        }
    }

    // MARK: - Curve
    //
    // XP to advance FROM level L TO L+1. Index 0 = L1→L2, index 98 = L99→L100.
    // Cumulative to reach L10/20/40/60/80/100 matches the ~350 XP/day calibration.
    // Strictly increasing. Do not replace with a board-rank multiplier.

    static let xpToAdvanceByLevel: [Int] = makeXpToAdvanceTable()

    private static func makeXpToAdvanceTable() -> [Int] {
        let values: [Int] = [
            148, 150, 152, 154, 156, 157, 159, 161, 163, 341,
            343, 345, 347, 349, 351, 353, 355, 357, 359, 786,
            788, 790, 792, 794, 796, 798, 800, 802, 804, 806,
            808, 810, 812, 814, 816, 818, 820, 822, 824, 1556,
            1558, 1560, 1562, 1564, 1566, 1568, 1570, 1572, 1574, 1576,
            1578, 1580, 1582, 1584, 1586, 1588, 1590, 1592, 1594, 2081,
            2083, 2085, 2087, 2089, 2091, 2093, 2095, 2097, 2099, 2101,
            2103, 2105, 2107, 2109, 2111, 2113, 2115, 2117, 2119, 2256,
            2258, 2260, 2262, 2264, 2266, 2268, 2270, 2272, 2274, 2276,
            2278, 2280, 2282, 2284, 2286, 2288, 2290, 2292, 2294
        ]
        validateTable(values)
        return values
    }

    private static func validateTable(_ values: [Int]) {
        precondition(values.count == maxLevel - 1, "XP table must have 99 entries")
        var previous = 0
        var cumulative = 0
        for amount in values {
            precondition(amount > 0, "XP-to-next must be positive")
            precondition(amount >= previous, "XP curve must be monotonic")
            previous = amount
            cumulative += amount
        }
        precondition(cumulative == 140_000, "Lifetime XP to L100 must be 140000")
        let targets: [(Int, Int)] = [
            (10, 1_400),
            (20, 4_900),
            (40, 21_000),
            (60, 52_500),
            (80, 94_500),
            (100, 140_000)
        ]
        for (level, expected) in targets {
            var sum = 0
            let upto = level - 1
            for i in 0..<upto {
                sum += values[i]
            }
            precondition(sum == expected, "Cumulative XP to level \(level) must be \(expected)")
        }
    }

    /// XP required to advance from `level` → `level + 1`.
    static func xpToAdvance(from level: Int) -> Int {
        let L = max(1, min(level, maxLevel))
        if L >= maxLevel {
            return valuesLast
        }
        return xpToAdvanceByLevel[L - 1]
    }

    private static var valuesLast: Int {
        xpToAdvanceByLevel[xpToAdvanceByLevel.count - 1]
    }

    /// Cumulative XP required to *reach* `level` (level 1 = 0).
    static func cumulativeXP(forLevel level: Int) -> Int {
        let capped = max(1, min(level, maxLevel))
        if capped <= 1 { return 0 }
        var total = 0
        for L in 1..<capped {
            total += xpToAdvance(from: L)
        }
        return total
    }

    static func level(fromTotalXP totalXP: Int) -> (level: Int, xpIntoLevel: Int, xpForNext: Int) {
        var remaining = max(0, totalXP)
        var L = 1
        while L < maxLevel {
            let need = xpToAdvance(from: L)
            if remaining < need { break }
            remaining -= need
            L += 1
        }
        let next = xpToAdvance(from: L)
        return (L, remaining, next)
    }

    // MARK: - Safety / ranges

    static func isExtremeWorkout(durationMinutes: Int, calories: Double) -> Bool {
        durationMinutes > extremeWorkoutMinutes || calories > extremeWorkoutCalories
    }

    static func isInCalorieRange(consumed: Double, goal: Double) -> Bool {
        guard goal > 0 else { return false }
        guard consumed >= calorieSafeFloor else { return false }
        guard consumed > goal * extremeDeficitFraction else { return false }
        let low = goal * calorieRangeLow
        let high = goal * calorieRangeHigh
        return consumed >= low && consumed <= high
    }

    static func isInProteinRange(consumed: Double, goal: Double) -> Bool {
        guard goal > 0 else { return false }
        let low = goal * proteinRangeLow
        let high = goal * proteinRangeHigh
        return consumed >= low && consumed <= high
    }

    static func movementGoalMet(
        minutes: Int,
        targetMinutes: Int,
        goalEnabled: Bool,
        exerciseMinutes: Double
    ) -> Bool {
        if goalEnabled {
            return targetMinutes > 0 && minutes >= targetMinutes
        }
        let fallback = Double(defaultMovementMinutes)
        return minutes >= defaultMovementMinutes || exerciseMinutes >= fallback
    }

    static func dayKey(for date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = Calendar.current.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

/// Ledger keys for one calendar day's idempotent XP rows.
enum XPAction: String, Codable, CaseIterable, Sendable {
    case logBreakfast
    case logLunch
    case logDinner
    case completeNutrition
    case proteinTarget
    case calorieTarget
    case workout
    case movementGoal
    case recoveryGoal
    case dailyQuest
    case streak3
    case streak7

    var displayName: String {
        switch self {
        case .logBreakfast: return "Logged breakfast"
        case .logLunch: return "Logged lunch"
        case .logDinner: return "Logged dinner"
        case .completeNutrition: return "Nutrition complete"
        case .proteinTarget: return "Protein range"
        case .calorieTarget: return "Calorie range"
        case .workout: return "Workout"
        case .movementGoal: return "Movement goal"
        case .recoveryGoal: return "Recovery goal"
        case .dailyQuest: return "Daily quest"
        case .streak3: return "3-day streak"
        case .streak7: return "7-day streak"
        }
    }
}

enum DailyQuestKind: String, Codable, CaseIterable, Sendable {
    case proteinRange
    case logThreeMeals
    case movementGoal
    case calorieRange
    case recoveryGoal

    var title: String {
        switch self {
        case .proteinRange: return "Hit your protein range"
        case .logThreeMeals: return "Log all 3 meals"
        case .movementGoal: return "Hit movement goal"
        case .calorieRange: return "Stay in calorie range"
        case .recoveryGoal: return "Hit your recovery goal"
        }
    }

    static let rotation: [DailyQuestKind] = [
        .proteinRange,
        .logThreeMeals,
        .movementGoal,
        .calorieRange,
        .recoveryGoal
    ]

    static func quest(forDayKey dayKey: String) -> DailyQuestKind {
        let items = rotation
        let count = items.count
        guard count > 0 else { return .logThreeMeals }
        var hash: UInt64 = 2166136261
        for byte in dayKey.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 16777619
        }
        let index = Int(hash % UInt64(count))
        return items[index]
    }
}

enum ShopCurrency: String, Sendable, Hashable {
    case coins
    case crystals
}
