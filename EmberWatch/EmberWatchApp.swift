import SwiftUI
import SwiftData

@main
struct EmberWatchApp: App {
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var foodDataManager = FoodDataManager()
    @StateObject private var calorieGoalManager = CalorieGoalManager()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            FoodEntry.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(healthKitManager)
                .environmentObject(foodDataManager)
                .environmentObject(calorieGoalManager)
                .modelContainer(sharedModelContainer)
                .onAppear {
                    foodDataManager.setModelContext(sharedModelContainer.mainContext)
                }
        }
    }
}
