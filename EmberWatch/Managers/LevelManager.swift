import Foundation
import SwiftUI
import UIKit

/// Central XP / leveling (1…100). Tune base awards here.
@MainActor
final class LevelManager: ObservableObject {
    // MARK: - Tunable base XP (before board multiplier)
    static let waterServingXP = 5
    static let caloriesPerXP = 1          // 1 XP per new calorie burned
    static let exerciseXP = 50
    static let challengeXP = 25
    static let maxLevel = 100
    
    /// XP required to advance from level L → L+1.
    static func xpToAdvance(from level: Int) -> Int {
        let L = max(1, min(level, maxLevel))
        return 100 + (L - 1) * 25
    }
    
    /// Cumulative XP required to *reach* `level` (level 1 = 0).
    static func cumulativeXP(forLevel level: Int) -> Int {
        let capped = max(1, min(level, maxLevel + 1))
        var total = 0
        if capped <= 1 { return 0 }
        for L in 1..<(capped) {
            total += xpToAdvance(from: L)
        }
        return total
    }
    
    @Published private(set) var totalXP: Int {
        didSet { UserDefaults.standard.set(totalXP, forKey: Keys.totalXP) }
    }
    
    /// 1…100 derived from totalXP.
    @Published private(set) var level: Int = 1
    
    /// XP progress within the current level (0…needed), or overflow at 100.
    @Published private(set) var xpIntoLevel: Int = 0
    @Published private(set) var xpForNextLevel: Int = 100
    
    /// Board rank used for multiplier (1 = first). 0 / nil → ×1.0
    @Published var boardRank: Int = 0 {
        didSet { UserDefaults.standard.set(boardRank, forKey: Keys.boardRank) }
    }
    
    @Published var levelUpBanner: String? = nil
    
    private var awardedWorkoutIDs: Set<String> {
        didSet {
            UserDefaults.standard.set(Array(awardedWorkoutIDs), forKey: Keys.awardedWorkouts)
        }
    }
    
    private var lastAwardedBurned: Double {
        didSet {
            UserDefaults.standard.set(lastAwardedBurned, forKey: Keys.lastAwardedBurned)
            UserDefaults.standard.set(Self.todayKey(), forKey: Keys.lastAwardedBurnedDay)
        }
    }
    
    private var lastAwardedBurnedDay: String
    
    /// friendId → yyyy-MM-dd of last challenge award
    private var challengeAwards: [String: String] {
        didSet {
            if let data = try? JSONEncoder().encode(challengeAwards) {
                UserDefaults.standard.set(data, forKey: Keys.challengeAwards)
            }
        }
    }
    
    private enum Keys {
        static let totalXP = "levelManager.totalXP"
        static let boardRank = "levelManager.boardRank"
        static let awardedWorkouts = "levelManager.awardedWorkoutIDs"
        static let lastAwardedBurned = "levelManager.lastAwardedBurned"
        static let lastAwardedBurnedDay = "levelManager.lastAwardedBurnedDay"
        static let challengeAwards = "levelManager.challengeAwards"
        static let migrated = "levelManager.migratedFromCalorieGoal"
    }
    
    init() {
        let defaults = UserDefaults.standard
        
        // One-time migrate from CalorieGoalManager stub XP if present.
        if !defaults.bool(forKey: Keys.migrated) {
            let oldLevel = defaults.integer(forKey: "currentLevel")
            let oldXP = defaults.integer(forKey: "currentXP")
            if oldLevel > 0 || oldXP > 0 {
                var migrated = 0
                let L = max(1, oldLevel == 0 ? 1 : oldLevel)
                // Old curve: need L*100 to leave level L
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
        
        self.totalXP = defaults.integer(forKey: Keys.totalXP)
        self.boardRank = defaults.integer(forKey: Keys.boardRank)
        let ids = defaults.stringArray(forKey: Keys.awardedWorkouts) ?? []
        self.awardedWorkoutIDs = Set(ids)
        
        let day = defaults.string(forKey: Keys.lastAwardedBurnedDay) ?? ""
        self.lastAwardedBurnedDay = day
        if day == Self.todayKey() {
            self.lastAwardedBurned = defaults.double(forKey: Keys.lastAwardedBurned)
        } else {
            self.lastAwardedBurned = 0
            self.lastAwardedBurnedDay = Self.todayKey()
        }
        
        if let data = defaults.data(forKey: Keys.challengeAwards),
           let map = try? JSONDecoder().decode([String: String].self, from: data) {
            self.challengeAwards = map
        } else {
            self.challengeAwards = [:]
        }
        
        recomputeLevel(from: totalXP, announce: false)
    }
    
    // MARK: - Multiplier
    
    var boardMultiplier: Double {
        switch boardRank {
        case 1: return 1.30
        case 2: return 1.20
        case 3: return 1.10
        default: return 1.0
        }
    }
    
    var boardMultiplierLabel: String? {
        switch boardRank {
        case 1: return "+30% XP"
        case 2: return "+20% XP"
        case 3: return "+10% XP"
        default: return nil
        }
    }
    
    var progressFraction: Double {
        if level >= Self.maxLevel {
            return 1.0
        }
        guard xpForNextLevel > 0 else { return 0 }
        return min(1.0, Double(xpIntoLevel) / Double(xpForNextLevel))
    }
    
    // MARK: - Awards
    
    @discardableResult
    func awardWaterServing() -> Int {
        award(base: Self.waterServingXP, reason: "water")
    }
    
    /// Award XP for *new* burned calories since last watermark today.
    @discardableResult
    func processBurnedCalories(_ currentTotal: Double) -> Int {
        resetBurnedWatermarkIfNewDay()
        let current = max(0, currentTotal)
        let delta = current - lastAwardedBurned
        guard delta >= 1 else {
            if current < lastAwardedBurned {
                // Day reset / HealthKit dip — don't claw back XP; realign watermark down.
                lastAwardedBurned = current
            }
            return 0
        }
        let whole = Int(delta.rounded(.down))
        guard whole > 0 else { return 0 }
        lastAwardedBurned = lastAwardedBurned + Double(whole)
        return award(base: whole * Self.caloriesPerXP, reason: "burned")
    }
    
    @discardableResult
    func awardWorkout(id: String) -> Int {
        guard !awardedWorkoutIDs.contains(id) else { return 0 }
        awardedWorkoutIDs.insert(id)
        return award(base: Self.exerciseXP, reason: "workout")
    }
    
    /// Process a batch of HealthKit / local workout IDs.
    @discardableResult
    func processWorkouts(ids: [String]) -> Int {
        var gained = 0
        for id in ids {
            gained += awardWorkout(id: id)
        }
        return gained
    }
    
    /// Once per friend per calendar day.
    @discardableResult
    func awardChallenge(friendId: String) -> Int {
        let today = Self.todayKey()
        if challengeAwards[friendId] == today {
            return 0
        }
        challengeAwards[friendId] = today
        return award(base: Self.challengeXP, reason: "challenge")
    }
    
    func canChallenge(friendId: String) -> Bool {
        challengeAwards[friendId] != Self.todayKey()
    }
    
    func updateBoardRank(_ rank: Int) {
        boardRank = max(0, rank)
    }
    
    // MARK: - Internals
    
    @discardableResult
    private func award(base: Int, reason: String) -> Int {
        guard base > 0 else { return 0 }
        let multiplied = Int((Double(base) * boardMultiplier).rounded())
        guard multiplied > 0 else { return 0 }
        
        let previousLevel = level
        totalXP += multiplied
        recomputeLevel(from: totalXP, announce: true)
        
        if level > previousLevel {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            levelUpBanner = "Level up! → \(level)"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) { [weak self] in
                if self?.levelUpBanner?.contains("\(self?.level ?? 0)") == true {
                    self?.levelUpBanner = nil
                }
            }
        }
        _ = reason
        return multiplied
    }
    
    private func recomputeLevel(from total: Int, announce: Bool) {
        var remaining = max(0, total)
        var L = 1
        while L < Self.maxLevel {
            let need = Self.xpToAdvance(from: L)
            if remaining < need { break }
            remaining -= need
            L += 1
        }
        level = L
        if L >= Self.maxLevel {
            xpIntoLevel = remaining
            xpForNextLevel = Self.xpToAdvance(from: Self.maxLevel) // vanity overflow denom
        } else {
            xpIntoLevel = remaining
            xpForNextLevel = Self.xpToAdvance(from: L)
        }
        _ = announce
    }
    
    private func resetBurnedWatermarkIfNewDay() {
        let today = Self.todayKey()
        if lastAwardedBurnedDay != today {
            lastAwardedBurnedDay = today
            lastAwardedBurned = 0
        }
    }
    
    private static func todayKey() -> String {
        let f = DateFormatter()
        f.calendar = Calendar.current
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}
