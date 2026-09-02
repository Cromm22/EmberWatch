import Foundation
import SwiftData

@Model
class FoodEntry {
    var id: UUID
    var name: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var timestamp: Date
    var mealType: String
    /// Number of servings logged (multiplier applied to per-serving nutrition).
    /// Defaults enable SwiftData lightweight migration from pre-servings stores.
    var servings: Double = 1.0
    var caloriesPerServing: Double = 0
    var proteinPerServing: Double = 0
    var carbsPerServing: Double = 0
    var fatPerServing: Double = 0
    
    init(
        id: UUID = UUID(),
        name: String,
        calories: Double,
        protein: Double = 0,
        carbs: Double = 0,
        fat: Double = 0,
        timestamp: Date = Date(),
        mealType: String = "Snack",
        servings: Double = 1.0,
        caloriesPerServing: Double? = nil,
        proteinPerServing: Double? = nil,
        carbsPerServing: Double? = nil,
        fatPerServing: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.timestamp = timestamp
        self.mealType = mealType
        let safeServings = max(servings, 0.01)
        self.servings = servings
        self.caloriesPerServing = caloriesPerServing ?? (calories / safeServings)
        self.proteinPerServing = proteinPerServing ?? (protein / safeServings)
        self.carbsPerServing = carbsPerServing ?? (carbs / safeServings)
        self.fatPerServing = fatPerServing ?? (fat / safeServings)
    }
    
    /// Per-serving calories, deriving from totals when legacy rows lack stored values.
    var effectiveCaloriesPerServing: Double {
        if caloriesPerServing > 0 { return caloriesPerServing }
        return calories / max(servings, 0.01)
    }
    
    var effectiveProteinPerServing: Double {
        if proteinPerServing > 0 || caloriesPerServing > 0 { return proteinPerServing }
        return protein / max(servings, 0.01)
    }
    
    var effectiveCarbsPerServing: Double {
        if carbsPerServing > 0 || caloriesPerServing > 0 { return carbsPerServing }
        return carbs / max(servings, 0.01)
    }
    
    var effectiveFatPerServing: Double {
        if fatPerServing > 0 || caloriesPerServing > 0 { return fatPerServing }
        return fat / max(servings, 0.01)
    }
    
    /// Recalculate totals from per-serving nutrition × new servings count.
    func applyServings(_ newServings: Double) {
        let s = max(newServings, 0.01)
        let calPS = effectiveCaloriesPerServing
        let proPS = effectiveProteinPerServing
        let carbPS = effectiveCarbsPerServing
        let fatPS = effectiveFatPerServing
        
        servings = newServings
        caloriesPerServing = calPS
        proteinPerServing = proPS
        carbsPerServing = carbPS
        fatPerServing = fatPS
        calories = calPS * s
        protein = proPS * s
        carbs = carbPS * s
        fat = fatPS * s
    }
}

enum MealType: String, CaseIterable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"
}
