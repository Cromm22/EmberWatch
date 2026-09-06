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
    @StateObject private var emberTalkManager = EmberTalkManager()
    
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
        // Explicitly disable CloudKit sync for SwiftData (friends use separate CKContainer).
        // This prevents "attributes must be optional" crashes and keeps food data local-only.
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )

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
                // NEVER crash on launch. Fall back to in-memory container if disk fails.
                print("EmberWatch: ModelContainer reset failed (\(error)). Using in-memory store.")
                let memoryConfig = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: true,
                    cloudKitDatabase: .none
                )
                do {
                    return try ModelContainer(for: schema, configurations: [memoryConfig])
                } catch {
                    // Last resort: This should never fail, but return an empty in-memory container.
                    // User will see empty food diary but app won't crash.
                    print("EmberWatch: Critical - in-memory ModelContainer failed (\(error)).")
                    return try! ModelContainer(for: schema, configurations: [memoryConfig])
                }
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
                .environmentObject(emberTalkManager)
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
