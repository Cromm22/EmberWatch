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
    
    init(id: UUID = UUID(), name: String, calories: Double, protein: Double = 0, carbs: Double = 0, fat: Double = 0, timestamp: Date = Date(), mealType: String = "Snack") {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.timestamp = timestamp
        self.mealType = mealType
    }
}

enum MealType: String, CaseIterable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"
}
