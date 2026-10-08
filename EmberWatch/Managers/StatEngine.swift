import Foundation
import HealthKit

/// The five character stats. File-level / Sendable so Swift 6 does not isolate
/// this table on MainActor.
enum CharacterStat: String, CaseIterable, Codable, Sendable, Identifiable {
    case strength
    case endurance
    case vitality
    case agility
    case recovery

    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .strength: return "STR"
        case .endurance: return "END"
        case .vitality: return "VIT"
        case .agility: return "AGI"
        case .recovery: return "REC"
        }
    }

    var fullName: String {
        switch self {
        case .strength: return "Strength"
        case .endurance: return "Endurance"
        case .vitality: return "Vitality"
        case .agility: return "Agility"
        case .recovery: return "Recovery"
        }
    }
}

enum WorkoutStatFamily: String, Codable, Sendable {
    case strength
    case cardio
    case mobility
    case recovery
    case other
}

/// Pure Phase 2 stat rules. Same safety gates as XP. Slow growth that roughly
/// tracks level (a typical L37 user lands around 20–45 per stat).
enum StatRules: Sendable {
    static let floorValue = 5.0
    /// Soft display cap for compact bars (stats can exceed this; bar clamps).
    static let displayCap = 100.0
    static let primaryStatMultiplier = 1.5

    /// Daily cap *after* the build multiplier. ~0.70 × ~50 active days ≈ 35.
    static let dailyCap = 0.70

    static let strengthPerWorkout = 0.40
    static let cardioPerWorkout = 0.32
    static let mobilityPerWorkout = 0.40
    static let movementGoalEndurance = 0.20
    static let completeNutritionVitality = 0.22
    static let proteinRangeVitality = 0.18
    static let calorieRangeVitality = 0.18
    static let recoveryGoalRec = 0.28
    static let restDayRec = 0.22

    static let maxCountedWorkouts = 2

    /// Starting stats for a brand-new Level 1 character.
    static func floorStats() -> CharacterStats {
        CharacterStats(
            strength: floorValue,
            endurance: floorValue,
            vitality: floorValue,
            agility: floorValue,
            recovery: floorValue
        )
    }

    /// Level-based baseline for existing users when history is thin.
    /// L37 → ~28 secondary / ~33 primary (inside the 20–45 band).
    static func baselineStats(level: Int, build: BuildKind?) -> CharacterStats {
        let L = Double(max(1, min(level, XPRules.maxLevel)))
        let mid = floorValue + (L - 1.0) * 0.65
        let primaryMid = mid * 1.15
        let secondaryMid = mid * 0.85
        var stats = CharacterStats(
            strength: secondaryMid,
            endurance: secondaryMid,
            vitality: secondaryMid,
            agility: secondaryMid,
            recovery: secondaryMid
        )
        if let build {
            if build == .mage {
                stats = CharacterStats(
                    strength: mid,
                    endurance: mid,
                    vitality: mid,
                    agility: mid,
                    recovery: mid
                )
            } else {
                for stat in CharacterStat.allCases where build.isPrimary(stat) {
                    stats.setValue(primaryMid, for: stat)
                }
            }
        }
        return stats.clamped()
    }

    static func classifyWorkout(
        type: HKWorkoutActivityType,
        customName: String?
    ) -> WorkoutStatFamily {
        if let family = classifyName(customName) {
            return family
        }
        return classifyType(type)
    }

    private static func classifyName(_ raw: String?) -> WorkoutStatFamily? {
        guard let raw else { return nil }
        let name = raw.lowercased()
        if name.isEmpty { return nil }
        if name.contains("yoga")
            || name.contains("stretch")
            || name.contains("pilates")
            || name.contains("mobility")
            || name.contains("flexib")
            || name.contains("tai chi")
            || name.contains("barre") {
            return .mobility
        }
        if name.contains("strength")
            || name.contains("lift")
            || name.contains("weight")
            || name.contains("dumbbell")
            || name.contains("barbell") {
            return .strength
        }
        if name.contains("run")
            || name.contains("walk")
            || name.contains("cycle")
            || name.contains("bike")
            || name.contains("cardio")
            || name.contains("swim")
            || name.contains("row")
            || name.contains("hik")
            || name.contains("ellipti") {
            return .cardio
        }
        if name.contains("rest")
            || name.contains("recover")
            || name.contains("cooldown")
            || name.contains("cool down") {
            return .recovery
        }
        return nil
    }

    private static func classifyType(_ type: HKWorkoutActivityType) -> WorkoutStatFamily {
        switch type {
        case .traditionalStrengthTraining,
             .functionalStrengthTraining,
             .coreTraining,
             .climbing,
             .martialArts,
             .boxing,
             .kickboxing,
             .wrestling:
            return .strength
        case .running,
             .walking,
             .cycling,
             .swimming,
             .elliptical,
             .rowing,
             .hiking,
             .stairs,
             .stairClimbing,
             .highIntensityIntervalTraining,
             .dance,
             .jumpRope,
             .mixedCardio,
             .handCycling,
             .wheelchairRunPace,
             .wheelchairWalkPace,
             .swimBikeRun,
             .cardioDance,
             .stepTraining,
             .skatingSports:
            return .cardio
        case .yoga,
             .flexibility,
             .pilates,
             .taiChi,
             .barre,
             .gymnastics:
            return .mobility
        case .mindAndBody,
             .cooldown:
            return .recovery
        default:
            return .other
        }
    }
}

struct CharacterStats: Equatable, Codable, Sendable {
    var strength: Double
    var endurance: Double
    var vitality: Double
    var agility: Double
    var recovery: Double

    func value(for stat: CharacterStat) -> Double {
        switch stat {
        case .strength: return strength
        case .endurance: return endurance
        case .vitality: return vitality
        case .agility: return agility
        case .recovery: return recovery
        }
    }

    mutating func setValue(_ value: Double, for stat: CharacterStat) {
        let clamped = max(0, value)
        switch stat {
        case .strength: strength = clamped
        case .endurance: endurance = clamped
        case .vitality: vitality = clamped
        case .agility: agility = clamped
        case .recovery: recovery = clamped
        }
    }

    mutating func add(_ amount: Double, to stat: CharacterStat) {
        setValue(value(for: stat) + amount, for: stat)
    }

    func displayed(_ stat: CharacterStat) -> Int {
        Int(value(for: stat).rounded(.down))
    }

    func clamped() -> CharacterStats {
        var next = self
        for stat in CharacterStat.allCases {
            next.setValue(max(0, value(for: stat)), for: stat)
        }
        return next
    }

    func raised(toFloor floor: CharacterStats) -> CharacterStats {
        CharacterStats(
            strength: max(strength, floor.strength),
            endurance: max(endurance, floor.endurance),
            vitality: max(vitality, floor.vitality),
            agility: max(agility, floor.agility),
            recovery: max(recovery, floor.recovery)
        )
    }
}

struct DailyStatLedger: Codable, Equatable, Sendable {
    var dayKey: String
    var strength: Double
    var endurance: Double
    var vitality: Double
    var agility: Double
    var recovery: Double

    init(
        dayKey: String,
        strength: Double = 0,
        endurance: Double = 0,
        vitality: Double = 0,
        agility: Double = 0,
        recovery: Double = 0
    ) {
        self.dayKey = dayKey
        self.strength = strength
        self.endurance = endurance
        self.vitality = vitality
        self.agility = agility
        self.recovery = recovery
    }

    func value(for stat: CharacterStat) -> Double {
        switch stat {
        case .strength: return strength
        case .endurance: return endurance
        case .vitality: return vitality
        case .agility: return agility
        case .recovery: return recovery
        }
    }

    mutating func setValue(_ value: Double, for stat: CharacterStat) {
        switch stat {
        case .strength: strength = value
        case .endurance: endurance = value
        case .vitality: vitality = value
        case .agility: agility = value
        case .recovery: recovery = value
        }
    }
}

struct StatWorkoutCandidate: Equatable, Sendable {
    var id: String
    var durationMinutes: Int
    var calories: Double
    var family: WorkoutStatFamily
}

struct DailyStatSnapshot: Equatable, Sendable {
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
    var workouts: [StatWorkoutCandidate]
}

struct StatEvaluation: Equatable, Sendable {
    var ledger: DailyStatLedger
    var delta: CharacterStats
}

/// Idempotent daily stat evaluator. No MainActor; no XP multipliers.
enum StatEngine: Sendable {
    static func evaluate(
        snapshot: DailyStatSnapshot,
        ledger existing: DailyStatLedger,
        build: BuildKind?
    ) -> StatEvaluation {
        let dayKey = snapshot.dayKey
        var ledger = existing
        if ledger.dayKey != dayKey {
            ledger = DailyStatLedger(dayKey: dayKey)
        }

        let desired = desiredGains(snapshot: snapshot, build: build)
        var delta = CharacterStats(
            strength: 0,
            endurance: 0,
            vitality: 0,
            agility: 0,
            recovery: 0
        )
        for stat in CharacterStat.allCases {
            let want = desired.value(for: stat)
            let have = ledger.value(for: stat)
            let change = want - have
            delta.setValue(change, for: stat)
            ledger.setValue(want, for: stat)
        }
        return StatEvaluation(ledger: ledger, delta: delta)
    }

    static func desiredGains(
        snapshot: DailyStatSnapshot,
        build: BuildKind?
    ) -> CharacterStats {
        var base = CharacterStats(
            strength: 0,
            endurance: 0,
            vitality: 0,
            agility: 0,
            recovery: 0
        )

        let eligible = snapshot.workouts.filter { candidate in
            !XPRules.isExtremeWorkout(
                durationMinutes: candidate.durationMinutes,
                calories: candidate.calories
            )
        }
        let counted = Array(eligible.prefix(StatRules.maxCountedWorkouts))

        var strengthHits = 0
        var cardioHits = 0
        var mobilityHits = 0
        var recoveryHits = 0
        for workout in counted {
            switch workout.family {
            case .strength:
                strengthHits += 1
            case .cardio, .other:
                cardioHits += 1
            case .mobility:
                mobilityHits += 1
            case .recovery:
                recoveryHits += 1
            }
        }

        if strengthHits > 0 {
            base.strength = StatRules.strengthPerWorkout * Double(strengthHits)
        }
        if cardioHits > 0 {
            base.endurance += StatRules.cardioPerWorkout * Double(cardioHits)
        }
        if snapshot.movementGoalMet {
            base.endurance += StatRules.movementGoalEndurance
        }
        if mobilityHits > 0 {
            base.agility = StatRules.mobilityPerWorkout * Double(mobilityHits)
        }

        let allMeals = snapshot.breakfastLogged && snapshot.lunchLogged && snapshot.dinnerLogged
        let extremeDeficit = isExtremeDeficit(
            consumed: snapshot.caloriesConsumed,
            goal: snapshot.calorieGoal
        )
        // Same safety as XP: no VIT from skipped meals or extreme deficits.
        if allMeals && !extremeDeficit {
            base.vitality += StatRules.completeNutritionVitality
            if XPRules.isInProteinRange(
                consumed: snapshot.proteinConsumed,
                goal: snapshot.proteinGoal
            ) {
                base.vitality += StatRules.proteinRangeVitality
            }
            if XPRules.isInCalorieRange(
                consumed: snapshot.caloriesConsumed,
                goal: snapshot.calorieGoal
            ) {
                base.vitality += StatRules.calorieRangeVitality
            }
        }

        if snapshot.waterGoalMet {
            base.recovery += StatRules.recoveryGoalRec
        }
        let trainedHard = strengthHits + cardioHits + mobilityHits
        let isRestDay = trainedHard == 0
        if isRestDay && (snapshot.waterGoalMet || allMeals || recoveryHits > 0) {
            base.recovery += StatRules.restDayRec
        }

        var scaled = CharacterStats(
            strength: 0,
            endurance: 0,
            vitality: 0,
            agility: 0,
            recovery: 0
        )
        for stat in CharacterStat.allCases {
            let multiplier = build?.multiplier(for: stat) ?? 1.0
            let raw = base.value(for: stat) * multiplier
            let capped = min(StatRules.dailyCap, raw)
            scaled.setValue(capped, for: stat)
        }
        return scaled
    }

    private static func isExtremeDeficit(consumed: Double, goal: Double) -> Bool {
        if consumed < XPRules.calorieSafeFloor { return true }
        if goal > 0 && consumed <= goal * XPRules.extremeDeficitFraction { return true }
        return false
    }
}
