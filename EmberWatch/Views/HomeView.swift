import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var foodDataManager: FoodDataManager
    @EnvironmentObject var calorieGoalManager: CalorieGoalManager
    @EnvironmentObject var waterManager: WaterManager
    @EnvironmentObject var avatarManager: AvatarManager
    @EnvironmentObject var levelManager: LevelManager
    @EnvironmentObject var sparksManager: SparksManager
    @EnvironmentObject var weightManager: WeightManager
    @State private var showingGoalSettings = false
    @State private var showingAvatarPicker = false
    @State private var showingWaterGoal = false
    @State private var showingWeightSettings = false
    
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
                        
                        weightCard
                        
                        waterCard
                        
                        dailySummaryCard
                        
                        quickStatsCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }
                
                if let banner = levelManager.streakBanner
                    ?? levelManager.weightLossBanner
                    ?? levelManager.levelUpBanner
                    ?? sparksManager.toast {
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
                                            colors: banner.contains("Sparks")
                                                ? [EmberColors.ember, EmberColors.emberAccent]
                                                : [EmberColors.gold, EmberColors.ember],
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
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: levelManager.streakBanner)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: levelManager.weightLossBanner)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: levelManager.levelUpBanner)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: sparksManager.toast)
            .navigationTitle("Ember")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
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
                    .environmentObject(sparksManager)
            }
            .sheet(isPresented: $showingWaterGoal) {
                WaterGoalSettingsView(isPresented: $showingWaterGoal)
                    .environmentObject(waterManager)
            }
            .sheet(isPresented: $showingWeightSettings) {
                WeightSettingsView(isPresented: $showingWeightSettings)
                    .environmentObject(weightManager)
                    .environmentObject(levelManager)
            }
            .onAppear {
                healthKitManager.fetchTodayWorkouts()
                foodDataManager.fetchTodayEntries()
                syncXPFromHealth()
                _ = levelManager.checkDailyOpenReward()
                _ = sparksManager.earnDailyLogin()
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
                    style: avatarManager.selectedStyle,
                    extraGlow: sparksManager.hasGlow
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
                    .foregroundColor(sparksManager.nameplateColor ?? EmberColors.cream.opacity(0.9))
                
                if levelManager.streakCount > 0 {
                    Text("🔥 \(levelManager.streakCount)d")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(EmberColors.ink)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(EmberColors.ember))
                        .accessibilityLabel("Day \(levelManager.streakCount) open streak")
                }
                
                // Sparks balance chip (ember orange)
                HStack(spacing: 3) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 9, weight: .bold))
                    Text("\(sparksManager.balance)")
                        .font(.caption2.weight(.bold))
                }
                .foregroundColor(EmberColors.ink)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(EmberColors.ember))
                .accessibilityLabel("\(sparksManager.balance) Sparks")
                
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
        Button(action: { showingGoalSettings = true }) {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: remainingCalories >= 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(remainingCalories >= 0 ? Color.green : Color.orange)
                    
                    Text("Calories")
                        .font(.headline)
                        .foregroundColor(EmberColors.cream)
                    
                    Spacer()
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(EmberColors.lightPlum)
            )
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Edit calorie goal")
        .accessibilityHint("Opens daily calorie goal and food settings")
    }
    

    private var weightCard: some View {
        Button(action: { showingWeightSettings = true }) {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "scalemass.fill")
                        .foregroundColor(EmberColors.ember)
                    
                    Text("Weight")
                        .font(.headline)
                        .foregroundColor(EmberColors.cream)
                    
                    Spacer()
                }
                
                if let current = weightManager.displayedCurrent {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(WeightManager.format(current))
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(EmberColors.ember)
                        Text(weightManager.unit.label)
                            .font(.title3)
                            .foregroundColor(EmberColors.cream.opacity(0.7))
                        Spacer()
                    }
                    
                    if let goal = weightManager.displayedGoal {
                        HStack {
                            Text("Goal \(WeightManager.format(goal)) \(weightManager.unit.label)")
                                .font(.subheadline)
                                .foregroundColor(EmberColors.cream.opacity(0.7))
                            Spacer()
                            if let caption = weightManager.deltaCaption {
                                Text(caption)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(EmberColors.gold)
                            }
                        }
                    } else {
                        Text("Set a goal to track progress")
                            .font(.subheadline)
                            .foregroundColor(EmberColors.cream.opacity(0.55))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    HStack {
                        Text("Log your weight")
                            .fontWeight(.semibold)
                        Image(systemName: "plus.circle.fill")
                    }
                    .foregroundColor(EmberColors.cream)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(EmberColors.ember.opacity(0.85)))
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(EmberColors.lightPlum)
            )
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Edit weight and goal")
        .accessibilityHint("Opens weight and goal settings")
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(EmberColors.lightPlum)
        )
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture {
            showingWaterGoal = true
        }
        .accessibilityElement(children: .contain)
        .accessibilityHint("Tap card (outside cups) to edit water goal")
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
            Text("Macros")
                .font(.headline)
                .foregroundColor(EmberColors.cream)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                MacroCard(name: "Protein", amount: Int(foodDataManager.totalProtein), color: .orange, icon: "flame.fill")
                MacroCard(name: "Carbs", amount: Int(foodDataManager.totalCarbs), color: .blue, icon: "bolt.fill")
                MacroCard(name: "Fat", amount: Int(foodDataManager.totalFat), color: .yellow, icon: "drop.fill")
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
            .toolbarColorScheme(.light, for: .navigationBar)
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


struct WeightSettingsView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var weightManager: WeightManager
    @EnvironmentObject var levelManager: LevelManager
    @State private var currentInput: String = ""
    @State private var goalInput: String = ""
    @State private var unit: WeightUnit = .lb
    /// Tracks unsaved field values in pounds so unit toggles convert correctly.
    @State private var draftCurrentLb: Double?
    @State private var draftGoalLb: Double?
    
    var body: some View {
        NavigationView {
            ZStack {
                EmberColors.dusk.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        Picker("Unit", selection: $unit) {
                            ForEach(WeightUnit.allCases) { u in
                                Text(u.label.uppercased()).tag(u)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .onChange(of: unit) { oldUnit, newUnit in
                            syncDraftFromInputs(using: oldUnit)
                            refreshInputs(from: newUnit)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Current weight")
                                .font(.headline)
                                .foregroundColor(EmberColors.cream)
                            TextField("e.g. 180", text: $currentInput)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundColor(EmberColors.ember)
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 16).fill(EmberColors.lightPlum))
                            Text(unit.label)
                                .font(.subheadline)
                                .foregroundColor(EmberColors.cream.opacity(0.7))
                        }
                        .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            Text("Goal weight")
                                .font(.headline)
                                .foregroundColor(EmberColors.cream)
                            TextField("Optional", text: $goalInput)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundColor(EmberColors.ember)
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 16).fill(EmberColors.lightPlum))
                            Text(unit.label)
                                .font(.subheadline)
                                .foregroundColor(EmberColors.cream.opacity(0.7))
                        }
                        .padding(.horizontal)
                        
                        if !weightManager.history.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Recent weigh-ins")
                                    .font(.headline)
                                    .foregroundColor(EmberColors.cream)
                                ForEach(weightManager.history.prefix(5)) { entry in
                                    HStack {
                                        Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                                            .foregroundColor(EmberColors.cream.opacity(0.65))
                                        Spacer()
                                        Text("\(WeightManager.format(unit.fromPounds(entry.weightLb))) \(unit.label)")
                                            .foregroundColor(EmberColors.cream)
                                            .fontWeight(.semibold)
                                    }
                                    .padding(.vertical, 6)
                                }
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 16).fill(EmberColors.lightPlum))
                            .padding(.horizontal)
                        }
                        
                        Text("Switching lb / kg converts displayed values. Saving current weight adds a weigh-in.")
                            .font(.caption)
                            .foregroundColor(EmberColors.cream.opacity(0.55))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(EmberColors.dusk, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                        .foregroundColor(EmberColors.cream)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                        .foregroundColor(EmberColors.ember)
                }
            }
            .onAppear {
                unit = weightManager.unit
                draftCurrentLb = weightManager.currentWeightLb
                draftGoalLb = weightManager.goalWeightLb
                refreshInputs(from: unit)
            }
        }
    }
    
    private func parse(_ raw: String) -> Double? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard let value = Double(trimmed), value > 0 else { return nil }
        return value
    }
    
    private func syncDraftFromInputs(using inputUnit: WeightUnit) {
        if let c = parse(currentInput) {
            draftCurrentLb = inputUnit.toPounds(c)
        }
        let goalTrimmed = goalInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if goalTrimmed.isEmpty {
            draftGoalLb = nil
        } else if let g = parse(goalTrimmed) {
            draftGoalLb = inputUnit.toPounds(g)
        }
    }
    
    private func refreshInputs(from displayUnit: WeightUnit) {
        if let lb = draftCurrentLb {
            currentInput = WeightManager.format(displayUnit.fromPounds(lb))
        }
        if let lb = draftGoalLb {
            goalInput = WeightManager.format(displayUnit.fromPounds(lb))
        } else {
            // Keep empty if cleared
            if goalInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                goalInput = ""
            }
        }
    }
    
    private func save() {
        syncDraftFromInputs(using: unit)
        weightManager.unit = unit
        if let lb = draftCurrentLb {
            if let poundsLost = weightManager.logCurrentWeight(unit.fromPounds(lb)) {
                _ = levelManager.awardWeightLoss(poundsLost: poundsLost)
            }
        }
        if let lb = draftGoalLb {
            weightManager.setGoalWeight(unit.fromPounds(lb))
        } else {
            weightManager.clearGoal()
        }
        isPresented = false
    }
}

struct WaterGoalSettingsView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var waterManager: WaterManager
    @State private var flOzInput: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                EmberColors.dusk.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("Daily Water Goal")
                            .font(.headline)
                            .foregroundColor(EmberColors.cream)
                        
                        TextField("fl oz", text: $flOzInput)
                            .keyboardType(.numberPad)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(EmberColors.ember)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(EmberColors.lightPlum)
                            )
                        
                        Text("fl oz / day")
                            .font(.subheadline)
                            .foregroundColor(EmberColors.cream.opacity(0.7))
                        
                        if let n = Int(flOzInput), n > 0 {
                            let cups = Int(ceil(Double(n) / WaterManager.ozPerGlass))
                            Text("≈ \(cups) cups · \(Int(WaterManager.ozPerGlass)) fl oz each / \(Int(Double(n) * 29.5735)) mL")
                                .font(.caption)
                                .foregroundColor(EmberColors.cream.opacity(0.55))
                        }
                    }
                    .padding()
                    
                    Text("Cups still log 8 fl oz servings. Goal is stored in fl oz (default 125).")
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
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(EmberColors.dusk, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                        .foregroundColor(EmberColors.cream)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let n = Int(flOzInput), n > 0 {
                            waterManager.goalFlOz = Double(n)
                        }
                        isPresented = false
                    }
                    .foregroundColor(EmberColors.ember)
                }
            }
            .onAppear {
                flOzInput = String(Int(waterManager.goalFlOz))
            }
        }
    }
}

struct WaterGlassView: View {
    let isFilled: Bool
    let onTap: () -> Void
    
    var body: some View {
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
        .contentShape(Rectangle())
        .highPriorityGesture(
            TapGesture().onEnded { _ in onTap() }
        )
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(isFilled ? "Filled water glass" : "Empty water glass")
    }
}
