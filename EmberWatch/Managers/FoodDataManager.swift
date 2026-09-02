import Foundation
import SwiftData
import SwiftUI

@MainActor
class FoodDataManager: ObservableObject {
    @Published var todayFoodEntries: [FoodEntry] = []
    @Published var recentFoodEntries: [FoodEntry] = []
    @Published var totalCaloriesConsumed: Double = 0
    @Published var totalProtein: Double = 0
    @Published var totalCarbs: Double = 0
    @Published var totalFat: Double = 0
    
    private var modelContext: ModelContext?
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        fetchTodayEntries()
        fetchRecentEntries()
    }
    
    func fetchTodayEntries() {
        guard let modelContext else { return }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = #Predicate<FoodEntry> { entry in
            entry.timestamp >= startOfDay && entry.timestamp < endOfDay
        }
        
        let descriptor = FetchDescriptor<FoodEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            let fetched = try modelContext.fetch(descriptor)
            var didMigrate = false
            for entry in fetched {
                if entry.ensureMealTypeResolved() {
                    didMigrate = true
                }
            }
            if didMigrate {
                try? modelContext.save()
            }
            todayFoodEntries = fetched
            calculateTotals()
        } catch {
            print("Failed to fetch food entries: \(error)")
        }
    }
    
    func addFoodEntry(_ entry: FoodEntry) {
        guard let modelContext else { return }
        
        modelContext.insert(entry)
        try? modelContext.save()
        fetchTodayEntries()
        fetchRecentEntries()
    }
    
    func deleteFoodEntry(_ entry: FoodEntry) {
        guard let modelContext else { return }
        
        modelContext.delete(entry)
        try? modelContext.save()
        fetchTodayEntries()
    }
    
    func updateFoodEntry(_ entry: FoodEntry) {
        guard let modelContext else { return }
        
        try? modelContext.save()
        fetchTodayEntries()
    }
    
    private func calculateTotals() {
        totalCaloriesConsumed = todayFoodEntries.reduce(0) { $0 + $1.calories }
        totalProtein = todayFoodEntries.reduce(0) { $0 + $1.protein }
        totalCarbs = todayFoodEntries.reduce(0) { $0 + $1.carbs }
        totalFat = todayFoodEntries.reduce(0) { $0 + $1.fat }
    }
    
    func fetchRecentEntries() {
        guard let modelContext else { return }
        
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        
        let predicate = #Predicate<FoodEntry> { entry in
            entry.timestamp >= sevenDaysAgo
        }
        
        let descriptor = FetchDescriptor<FoodEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            let allRecent = try modelContext.fetch(descriptor)
            var seen = Set<String>()
            var unique: [FoodEntry] = []
            
            for entry in allRecent {
                let key = "\(entry.name)_\(Int(entry.calories))"
                if !seen.contains(key) {
                    seen.insert(key)
                    unique.append(entry)
                    if unique.count >= 5 {
                        break
                    }
                }
            }
            
            recentFoodEntries = unique
        } catch {
            print("Failed to fetch recent entries: \(error)")
        }
    }
    
    func entries(forMealType meal: MealType) -> [FoodEntry] {
        todayFoodEntries.filter { $0.resolvedMealType == meal.rawValue }
    }
}

