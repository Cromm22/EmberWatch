import Foundation
import HealthKit
import UIKit

enum AuthorizationStatus {
    case notDetermined
    case authorized
    case denied
}

class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()

    @Published var workouts: [WorkoutData] = []
    /// Prefer Active Energy (Watch Move) for remaining calories — not workout-only sum.
    @Published var totalCaloriesBurned: Double = 0
    @Published var workoutCaloriesBurned: Double = 0
    @Published var authorizationStatus: AuthorizationStatus = .notDetermined
    @Published var isLoading: Bool = false
    @Published var lastErrorMessage: String?

    /// Quick Add / manual workouts for today — merged into `workouts`, never written to HealthKit.
    private var localWorkouts: [WorkoutData] = []

    private let workoutType = HKObjectType.workoutType()
    private let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
    
    private var workoutObserverQuery: HKObserverQuery?
    private var activeEnergyObserverQuery: HKObserverQuery?

    init() {
        refreshAccessByQuerying()
    }
    
    deinit {
        stopObserving()
    }

    func refreshAccessByQuerying() {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationStatus = .denied
            lastErrorMessage = "Health data isn’t available on this device."
            return
        }
        fetchTodayActivity(markAccessFromResult: true)
    }

    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationStatus = .denied
            lastErrorMessage = "Health data isn’t available on this device."
            return
        }

        let typesToRead: Set<HKObjectType> = [workoutType, activeEnergyType]

        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] _, error in
            DispatchQueue.main.async {
                if let error {
                    self?.lastErrorMessage = error.localizedDescription
                }
                self?.fetchTodayActivity(markAccessFromResult: true)
            }
        }
    }

    func openHealthSettings() {
        if let url = URL(string: "x-apple-health://") {
            UIApplication.shared.open(url)
        } else if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    /// Public entry used by Home / Workout refresh.
    func fetchTodayWorkouts(markAccessFromResult: Bool = false) {
        fetchTodayActivity(markAccessFromResult: markAccessFromResult)
    }
    
    /// Append a Quick Add workout to today's list without writing to HealthKit
    /// and without changing Active Energy (`totalCaloriesBurned`).
    func addLocalWorkout(_ workout: WorkoutData) {
        pruneLocalWorkoutsToToday()
        localWorkouts.insert(workout, at: 0)
        var merged = localWorkouts
        let localIDs = Set(localWorkouts.map(\.id))
        merged.append(contentsOf: workouts.filter { !localIDs.contains($0.id) && !$0.isLocal })
        workouts = merged
        workoutCaloriesBurned = workouts.reduce(0) { $0 + $1.caloriesBurned }
        // Intentionally do NOT touch totalCaloriesBurned — Active Energy stays source of truth.
    }
    
    private func pruneLocalWorkoutsToToday() {
        let start = Calendar.current.startOfDay(for: Date())
        localWorkouts = localWorkouts.filter { $0.startDate >= start }
    }
    
    private func mergeWithLocal(_ hkRows: [WorkoutData]) -> [WorkoutData] {
        pruneLocalWorkoutsToToday()
        let localIDs = Set(localWorkouts.map(\.id))
        return localWorkouts + hkRows.filter { !localIDs.contains($0.id) }
    }

    private func dayBounds() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        return (start, end)
    }

    private func fetchTodayActivity(markAccessFromResult: Bool) {
        isLoading = true
        lastErrorMessage = nil

        let group = DispatchGroup()
        var activeEnergy: Double = 0
        var workoutRows: [WorkoutData] = []
        var workoutSum: Double = 0
        var fetchError: Error?

        group.enter()
        fetchActiveEnergyToday { kcal, error in
            if let error { fetchError = error }
            activeEnergy = kcal
            group.leave()
        }

        group.enter()
        fetchWorkoutsToday { rows, error in
            if let error { fetchError = error }
            workoutRows = rows
            workoutSum = rows.reduce(0) { $0 + $1.caloriesBurned }
            group.leave()
        }

        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            self.isLoading = false

            if let error = fetchError {
                let ns = error as NSError
                if ns.domain == "com.apple.healthkit", ns.code == 5 {
                    if markAccessFromResult {
                        self.authorizationStatus = .denied
                    }
                    self.lastErrorMessage = "Health access is off. Enable Workouts + Active Energy for EmberWatch in the Health app."
                } else {
                    self.lastErrorMessage = error.localizedDescription
                }
                return
            }

            if markAccessFromResult {
                self.authorizationStatus = .authorized
                self.startObserving()
            }

            let merged = self.mergeWithLocal(workoutRows)
            self.workouts = merged
            self.workoutCaloriesBurned = merged.reduce(0) { $0 + $1.caloriesBurned }
            // Watch Move ring ≈ Active Energy. Fall back to HK workout sum if energy is 0 but workouts exist.
            // Local Quick Add calories never inflate Active Energy / Move total.
            self.totalCaloriesBurned = activeEnergy > 0 ? activeEnergy : workoutSum
        }
    }

    private func fetchActiveEnergyToday(completion: @escaping (Double, Error?) -> Void) {
        let bounds = dayBounds()
        let predicate = HKQuery.predicateForSamples(
            withStart: bounds.start,
            end: bounds.end,
            options: .strictStartDate
        )

        let query = HKStatisticsQuery(
            quantityType: activeEnergyType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, statistics, error in
            if let error {
                completion(0, error)
                return
            }
            let kcal = statistics?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
            completion(kcal, nil)
        }
        healthStore.execute(query)
    }

    private func fetchWorkoutsToday(completion: @escaping ([WorkoutData], Error?) -> Void) {
        let bounds = dayBounds()
        let predicate = HKQuery.predicateForSamples(
            withStart: bounds.start,
            end: bounds.end,
            options: .strictStartDate
        )
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: false
        )

        let query = HKSampleQuery(
            sampleType: workoutType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            if let error {
                completion([], error)
                return
            }

            let workoutSamples = (samples as? [HKWorkout]) ?? []
            let rows: [WorkoutData] = workoutSamples.map { workout in
                var calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
                // Newer HealthKit often leaves totalEnergyBurned nil — use statistics when available.
                if calories <= 0 {
                    if let stats = workout.statistics(for: self.activeEnergyType),
                       let qty = stats.sumQuantity() {
                        calories = qty.doubleValue(for: .kilocalorie())
                    }
                }
                return WorkoutData(
                    id: workout.uuid,
                    workoutType: workout.workoutActivityType,
                    duration: workout.duration,
                    caloriesBurned: calories,
                    startDate: workout.startDate
                )
            }
            completion(rows, nil)
        }
        healthStore.execute(query)
    }
    
    func startObserving() {
        guard authorizationStatus == .authorized else { return }
        stopObserving()
        
        workoutObserverQuery = HKObserverQuery(sampleType: workoutType, predicate: nil) { [weak self] _, completionHandler, error in
            if let error {
                print("Workout observer error: \(error.localizedDescription)")
            }
            DispatchQueue.main.async {
                self?.fetchTodayActivity(markAccessFromResult: false)
            }
            completionHandler()
        }
        
        activeEnergyObserverQuery = HKObserverQuery(sampleType: activeEnergyType, predicate: nil) { [weak self] _, completionHandler, error in
            if let error {
                print("Active energy observer error: \(error.localizedDescription)")
            }
            DispatchQueue.main.async {
                self?.fetchTodayActivity(markAccessFromResult: false)
            }
            completionHandler()
        }
        
        if let workoutObserverQuery {
            healthStore.execute(workoutObserverQuery)
        }
        if let activeEnergyObserverQuery {
            healthStore.execute(activeEnergyObserverQuery)
        }
        
        healthStore.enableBackgroundDelivery(for: workoutType, frequency: .immediate) { _, error in
            if let error {
                print("Background delivery error for workouts: \(error.localizedDescription)")
            }
        }
        
        healthStore.enableBackgroundDelivery(for: activeEnergyType, frequency: .immediate) { _, error in
            if let error {
                print("Background delivery error for active energy: \(error.localizedDescription)")
            }
        }
    }
    
    func stopObserving() {
        if let workoutObserverQuery {
            healthStore.stop(workoutObserverQuery)
        }
        if let activeEnergyObserverQuery {
            healthStore.stop(activeEnergyObserverQuery)
        }
    }
}
