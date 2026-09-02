import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var foodDataManager: FoodDataManager
    @EnvironmentObject var calorieGoalManager: CalorieGoalManager
    @EnvironmentObject var waterManager: WaterManager
    @EnvironmentObject var avatarManager: AvatarManager
    @EnvironmentObject var levelManager: LevelManager
    @State private var showingGoalSettings = false
    @State private var showingAvatarPicker = false
    @State private var showingWaterGoal = false
    
    var remainingCalories: Double {
        calorieGoalManager.calculateRemainingCalories(
            burned: healthKitManager.totalCaloriesBurned,
            consumed: foodDataManager.totalCaloriesConsumed
        )
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                EmberColors.dusk
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        emberAvatarCard
                        
                        remainingCaloriesCard
                        
                        waterCard
                        
                        dailySummaryCard
                        
                        quickStatsCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }
                
                if let banner = levelManager.levelUpBanner {
                    VStack {
                        Text(banner)
                            .font(.headline)
                            .foregroundColor(EmberColors.ink)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [EmberColors.gold, EmberColors.ember],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .shadow(color: EmberColors.ember.opacity(0.45), radius: 12, y: 4)
                            .padding(.top, 8)
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(20)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: levelManager.levelUpBanner)
            .navigationTitle("Ember")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(EmberColors.dusk, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showingGoalSettings) {
                GoalSettingsView(isPresented: $showingGoalSettings)
                    .environmentObject(calorieGoalManager)
            }
            .sheet(isPresented: $showingAvatarPicker) {
                AvatarPickerView()
                    .environmentObject(avatarManager)
                    .environmentObject(levelManager)
            }
            .sheet(isPresented: $showingWaterGoal) {
                WaterGoalSettingsView(isPresented: $showingWaterGoal)
                    .environmentObject(waterManager)
            }
            .onAppear {
                healthKitManager.fetchTodayWorkouts()
                foodDataManager.fetchTodayEntries()
                syncXPFromHealth()
            }
            .onChange(of: healthKitManager.totalCaloriesBurned) { _, _ in
                syncXPFromHealth()
            }
            .onChange(of: healthKitManager.workouts.map(\.id)) { _, _ in
                syncXPFromHealth()
            }
            .refreshable {
                healthKitManager.fetchTodayWorkouts()
                foodDataManager.fetchTodayEntries()
                syncXPFromHealth()
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private func syncXPFromHealth() {
        _ = levelManager.processBurnedCalories(healthKitManager.totalCaloriesBurned)
        _ = levelManager.processWorkouts(ids: healthKitManager.workouts.map { $0.id.uuidString })
    }
    
    private var emberAvatarCard: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .topTrailing) {
                EmberFlameAvatar(
                    level: levelManager.level,
                    size: 220,
                    style: avatarManager.selectedStyle
                )
                .frame(width: 220, height: 250)
                .onTapGesture {
                    showingAvatarPicker = true
                }
                
                Button(action: { showingAvatarPicker = true }) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 30))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(EmberColors.ember, EmberColors.dusk)
                        .shadow(color: EmberColors.ember.opacity(0.35), radius: 8)
                }
                .accessibilityLabel("Edit avatar")
                .offset(x: 6, y: -2)
            }
            .frame(maxWidth: .infinity)
            
            HStack(spacing: 8) {
                Text(avatarManager.displayName)
                    .font(.headline)
                    .foregroundColor(EmberColors.cream.opacity(0.9))
                
                if let boost = levelManager.boardMultiplierLabel {
                    Text(boost)
                        .font(.caption2.weight(.bold))
                        .foregroundColor(EmberColors.ink)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(EmberColors.gold))
                }
            }
            
            Text("Level \(levelManager.level)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(EmberColors.cream)
            
            VStack(spacing: 8) {
                HStack {
                    if levelManager.level >= LevelManager.maxLevel {
                        Text("XP: \(levelManager.totalXP) · Max level")
                            .font(.caption)
                            .foregroundColor(EmberColors.cream.opacity(0.7))
                    } else {
                        Text("XP: \(levelManager.xpIntoLevel) / \(levelManager.xpForNextLevel)")
                            .font(.caption)
                            .foregroundColor(EmberColors.cream.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Text("Total \(levelManager.totalXP)")
                        .font(.caption2)
                        .foregroundColor(EmberColors.cream.opacity(0.45))
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(EmberColors.darkPlum)
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [EmberColors.ember, Color.orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * levelManager.progressFraction, height: 8)
                    }
                }
                .frame(height: 8)
            }
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(EmberColors.lightPlum)
        )
    }
    
    private var remainingCaloriesCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: remainingCalories >= 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(remainingCalories >= 0 ? Color.green : Color.orange)
                
                Text("Calories")
                    .font(.headline)
                    .foregroundColor(EmberColors.cream)
                
                Spacer()
                
                Button(action: { showingGoalSettings = true }) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundColor(EmberColors.ember)
                }
                .accessibilityLabel("Edit calorie goal")
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(Int(remainingCalories))")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(remainingCalories >= 0 ? EmberColors.ember : Color.orange)
                
                Text("cal")
                    .font(.title3)
                    .foregroundColor(EmberColors.cream.opacity(0.7))
                
                Spacer()
            }
            
            Text(calorieGoalManager.ignoreFoodFromRemaining ? "remaining (food ignored)" : "remaining")
                .font(.subheadline)
                .foregroundColor(EmberColors.cream.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(EmberColors.lightPlum)
        )
    }
    
    private var waterCard: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "drop.fill")
                    .foregroundColor(EmberColors.ember)
                
                Text("Stay Hydrated")
                    .font(.headline)
                    .foregroundColor(EmberColors.cream)
                
                Spacer(minLength: 8)
                
                Text("\(Int(waterManager.totalOz)) / \(Int(waterManager.goalOz)) fl oz")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(EmberColors.cream)
                    .lineLimit(1)
                
                Button(action: { showingWaterGoal = true }) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundColor(EmberColors.ember)
                }
                .accessibilityLabel("Edit water goal")
            }
            
            Text("\(waterManager.totalMl) mL")
                .font(.caption)
                .foregroundColor(EmberColors.cream.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: min(8, waterManager.glassesGoal))
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(0..<waterManager.glassesGoal, id: \.self) { index in
                    WaterGlassView(
                        isFilled: index < waterManager.glassesLogged,
                        onTap: {
                            if index < waterManager.glassesLogged {
                                waterManager.removeGlass()
                            } else if index == waterManager.glassesLogged {
                                if waterManager.logGlass() {
                                    _ = levelManager.awardWaterServing()
                                }
                            }
                        }
                    )
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(EmberColors.lightPlum)
        )
    }
    
    private var dailySummaryCard: some View {
        VStack(spacing: 12) {
            Text("Today's Summary")
                .font(.headline)
                .foregroundColor(EmberColors.cream)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                SummaryItem(
                    icon: "target",
                    label: "Goal",
                    value: "\(Int(calorieGoalManager.dailyCalorieGoal))",
                    color: EmberColors.cream
                )
                
                SummaryItem(
                    icon: "flame.fill",
                    label: "Burned",
                    value: "+\(Int(healthKitManager.totalCaloriesBurned))",
                    color: Color.orange
                )
                
                SummaryItem(
                    icon: "fork.knife",
                    label: calorieGoalManager.ignoreFoodFromRemaining ? "Eaten*" : "Eaten",
                    value: "-\(Int(foodDataManager.totalCaloriesConsumed))",
                    color: Color.blue
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(EmberColors.lightPlum)
        )
    }
    
    private var quickStatsCard: some View {
        VStack(spacing: 16) {
            Text("Quick Stats")
                .font(.headline)
                .foregroundColor(EmberColors.cream)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                QuickStatItem(
                    icon: "figure.run",
                    value: "\(healthKitManager.workouts.count)",
                    label: "Workouts"
                )
                
                QuickStatItem(
                    icon: "fork.knife",
                    value: "\(foodDataManager.todayFoodEntries.count)",
                    label: "Meals"
                )
                
                QuickStatItem(
                    icon: "bolt.fill",
                    value: "\(Int(foodDataManager.totalProtein))g",
                    label: "Protein"
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(EmberColors.lightPlum)
        )
    }
}

struct SummaryItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(EmberColors.cream)
            
            Text(label)
                .font(.caption)
                .foregroundColor(EmberColors.cream.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(EmberColors.darkPlum)
        )
    }
}

struct QuickStatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(EmberColors.ember)
            
            Text(value)
                .font(.headline)
                .foregroundColor(EmberColors.cream)
            
            Text(label)
                .font(.caption)
                .foregroundColor(EmberColors.cream.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(EmberColors.darkPlum)
        )
    }
}

struct GoalSettingsView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var calorieGoalManager: CalorieGoalManager
    @State private var goalInput: String = ""
    @State private var ignoreFood: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                EmberColors.dusk
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("Daily Calorie Goal")
                            .font(.headline)
                            .foregroundColor(EmberColors.cream)
                        
                        TextField("Enter goal", text: $goalInput)
                            .keyboardType(.numberPad)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(EmberColors.ember)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(EmberColors.lightPlum)
                            )
                    }
                    .padding(.horizontal)
                    
                    Toggle(isOn: $ignoreFood) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Ignore calories eaten")
                                .font(.headline)
                                .foregroundColor(EmberColors.cream)
                            Text("Don’t subtract food from remaining. Food still logs in the diary.")
                                .font(.caption)
                                .foregroundColor(EmberColors.cream.opacity(0.65))
                        }
                    }
                    .tint(EmberColors.ember)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(EmberColors.lightPlum)
                    )
                    .padding(.horizontal)
                    
                    Text(ignoreFood
                         ? "Remaining = goal + exercise (food ignored)."
                         : "Remaining = goal + exercise − food.")
                        .font(.subheadline)
                        .foregroundColor(EmberColors.cream.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.top, 12)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(EmberColors.dusk, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(EmberColors.cream)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let goal = Double(goalInput) {
                            calorieGoalManager.dailyCalorieGoal = goal
                        }
                        calorieGoalManager.ignoreFoodFromRemaining = ignoreFood
                        isPresented = false
                    }
                    .foregroundColor(EmberColors.ember)
                }
            }
            .onAppear {
                goalInput = String(Int(calorieGoalManager.dailyCalorieGoal))
                ignoreFood = calorieGoalManager.ignoreFoodFromRemaining
            }
        }
    }
}

struct WaterGoalSettingsView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var waterManager: WaterManager
    @State private var glassesInput: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                EmberColors.dusk.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("Daily Water Goal")
                            .font(.headline)
                            .foregroundColor(EmberColors.cream)
                        
                        TextField("Glasses", text: $glassesInput)
                            .keyboardType(.numberPad)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(EmberColors.ember)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(EmberColors.lightPlum)
                            )
                        
                        Text("glasses · 8 fl oz each")
                            .font(.subheadline)
                            .foregroundColor(EmberColors.cream.opacity(0.7))
                        
                        if let n = Int(glassesInput), n > 0 {
                            Text("≈ \(n * 8) fl oz / \(Int(Double(n * 8) * 29.5735)) mL")
                                .font(.caption)
                                .foregroundColor(EmberColors.cream.opacity(0.55))
                        }
                    }
                    .padding()
                    
                    Text("Logged servings are unchanged, only daily glass goal is updated.")
                        .font(.subheadline)
                        .foregroundColor(EmberColors.cream.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.top, 12)
            }
            .navigationTitle("Water Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(EmberColors.dusk, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                        .foregroundColor(EmberColors.cream)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let n = Int(glassesInput) {
                            waterManager.glassesGoal = max(1, min(n, 20))
                        }
                        isPresented = false
                    }
                    .foregroundColor(EmberColors.ember)
                }
            }
            .onAppear {
                glassesInput = String(waterManager.glassesGoal)
            }
        }
    }
}

struct WaterGlassView: View {
    let isFilled: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isFilled ? EmberColors.ember : EmberColors.dusk)
                    .frame(width: 32, height: 40)
                
                VStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isFilled ? EmberColors.cream : EmberColors.cream.opacity(0.3))
                        .frame(width: 24, height: 3)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(isFilled ? EmberColors.cream.opacity(0.9) : EmberColors.cream.opacity(0.2))
                        .frame(width: 20, height: 28)
                }
            }
        }
    }
}
