import Foundation
import SwiftUI

/// Persists the chosen build and STR/END/VIT/AGI/REC. Observes the same
/// published food / workout / water state as XP — does not write tracking data.
@MainActor
final class CharacterManager: ObservableObject {
    @Published private(set) var selectedBuild: BuildKind? {
        didSet {
            if let selectedBuild {
                UserDefaults.standard.set(selectedBuild.rawValue, forKey: Keys.build)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.build)
            }
        }
    }

    @Published private(set) var stats: CharacterStats {
        didSet { persistStats() }
    }

    /// Lifetime floor so claw-backs never drop below the Phase 2 baseline.
    private var floorStats: CharacterStats {
        didSet { persistFloor() }
    }

    private var ledgerByDay: [String: DailyStatLedger] {
        didSet { persistLedgers() }
    }

    private var didBackfill: Bool {
        didSet { UserDefaults.standard.set(didBackfill, forKey: Keys.didBackfill) }
    }

    private var lastSnapshot: DailyStatSnapshot?

    private enum Keys {
        static let build = "characterManager.build"
        static let stats = "characterManager.stats.v1"
        static let floor = "characterManager.statFloor.v1"
        static let ledgers = "characterManager.statLedger.v1"
        static let didBackfill = "characterManager.didBackfill"
    }

    init() {
        let defaults = UserDefaults.standard
        self.selectedBuild = BuildKind.parse(defaults.string(forKey: Keys.build))

        if let data = defaults.data(forKey: Keys.stats),
           let decoded = try? JSONDecoder().decode(CharacterStats.self, from: data) {
            self.stats = decoded.clamped()
        } else {
            self.stats = StatRules.floorStats()
        }

        if let data = defaults.data(forKey: Keys.floor),
           let decoded = try? JSONDecoder().decode(CharacterStats.self, from: data) {
            self.floorStats = decoded.clamped()
        } else {
            self.floorStats = StatRules.floorStats()
        }

        if let data = defaults.data(forKey: Keys.ledgers),
           let map = try? JSONDecoder().decode([String: DailyStatLedger].self, from: data) {
            self.ledgerByDay = map
        } else {
            self.ledgerByDay = [:]
        }

        self.didBackfill = defaults.bool(forKey: Keys.didBackfill)
        self.stats = stats.raised(toFloor: floorStats)
    }

    var hasChosenBuild: Bool {
        selectedBuild != nil
    }

    var buildDisplayName: String {
        selectedBuild?.uppercaseName ?? ""
    }

    func isPrimary(_ stat: CharacterStat) -> Bool {
        selectedBuild?.isPrimary(stat) == true
    }

    /// Changing build does not reset XP, level, or earned stats.
    func selectBuild(_ build: BuildKind) {
        selectedBuild = build
        if let snapshot = lastSnapshot {
            applyEvaluation(snapshot)
        }
    }

    func displayedValue(for stat: CharacterStat) -> Int {
        stats.displayed(stat)
    }

    func barFraction(for stat: CharacterStat) -> Double {
        let value = stats.value(for: stat)
        guard StatRules.displayCap > 0 else { return 0 }
        return min(1.0, max(0, value / StatRules.displayCap))
    }

    // MARK: - Observe (same hook points as XP)

    func syncFromApp(
        food: FoodDataManager,
        calories: CalorieGoalManager,
        water: WaterManager,
        health: HealthKitManager,
        workoutGoal: WorkoutGoalManager,
        level: Int
    ) {
        backfillIfNeeded(
            food: food,
            calories: calories,
            level: level
        )

        let snapshot = makeSnapshot(
            entries: food.todayFoodEntries,
            calories: calories,
            waterGoalMet: water.progress >= 1.0,
            workouts: health.workouts,
            workoutGoal: workoutGoal,
            exerciseMinutes: health.exerciseMinutes
        )
        applyEvaluation(snapshot)
    }

    /// Seed existing users once. Uses recent food history when present;
    /// otherwise a level-based baseline so a typical L37 sits around 20–45.
    private func backfillIfNeeded(
        food: FoodDataManager,
        calories: CalorieGoalManager,
        level: Int
    ) {
        guard !didBackfill else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lookbackDays = 14
        let start = calendar.date(byAdding: .day, value: -lookbackDays, to: today) ?? today
        let history = food.entries(from: start, to: today)

        var seeded = StatRules.floorStats()
        if level > 1 {
            seeded = StatRules.baselineStats(level: level, build: selectedBuild)
        }

        if !history.isEmpty {
            var fromHistory = StatRules.floorStats()
            for offset in 0..<lookbackDays {
                guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
                let dayStart = calendar.startOfDay(for: day)
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
                let dayEntries = history.filter { entry in
                    entry.timestamp >= dayStart && entry.timestamp < dayEnd
                }
                if dayEntries.isEmpty { continue }
                let snapshot = makeFoodOnlySnapshot(
                    dayKey: XPRules.dayKey(for: dayStart),
                    entries: dayEntries,
                    calories: calories,
                    workouts: [],
                    movementGoalMet: false,
                    waterGoalMet: false
                )
                let gains = StatEngine.desiredGains(snapshot: snapshot, build: selectedBuild)
                for stat in CharacterStat.allCases {
                    fromHistory.add(gains.value(for: stat), to: stat)
                }
            }
            // Prefer the higher of baseline vs observed recent history so a
            // high-level user with a quiet last two weeks is not reset low.
            seeded = CharacterStats(
                strength: max(seeded.strength, fromHistory.strength),
                endurance: max(seeded.endurance, fromHistory.endurance),
                vitality: max(seeded.vitality, fromHistory.vitality),
                agility: max(seeded.agility, fromHistory.agility),
                recovery: max(seeded.recovery, fromHistory.recovery)
            )
        }

        floorStats = seeded
        stats = stats.raised(toFloor: seeded)
        didBackfill = true
    }

    private func applyEvaluation(_ snapshot: DailyStatSnapshot) {
        lastSnapshot = snapshot
        let existing = ledgerByDay[snapshot.dayKey] ?? DailyStatLedger(dayKey: snapshot.dayKey)
        let result = StatEngine.evaluate(
            snapshot: snapshot,
            ledger: existing,
            build: selectedBuild
        )
        ledgerByDay[snapshot.dayKey] = result.ledger

        var next = stats
        for stat in CharacterStat.allCases {
            next.add(result.delta.value(for: stat), to: stat)
        }
        stats = next.raised(toFloor: floorStats)
    }

    private func makeSnapshot(
        entries: [FoodEntry],
        calories: CalorieGoalManager,
        waterGoalMet: Bool,
        workouts: [WorkoutData],
        workoutGoal: WorkoutGoalManager,
        exerciseMinutes: Double
    ) -> DailyStatSnapshot {
        let meals = mealFlags(from: entries)
        let movementMet = XPRules.movementGoalMet(
            minutes: workoutGoal.todayMinutes(from: workouts),
            targetMinutes: workoutGoal.targetMinutes,
            goalEnabled: workoutGoal.isEnabled,
            exerciseMinutes: exerciseMinutes
        )
        return DailyStatSnapshot(
            dayKey: XPRules.dayKey(),
            breakfastLogged: meals.breakfast,
            lunchLogged: meals.lunch,
            dinnerLogged: meals.dinner,
            caloriesConsumed: meals.calories,
            calorieGoal: calories.dailyCalorieGoal,
            proteinConsumed: meals.protein,
            proteinGoal: calories.dailyProteinGoal,
            waterGoalMet: waterGoalMet,
            movementGoalMet: movementMet,
            workouts: Self.statCandidates(from: workouts)
        )
    }

    private func makeFoodOnlySnapshot(
        dayKey: String,
        entries: [FoodEntry],
        calories: CalorieGoalManager,
        workouts: [StatWorkoutCandidate],
        movementGoalMet: Bool,
        waterGoalMet: Bool
    ) -> DailyStatSnapshot {
        let meals = mealFlags(from: entries)
        return DailyStatSnapshot(
            dayKey: dayKey,
            breakfastLogged: meals.breakfast,
            lunchLogged: meals.lunch,
            dinnerLogged: meals.dinner,
            caloriesConsumed: meals.calories,
            calorieGoal: calories.dailyCalorieGoal,
            proteinConsumed: meals.protein,
            proteinGoal: calories.dailyProteinGoal,
            waterGoalMet: waterGoalMet,
            movementGoalMet: movementGoalMet,
            workouts: workouts
        )
    }

    private func mealFlags(from entries: [FoodEntry]) -> (breakfast: Bool, lunch: Bool, dinner: Bool, calories: Double, protein: Double) {
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
        return (breakfast, lunch, dinner, consumed, protein)
    }

    private static func statCandidates(from workouts: [WorkoutData]) -> [StatWorkoutCandidate] {
        var result: [StatWorkoutCandidate] = []
        for workout in workouts {
            let minutes = Int((workout.duration / 60.0).rounded(.down))
            let family = StatRules.classifyWorkout(
                type: workout.workoutType,
                customName: workout.customName
            )
            result.append(
                StatWorkoutCandidate(
                    id: workout.id.uuidString,
                    durationMinutes: minutes,
                    calories: workout.caloriesBurned,
                    family: family
                )
            )
        }
        return result
    }

    private func persistStats() {
        if let data = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(data, forKey: Keys.stats)
        }
    }

    private func persistFloor() {
        if let data = try? JSONEncoder().encode(floorStats) {
            UserDefaults.standard.set(data, forKey: Keys.floor)
        }
    }

    private func persistLedgers() {
        if let data = try? JSONEncoder().encode(ledgerByDay) {
            UserDefaults.standard.set(data, forKey: Keys.ledgers)
        }
    }
}
