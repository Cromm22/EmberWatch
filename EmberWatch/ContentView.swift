import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var foodDataManager: FoodDataManager
    @EnvironmentObject var calorieGoalManager: CalorieGoalManager
    @EnvironmentObject var waterManager: WaterManager
    @EnvironmentObject var avatarManager: AvatarManager
    @EnvironmentObject var levelManager: LevelManager
    @EnvironmentObject var sparksManager: SparksManager
    @EnvironmentObject var feedbackManager: FeedbackManager
    @EnvironmentObject var friendsManager: FriendsManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab = 0
    @State private var showingFeedback = false
    @State private var showFeedbackFAB = false
    
    var body: some View {
        Group {
            if !avatarManager.hasCompletedOnboarding {
                OnboardingView()
                    .environmentObject(avatarManager)
                    .environmentObject(levelManager)
            } else {
                mainTabs
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active, avatarManager.hasCompletedOnboarding else { return }
            _ = levelManager.checkDailyOpenReward()
            _ = sparksManager.earnDailyLogin()
            // Update CloudKit profile with latest data
            Task {
                await friendsManager.updateMyProfile(
                    name: avatarManager.emberName,
                    avatarId: avatarManager.selectedAvatarId,
                    weeklyXP: levelManager.totalXP
                )
            }
        }
        .onAppear {
            guard avatarManager.hasCompletedOnboarding else { return }
            _ = levelManager.checkDailyOpenReward()
            _ = sparksManager.earnDailyLogin()
        }
    }
    
    private var mainTabs: some View {
        ZStack(alignment: .bottomTrailing) {
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
                    .environmentObject(levelManager)
                    .environmentObject(sparksManager)
                
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
                    .environmentObject(levelManager)
                
                BoardView()
                    .tabItem {
                        Label("Board", systemImage: "list.number")
                    }
                    .tag(3)
                    .environmentObject(levelManager)
                    .environmentObject(sparksManager)
                    .environmentObject(friendsManager)
                    .environmentObject(avatarManager)
                
                ShareView()
                    .tabItem {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .tag(4)
                    .environmentObject(healthKitManager)
                    .environmentObject(foodDataManager)
                    .environmentObject(calorieGoalManager)
                    .environmentObject(avatarManager)
                    .environmentObject(levelManager)
                    .environmentObject(friendsManager)
                    .environmentObject(sparksManager)
            }
            .tint(EmberColors.ember)
            
            if showFeedbackFAB {
                FeedbackFAB(isPresented: $showingFeedback)
                    .padding(.bottom, 56) // sit above tab bar without eating tab hits
                    .transition(.opacity)
            }
        }
        .sheet(isPresented: $showingFeedback) {
            FeedbackSheetView(isPresented: $showingFeedback)
                .environmentObject(feedbackManager)
        }
        .task {
            // Defer FAB until after tab content has a chance to mount.
            try? await Task.sleep(nanoseconds: 150_000_000)
            showFeedbackFAB = true
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
