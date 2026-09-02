import Foundation
import SwiftUI

@MainActor
class WaterManager: ObservableObject {
    /// Default daily hydration goal in fluid ounces (new installs + shipped default).
    static let defaultGoalFlOz: Double = 125

    /// One cup/glass serving size.
    static let ozPerGlass: Double = 8

    private static let goalFlOzKey = "waterGoalFlOz"
    private static let legacyGlassesGoalKey = "waterGlassesGoal"
    /// One-time migrate/overwrite so existing installs leave the old 64 oz (8 glasses) default.
    private static let default125MigrationKey = "waterGoalFlOz_default125_applied"

    @Published var glassesLogged: Int {
        didSet {
            UserDefaults.standard.set(glassesLogged, forKey: "waterGlassesToday_\(Self.makeTodayKey())")
        }
    }

    /// Daily goal in fl oz (source of truth). Cups still log `ozPerGlass` servings.
    @Published var goalFlOz: Double {
        didSet {
            let clamped = Self.clampGoalFlOz(goalFlOz)
            if clamped != goalFlOz {
                goalFlOz = clamped
                return
            }
            UserDefaults.standard.set(goalFlOz, forKey: Self.goalFlOzKey)
            // Keep legacy key roughly in sync for any old readers.
            UserDefaults.standard.set(glassesGoal, forKey: Self.legacyGlassesGoalKey)
        }
    }

    private let mlPerOz = 29.5735

    private static func makeTodayKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private static func clampGoalFlOz(_ value: Double) -> Double {
        max(8, min(value.rounded(), 400))
    }

    init() {
        let key = Self.makeTodayKey()
        self.glassesLogged = UserDefaults.standard.integer(forKey: "waterGlassesToday_\(key)")

        let defaults = UserDefaults.standard
        let migrated = defaults.bool(forKey: Self.default125MigrationKey)

        if !migrated {
            // New installs and existing phones stuck on the old 8-glass / 64 oz default → 125 fl oz.
            self.goalFlOz = Self.defaultGoalFlOz
            defaults.set(Self.defaultGoalFlOz, forKey: Self.goalFlOzKey)
            defaults.set(Int(ceil(Self.defaultGoalFlOz / Self.ozPerGlass)), forKey: Self.legacyGlassesGoalKey)
            defaults.set(true, forKey: Self.default125MigrationKey)
        } else if defaults.object(forKey: Self.goalFlOzKey) != nil {
            let stored = defaults.double(forKey: Self.goalFlOzKey)
            self.goalFlOz = stored > 0 ? Self.clampGoalFlOz(stored) : Self.defaultGoalFlOz
        } else {
            // Fallback: derive from legacy glasses goal if present.
            let legacyGlasses = defaults.integer(forKey: Self.legacyGlassesGoalKey)
            if legacyGlasses > 0 {
                self.goalFlOz = Self.clampGoalFlOz(Double(legacyGlasses) * Self.ozPerGlass)
            } else {
                self.goalFlOz = Self.defaultGoalFlOz
            }
            defaults.set(self.goalFlOz, forKey: Self.goalFlOzKey)
        }
    }

    /// Number of 8 oz cup slots shown / needed to reach the fl oz goal (ceil).
    var glassesGoal: Int {
        max(1, Int(ceil(goalFlOz / Self.ozPerGlass)))
    }

    @discardableResult
    func logGlass() -> Bool {
        // Allow filling every displayed cup (ceil of goal); progress caps at 100% via `progress`.
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
        Double(glassesLogged) * Self.ozPerGlass
    }

    var goalOz: Double {
        goalFlOz
    }

    var totalMl: Int {
        Int(totalOz * mlPerOz)
    }

    var goalMl: Int {
        Int(goalFlOz * mlPerOz)
    }

    var progress: Double {
        guard goalFlOz > 0 else { return 0 }
        return min(1.0, totalOz / goalFlOz)
    }
}
