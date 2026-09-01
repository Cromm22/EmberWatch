import Foundation
import HealthKit

struct WorkoutData: Identifiable {
    let id: UUID
    let workoutType: HKWorkoutActivityType
    let duration: TimeInterval
    let caloriesBurned: Double
    let startDate: Date
    
    var displayName: String {
        switch workoutType {
        case .walking:
            return "Outdoor Walk"
        case .running:
            return "Outdoor Run"
        case .cycling:
            return "Outdoor Cycle"
        case .swimming:
            return "Pool Swim"
        case .functionalStrengthTraining:
            return "Functional Strength Training"
        case .highIntensityIntervalTraining:
            return "High Intensity Interval Training"
        case .traditionalStrengthTraining:
            return "Strength Training"
        case .yoga:
            return "Yoga"
        case .dance:
            return "Dance"
        case .elliptical:
            return "Elliptical"
        case .rowing:
            return "Rowing"
        case .stairs:
            return "Stair Stepper"
        default:
            return workoutType.name
        }
    }
    
    var iconName: String {
        switch workoutType {
        case .walking:
            return "figure.walk"
        case .running:
            return "figure.run"
        case .cycling:
            return "bicycle"
        case .swimming:
            return "figure.pool.swim"
        case .functionalStrengthTraining, .traditionalStrengthTraining:
            return "dumbbell.fill"
        case .highIntensityIntervalTraining:
            return "bolt.fill"
        case .yoga:
            return "figure.mind.and.body"
        case .dance:
            return "figure.dance"
        case .elliptical:
            return "figure.elliptical"
        case .rowing:
            return "figure.rower"
        case .stairs:
            return "figure.stairs"
        default:
            return "figure.mixed.cardio"
        }
    }
    
    var formattedDuration: String {
        let minutes = Int(duration / 60)
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours) hr"
            }
            return "\(hours) hr \(remainingMinutes) min"
        }
    }
    
    var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: startDate)
    }
}

extension HKWorkoutActivityType {
    var name: String {
        let typeString = String(describing: self)
        return typeString
            .replacingOccurrences(of: "HKWorkoutActivityType", with: "")
            .replacingOccurrences(of: "([A-Z])", with: " $1", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
            .capitalized
    }
}
