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
    /// Apple Watch Exercise ring minutes for today, when Health access is granted.
    @Published var exerciseMinutes: Double = 0
    @Published var authorizationStatus: AuthorizationStatus = .notDetermined
    @Published var isLoading: Bool = false
    @Published var lastErrorMessage: String?

    /// Quick Add / manual workouts for today — merged into `workouts`, never written to HealthKit.
    private var localWorkouts: [WorkoutData] = []

    private let workoutType = HKObjectType.workoutType()
    private let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
    private let exerciseTimeType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!
    private let walkingRunningDistanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)
    private let cyclingDistanceType = HKQuantityType.quantityType(forIdentifier: .distanceCycling)
    private let swimmingDistanceType = HKQuantityType.quantityType(forIdentifier: .distanceSwimming)

    private var typesToRead: Set<HKObjectType> {
        [workoutType, activeEnergyType, exerciseTimeType]
    }

    private var workoutObserverQuery: HKObserverQuery?
    private var activeEnergyObserverQuery: HKObserverQuery?
    private var exerciseTimeObserverQuery: HKObserverQuery?
    private var isRequestingAuthorization = false

    init() {
        bootstrap()
    }

    deinit {
        stopObserving()
    }

    /// On launch: if we've already asked for Health access, start queries + observers.
    /// Never treat an unread / unprompted store as authorized (Apple hides read denial as empty results).
    func bootstrap() {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationStatus = .denied
            lastErrorMessage = "Health data isn’t available on this device."
            return
        }

        healthStore.getRequestStatusForAuthorization(toShare: [], read: typesToRead) { [weak self] status, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                switch status {
                case .unnecessary:
                    self.fetchTodayActivity(markAccessFromResult: true)
                case .shouldRequest, .unknown:
                    self.authorizationStatus = .notDetermined
                @unknown default:
                    self.authorizationStatus = .notDetermined
                }
            }
        }
    }

    /// Show the Health permission sheet when needed; otherwise refresh today's Watch / HealthKit data.
    func ensureAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationStatus = .denied
            lastErrorMessage = "Health data isn’t available on this device."
            return
        }

        healthStore.getRequestStatusForAuthorization(toShare: [], read: typesToRead) { [weak self] status, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                switch status {
                case .shouldRequest, .unknown:
                    self.authorizationStatus = .notDetermined
                    self.requestAuthorization()
                case .unnecessary:
                    self.fetchTodayActivity(markAccessFromResult: true)
                @unknown default:
                    self.requestAuthorization()
                }
            }
        }
    }

    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationStatus = .denied
            lastErrorMessage = "Health data isn’t available on this device."
            return
        }
        guard !isRequestingAuthorization else { return }
        isRequestingAuthorization = true

        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] _, error in
            DispatchQueue.main.async {
                self?.isRequestingAuthorization = false
                if let error {
                    self?.lastErrorMessage = error.localizedDescription
                }
                // The sheet completing does not mean read was granted — probe by querying.
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

    /// Update a local workout's fields (only affects Quick Add / manual entries).
    func updateLocalWorkout(_ workout: WorkoutData) {
        guard workout.isLocal else { return }
        if let index = localWorkouts.firstIndex(where: { $0.id == workout.id }) {
            localWorkouts[index] = workout
            var merged = localWorkouts
            let localIDs = Set(localWorkouts.map(\.id))
            merged.append(contentsOf: workouts.filter { !localIDs.contains($0.id) && !$0.isLocal })
            workouts = merged
            workoutCaloriesBurned = workouts.reduce(0) { $0 + $1.caloriesBurned }
        }
    }

    /// Delete a workout from today's list.
    /// - For local workouts: removes from in-memory store
    /// - For HealthKit workouts: deletes the HK sample (requires write permission)
    func deleteWorkout(_ workout: WorkoutData, completion: ((Bool, Error?) -> Void)? = nil) {
        if workout.isLocal {
            localWorkouts.removeAll { $0.id == workout.id }
            var merged = localWorkouts
            let localIDs = Set(localWorkouts.map(\.id))
            merged.append(contentsOf: workouts.filter { !localIDs.contains($0.id) && !$0.isLocal })
            workouts = merged
            workoutCaloriesBurned = workouts.reduce(0) { $0 + $1.caloriesBurned }
            completion?(true, nil)
        } else {
            // HealthKit workout — delete the HK sample
            let predicate = HKQuery.predicateForObject(with: workout.id)
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: nil
            ) { [weak self] _, samples, error in
                guard let self = self else { return }
                if let error = error {
                    DispatchQueue.main.async {
                        completion?(false, error)
                    }
                    return
                }
                guard let sample = samples?.first else {
                    DispatchQueue.main.async {
                        completion?(false, NSError(domain: "HealthKitManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Workout not found in HealthKit"]))
                    }
                    return
                }
                self.healthStore.delete(sample) { success, error in
                    DispatchQueue.main.async {
                        if success {
                            self.workouts.removeAll { $0.id == workout.id }
                            self.workoutCaloriesBurned = self.workouts.reduce(0) { $0 + $1.caloriesBurned }
                        }
                        completion?(success, error)
                    }
                }
            }
            healthStore.execute(query)
        }
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
        var exerciseMins: Double = 0
        var workoutRows: [WorkoutData] = []
        var workoutSum: Double = 0

        var energyError: Error?
        var workoutError: Error?

        group.enter()
        fetchActiveEnergyToday { kcal, error in
            energyError = error
            activeEnergy = kcal
            group.leave()
        }

        group.enter()
        fetchExerciseMinutesToday { minutes, _ in
            // Exercise Minutes is best-effort — user may grant Workouts but not this type.
            exerciseMins = minutes
            group.leave()
        }

        group.enter()
        fetchWorkoutsToday { rows, error in
            workoutError = error
            workoutRows = rows
            workoutSum = rows.reduce(0) { $0 + $1.caloriesBurned }
            group.leave()
        }

        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            self.isLoading = false

            if let error = workoutError ?? energyError {
                self.applyHealthKitError(error, markAccessFromResult: markAccessFromResult)
                return
            }

            if markAccessFromResult {
                self.authorizationStatus = .authorized
                self.startObserving()
            }

            let merged = self.mergeWithLocal(workoutRows)
            self.workouts = merged
            self.workoutCaloriesBurned = merged.reduce(0) { $0 + $1.caloriesBurned }
            self.exerciseMinutes = exerciseMins
            // Watch Move ring ≈ Active Energy. Fall back to HK workout sum if energy is 0 but workouts exist.
            // Local Quick Add calories never inflate Active Energy / Move total.
            self.totalCaloriesBurned = activeEnergy > 0 ? activeEnergy : workoutSum
        }
    }

    private func applyHealthKitError(_ error: Error, markAccessFromResult: Bool) {
        let ns = error as NSError
        let hkCode: HKError.Code?
        if let hkError = error as? HKError {
            hkCode = hkError.code
        } else if ns.domain == "com.apple.healthkit" {
            hkCode = HKError.Code(rawValue: ns.code)
        } else {
            hkCode = nil
        }

        switch hkCode {
        case .errorAuthorizationNotDetermined:
            if markAccessFromResult {
                authorizationStatus = .notDetermined
            }
            lastErrorMessage = "Allow EmberWatch to read Workouts, Active Energy, and Exercise Minutes in Apple Health."
        case .errorAuthorizationDenied, .errorRequiredAuthorizationDenied:
            if markAccessFromResult {
                authorizationStatus = .denied
            }
            lastErrorMessage = "Health access is off. Enable Workouts + Active Energy for EmberWatch in the Health app."
        case .errorDatabaseInaccessible:
            lastErrorMessage = "Unlock your iPhone to read Apple Watch data from Health."
        default:
            lastErrorMessage = error.localizedDescription
        }
    }

    private func fetchActiveEnergyToday(completion: @escaping (Double, Error?) -> Void) {
        fetchCumulativeSum(activeEnergyType, unit: .kilocalorie(), completion: completion)
    }

    private func fetchExerciseMinutesToday(completion: @escaping (Double, Error?) -> Void) {
        fetchCumulativeSum(exerciseTimeType, unit: .minute(), completion: completion)
    }

    private func fetchCumulativeSum(
        _ quantityType: HKQuantityType,
        unit: HKUnit,
        completion: @escaping (Double, Error?) -> Void
    ) {
        let bounds = dayBounds()
        let predicate = HKQuery.predicateForSamples(
            withStart: bounds.start,
            end: bounds.end,
            options: .strictStartDate
        )

        let query = HKStatisticsQuery(
            quantityType: quantityType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, statistics, error in
            if let error {
                completion(0, error)
                return
            }
            let value = statistics?.sumQuantity()?.doubleValue(for: unit) ?? 0
            completion(value, nil)
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
        ) { [weak self] _, samples, error in
            guard let self else {
                completion([], error)
                return
            }
            if let error {
                completion([], error)
                return
            }

            let workoutSamples = (samples as? [HKWorkout]) ?? []
            self.mapWorkouts(workoutSamples, completion: completion)
        }
        healthStore.execute(query)
    }

    private func mapWorkouts(_ workoutSamples: [HKWorkout], completion: @escaping ([WorkoutData], Error?) -> Void) {
        guard !workoutSamples.isEmpty else {
            completion([], nil)
            return
        }

        let group = DispatchGroup()
        let lock = NSLock()
        var rows = Array<WorkoutData?>(repeating: nil, count: workoutSamples.count)

        for (index, workout) in workoutSamples.enumerated() {
            let duration = max(workout.duration, workout.endDate.timeIntervalSince(workout.startDate))
            let distance = self.distance(for: workout)
            let name = self.healthKitDisplayName(for: workout)
            let sourceName = workout.sourceRevision.source.name

            var calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
            if calories <= 0 {
                if let stats = workout.statistics(for: self.activeEnergyType),
                   let qty = stats.sumQuantity() {
                    calories = qty.doubleValue(for: .kilocalorie())
                }
            }

            func store(calories kcal: Double) {
                lock.lock()
                rows[index] = WorkoutData(
                    id: workout.uuid,
                    workoutType: workout.workoutActivityType,
                    duration: duration,
                    caloriesBurned: kcal,
                    startDate: workout.startDate,
                    customName: name,
                    distanceMiles: distance?.value,
                    distanceUnit: distance?.unit ?? .miles,
                    isLocal: false,
                    sourceName: sourceName
                )
                lock.unlock()
            }

            if calories > 0 {
                store(calories: calories)
                continue
            }

            group.enter()
            self.fetchActiveEnergy(for: workout) { kcal in
                store(calories: kcal)
                group.leave()
            }
        }

        group.notify(queue: .global(qos: .userInitiated)) {
            completion(rows.compactMap { $0 }, nil)
        }
    }

    /// Newer Watch workouts often leave `totalEnergyBurned` / statistics empty; sum associated samples.
    private func fetchActiveEnergy(for workout: HKWorkout, completion: @escaping (Double) -> Void) {
        let predicate = HKQuery.predicateForObjects(from: workout)
        let query = HKStatisticsQuery(
            quantityType: activeEnergyType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, statistics, _ in
            let kcal = statistics?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
            completion(kcal)
        }
        healthStore.execute(query)
    }

    private func healthKitDisplayName(for workout: HKWorkout) -> String? {
        let indoor = workout.metadata?[HKMetadataKeyIndoorWorkout] as? Bool
        switch workout.workoutActivityType {
        case .walking:
            return indoor == true ? "Indoor Walk" : "Outdoor Walk"
        case .running:
            return indoor == true ? "Indoor Run" : "Outdoor Run"
        case .cycling:
            return indoor == true ? "Indoor Cycle" : "Outdoor Cycle"
        case .swimming:
            if let raw = workout.metadata?[HKMetadataKeySwimmingLocationType] as? NSNumber,
               let location = HKWorkoutSwimmingLocationType(rawValue: raw.intValue) {
                switch location {
                case .openWater: return "Open Water Swim"
                case .pool: return "Pool Swim"
                default: break
                }
            }
            return nil
        default:
            return nil
        }
    }

    private func distance(for workout: HKWorkout) -> (value: Double, unit: WorkoutDistanceUnit)? {
        if workout.workoutActivityType == .swimming,
           let laps = lapCount(for: workout), laps > 0 {
            return (laps, .laps)
        }

        var meters = workout.totalDistance?.doubleValue(for: .meter()) ?? 0
        if meters <= 0 {
            let distanceType: HKQuantityType?
            switch workout.workoutActivityType {
            case .cycling:
                distanceType = cyclingDistanceType
            case .swimming:
                distanceType = swimmingDistanceType
            default:
                distanceType = walkingRunningDistanceType
            }
            if let distanceType,
               let stats = workout.statistics(for: distanceType),
               let qty = stats.sumQuantity() {
                meters = qty.doubleValue(for: .meter())
            }
        }
        guard meters > 0 else { return nil }
        return (meters / 1609.344, .miles)
    }

    private func lapCount(for workout: HKWorkout) -> Double? {
        guard let lapLength = workout.metadata?[HKMetadataKeyLapLength] as? HKQuantity else { return nil }
        let lapMeters = lapLength.doubleValue(for: .meter())
        guard lapMeters > 0 else { return nil }
        var totalMeters = workout.totalDistance?.doubleValue(for: .meter()) ?? 0
        if totalMeters <= 0,
           let swimmingDistanceType,
           let qty = workout.statistics(for: swimmingDistanceType)?.sumQuantity() {
            totalMeters = qty.doubleValue(for: .meter())
        }
        guard totalMeters > 0 else { return nil }
        return (totalMeters / lapMeters).rounded()
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

        exerciseTimeObserverQuery = HKObserverQuery(sampleType: exerciseTimeType, predicate: nil) { [weak self] _, completionHandler, error in
            if let error {
                print("Exercise time observer error: \(error.localizedDescription)")
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
        if let exerciseTimeObserverQuery {
            healthStore.execute(exerciseTimeObserverQuery)
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

        healthStore.enableBackgroundDelivery(for: exerciseTimeType, frequency: .immediate) { _, error in
            if let error {
                print("Background delivery error for exercise time: \(error.localizedDescription)")
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
        if let exerciseTimeObserverQuery {
            healthStore.stop(exerciseTimeObserverQuery)
        }
    }
}
