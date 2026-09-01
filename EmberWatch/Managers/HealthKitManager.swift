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
    @Published var totalCaloriesBurned: Double = 0
    @Published var authorizationStatus: AuthorizationStatus = .notDetermined
    @Published var isLoading: Bool = false
    @Published var lastErrorMessage: String?

    private let workoutType = HKObjectType.workoutType()
    private let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!

    init() {
        // Read authorization is intentionally opaque on iOS — probe by querying.
        refreshAccessByQuerying()
    }

    /// Prefer this over authorizationStatus(for:) for *read* types.
    func refreshAccessByQuerying() {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationStatus = .denied
            lastErrorMessage = "Health data isn’t available on this device."
            return
        }
        fetchTodayWorkouts(markAccessFromResult: true)
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
                // Whether Allow or Don’t Allow, the sheet completes with success=true.
                // Probe by reading — empty result still means authorized.
                self?.fetchTodayWorkouts(markAccessFromResult: true)
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

    func fetchTodayWorkouts(markAccessFromResult: Bool = false) {
        isLoading = true
        lastErrorMessage = nil

        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
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
            guard let self else { return }

            DispatchQueue.main.async {
                self.isLoading = false

                if let error {
                    // Protected data / no permission typically surfaces here.
                    let ns = error as NSError
                    if ns.domain == "com.apple.healthkit", ns.code == 5 {
                        // Authorization not determined / denied for read
                        if markAccessFromResult {
                            // If user previously denied, keep denied; otherwise notDetermined.
                            let energy = self.healthStore.authorizationStatus(for: self.activeEnergyType)
                            let workout = self.healthStore.authorizationStatus(for: self.workoutType)
                            if energy == .sharingDenied || workout == .sharingDenied {
                                self.authorizationStatus = .denied
                            } else if self.authorizationStatus != .authorized {
                                self.authorizationStatus = .denied
                            }
                        }
                        self.lastErrorMessage = "Health access is off. Enable Workouts + Active Energy for EmberWatch in the Health app."
                    } else {
                        self.lastErrorMessage = error.localizedDescription
                    }
                    return
                }

                if markAccessFromResult {
                    self.authorizationStatus = .authorized
                }

                let workoutSamples = (samples as? [HKWorkout]) ?? []
                let workoutData = workoutSamples.map { workout -> WorkoutData in
                    let calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
                    return WorkoutData(
                        id: workout.uuid,
                        workoutType: workout.workoutActivityType,
                        duration: workout.duration,
                        caloriesBurned: calories,
                        startDate: workout.startDate
                    )
                }

                self.workouts = workoutData
                self.totalCaloriesBurned = workoutData.reduce(0) { $0 + $1.caloriesBurned }
            }
        }

        healthStore.execute(query)
    }
}
