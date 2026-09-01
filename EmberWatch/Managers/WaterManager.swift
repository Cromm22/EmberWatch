import Foundation
import SwiftUI

@MainActor
class WaterManager: ObservableObject {
    @Published var glassesLogged: Int {
        didSet {
            UserDefaults.standard.set(glassesLogged, forKey: "waterGlassesToday_\(Self.makeTodayKey())")
        }
    }
    
    private let glassesPerDay = 8
    private let ozPerGlass = 8.0
    private let mlPerOz = 29.5735
    
    private static func makeTodayKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private var todayKey: String { Self.makeTodayKey() }
    
    init() {
        let key = Self.makeTodayKey()
        self.glassesLogged = UserDefaults.standard.integer(forKey: "waterGlassesToday_\(key)")
    }
    
    func logGlass() {
        if glassesLogged < glassesPerDay {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                glassesLogged += 1
            }
        }
    }
    
    func removeGlass() {
        if glassesLogged > 0 {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                glassesLogged -= 1
            }
        }
    }
    
    var totalOz: Double {
        return Double(glassesLogged) * ozPerGlass
    }
    
    var totalMl: Int {
        return Int(totalOz * mlPerOz)
    }
    
    var progress: Double {
        return Double(glassesLogged) / Double(glassesPerDay)
    }
}
