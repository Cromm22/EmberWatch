import Foundation
import SwiftUI

@MainActor
class CalorieGoalManager: ObservableObject {
    @Published var dailyCalorieGoal: Double {
        didSet {
            UserDefaults.standard.set(dailyCalorieGoal, forKey: Keys.calories)
        }
    }
    
    @Published var dailyProteinGoal: Double {
        didSet {
            let clamped = Self.clampProtein(dailyProteinGoal)
            if clamped != dailyProteinGoal {
                dailyProteinGoal = clamped
                return
            }
            UserDefaults.standard.set(dailyProteinGoal, forKey: Keys.protein)
        }
    }
    
    @Published var dailyCarbsGoal: Double {
        didSet {
            let clamped = Self.clampCarbs(dailyCarbsGoal)
            if clamped != dailyCarbsGoal {
                dailyCarbsGoal = clamped
                return
            }
            UserDefaults.standard.set(dailyCarbsGoal, forKey: Keys.carbs)
        }
    }
    
    @Published var dailyFatGoal: Double {
        didSet {
            let clamped = Self.clampFat(dailyFatGoal)
            if clamped != dailyFatGoal {
                dailyFatGoal = clamped
                return
            }
            UserDefaults.standard.set(dailyFatGoal, forKey: Keys.fat)
        }
    }
    
    /// Daily sodium target in milligrams.
    @Published var dailySodiumGoal: Double {
        didSet {
            let clamped = Self.clampSodium(dailySodiumGoal)
            if clamped != dailySodiumGoal {
                dailySodiumGoal = clamped
                return
            }
            UserDefaults.standard.set(dailySodiumGoal, forKey: Keys.sodium)
        }
    }
    
    /// When true, remaining = goal + burned (food logged still shows in diary but is not subtracted).
    @Published var ignoreFoodFromRemaining: Bool {
        didSet {
            UserDefaults.standard.set(ignoreFoodFromRemaining, forKey: Keys.ignoreFood)
        }
    }
    
    static let defaultCalorieGoal: Double = 2000
    static let defaultProteinGoal: Double = 150
    static let defaultCarbsGoal: Double = 250
    static let defaultFatGoal: Double = 65
    static let defaultSodiumGoal: Double = 2300
    
    private enum Keys {
        static let calories = "dailyCalorieGoal"
        static let protein = "dailyProteinGoal"
        static let carbs = "dailyCarbsGoal"
        static let fat = "dailyFatGoal"
        static let sodium = "dailySodiumGoal"
        static let ignoreFood = "ignoreFoodFromRemaining"
    }
    
    init() {
        let defaults = UserDefaults.standard
        
        let storedCalories = defaults.double(forKey: Keys.calories)
        self.dailyCalorieGoal = storedCalories == 0 ? Self.defaultCalorieGoal : storedCalories
        
        let storedProtein = defaults.double(forKey: Keys.protein)
        if storedProtein == 0 {
            self.dailyProteinGoal = Self.defaultProteinGoal
        } else {
            self.dailyProteinGoal = Self.clampProtein(storedProtein)
        }
        
        let storedCarbs = defaults.double(forKey: Keys.carbs)
        if storedCarbs == 0 {
            self.dailyCarbsGoal = Self.defaultCarbsGoal
        } else {
            self.dailyCarbsGoal = Self.clampCarbs(storedCarbs)
        }
        
        let storedFat = defaults.double(forKey: Keys.fat)
        if storedFat == 0 {
            self.dailyFatGoal = Self.defaultFatGoal
        } else {
            self.dailyFatGoal = Self.clampFat(storedFat)
        }
        
        let storedSodium = defaults.double(forKey: Keys.sodium)
        if storedSodium == 0 {
            self.dailySodiumGoal = Self.defaultSodiumGoal
        } else {
            self.dailySodiumGoal = Self.clampSodium(storedSodium)
        }
        
        // Force false to neutralize legacy behavior now that toggle is removed
        self.ignoreFoodFromRemaining = false
        defaults.set(false, forKey: Keys.ignoreFood)
    }
    
    func calculateRemainingCalories(burned: Double, consumed: Double) -> Double {
        // Always subtract food (toggle removed, legacy behavior neutralized)
        return dailyCalorieGoal + burned - consumed
    }
    
    static func clampProtein(_ value: Double) -> Double {
        min(max(value, 10), 400)
    }
    
    static func clampCarbs(_ value: Double) -> Double {
        min(max(value, 10), 600)
    }
    
    static func clampFat(_ value: Double) -> Double {
        min(max(value, 5), 250)
    }
    
    static func clampSodium(_ value: Double) -> Double {
        min(max(value, 200), 10_000)
    }
    
    func progress(consumed: Double, goal: Double) -> Double {
        guard goal > 0 else { return 0 }
        return min(1, consumed / goal)
    }
}
