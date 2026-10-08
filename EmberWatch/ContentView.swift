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
    @EnvironmentObject var emberTalkManager: EmberTalkManager
    @EnvironmentObject var workoutGoalManager: WorkoutGoalManager
    @EnvironmentObject var characterManager: CharacterManager
    @EnvironmentObject var companionManager: CompanionManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab = 0
    @State private var showingFeedback = false
    @State private var showFeedbackFAB = false
    @State private var showLevelUpCelebration = false
    @State private var celebrationLevel: Int = 0
    @State private var showingBuildChoice = false
    @State private var didOfferBuildThisSession = false
    @State private var showingCompanionChoice = false
    @State private var didOfferCompanionThisSession = false
    @State private var showEvolutionCelebration = false
    @State private var evolutionStage: CompanionStage = .baby
    
    var body: some View {
        ZStack {
            Group {
                if !avatarManager.hasCompletedOnboarding {
                    OnboardingView()
                        .environmentObject(avatarManager)
                        .environmentObject(levelManager)
                        .environmentObject(friendsManager)
                        .environmentObject(healthKitManager)
                        .environmentObject(characterManager)
                        .environmentObject(companionManager)
                } else {
                    mainTabs
                }
            }
        }
        .overlay(alignment: .bottom) {
            if showLevelUpCelebration {
                LevelUpCelebrationView(newLevel: celebrationLevel) {
                    showLevelUpCelebration = false
                }
                .safeAreaPadding(.bottom)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else if showEvolutionCelebration {
                EvolutionCelebrationView(
                    species: companionManager.resolvedSpecies,
                    stage: evolutionStage
                ) {
                    showEvolutionCelebration = false
                    companionManager.clearPendingEvolution()
                }
                .safeAreaPadding(.bottom)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else if let banner = levelManager.xpToast ?? sparksManager.toast {
                CelebrationToastAnchor(sitsOutsideTabView: true) {
                    CelebrationToastCard(
                        accent: EmberColors.gold,
                        secondaryAccent: EmberColors.ember
                    ) {
                        Text(banner)
                            .font(.headline)
                            .foregroundColor(EmberColors.ink)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.82), value: showLevelUpCelebration)
        .animation(.spring(response: 0.4, dampingFraction: 0.82), value: showEvolutionCelebration)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: levelManager.xpToast)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: sparksManager.toast)
        .onChange(of: levelManager.levelUpEvent) { _, newLevel in
            if let level = newLevel {
                celebrationLevel = level
                showLevelUpCelebration = true
                if let stage = companionManager.checkEvolution(level: level) {
                    evolutionStage = stage
                    showEvolutionCelebration = true
                }
                // Clear the event after handling
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    levelManager.levelUpEvent = nil
                }
            }
        }
        .onChange(of: avatarManager.hasCompletedOnboarding) { _, completed in
            if completed {
                healthKitManager.ensureAuthorization()
            }
        }
        .onChange(of: characterManager.selectedBuild) { _, _ in
            publishProfile()
        }
        .onChange(of: companionManager.selectedSpecies) { _, _ in
            publishProfile()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active, avatarManager.hasCompletedOnboarding else { return }
            healthKitManager.ensureAuthorization()
            _ = levelManager.checkDailyOpenReward()
            syncRPGProgress()
            publishProfile()
        }
        .onAppear {
            guard avatarManager.hasCompletedOnboarding else { return }
            healthKitManager.ensureAuthorization()
            _ = levelManager.checkDailyOpenReward()
            syncRPGProgress()
            companionManager.grantFreeUnlocks(level: levelManager.level)
            companionManager.noteCurrentStageWithoutCelebrating(level: levelManager.level)
            offerBuildChoiceIfNeeded()
            offerCompanionChoiceIfNeeded()
        }
        .sheet(isPresented: $showingBuildChoice, onDismiss: {
            offerCompanionChoiceIfNeeded()
        }) {
            BuildChoiceSheet(isPresented: $showingBuildChoice, allowsSkip: true)
                .environmentObject(characterManager)
        }
        .sheet(isPresented: $showingCompanionChoice) {
            CompanionChoiceSheet(isPresented: $showingCompanionChoice, allowsSkip: true)
                .environmentObject(companionManager)
                .environmentObject(avatarManager)
                .environmentObject(levelManager)
        }
    }

    private func publishProfile() {
        Task {
            await friendsManager.updateMyProfile(
                name: avatarManager.emberName,
                avatarId: avatarManager.selectedAvatarId,
                totalXP: levelManager.totalXP,
                level: levelManager.level,
                build: characterManager.selectedBuild?.rawValue,
                companion: companionManager.selectedSpecies?.rawValue
            )
        }
    }
    
    private var mainTabs: some View {
        ZStack(alignment: .bottomTrailing) {
            EmberColors.dusk.ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                HomeView(selectedTab: $selectedTab)
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
                    .environmentObject(emberTalkManager)
                    .environmentObject(workoutGoalManager)
                    .environmentObject(characterManager)
                    .environmentObject(companionManager)
                
                FoodDiaryView()
                    .tabItem {
                        Label("Food", systemImage: "fork.knife")
                    }
                    .tag(1)
                    .environmentObject(foodDataManager)
                    .environmentObject(healthKitManager)
                    .environmentObject(calorieGoalManager)
                    .environmentObject(emberTalkManager)
                
                WorkoutsView()
                    .tabItem {
                        Label("Workout", systemImage: "figure.run")
                    }
                    .tag(2)
                    .environmentObject(healthKitManager)
                    .environmentObject(levelManager)
                    .environmentObject(emberTalkManager)
                
                BoardView()
                    .tabItem {
                        Label("Board", systemImage: "list.number")
                    }
                    .tag(3)
                    .environmentObject(levelManager)
                    .environmentObject(sparksManager)
                    .environmentObject(friendsManager)
                    .environmentObject(avatarManager)
                    .environmentObject(characterManager)
                    .environmentObject(companionManager)
                
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
                    .environmentObject(companionManager)
            }
            .tint(EmberColors.ember)
            
            if showFeedbackFAB {
                FeedbackFAB(isPresented: $showingFeedback)
                    .padding(.bottom, 56)
                    .transition(.opacity)
            }
            
            EmberTalkOverlay()
                .environmentObject(emberTalkManager)
                .frame(maxWidth: .infinity)
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
                .foregroundColor: UIColor(EmberColors.ember)
            ]
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }

    private func syncRPGProgress() {
        levelManager.syncFromApp(
            food: foodDataManager,
            calories: calorieGoalManager,
            water: waterManager,
            health: healthKitManager,
            workoutGoal: workoutGoalManager
        )
        characterManager.syncFromApp(
            food: foodDataManager,
            calories: calorieGoalManager,
            water: waterManager,
            health: healthKitManager,
            workoutGoal: workoutGoalManager,
            level: levelManager.level
        )
    }

    private func offerBuildChoiceIfNeeded() {
        guard avatarManager.hasCompletedOnboarding else { return }
        guard !characterManager.hasChosenBuild else { return }
        guard !didOfferBuildThisSession else { return }
        didOfferBuildThisSession = true
        showingBuildChoice = true
    }

    private func offerCompanionChoiceIfNeeded() {
        guard avatarManager.hasCompletedOnboarding else { return }
        guard !companionManager.hasChosenCompanion else { return }
        guard !didOfferCompanionThisSession else { return }
        guard !showingBuildChoice else { return }
        didOfferCompanionThisSession = true
        showingCompanionChoice = true
    }
}

struct EmberColors {
    // Light theme backgrounds
    static let dusk = Color(hex: "#ffffff")
    static let dusk2 = Color(hex: "#f5f5f5")
    static let plum = Color(hex: "#f0f0f0")
    
    // Brand colors (keep ember orange)
    static let ember = Color(hex: "#ff7a3c")
    static let emberAccent = Color(hex: "#f97316")
    static let gold = Color(hex: "#ffc107")
    
    // Text colors (inverted for light theme)
    static let cream = Color(hex: "#1a1a1a")
    static let creamAlt = Color(hex: "#2a2a2a")
    static let muted = Color(hex: "#666666")
    static let ink = Color(hex: "#ffffff")
    
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
