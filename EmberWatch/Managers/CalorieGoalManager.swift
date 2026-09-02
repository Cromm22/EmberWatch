import Foundation
import SwiftUI

@MainActor
class CalorieGoalManager: ObservableObject {
    @Published var dailyCalorieGoal: Double {
        didSet {
            UserDefaults.standard.set(dailyCalorieGoal, forKey: "dailyCalorieGoal")
        }
    }
    
    /// When true, remaining = goal + burned (food logged still shows in diary but is not subtracted).
    @Published var ignoreFoodFromRemaining: Bool {
        didSet {
            UserDefaults.standard.set(ignoreFoodFromRemaining, forKey: "ignoreFoodFromRemaining")
        }
    }
    
    init() {
        let goal = UserDefaults.standard.double(forKey: "dailyCalorieGoal")
        self.dailyCalorieGoal = goal == 0 ? 2000 : goal
        self.ignoreFoodFromRemaining = UserDefaults.standard.bool(forKey: "ignoreFoodFromRemaining")
    }
    
    func calculateRemainingCalories(burned: Double, consumed: Double) -> Double {
        if ignoreFoodFromRemaining {
            return dailyCalorieGoal + burned
        }
        return dailyCalorieGoal + burned - consumed
    }
}
