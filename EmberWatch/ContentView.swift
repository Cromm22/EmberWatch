import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var foodDataManager: FoodDataManager
    @EnvironmentObject var calorieGoalManager: CalorieGoalManager
    @EnvironmentObject var waterManager: WaterManager
    @EnvironmentObject var avatarManager: AvatarManager
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            EmberColors.dusk.ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "flame.fill")
                    }
                    .tag(0)
                    .environmentObject(healthKitManager)
                    .environmentObject(foodDataManager)
                    .environmentObject(calorieGoalManager)
                    .environmentObject(waterManager)
                    .environmentObject(avatarManager)
                
                FoodDiaryView()
                    .tabItem {
                        Label("Food", systemImage: "fork.knife")
                    }
                    .tag(1)
                    .environmentObject(foodDataManager)
                    .environmentObject(healthKitManager)
                    .environmentObject(calorieGoalManager)
                
                WorkoutsView()
                    .tabItem {
                        Label("Workout", systemImage: "figure.run")
                    }
                    .tag(2)
                    .environmentObject(healthKitManager)
                
                BoardView()
                    .tabItem {
                        Label("Board", systemImage: "list.number")
                    }
                    .tag(3)
                    .environmentObject(calorieGoalManager)
                
                ShareView()
                    .tabItem {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .tag(4)
                    .environmentObject(healthKitManager)
                    .environmentObject(foodDataManager)
                    .environmentObject(calorieGoalManager)
                    .environmentObject(avatarManager)
            }
            .tint(EmberColors.ember)
        }
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(EmberColors.dusk)
            
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(EmberColors.muted)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor(EmberColors.muted)
            ]
            
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(EmberColors.ember)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(EmberColors.cream)
            ]
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

struct EmberColors {
    static let dusk = Color(hex: "#100814")
    static let dusk2 = Color(hex: "#1a0d22")
    static let plum = Color(hex: "#3a1848")
    static let ember = Color(hex: "#ff7a3c")
    static let emberAccent = Color(hex: "#f97316")
    static let gold = Color(hex: "#ffd27a")
    static let cream = Color(hex: "#fff1dc")
    static let creamAlt = Color(hex: "#f6ead9")
    static let muted = Color(hex: "#c9b4a4")
    static let ink = Color(hex: "#140c09")
    
    // Back-compat aliases used by existing views
    static let darkPlum = dusk
    static let flame = ember
    static let lightPlum = dusk2
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
