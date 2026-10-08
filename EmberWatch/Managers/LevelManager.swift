import Foundation
import SwiftUI
import UIKit

struct XPGainEvent: Equatable {
    let amount: Int
    let actionName: String
    let timestamp: Date
}

struct DailyQuestStatus: Equatable {
    var title: String
    var isComplete: Bool
}

@MainActor
final class LevelManager: ObservableObject {
    static let maxLevel = XPRules.maxLevel

    @Published private(set) var totalXP: Int {
        didSet { UserDefaults.standard.set(totalXP, forKey: Keys.totalXP) }
    }

    @Published private(set) var level: Int = 1
    @Published private(set) var xpIntoLevel: Int = 0
    @Published private(set) var xpForNextLevel: Int = 100
    @Published private(set) var levelTitle: String = XPRules.title(forLevel: 1)

    /// Rank on the friends board (1 = first). No longer multiplies XP.
    @Published var boardRank: Int = 0 {
        didSet { UserDefaults.standard.set(boardRank, forKey: Keys.boardRank) }
    }

    @Published var levelUpBanner: String? = nil
    @Published var xpGainEvent: XPGainEvent? = nil
    @Published var levelUpEvent: Int? = nil
    @Published var xpToast: String? = nil
    @Published var streakBanner: String? = nil
    @Published var todaysQuest: DailyQuestStatus = DailyQuestStatus(
        title: DailyQuestKind.quest(forDayKey: XPRules.dayKey()).title,
        isComplete: false
    )

    weak var sparksManager: SparksManager?

    /// Last evaluated activity snapshot. Workout-only observers merge into this
    /// so Food Diary / Workout screens never have to pass nutrition managers.
    private var lastSnapshot: DailyActivitySnapshot?

    @Published private(set) var streakCount: Int {
        didSet { UserDefaults.standard.set(streakCount, forKey: Keys.streakCount) }
    }

    @Published private(set) var lastRewardDate: Date? {
        didSet {
            if let date = lastRewardDate {
                UserDefaults.standard.set(date.timeIntervalSince1970, forKey: Keys.lastRewardDate)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.lastRewardDate)
            }
        }
    }

    private var ledgerByDay: [String: DailyXPLedger] {
        didSet { persistLedgers() }
    }

    private var streak3Start: Date? {
        didSet { persistOptionalDate(streak3Start, key: Keys.streak3Start) }
    }

    private var streak7Start: Date? {
        didSet { persistOptionalDate(streak7Start, key: Keys.streak7Start) }
    }

    /// Days that already received daily-quest Coins (XP can still revoke/re-grant).
    private var questCoinDays: Set<String> {
        didSet { UserDefaults.standard.set(Array(questCoinDays), forKey: Keys.questCoinDays) }
    }

    private enum Keys {
        static let totalXP = "levelManager.totalXP"
        static let boardRank = "levelManager.boardRank"
        static let migrated = "levelManager.migratedFromCalorieGoal"
        static let streakCount = "levelManager.streakCount"
        static let lastRewardDate = "levelManager.lastRewardDate"
        static let ledgers = "levelManager.xpLedger.v1"
        static let streak3Start = "levelManager.streak3Start"
        static let streak7Start = "levelManager.streak7Start"
        static let questCoinDays = "levelManager.questCoinDays"
    }

    init() {
        let defaults = UserDefaults.standard

        if !defaults.bool(forKey: Keys.migrated) {
            let oldLevel = defaults.integer(forKey: "currentLevel")
            let oldXP = defaults.integer(forKey: "currentXP")
            if oldLevel > 0 || oldXP > 0 {
                var migrated = 0
                let L = max(1, oldLevel == 0 ? 1 : oldLevel)
                for i in 1..<L {
                    migrated += i * 100
                }
                migrated += max(0, oldXP)
                if defaults.object(forKey: Keys.totalXP) == nil {
                    defaults.set(migrated, forKey: Keys.totalXP)
                }
            }
            defaults.set(true, forKey: Keys.migrated)
        }

        self.totalXP = max(0, defaults.integer(forKey: Keys.totalXP))
        self.boardRank = defaults.integer(forKey: Keys.boardRank)

        if let data = defaults.data(forKey: Keys.ledgers),
           let map = try? JSONDecoder().decode([String: DailyXPLedger].self, from: data) {
            self.ledgerByDay = map
        } else {
            self.ledgerByDay = [:]
        }

        self.streakCount = max(0, defaults.integer(forKey: Keys.streakCount))
        if defaults.object(forKey: Keys.lastRewardDate) != nil {
            let interval = defaults.double(forKey: Keys.lastRewardDate)
            self.lastRewardDate = Date(timeIntervalSince1970: interval)
        } else {
            self.lastRewardDate = nil
        }
        self.streak3Start = Self.readOptionalDate(defaults, key: Keys.streak3Start)
        self.streak7Start = Self.readOptionalDate(defaults, key: Keys.streak7Start)
        let questDays = defaults.stringArray(forKey: Keys.questCoinDays) ?? []
        self.questCoinDays = Set(questDays)

        // Lifetime XP is kept; level is derived from the Phase 1 curve (may change vs the old 100+25*(L-1) table).
        recomputeLevel(from: totalXP, announce: false)
        refreshQuestStatus()
    }

    var progressFraction: Double {
        if level >= Self.maxLevel {
            return 1.0
        }
        guard xpForNextLevel > 0 else { return 0 }
        return min(1.0, Double(xpIntoLevel) / Double(xpForNextLevel))
    }

    static func xpToAdvance(from level: Int) -> Int {
        XPRules.xpToAdvance(from: level)
    }

    static func cumulativeXP(forLevel level: Int) -> Int {
        XPRules.cumulativeXP(forLevel: level)
    }

    // MARK: - Daily open / streak (no daily-open XP)

    @discardableResult
    func checkDailyOpenReward() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let last = lastRewardDate.map({ calendar.startOfDay(for: $0) }), last == today {
            return 0
        }

        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        if let last = lastRewardDate.map({ calendar.startOfDay(for: $0) }), last == yesterday {
            streakCount = max(1, streakCount + 1)
        } else {
            streakCount = 1
        }

        lastRewardDate = today
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        return 0
    }

    func updateBoardRank(_ rank: Int) {
        boardRank = max(0, rank)
    }

    // MARK: - Evaluate today from live managers

    func syncFromApp(
        food: FoodDataManager,
        calories: CalorieGoalManager,
        water: WaterManager,
        health: HealthKitManager,
        workoutGoal: WorkoutGoalManager
    ) {
        let entries = food.todayFoodEntries
        var breakfast = false
        var lunch = false
        var dinner = false
        var consumed = 0.0
        var protein = 0.0
        for entry in entries {
            consumed += entry.calories
            protein += entry.protein
            switch entry.resolvedMealType {
            case MealType.breakfast.rawValue:
                breakfast = true
            case MealType.lunch.rawValue:
                lunch = true
            case MealType.dinner.rawValue:
                dinner = true
            default:
                break
            }
        }

        let workoutCandidates = Self.workoutCandidates(from: health.workouts)

        let movementMet = XPRules.movementGoalMet(
            minutes: workoutGoal.todayMinutes(from: health.workouts),
            targetMinutes: workoutGoal.targetMinutes,
            goalEnabled: workoutGoal.isEnabled,
            exerciseMinutes: health.exerciseMinutes
        )

        let snapshot = DailyActivitySnapshot(
            dayKey: XPRules.dayKey(),
            breakfastLogged: breakfast,
            lunchLogged: lunch,
            dinnerLogged: dinner,
            caloriesConsumed: consumed,
            calorieGoal: calories.dailyCalorieGoal,
            proteinConsumed: protein,
            proteinGoal: calories.dailyProteinGoal,
            waterGoalMet: water.progress >= 1.0,
            movementGoalMet: movementMet,
            workouts: workoutCandidates,
            streakCount: streakCount
        )
        applyEvaluation(snapshot)
    }

    /// Read-only hook after workouts are already saved (Quick Add or HealthKit list).
    /// Does not write HealthKit or the local workout list.
    func observeWorkouts(_ workouts: [WorkoutData]) {
        let candidates = Self.workoutCandidates(from: workouts)
        let day = XPRules.dayKey()
        if var cached = lastSnapshot, cached.dayKey == day {
            cached.workouts = candidates
            cached.streakCount = streakCount
            applyEvaluation(cached)
            return
        }
        let existing = ledgerByDay[day] ?? DailyXPLedger(dayKey: day)
        let result = XPEngine.evaluateWorkoutsOnly(
            candidates: candidates,
            ledger: existing,
            dayKey: day
        )
        ledgerByDay[day] = result.ledger
        if result.xpDelta != 0 {
            applyXPDelta(result.xpDelta, gains: result.gains)
        }
    }

    private static func workoutCandidates(from workouts: [WorkoutData]) -> [WorkoutXPCandidate] {
        var result: [WorkoutXPCandidate] = []
        for workout in workouts {
            let minutes = Int((workout.duration / 60.0).rounded(.down))
            result.append(
                WorkoutXPCandidate(
                    id: workout.id.uuidString,
                    durationMinutes: minutes,
                    calories: workout.caloriesBurned
                )
            )
        }
        return result
    }

    // MARK: - Internals

    private func applyEvaluation(_ snapshot: DailyActivitySnapshot) {
        let start = currentStreakStart()
        let awarded3 = datesMatch(streak3Start, start) && snapshot.streakCount >= 3
        let awarded7 = datesMatch(streak7Start, start) && snapshot.streakCount >= 7
        let existing = ledgerByDay[snapshot.dayKey] ?? DailyXPLedger(dayKey: snapshot.dayKey)

        let result = XPEngine.evaluate(
            snapshot: snapshot,
            ledger: existing,
            awardedStreak3: awarded3,
            awardedStreak7: awarded7
        )
        lastSnapshot = snapshot
        ledgerByDay[snapshot.dayKey] = result.ledger
        todaysQuest = DailyQuestStatus(title: result.questKind.title, isComplete: result.questComplete)

        if result.xpDelta != 0 {
            applyXPDelta(result.xpDelta, gains: result.gains)
        }

        if result.questJustCompleted, !questCoinDays.contains(snapshot.dayKey) {
            questCoinDays.insert(snapshot.dayKey)
            _ = sparksManager?.earnCoins(XPRules.dailyQuestCoins, reason: "dailyQuest")
        }

        if snapshot.streakCount >= 3 && !awarded3 && result.ledger.amount(for: .streak3) > 0 {
            streak3Start = start
            _ = sparksManager?.earnCoins(XPRules.streak3Coins, reason: "streak3")
        }
        if snapshot.streakCount >= 7 && !awarded7 && result.ledger.amount(for: .streak7) > 0 {
            streak7Start = start
            _ = sparksManager?.earnCoins(XPRules.streak7Coins, reason: "streak7")
        }
    }

    private func applyXPDelta(_ delta: Int, gains: [XPGain]) {
        guard delta != 0 else { return }
        let previousLevel = level
        totalXP = max(0, totalXP + delta)
        recomputeLevel(from: totalXP, announce: true)

        if delta > 0 {
            let names = gains.map(\.displayName)
            let label: String
            if names.count == 1 {
                label = names[0]
            } else if names.count > 1 {
                label = names.joined(separator: " · ")
            } else {
                label = "XP"
            }
            xpGainEvent = XPGainEvent(amount: delta, actionName: label, timestamp: Date())
            showXPToast("\(label) — +\(delta) XP")
        }

        if level > previousLevel {
            handleLevelUp(from: previousLevel, to: level)
        }
    }

    private func handleLevelUp(from previous: Int, to newLevel: Int) {
        var coinsGained = 0
        var crystalsGained = 0
        if let sparks = sparksManager {
            for L in (previous + 1)...newLevel {
                coinsGained += sparks.earnLevelUpCoins(toLevel: L)
                crystalsGained += sparks.earnMilestoneCrystals(forLevel: L)
            }
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        levelUpEvent = newLevel

        var parts = ["Level up! → \(newLevel)"]
        if coinsGained > 0 {
            parts.append("+\(coinsGained) Coins")
        }
        if crystalsGained > 0 {
            parts.append("+\(crystalsGained) Crystals")
        }
        levelUpBanner = parts.joined(separator: "  ·  ")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) { [weak self] in
            if self?.levelUpBanner?.contains("\(newLevel)") == true {
                self?.levelUpBanner = nil
            }
        }
    }

    private func recomputeLevel(from total: Int, announce: Bool) {
        let result = XPRules.level(fromTotalXP: total)
        level = result.level
        xpIntoLevel = result.xpIntoLevel
        xpForNextLevel = result.xpForNext
        levelTitle = XPRules.title(forLevel: result.level)
        _ = announce
    }

    private func showXPToast(_ message: String) {
        xpToast = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) { [weak self] in
            if self?.xpToast == message {
                self?.xpToast = nil
            }
        }
    }

    private func refreshQuestStatus() {
        let day = XPRules.dayKey()
        let quest = DailyQuestKind.quest(forDayKey: day)
        let complete = (ledgerByDay[day]?.amount(for: .dailyQuest) ?? 0) > 0
        todaysQuest = DailyQuestStatus(title: quest.title, isComplete: complete)
    }

    private func currentStreakStart() -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let days = max(1, streakCount) - 1
        return calendar.date(byAdding: .day, value: -days, to: today) ?? today
    }

    private func datesMatch(_ lhs: Date?, _ rhs: Date) -> Bool {
        guard let lhs else { return false }
        return Calendar.current.isDate(lhs, inSameDayAs: rhs)
    }

    private func persistLedgers() {
        if let data = try? JSONEncoder().encode(ledgerByDay) {
            UserDefaults.standard.set(data, forKey: Keys.ledgers)
        }
    }

    private func persistOptionalDate(_ date: Date?, key: String) {
        if let date {
            UserDefaults.standard.set(date.timeIntervalSince1970, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    private static func readOptionalDate(_ defaults: UserDefaults, key: String) -> Date? {
        guard defaults.object(forKey: key) != nil else { return nil }
        return Date(timeIntervalSince1970: defaults.double(forKey: key))
    }
}
