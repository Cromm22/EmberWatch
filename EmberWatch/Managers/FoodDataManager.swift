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
    
    /// Copies yesterday's entries for `meal` onto today (new IDs, today's calendar date).
    /// Allows re-copy (adds another set of entries). Returns number of entries copied.
    @discardableResult
    func copyYesterdayMeal(toToday meal: MealType) -> Int {
        guard let modelContext else { return 0 }
        
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        guard let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday),
              let endOfYesterday = calendar.date(byAdding: .day, value: 1, to: startOfYesterday) else {
            return 0
        }
        
        let predicate = #Predicate<FoodEntry> { entry in
            entry.timestamp >= startOfYesterday && entry.timestamp < endOfYesterday
        }
        
        let descriptor = FetchDescriptor<FoodEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        
        do {
            let yesterdayEntries = try modelContext.fetch(descriptor)
            let mealRaw = meal.rawValue
            let toCopy = yesterdayEntries.filter { $0.resolvedMealType == mealRaw }
            guard !toCopy.isEmpty else { return 0 }
            
            let now = Date()
            for (index, source) in toCopy.enumerated() {
                // Preserve time-of-day on today's date
                let comps = calendar.dateComponents([.hour, .minute, .second], from: source.timestamp)
                var timestamp = calendar.date(
                    bySettingHour: comps.hour ?? 12,
                    minute: comps.minute ?? 0,
                    second: comps.second ?? 0,
                    of: now
                ) ?? now
                if index > 0 {
                    timestamp = timestamp.addingTimeInterval(TimeInterval(index) * 0.001)
                }
                
                let copy = FoodEntry(
                    name: source.name,
                    calories: source.calories,
                    protein: source.protein,
                    carbs: source.carbs,
                    fat: source.fat,
                    timestamp: timestamp,
                    mealType: mealRaw,
                    servings: source.servings,
                    caloriesPerServing: source.effectiveCaloriesPerServing,
                    proteinPerServing: source.effectiveProteinPerServing,
                    carbsPerServing: source.effectiveCarbsPerServing,
                    fatPerServing: source.effectiveFatPerServing
                )
                modelContext.insert(copy)
            }
            
            try? modelContext.save()
            fetchTodayEntries()
            fetchRecentEntries()
            return toCopy.count
        } catch {
            print("Failed to copy yesterday meal: \(error)")
            return 0
        }
    }
}

