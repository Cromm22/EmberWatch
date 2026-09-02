import SwiftUI
import SwiftData

@main
struct EmberWatchApp: App {
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var foodDataManager = FoodDataManager()
    @StateObject private var calorieGoalManager = CalorieGoalManager()
    @StateObject private var waterManager = WaterManager()
    @StateObject private var avatarManager = AvatarManager()
    @StateObject private var levelManager: LevelManager
    @StateObject private var sparksManager: SparksManager
    @StateObject private var feedbackManager = FeedbackManager()
    @StateObject private var weightManager = WeightManager()
    @StateObject private var friendsManager = FriendsManager()
    
    init() {
        let sparks = SparksManager()
        let levels = LevelManager()
        levels.sparksManager = sparks
        _sparksManager = StateObject(wrappedValue: sparks)
        _levelManager = StateObject(wrappedValue: levels)
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            FoodEntry.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Schema changed (e.g. servings fields) and in-place migration failed.
            // Wipe local store so launch recovers; food diary will re-populate from use.
            print("EmberWatch: ModelContainer failed (\(error)). Resetting store…")
            Self.removeStoreFiles(at: modelConfiguration.url)
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer after store reset: \(error)")
            }
        }
    }()

    private static func removeStoreFiles(at url: URL) {
        let fm = FileManager.default
        let candidates = [
            url,
            URL(fileURLWithPath: url.path + "-shm"),
            URL(fileURLWithPath: url.path + "-wal"),
            url.deletingPathExtension().appendingPathExtension("store-shm"),
            url.deletingPathExtension().appendingPathExtension("store-wal"),
        ]
        for file in candidates {
            try? fm.removeItem(at: file)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(healthKitManager)
                .environmentObject(foodDataManager)
                .environmentObject(calorieGoalManager)
                .environmentObject(waterManager)
                .environmentObject(avatarManager)
                .environmentObject(levelManager)
                .environmentObject(sparksManager)
                .environmentObject(feedbackManager)
                .environmentObject(weightManager)
                .environmentObject(friendsManager)
                .modelContainer(sharedModelContainer)
                .onAppear {
                    foodDataManager.setModelContext(sharedModelContainer.mainContext)
                    // Keep Sparks ↔ Level link in case it was cleared.
                    levelManager.sparksManager = sparksManager
                }
                .task {
                    await friendsManager.setupCloudKit()
                }
        }
    }
}
