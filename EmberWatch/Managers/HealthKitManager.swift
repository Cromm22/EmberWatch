import Foundation
import HealthKit

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
    
    private let workoutType = HKObjectType.workoutType()
    private let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
    
    init() {
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        let workoutStatus = healthStore.authorizationStatus(for: workoutType)
        let energyStatus = healthStore.authorizationStatus(for: activeEnergyType)
        
        if workoutStatus == .sharingAuthorized && energyStatus == .sharingAuthorized {
            authorizationStatus = .authorized
        } else if workoutStatus == .sharingDenied || energyStatus == .sharingDenied {
            authorizationStatus = .denied
        } else {
            authorizationStatus = .notDetermined
        }
    }
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }
        
        let typesToRead: Set<HKObjectType> = [workoutType, activeEnergyType]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.checkAuthorizationStatus()
                    if self?.authorizationStatus == .authorized {
                        self?.fetchTodayWorkouts()
                    }
                } else {
                    print("Authorization failed: \(error?.localizedDescription ?? "Unknown error")")
                    self?.checkAuthorizationStatus()
                }
            }
        }
    }
    
    func fetchTodayWorkouts() {
        guard authorizationStatus == .authorized else {
            print("Not authorized to read health data")
            return
        }
        
        isLoading = true
        
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
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching workouts: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            guard let workoutSamples = samples as? [HKWorkout] else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
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
            
            DispatchQueue.main.async {
                self.workouts = workoutData
                self.totalCaloriesBurned = workoutData.reduce(0) { $0 + $1.caloriesBurned }
                self.isLoading = false
            }
        }
        
        healthStore.execute(query)
    }
}
