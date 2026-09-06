import Foundation
import SwiftData

@Model
class FoodEntry {
    // CloudKit integration requires all attributes be optional OR have default values.
    // All properties now have defaults to prevent ModelContainer CloudKit config crashes.
    var id: UUID = UUID()
    var name: String = ""
    var calories: Double = 0
    var protein: Double = 0
    var carbs: Double = 0
    var fat: Double = 0
    var timestamp: Date = Date()
    /// Defaults enable SwiftData lightweight migration from stores without mealType.
    var mealType: String = "Snack"
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
        mealType: String? = nil,
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
        self.mealType = mealType ?? MealType.suggested(for: timestamp).rawValue
        let safeServings = max(servings, 0.01)
        self.servings = servings
        self.caloriesPerServing = caloriesPerServing ?? (calories / safeServings)
        self.proteinPerServing = proteinPerServing ?? (protein / safeServings)
        self.carbsPerServing = carbsPerServing ?? (carbs / safeServings)
        self.fatPerServing = fatPerServing ?? (fat / safeServings)
    }
    
    /// Canonical meal type; derives from timestamp when unset/unknown (legacy rows).
    var resolvedMealType: String {
        let trimmed = mealType.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return MealType.suggested(for: timestamp).rawValue
        }
        if MealType(rawValue: trimmed) != nil {
            return trimmed
        }
        if trimmed.lowercased() == "snacks" {
            return MealType.snack.rawValue
        }
        return MealType.suggested(for: timestamp).rawValue
    }
    
    /// Persist a resolved mealType for rows that migrated with an empty/invalid value.
    @discardableResult
    func ensureMealTypeResolved() -> Bool {
        let resolved = resolvedMealType
        if mealType != resolved {
            mealType = resolved
            return true
        }
        return false
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

enum MealType: String, CaseIterable, Identifiable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"
    
    var id: String { rawValue }
    
    /// Section header label (Snacks plural for clarity).
    var sectionTitle: String {
        switch self {
        case .snack: return "Snacks"
        default: return rawValue
        }
    }
    
    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "cup.and.saucer.fill"
        }
    }
    
    /// Breakfast before 11:00, Lunch 11:00–15:59, Dinner 16:00–20:59, else Snacks.
    static func suggested(for date: Date = Date()) -> MealType {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case ..<11: return .breakfast
        case 11..<16: return .lunch
        case 16..<21: return .dinner
        default: return .snack
        }
    }
}
