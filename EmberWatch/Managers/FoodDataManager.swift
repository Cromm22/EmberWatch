import Foundation
import SwiftData
import SwiftUI

@MainActor
class FoodDataManager: ObservableObject {
    @Published var todayFoodEntries: [FoodEntry] = []
    @Published var totalCaloriesConsumed: Double = 0
    @Published var totalProtein: Double = 0
    @Published var totalCarbs: Double = 0
    @Published var totalFat: Double = 0
    
    private var modelContext: ModelContext?
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        fetchTodayEntries()
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
            todayFoodEntries = try modelContext.fetch(descriptor)
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
}
