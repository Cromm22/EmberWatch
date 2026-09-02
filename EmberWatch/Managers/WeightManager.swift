import Foundation
import SwiftUI

enum WeightUnit: String, CaseIterable, Identifiable {
    case lb
    case kg
    
    var id: String { rawValue }
    
    var label: String { rawValue }
    
    /// Convert a value stored in pounds into this unit for display.
    func fromPounds(_ lb: Double) -> Double {
        switch self {
        case .lb: return lb
        case .kg: return lb / 2.2046226218
        }
    }
    
    /// Convert a value entered in this unit into pounds for storage.
    func toPounds(_ value: Double) -> Double {
        switch self {
        case .lb: return value
        case .kg: return value * 2.2046226218
        }
    }
}

struct WeighIn: Codable, Identifiable, Equatable {
    var id: UUID
    var date: Date
    /// Always stored in pounds.
    var weightLb: Double
    
    init(id: UUID = UUID(), date: Date = Date(), weightLb: Double) {
        self.id = id
        self.date = date
        self.weightLb = weightLb
    }
}

@MainActor
class WeightManager: ObservableObject {
    /// Current body weight in pounds. `nil` until the user logs one.
    @Published var currentWeightLb: Double? {
        didSet { persistCurrent() }
    }
    
    /// Goal weight in pounds. `nil` until set.
    @Published var goalWeightLb: Double? {
        didSet { persistGoal() }
    }
    
    @Published var unit: WeightUnit {
        didSet {
            UserDefaults.standard.set(unit.rawValue, forKey: Keys.unit)
        }
    }
    
    /// Newest-first weigh-ins (lightweight history).
    @Published var history: [WeighIn] {
        didSet { persistHistory() }
    }
    
    private enum Keys {
        static let current = "bodyWeightLb"
        static let goal = "goalWeightLb"
        static let unit = "weightUnit"
        static let history = "weighInHistory"
        static let hasCurrent = "bodyWeightLbSet"
        static let hasGoal = "goalWeightLbSet"
    }
    
    private let maxHistory = 10
    
    init() {
        let defaults = UserDefaults.standard
        if let raw = defaults.string(forKey: Keys.unit), let u = WeightUnit(rawValue: raw) {
            self.unit = u
        } else {
            self.unit = .lb
        }
        
        if defaults.bool(forKey: Keys.hasCurrent) {
            self.currentWeightLb = defaults.double(forKey: Keys.current)
        } else {
            self.currentWeightLb = nil
        }
        
        if defaults.bool(forKey: Keys.hasGoal) {
            self.goalWeightLb = defaults.double(forKey: Keys.goal)
        } else {
            self.goalWeightLb = nil
        }
        
        if let data = defaults.data(forKey: Keys.history),
           let decoded = try? JSONDecoder().decode([WeighIn].self, from: data) {
            self.history = decoded
        } else {
            self.history = []
        }
    }
    
    // MARK: - Display helpers (always convert from stored lb)
    
    var displayedCurrent: Double? {
        guard let lb = currentWeightLb else { return nil }
        return unit.fromPounds(lb)
    }
    
    var displayedGoal: Double? {
        guard let lb = goalWeightLb else { return nil }
        return unit.fromPounds(lb)
    }
    
    /// Positive = still above goal (weight to lose). Negative = below goal.
    var deltaInUnit: Double? {
        guard let current = displayedCurrent, let goal = displayedGoal else { return nil }
        return current - goal
    }
    
    var deltaCaption: String? {
        guard let delta = deltaInUnit else { return nil }
        let absDelta = abs(delta)
        let formatted = Self.format(absDelta)
        let unitLabel = unit.label
        if absDelta < 0.05 {
            return "At goal"
        } else if delta > 0 {
            return "\(formatted) \(unitLabel) to go"
        } else {
            return "\(formatted) \(unitLabel) under goal"
        }
    }
    
    static func format(_ value: Double) -> String {
        if abs(value - value.rounded()) < 0.05 {
            return String(Int(value.rounded()))
        }
        return String(format: "%.1f", value)
    }
    
    // MARK: - Mutations
    
    /// Logs a weigh-in. Returns pounds lost vs previous current weight when lower;
    /// `nil` if first log, unchanged, or weight went up.
    @discardableResult
    func logCurrentWeight(_ valueInUnit: Double) -> Double? {
        let lb = unit.toPounds(valueInUnit)
        let previous = currentWeightLb
        currentWeightLb = lb
        var next = history
        next.insert(WeighIn(weightLb: lb), at: 0)
        if next.count > maxHistory {
            next = Array(next.prefix(maxHistory))
        }
        history = next
        
        guard let previous else { return nil }
        let lost = previous - lb
        guard lost > 0.05 else { return nil }
        return lost
    }
    
    func setGoalWeight(_ valueInUnit: Double?) {
        if let valueInUnit {
            goalWeightLb = unit.toPounds(valueInUnit)
        } else {
            goalWeightLb = nil
        }
    }
    
    func clearCurrent() {
        currentWeightLb = nil
    }
    
    func clearGoal() {
        goalWeightLb = nil
    }
    
    // MARK: - Persistence
    
    private func persistCurrent() {
        let defaults = UserDefaults.standard
        if let lb = currentWeightLb {
            defaults.set(lb, forKey: Keys.current)
            defaults.set(true, forKey: Keys.hasCurrent)
        } else {
            defaults.removeObject(forKey: Keys.current)
            defaults.set(false, forKey: Keys.hasCurrent)
        }
    }
    
    private func persistGoal() {
        let defaults = UserDefaults.standard
        if let lb = goalWeightLb {
            defaults.set(lb, forKey: Keys.goal)
            defaults.set(true, forKey: Keys.hasGoal)
        } else {
            defaults.removeObject(forKey: Keys.goal)
            defaults.set(false, forKey: Keys.hasGoal)
        }
    }
    
    private func persistHistory() {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: Keys.history)
        }
    }
}
