import Foundation

/// One day's persisted XP rows. Recompute overwrites amounts; never double-awards.
struct DailyXPLedger: Codable, Equatable, Sendable {
    var dayKey: String
    /// `XPAction.rawValue` → XP currently counted.
    var actionXP: [String: Int]
    /// Workout IDs that received the +100 complete-workout award today (max 2).
    var workoutIDs: [String]

    init(dayKey: String, actionXP: [String: Int] = [:], workoutIDs: [String] = []) {
        self.dayKey = dayKey
        self.actionXP = actionXP
        self.workoutIDs = workoutIDs
    }

    func amount(for action: XPAction) -> Int {
        actionXP[action.rawValue] ?? 0
    }
}

struct WorkoutXPCandidate: Equatable, Sendable {
    var id: String
    var durationMinutes: Int
    var calories: Double
}

struct DailyActivitySnapshot: Equatable, Sendable {
    var dayKey: String
    var breakfastLogged: Bool
    var lunchLogged: Bool
    var dinnerLogged: Bool
    var caloriesConsumed: Double
    var calorieGoal: Double
    var proteinConsumed: Double
    var proteinGoal: Double
    var waterGoalMet: Bool
    var movementGoalMet: Bool
    var workouts: [WorkoutXPCandidate]
    var streakCount: Int
}

struct XPGain: Equatable, Sendable {
    var action: XPAction
    var amount: Int
    var displayName: String
}

struct XPEvaluation: Equatable, Sendable {
    var ledger: DailyXPLedger
    var xpDelta: Int
    var gains: [XPGain]
    var questKind: DailyQuestKind
    var questComplete: Bool
    var questJustCompleted: Bool
}

/// Idempotent daily XP evaluator. No MainActor; no multipliers.
enum XPEngine: Sendable {
    static func evaluate(
        snapshot: DailyActivitySnapshot,
        ledger existing: DailyXPLedger,
        awardedStreak3: Bool,
        awardedStreak7: Bool
    ) -> XPEvaluation {
        let dayKey = snapshot.dayKey
        var ledger = existing
        if ledger.dayKey != dayKey {
            ledger = DailyXPLedger(dayKey: dayKey)
        }

        var desired: [XPAction: Int] = [:]

        desired[.logBreakfast] = snapshot.breakfastLogged ? XPRules.breakfastXP : 0
        desired[.logLunch] = snapshot.lunchLogged ? XPRules.lunchXP : 0
        desired[.logDinner] = snapshot.dinnerLogged ? XPRules.dinnerXP : 0

        let allMeals = snapshot.breakfastLogged && snapshot.lunchLogged && snapshot.dinnerLogged
        desired[.completeNutrition] = allMeals ? XPRules.completeNutritionXP : 0

        let proteinOK = XPRules.isInProteinRange(
            consumed: snapshot.proteinConsumed,
            goal: snapshot.proteinGoal
        )
        desired[.proteinTarget] = proteinOK ? XPRules.proteinRangeXP : 0

        let calorieOK = allMeals && XPRules.isInCalorieRange(
            consumed: snapshot.caloriesConsumed,
            goal: snapshot.calorieGoal
        )
        desired[.calorieTarget] = calorieOK ? XPRules.calorieRangeXP : 0

        let workoutPlan = selectWorkouts(
            candidates: snapshot.workouts,
            previouslyAwarded: ledger.workoutIDs
        )
        ledger.workoutIDs = workoutPlan.ids
        let workoutXP = min(workoutPlan.xp, XPRules.exerciseXPDailyCap)
        desired[.workout] = workoutXP

        desired[.movementGoal] = snapshot.movementGoalMet ? XPRules.movementGoalXP : 0
        desired[.recoveryGoal] = snapshot.waterGoalMet ? XPRules.recoveryGoalXP : 0

        let quest = DailyQuestKind.quest(forDayKey: dayKey)
        let questComplete = isQuestComplete(quest, snapshot: snapshot, allMeals: allMeals, proteinOK: proteinOK, calorieOK: calorieOK)
        desired[.dailyQuest] = questComplete ? XPRules.dailyQuestXP : 0

        // Streak bonuses are once per streak *run*, not every day the count stays ≥ 3.
        desired[.streak3] = (!awardedStreak3 && snapshot.streakCount >= 3) ? XPRules.streak3XP : ledger.amount(for: .streak3)
        desired[.streak7] = (!awardedStreak7 && snapshot.streakCount >= 7) ? XPRules.streak7XP : ledger.amount(for: .streak7)
        if awardedStreak3 && snapshot.streakCount < 3 {
            desired[.streak3] = 0
        }
        if awardedStreak7 && snapshot.streakCount < 7 {
            desired[.streak7] = 0
        }

        var delta = 0
        var gains: [XPGain] = []
        var nextAmounts: [String: Int] = ledger.actionXP

        let actions: [XPAction] = [
            .logBreakfast, .logLunch, .logDinner, .completeNutrition,
            .proteinTarget, .calorieTarget, .workout, .movementGoal,
            .recoveryGoal, .dailyQuest, .streak3, .streak7
        ]
        for action in actions {
            let want = desired[action] ?? 0
            let have = ledger.amount(for: action)
            let change = want - have
            if change != 0 {
                delta += change
                nextAmounts[action.rawValue] = want
                if change > 0 {
                    let name: String
                    if action == .dailyQuest {
                        name = "Daily quest: \(quest.title)"
                    } else {
                        name = action.displayName
                    }
                    gains.append(XPGain(action: action, amount: change, displayName: name))
                }
            } else {
                nextAmounts[action.rawValue] = want
            }
        }
        ledger.actionXP = nextAmounts

        let questWasComplete = existing.dayKey == dayKey && existing.amount(for: .dailyQuest) > 0
        let questJustCompleted = questComplete && !questWasComplete

        return XPEvaluation(
            ledger: ledger,
            xpDelta: delta,
            gains: gains,
            questKind: quest,
            questComplete: questComplete,
            questJustCompleted: questJustCompleted
        )
    }

    /// Updates only workout XP rows so a Workout-tab hook cannot zero meal awards.
    static func evaluateWorkoutsOnly(
        candidates: [WorkoutXPCandidate],
        ledger existing: DailyXPLedger,
        dayKey: String
    ) -> XPEvaluation {
        var ledger = existing
        if ledger.dayKey != dayKey {
            ledger = DailyXPLedger(dayKey: dayKey)
        }
        let workoutPlan = selectWorkouts(
            candidates: candidates,
            previouslyAwarded: ledger.workoutIDs
        )
        ledger.workoutIDs = workoutPlan.ids
        let want = min(workoutPlan.xp, XPRules.exerciseXPDailyCap)
        let have = ledger.amount(for: .workout)
        let change = want - have
        var gains: [XPGain] = []
        if change != 0 {
            ledger.actionXP[XPAction.workout.rawValue] = want
            if change > 0 {
                gains.append(XPGain(action: .workout, amount: change, displayName: XPAction.workout.displayName))
            }
        }
        let quest = DailyQuestKind.quest(forDayKey: dayKey)
        return XPEvaluation(
            ledger: ledger,
            xpDelta: change,
            gains: gains,
            questKind: quest,
            questComplete: ledger.amount(for: .dailyQuest) > 0,
            questJustCompleted: false
        )
    }

    private static func selectWorkouts(
        candidates: [WorkoutXPCandidate],
        previouslyAwarded: [String]
    ) -> (ids: [String], xp: Int) {
        let eligible = candidates.filter { candidate in
            !XPRules.isExtremeWorkout(
                durationMinutes: candidate.durationMinutes,
                calories: candidate.calories
            )
        }
        let eligibleIDs = eligible.map(\.id)
        let eligibleSet = Set(eligibleIDs)
        let kept = previouslyAwarded.filter { eligibleSet.contains($0) }
        var chosen = Array(kept.prefix(XPRules.maxWorkoutsPerDay))
        if chosen.count < XPRules.maxWorkoutsPerDay {
            let chosenSet = Set(chosen)
            for id in eligibleIDs where !chosenSet.contains(id) {
                chosen.append(id)
                if chosen.count >= XPRules.maxWorkoutsPerDay { break }
            }
        }
        let xp = chosen.count * XPRules.workoutXP
        return (chosen, xp)
    }

    private static func isQuestComplete(
        _ quest: DailyQuestKind,
        snapshot: DailyActivitySnapshot,
        allMeals: Bool,
        proteinOK: Bool,
        calorieOK: Bool
    ) -> Bool {
        switch quest {
        case .proteinRange:
            return proteinOK
        case .logThreeMeals:
            return allMeals
        case .movementGoal:
            return snapshot.movementGoalMet
        case .calorieRange:
            return calorieOK
        case .recoveryGoal:
            return snapshot.waterGoalMet
        }
    }
}
