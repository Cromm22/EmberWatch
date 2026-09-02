import Foundation
import SwiftUI

@MainActor
class WaterManager: ObservableObject {
    @Published var glassesLogged: Int {
        didSet {
            UserDefaults.standard.set(glassesLogged, forKey: "waterGlassesToday_\(Self.makeTodayKey())")
        }
    }
    
    /// Daily goal in glasses (each glass = 8 fl oz).
    @Published var glassesGoal: Int {
        didSet {
            UserDefaults.standard.set(glassesGoal, forKey: "waterGlassesGoal")
        }
    }
    
    private let ozPerGlass = 8.0
    private let mlPerOz = 29.5735
    
    private static func makeTodayKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    init() {
        let key = Self.makeTodayKey()
        self.glassesLogged = UserDefaults.standard.integer(forKey: "waterGlassesToday_\(key)")
        let goal = UserDefaults.standard.integer(forKey: "waterGlassesGoal")
        self.glassesGoal = goal == 0 ? 8 : max(1, min(goal, 20))
    }
    
    @discardableResult
    func logGlass() -> Bool {
        if glassesLogged < glassesGoal {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                glassesLogged += 1
            }
            return true
        }
        return false
    }
    
    func removeGlass() {
        if glassesLogged > 0 {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                glassesLogged -= 1
            }
        }
    }
    
    var totalOz: Double {
        Double(glassesLogged) * ozPerGlass
    }
    
    var goalOz: Double {
        Double(glassesGoal) * ozPerGlass
    }
    
    var totalMl: Int {
        Int(totalOz * mlPerOz)
    }
    
    var progress: Double {
        guard glassesGoal > 0 else { return 0 }
        return min(1.0, Double(glassesLogged) / Double(glassesGoal))
    }
}
