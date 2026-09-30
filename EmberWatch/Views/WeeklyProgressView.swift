import SwiftUI

/// Rolling week used by the Home Progress sheet: today plus the previous 6 calendar days.
enum WeeklyProgressWindow {
    static let dayCount = 7
    
    static func lastSevenDays(now: Date = Date(), calendar: Calendar = .current) -> (start: Date, end: Date) {
        let startOfToday = calendar.startOfDay(for: now)
        let start = calendar.date(byAdding: .day, value: -(dayCount - 1), to: startOfToday) ?? startOfToday
        let end = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? now
        return (start, end)
    }
}

/// Display-ready weekly totals for weight, calorie days, and workouts.
@MainActor
struct WeeklyProgressSnapshot {
    let start: Date
    let end: Date
    /// Latest minus first weigh-in in the window, in the user's unit. `nil` if fewer than two.
    let weightDeltaInUnit: Double?
    let weighInCount: Int
    let onCalorieDays: Int
    let loggedFoodDays: Int
    let workoutCount: Int
    let unit: WeightUnit
    
    static func build(
        weighIns: [WeighIn],
        unit: WeightUnit,
        foodEntries: [FoodEntry],
        energyByDay: [Date: Double],
        workouts: [WorkoutData],
        remainingCalories: (Double, Double) -> Double,
        start: Date,
        end: Date,
        calendar: Calendar = .current
    ) -> WeeklyProgressSnapshot {
        let weightDelta: Double?
        if weighIns.count >= 2, let first = weighIns.first, let last = weighIns.last {
            weightDelta = unit.fromPounds(last.weightLb - first.weightLb)
        } else {
            weightDelta = nil
        }
        
        var consumedByDay: [Date: Double] = [:]
        for entry in foodEntries {
            let day = calendar.startOfDay(for: entry.timestamp)
            guard day >= start && day < end else { continue }
            consumedByDay[day, default: 0] += entry.calories
        }
        
        var workoutCaloriesByDay: [Date: Double] = [:]
        for workout in workouts where !workout.isLocal {
            let day = calendar.startOfDay(for: workout.startDate)
            guard day >= start && day < end else { continue }
            workoutCaloriesByDay[day, default: 0] += workout.caloriesBurned
        }
        
        var onTarget = 0
        for (day, consumed) in consumedByDay {
            let energy = energyByDay[day] ?? 0
            let workoutSum = workoutCaloriesByDay[day] ?? 0
            // Same fallback as today's remaining: Active Energy, else HealthKit workout sum.
            let burned = energy > 0 ? energy : workoutSum
            let remaining = remainingCalories(burned, consumed)
            if remaining >= 0 {
                onTarget += 1
            }
        }
        
        let workoutsInWindow = workouts.filter { $0.startDate >= start && $0.startDate < end }
        
        return WeeklyProgressSnapshot(
            start: start,
            end: end,
            weightDeltaInUnit: weightDelta,
            weighInCount: weighIns.count,
            onCalorieDays: onTarget,
            loggedFoodDays: consumedByDay.count,
            workoutCount: workoutsInWindow.count,
            unit: unit
        )
    }
    
    var lastInclusiveDay: Date {
        Calendar.current.date(byAdding: .day, value: -1, to: end) ?? start
    }
    
    var rangeLabel: String {
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: start, to: lastInclusiveDay)
    }
    
    var weightValueText: String {
        guard let delta = weightDeltaInUnit else { return "—" }
        let formatted = WeightManager.format(abs(delta))
        let label = unit.label
        if abs(delta) < 0.05 {
            return "0 \(label)"
        } else if delta < 0 {
            return "-\(formatted) \(label)"
        } else {
            return "+\(formatted) \(label)"
        }
    }
    
    var weightCaption: String {
        switch weighInCount {
        case 0:
            return "No weigh-ins this week"
        case 1:
            return "Need 2 weigh-ins to show change"
        default:
            return "First to latest weigh-in"
        }
    }
    
    var calorieValueText: String {
        guard loggedFoodDays > 0 else { return "—" }
        return "\(onCalorieDays) of \(loggedFoodDays)"
    }
    
    var calorieCaption: String {
        if loggedFoodDays == 0 {
            return "Log food to track calorie days"
        }
        return "Days at or under calories"
    }
    
    var workoutCaption: String {
        workoutCount == 1 ? "Workout logged" : "Workouts logged"
    }
    
    var encouragement: String {
        if weighInCount == 0 && loggedFoodDays == 0 && workoutCount == 0 {
            return "Log a weigh-in, meal, or workout and this week will start to take shape."
        }
        if loggedFoodDays > 0 && onCalorieDays == loggedFoodDays {
            return "Every logged day stayed at or under calories. Keep that fire going."
        }
        if let delta = weightDeltaInUnit, delta < -0.05 {
            return "Weight is trending down this week. Nice work — stay consistent."
        }
        if workoutCount >= 3 {
            return "Solid workout week. Ember's proud of the consistency."
        }
        if onCalorieDays > 0 {
            return "You're stacking good days. A little more consistency goes a long way."
        }
        return "This week is still yours to shape. One good day at a time."
    }
}

/// Home Progress sheet: last-7-day weight, calorie days, and workout summary.
struct WeeklyProgressView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var weightManager: WeightManager
    @EnvironmentObject var foodDataManager: FoodDataManager
    @EnvironmentObject var calorieGoalManager: CalorieGoalManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var levelManager: LevelManager
    
    @State private var showingWeightHistory = false
    @State private var isLoadingActivity = true
    @State private var windowStart = WeeklyProgressWindow.lastSevenDays().start
    @State private var windowEnd = WeeklyProgressWindow.lastSevenDays().end
    @State private var weighIns: [WeighIn] = []
    @State private var foodEntries: [FoodEntry] = []
    @State private var workouts: [WorkoutData] = []
    @State private var energyByDay: [Date: Double] = [:]
    
    private var snapshot: WeeklyProgressSnapshot {
        WeeklyProgressSnapshot.build(
            weighIns: weighIns,
            unit: weightManager.unit,
            foodEntries: foodEntries,
            energyByDay: energyByDay,
            workouts: workouts,
            remainingCalories: { burned, consumed in
                calorieGoalManager.calculateRemainingCalories(burned: burned, consumed: consumed)
            },
            start: windowStart,
            end: windowEnd
        )
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                EmberColors.dusk.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        header
                        
                        VStack(spacing: 12) {
                            WeeklyProgressStatCard(
                                icon: "scalemass.fill",
                                title: "Weight",
                                value: snapshot.weightValueText,
                                caption: snapshot.weightCaption,
                                fill: HomeQuickActionPalette.foodFill,
                                iconColor: HomeQuickActionPalette.foodIcon
                            )
                            
                            WeeklyProgressStatCard(
                                icon: "leaf.fill",
                                title: "Calories",
                                value: snapshot.calorieValueText,
                                caption: snapshot.calorieCaption,
                                fill: HomeQuickActionPalette.progressFill,
                                iconColor: HomeQuickActionPalette.progressIcon
                            )
                            
                            WeeklyProgressStatCard(
                                icon: "figure.run",
                                title: "Workouts",
                                value: isLoadingActivity && snapshot.workoutCount == 0
                                    ? "—"
                                    : "\(snapshot.workoutCount)",
                                caption: snapshot.workoutCaption,
                                fill: HomeQuickActionPalette.workoutFill,
                                iconColor: HomeQuickActionPalette.workoutIcon,
                                isLoading: isLoadingActivity && snapshot.workoutCount == 0
                            )
                        }
                        
                        encouragementCard
                        
                        viewHistoryButton
                        
                        Text("Calorie days only count days with food logged. Remaining uses your daily goal plus exercise calories, the same way Food does.")
                            .font(.caption)
                            .foregroundColor(EmberColors.muted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(EmberColors.dusk, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { isPresented = false }
                        .foregroundColor(EmberColors.ember)
                }
            }
            .onAppear { reload() }
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showingWeightHistory) {
            WeightSettingsView(isPresented: $showingWeightHistory)
                .environmentObject(weightManager)
                .environmentObject(levelManager)
        }
    }
    
    private var header: some View {
        VStack(spacing: 6) {
            Text("Last 7 days")
                .font(.title2.weight(.bold))
                .foregroundColor(EmberColors.cream)
            Text(snapshot.rangeLabel)
                .font(.subheadline)
                .foregroundColor(EmberColors.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
        .accessibilityElement(children: .combine)
    }
    
    private var encouragementCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "flame.fill")
                .font(.title3)
                .foregroundColor(EmberColors.ember)
                .accessibilityHidden(true)
            
            Text(snapshot.encouragement)
                .font(.subheadline)
                .foregroundColor(EmberColors.cream)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(HomeQuickActionPalette.foodFill)
        )
    }
    
    private var viewHistoryButton: some View {
        Button {
            showingWeightHistory = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "scalemass.fill")
                    .font(.system(size: 14, weight: .semibold))
                Text("View Weight History")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundColor(EmberColors.cream)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(EmberColors.lightPlum)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("View Weight History")
        .accessibilityHint("Opens weight history and settings")
    }
    
    private func reload() {
        let window = WeeklyProgressWindow.lastSevenDays()
        windowStart = window.start
        windowEnd = window.end
        weighIns = weightManager.weighIns(from: window.start, to: window.end)
        foodEntries = foodDataManager.entries(from: window.start, to: window.end)
        workouts = healthKitManager.workouts.filter {
            $0.startDate >= window.start && $0.startDate < window.end
        }
        var seededEnergy: [Date: Double] = [:]
        let today = Calendar.current.startOfDay(for: Date())
        if healthKitManager.totalCaloriesBurned > 0 {
            seededEnergy[today] = healthKitManager.totalCaloriesBurned
        }
        energyByDay = seededEnergy
        isLoadingActivity = true
        
        healthKitManager.fetchWeekActivity(from: window.start, to: window.end) { fetchedWorkouts, fetchedEnergy in
            var energy = fetchedEnergy
            let today = Calendar.current.startOfDay(for: Date())
            if (energy[today] ?? 0) == 0, healthKitManager.totalCaloriesBurned > 0 {
                energy[today] = healthKitManager.totalCaloriesBurned
            }
            
            var merged = fetchedWorkouts
            let ids = Set(merged.map(\.id))
            for workout in healthKitManager.workouts
            where !ids.contains(workout.id)
                && workout.startDate >= window.start
                && workout.startDate < window.end {
                merged.append(workout)
            }
            
            workouts = merged
            energyByDay = energy
            isLoadingActivity = false
        }
    }
}

private struct WeeklyProgressStatCard: View {
    let icon: String
    let title: String
    let value: String
    let caption: String
    let fill: Color
    let iconColor: Color
    var isLoading: Bool = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.55))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(EmberColors.cream.opacity(0.72))
                
                if isLoading {
                    ProgressView()
                        .tint(iconColor)
                        .scaleEffect(0.9)
                        .frame(height: 28, alignment: .leading)
                } else {
                    Text(value)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(EmberColors.cream)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .monospacedDigit()
                }
                
                Text(caption)
                    .font(.caption)
                    .foregroundColor(EmberColors.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(fill)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(isLoading ? "Loading" : value). \(caption)")
    }
}
