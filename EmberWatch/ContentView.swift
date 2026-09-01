import SwiftUI

struct ContentView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var foodDataManager: FoodDataManager
    @EnvironmentObject var calorieGoalManager: CalorieGoalManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "flame.fill")
                }
                .tag(0)
                .environmentObject(healthKitManager)
                .environmentObject(foodDataManager)
                .environmentObject(calorieGoalManager)
            
            FoodDiaryView()
                .tabItem {
                    Label("Food", systemImage: "fork.knife")
                }
                .tag(1)
                .environmentObject(foodDataManager)
            
            WorkoutsView()
                .tabItem {
                    Label("Workouts", systemImage: "figure.run")
                }
                .tag(2)
                .environmentObject(healthKitManager)
            
            HealthConnectView()
                .tabItem {
                    Label("Health", systemImage: "heart.fill")
                }
                .tag(3)
                .environmentObject(healthKitManager)
        }
        .accentColor(EmberColors.flame)
    }
}

struct EmberColors {
    static let darkPlum = Color(red: 0.3, green: 0.2, blue: 0.35)
    static let cream = Color(red: 0.98, green: 0.95, blue: 0.9)
    static let flame = Color(red: 1.0, green: 0.45, blue: 0.2)
    static let lightPlum = Color(red: 0.4, green: 0.3, blue: 0.45)
}
