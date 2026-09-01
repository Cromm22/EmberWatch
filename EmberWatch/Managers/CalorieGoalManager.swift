import Foundation
import SwiftUI

@MainActor
class CalorieGoalManager: ObservableObject {
    @Published var dailyCalorieGoal: Double {
        didSet {
            UserDefaults.standard.set(dailyCalorieGoal, forKey: "dailyCalorieGoal")
        }
    }
    
    @Published var currentLevel: Int {
        didSet {
            UserDefaults.standard.set(currentLevel, forKey: "currentLevel")
        }
    }
    
    @Published var currentXP: Int {
        didSet {
            UserDefaults.standard.set(currentXP, forKey: "currentXP")
        }
    }
    
    init() {
        let goal = UserDefaults.standard.double(forKey: "dailyCalorieGoal")
        let level = UserDefaults.standard.integer(forKey: "currentLevel")
        let xp = UserDefaults.standard.integer(forKey: "currentXP")
        self.dailyCalorieGoal = goal == 0 ? 2000 : goal
        self.currentLevel = level == 0 ? 1 : level
        self.currentXP = xp
    }
    
    func calculateRemainingCalories(burned: Double, consumed: Double) -> Double {
        return dailyCalorieGoal + burned - consumed
    }
    
    func xpForNextLevel() -> Int {
        return currentLevel * 100
    }
    
    func xpProgress() -> Double {
        let needed = xpForNextLevel()
        return min(Double(currentXP) / Double(needed), 1.0)
    }
    
    func addXP(_ amount: Int) {
        currentXP += amount
        
        while currentXP >= xpForNextLevel() {
            currentXP -= xpForNextLevel()
            currentLevel += 1
        }
    }
}
