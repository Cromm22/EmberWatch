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
    @EnvironmentObject var emberTalkManager: EmberTalkManager
    @Binding var selectedTab: Int
    @State private var showingGoalSettings = false
    @State private var showingAvatarPicker = false
    @State private var showingWaterGoal = false
    @State private var showingWeightSettings = false
    @State private var showingHealthConnect = false
    @State private var showingFoodSearch = false
    @AppStorage("emberWatch.lastGreetingDate") private var lastGreetingDateString: String = ""
    
    // XP animation states
    @State private var xpBarScale: CGFloat = 1.0
    @State private var showXPGain: Bool = false
    @State private var xpGainAmount: Int = 0
    @State private var xpGainOffset: CGFloat = 0
    @State private var xpGainOpacity: Double = 0
    @State private var wavePhase: CGFloat = 0
    
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
                        
                        if healthKitManager.authorizationStatus != .authorized {
                            healthConnectBanner
                        }
                        
                        remainingCaloriesCard
                        
                        HomeQuickActionRow(
                            onLogFood: { showingFoodSearch = true },
                            onLogWorkout: { selectedTab = 2 }, // Workout tab
                            onProgress: { showingWeightSettings = true },
                            onGoals: { showingGoalSettings = true }
                        )
                        
                        weightCard
                        
                        waterCard
                        
                        dailySummaryCard
                        
                        quickStatsCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }
            }
            .overlay(alignment: .bottom) {
                if let banner = levelManager.streakBanner
                    ?? levelManager.weightLossBanner
                    ?? levelManager.levelUpBanner
                    ?? sparksManager.toast {
                    CelebrationToastAnchor {
                        CelebrationToastCard(
                            accent: banner.contains("Sparks") ? EmberColors.ember : EmberColors.gold,
                            secondaryAccent: EmberColors.ember
                        ) {
                            Text(banner)
                                .font(.headline)
                                .foregroundColor(EmberColors.ink)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    DailyStreakPill(streak: levelManager.streakCount)
                }
            }
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
            .sheet(isPresented: $showingHealthConnect) {
                HealthConnectView(showsDismissButton: true)
                    .environmentObject(healthKitManager)
            }
            .sheet(isPresented: $showingFoodSearch) {
                FoodSearchView(isPresented: $showingFoodSearch)
                    .environmentObject(foodDataManager)
                    .environmentObject(emberTalkManager)
            }
            .onAppear {
                healthKitManager.fetchTodayWorkouts()
                foodDataManager.fetchTodayEntries()
                syncXPFromHealth()
                _ = levelManager.checkDailyOpenReward()
                _ = sparksManager.earnDailyLogin()
                startWaveAnimation()
                checkAndShowDailyGreeting()
            }
            .onChange(of: healthKitManager.totalCaloriesBurned) { _, _ in
                syncXPFromHealth()
            }
            .onChange(of: healthKitManager.workouts.map(\.id)) { _, _ in
                syncXPFromHealth()
            }
            .onChange(of: levelManager.xpGainEvent) { _, newValue in
                guard let event = newValue else { return }
                triggerXPGainAnimation(amount: event.amount)
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
    
    private func triggerXPGainAnimation(amount: Int) {
        guard amount > 0 else { return }
        
        // Bar bulge animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            xpBarScale = 1.15
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                xpBarScale = 1.0
            }
        }
        
        // Floating +XP animation
        xpGainAmount = amount
        showXPGain = true
        xpGainOffset = 0
        xpGainOpacity = 1.0
        
        withAnimation(.easeOut(duration: 0.8)) {
            xpGainOffset = -40
            xpGainOpacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            showXPGain = false
        }
    }
    
    private func startWaveAnimation() {
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            wavePhase = 1.0
        }
    }
    
    private func checkAndShowDailyGreeting() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todayString = ISO8601DateFormatter().string(from: today)
        
        if lastGreetingDateString != todayString {
            lastGreetingDateString = todayString
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                emberTalkManager.showGreeting()
            }
        }
    }
    
    private func emberSizeForLevel(_ level: Int) -> CGFloat {
        let minSize: CGFloat = 170
        let maxSize: CGFloat = 270
        let maxLevel = CGFloat(LevelManager.maxLevel)
        
        let clampedLevel = min(CGFloat(level), maxLevel)
        let progress = (clampedLevel - 1) / (maxLevel - 1)
        
        return minSize + (maxSize - minSize) * progress
    }
    
    private var healthConnectBanner: some View {
        Button {
            if healthKitManager.authorizationStatus == .denied {
                showingHealthConnect = true
            } else {
                healthKitManager.requestAuthorization()
            }
        } label: {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "applewatch")
                    .font(.title2)
                    .foregroundColor(EmberColors.ember)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(healthKitManager.authorizationStatus == .denied
                         ? "Health access is off"
                         : "Connect Apple Watch")
                        .font(.headline)
                        .foregroundColor(EmberColors.cream)
                    Text(healthKitManager.authorizationStatus == .denied
                         ? "Enable Workouts and Active Energy in Health so Move calories count."
                         : "Allow Health access to sync Watch workouts and Move calories.")
                        .font(.caption)
                        .foregroundColor(EmberColors.cream.opacity(0.65))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer(minLength: 8)
                
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(EmberColors.cream.opacity(0.4))
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(EmberColors.lightPlum)
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint("Connect Apple Health to include Watch workouts")
    }
    
    private var emberAvatarCard: some View {
        let emberSize = emberSizeForLevel(levelManager.level)
        let frameHeight = emberSize * 1.15
        
        return VStack(spacing: 12) {
            ZStack(alignment: .topTrailing) {
                EmberFlameAvatar(
                    level: levelManager.level,
                    size: emberSize,
                    style: avatarManager.selectedStyle,
                    extraGlow: sparksManager.hasGlow
                )
                .frame(width: emberSize, height: frameHeight)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: levelManager.level)
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
            
            VStack(spacing: 10) {
                Text(avatarManager.displayName)
                    .font(.headline)
                    .foregroundColor(sparksManager.nameplateColor ?? EmberColors.cream.opacity(0.9))

                HomeStatBadgeRow(
                    streak: levelManager.streakCount,
                    sparks: sparksManager.balance,
                    xpBoost: levelManager.xpBoostPercentLabel,
                    onSparksTap: { showingAvatarPicker = true }
                )
                .padding(.horizontal, 12)
            }
            
            // XP Progress Bar with level label inside
            ZStack {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background bar
                        RoundedRectangle(cornerRadius: 10)
                            .fill(EmberColors.darkPlum)
                            .frame(height: 36)
                        
                        // Progress fill with gradient
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            EmberColors.ember,
                                            EmberColors.emberAccent,
                                            Color.orange.opacity(0.9)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * levelManager.progressFraction, height: 36)
                                .scaleEffect(x: xpBarScale, y: xpBarScale, anchor: .leading)
                            
                            // Wave animation overlay
                            if levelManager.progressFraction > 0 {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0),
                                                Color.white.opacity(0.3),
                                                Color.white.opacity(0),
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: 60, height: 36)
                                    .offset(x: wavePhase * geometry.size.width * levelManager.progressFraction - 30)
                                    .mask(
                                        RoundedRectangle(cornerRadius: 10)
                                            .frame(width: geometry.size.width * levelManager.progressFraction, height: 36)
                                    )
                            }
                        }
                        
                        // Level label inside the bar - always visible with shadow for contrast
                        HStack {
                            Spacer()
                            Text(levelManager.level >= LevelManager.maxLevel ? "Max Lv" : "Lv \(levelManager.level)")
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(.black)
                                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                                .shadow(color: EmberColors.cream.opacity(0.2), radius: 1, x: 0, y: 0)
                            Spacer()
                        }
                        .frame(height: 36)
                        .allowsHitTesting(false)
                    }
                }
                .frame(height: 36)
                
                // Floating +XP animation
                if showXPGain {
                    HStack {
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "sparkle")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(EmberColors.ember)
                            Text("+\(xpGainAmount)")
                                .font(.headline.weight(.bold))
                                .foregroundColor(EmberColors.ember)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(EmberColors.cream)
                                .shadow(color: EmberColors.ember.opacity(0.4), radius: 8, y: 2)
                        )
                        .offset(y: xpGainOffset)
                        .opacity(xpGainOpacity)
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 60)
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
                
                Text("remaining")
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
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(HomeQuickActionPalette.foodFill)
                        .frame(width: 34, height: 34)
                    Image(systemName: "scalemass.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(EmberColors.ember)
                }
                .accessibilityHidden(true)

                Text("Weight")
                    .font(.headline)
                    .foregroundColor(EmberColors.cream)

                Spacer(minLength: 8)

                Button(action: { showingWeightSettings = true }) {
                    HStack(spacing: 6) {
                        Text("View History")
                            .font(.system(size: 13, weight: .semibold))
                        Image(systemName: "person.fill")
                            .font(.system(size: 11, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(EmberColors.cream.opacity(0.78))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color(hex: "#F3F4F6"))
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("View weight history")
                .accessibilityHint("Opens weight history and settings")
            }

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 12) {
                    weightLogCopy
                    Spacer(minLength: 8)
                    addWeightButton
                }
                VStack(alignment: .leading, spacing: 12) {
                    weightLogCopy
                    addWeightButton
                }
            }

            HomeWeightTrendChart(
                entries: weightManager.history,
                startingWeightLb: weightManager.startingWeightLb,
                currentWeightLb: weightManager.currentWeightLb,
                unit: weightManager.unit
            )
            .onTapGesture {
                showingWeightSettings = true
            }
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Opens weight history")
        }
        .padding(.horizontal, 4)
        .padding(.top, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var weightLogCopy: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Log your weight")
                .font(.title3.weight(.semibold))
                .foregroundColor(EmberColors.cream)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Text("Track your progress over time.")
                .font(.subheadline)
                .foregroundColor(EmberColors.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var addWeightButton: some View {
        Button(action: { showingWeightSettings = true }) {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                Text("Add Weight")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background(
                Capsule(style: .continuous)
                    .fill(EmberColors.ember)
            )
        }
        .buttonStyle(.plain)
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityLabel("Add weight")
        .accessibilityHint("Opens the log weight form")
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
                                    // Show Ember talk toast only on even-numbered glasses (2, 4, 6, ...)
                                    if waterManager.glassesLogged % 2 == 0 {
                                        emberTalkManager.showWaterPhrase()
                                    }
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
                    label: "Eaten",
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
                        isPresented = false
                    }
                    .foregroundColor(EmberColors.ember)
                }
            }
            .onAppear {
                goalInput = String(Int(calorieGoalManager.dailyCalorieGoal))
            }
        }
    }
}


struct WeightSettingsView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var weightManager: WeightManager
    @EnvironmentObject var levelManager: LevelManager
    @State private var startingInput: String = ""
    @State private var currentInput: String = ""
    @State private var goalInput: String = ""
    @State private var unit: WeightUnit = .lb
    /// Tracks unsaved field values in pounds so unit toggles convert correctly.
    @State private var draftStartingLb: Double?
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
                            Text("Starting weight")
                                .font(.headline)
                                .foregroundColor(EmberColors.cream)
                            TextField("Optional", text: $startingInput)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(EmberColors.ember.opacity(0.85))
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 16).fill(EmberColors.lightPlum))
                            Text(unit.label)
                                .font(.subheadline)
                                .foregroundColor(EmberColors.cream.opacity(0.7))
                        }
                        .padding(.horizontal)
                        
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
                        
                        if let startingLb = draftStartingLb, let goalLb = draftGoalLb, abs(startingLb - goalLb) > 0.5 {
                            WeightProjectionChart(
                                startingWeightLb: startingLb,
                                goalWeightLb: goalLb,
                                currentWeightLb: draftCurrentLb,
                                unit: unit
                            )
                            .padding(.horizontal)
                        }
                        
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
                        
                        Spacer()
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
                draftStartingLb = weightManager.startingWeightLb
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
        let startingTrimmed = startingInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if startingTrimmed.isEmpty {
            draftStartingLb = nil
        } else if let s = parse(startingTrimmed) {
            draftStartingLb = inputUnit.toPounds(s)
        }
        
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
        if let lb = draftStartingLb {
            startingInput = WeightManager.format(displayUnit.fromPounds(lb))
        } else if startingInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            startingInput = ""
        }
        
        if let lb = draftCurrentLb {
            currentInput = WeightManager.format(displayUnit.fromPounds(lb))
        }
        
        if let lb = draftGoalLb {
            goalInput = WeightManager.format(displayUnit.fromPounds(lb))
        } else if goalInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            goalInput = ""
        }
    }
    
    private func save() {
        syncDraftFromInputs(using: unit)
        weightManager.unit = unit
        
        if let lb = draftStartingLb {
            weightManager.setStartingWeight(unit.fromPounds(lb))
        } else {
            weightManager.clearStarting()
        }
        
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
