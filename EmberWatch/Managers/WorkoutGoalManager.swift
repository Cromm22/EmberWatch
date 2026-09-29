import Foundation
import SwiftUI

/// Daily workout goal: on/off plus a target number of minutes per day.
@MainActor
class WorkoutGoalManager: ObservableObject {
    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Keys.enabled)
        }
    }
    
    /// Target workout minutes per day when the goal is on.
    @Published var targetMinutes: Int {
        didSet {
            let clamped = Self.clampMinutes(targetMinutes)
            if clamped != targetMinutes {
                targetMinutes = clamped
                return
            }
            UserDefaults.standard.set(targetMinutes, forKey: Keys.minutes)
        }
    }
    
    static let defaultMinutes = 30
    
    private enum Keys {
        static let enabled = "workoutDailyGoalEnabled"
        static let minutes = "workoutDailyGoalMinutes"
        static let hasMinutes = "workoutDailyGoalMinutesSet"
    }
    
    init() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: Keys.enabled) == nil {
            self.isEnabled = true
        } else {
            self.isEnabled = defaults.bool(forKey: Keys.enabled)
        }
        
        if defaults.bool(forKey: Keys.hasMinutes) {
            self.targetMinutes = Self.clampMinutes(defaults.integer(forKey: Keys.minutes))
        } else {
            self.targetMinutes = Self.defaultMinutes
            defaults.set(Self.defaultMinutes, forKey: Keys.minutes)
            defaults.set(true, forKey: Keys.hasMinutes)
        }
    }
    
    static func clampMinutes(_ value: Int) -> Int {
        max(5, min(value, 300))
    }
    
    /// Today's logged-workout minutes (duration / 60).
    func todayMinutes(from workouts: [WorkoutData]) -> Int {
        let total = workouts.reduce(0.0) { $0 + $1.duration } / 60.0
        return max(0, Int(total.rounded()))
    }
    
    func todayWorkoutCount(from workouts: [WorkoutData]) -> Int {
        workouts.count
    }
    
    func progress(from workouts: [WorkoutData]) -> Double {
        guard isEnabled, targetMinutes > 0 else { return 0 }
        return min(1, Double(todayMinutes(from: workouts)) / Double(targetMinutes))
    }
}
