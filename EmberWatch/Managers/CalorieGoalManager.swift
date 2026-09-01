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
        self.dailyCalorieGoal = UserDefaults.standard.double(forKey: "dailyCalorieGoal")
        if self.dailyCalorieGoal == 0 {
            self.dailyCalorieGoal = 2000
        }
        
        self.currentLevel = UserDefaults.standard.integer(forKey: "currentLevel")
        if self.currentLevel == 0 {
            self.currentLevel = 1
        }
        
        self.currentXP = UserDefaults.standard.integer(forKey: "currentXP")
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
