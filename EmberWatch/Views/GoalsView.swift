import SwiftUI

/// Home → Goals: set, view, and change weight, workout, and calorie goals.
struct GoalsView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var calorieGoalManager: CalorieGoalManager
    @EnvironmentObject var weightManager: WeightManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var foodDataManager: FoodDataManager
    @EnvironmentObject var workoutGoalManager: WorkoutGoalManager
    @EnvironmentObject var characterManager: CharacterManager
    
    @State private var editingWeight = false
    @State private var editingWorkout = false
    @State private var editingCalories = false
    @State private var editingMacros = false
    @State private var editingBuild = false
    
    var body: some View {
        NavigationView {
            ZStack {
                EmberColors.dusk
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        Text("Set a target, then check in as you go.")
                            .font(.subheadline)
                            .foregroundColor(EmberColors.muted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                        
                        buildCard
                        weightCard
                        workoutCard
                        calorieCard
                        macrosCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Goals")
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
            .sheet(isPresented: $editingWeight) {
                WeightGoalEditView(isPresented: $editingWeight)
                    .environmentObject(weightManager)
            }
            .sheet(isPresented: $editingWorkout) {
                WorkoutGoalEditView(isPresented: $editingWorkout)
                    .environmentObject(workoutGoalManager)
            }
            .sheet(isPresented: $editingCalories) {
                GoalSettingsView(isPresented: $editingCalories)
                    .environmentObject(calorieGoalManager)
            }
            .sheet(isPresented: $editingMacros) {
                MacroGoalEditView(isPresented: $editingMacros)
                    .environmentObject(calorieGoalManager)
            }
            .sheet(isPresented: $editingBuild) {
                BuildChoiceSheet(isPresented: $editingBuild, allowsSkip: false)
                    .environmentObject(characterManager)
            }
            .onAppear {
                healthKitManager.fetchTodayWorkouts()
                foodDataManager.fetchTodayEntries()
            }
        }
    }
    
    private var buildCard: some View {
        let build = characterManager.selectedBuild
        let value = build?.displayName ?? "Not set"
        let detail = build?.goalLine ?? "Warrior, Assassin, Tank, Ranger, or Mage"
        let caption = build?.recommendedBehaviors.joined(separator: " · ") ?? "Does not reset XP or stats"
        let primary = build?.primaryStats ?? []
        
        return GoalProgressCard(
            icon: build?.iconName ?? "shield.fill",
            title: "Build",
            fill: HomeQuickActionPalette.progressFill,
            iconColor: HomeQuickActionPalette.progressIcon,
            value: value,
            detail: detail,
            caption: caption,
            progress: build == nil ? 0 : 1,
            progressLabel: primary.isEmpty ? (build == .mage ? "ALL" : "—") : primary.map(\.shortLabel).joined(separator: " "),
            onEdit: { editingBuild = true }
        )
        .accessibilityLabel("Build. \(value). \(detail). Changing build does not reset XP or stats.")
    }
    
    private var weightCard: some View {
        let unit = weightManager.unit.label
        let startText = weightManager.displayedStarting.map { "\(WeightManager.format($0)) \(unit)" } ?? "—"
        let goalText = weightManager.displayedGoal.map { "\(WeightManager.format($0)) \(unit)" } ?? "—"
        let currentText = (weightManager.displayedCurrent ?? weightManager.displayedStarting)
            .map { "\(WeightManager.format($0)) \(unit)" } ?? "—"
        let timingCaption: String = {
            if !weightManager.hasWeightGoal {
                return "Add a start and goal weight"
            }
            if weightManager.timingMode == .targetDate, let date = weightManager.targetDate {
                return "Target \(date.formatted(date: .abbreviated, time: .omitted))"
            }
            return "\(WeightManager.format(weightManager.displayedWeeklyPace)) \(unit)/week"
        }()
        
        return GoalProgressCard(
            icon: "scalemass.fill",
            title: "Lose weight",
            fill: HomeQuickActionPalette.foodFill,
            iconColor: EmberColors.ember,
            value: weightManager.hasWeightGoal ? currentText : "Not set",
            detail: weightManager.hasWeightGoal
                ? "Start \(startText) → goal \(goalText)"
                : "Starting weight, goal weight, and pace",
            caption: weightManager.deltaCaption ?? timingCaption,
            progress: weightManager.hasWeightGoal ? weightManager.goalProgress : 0,
            progressLabel: weightManager.hasWeightGoal
                ? "\(Int((weightManager.goalProgress * 100).rounded()))%"
                : "—",
            onEdit: { editingWeight = true }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(weightAccessibilityLabel(startText: startText, goalText: goalText, currentText: currentText, timing: timingCaption))
    }
    
    private var workoutCard: some View {
        let minutes = workoutGoalManager.todayMinutes(from: healthKitManager.workouts)
        let count = workoutGoalManager.todayWorkoutCount(from: healthKitManager.workouts)
        let target = workoutGoalManager.targetMinutes
        let enabled = workoutGoalManager.isEnabled
        let progress = workoutGoalManager.progress(from: healthKitManager.workouts)
        let value = enabled ? "\(minutes) / \(target) min" : "Off"
        let detail = enabled
            ? (count == 1 ? "1 workout logged today" : "\(count) workouts logged today")
            : "Turn on a daily workout target"
        let caption = enabled
            ? (progress >= 1 ? "Today's goal complete" : "\(max(0, target - minutes)) min to go")
            : "No daily workout goal"
        
        return GoalProgressCard(
            icon: "figure.run",
            title: "Workout daily",
            fill: HomeQuickActionPalette.workoutFill,
            iconColor: HomeQuickActionPalette.workoutIcon,
            value: value,
            detail: detail,
            caption: caption,
            progress: enabled ? progress : 0,
            progressLabel: enabled ? "\(Int((progress * 100).rounded()))%" : "Off",
            onEdit: { editingWorkout = true }
        )
        .accessibilityLabel("Workout daily. \(value). \(detail). \(caption)")
    }
    
    private var calorieCard: some View {
        let goal = calorieGoalManager.dailyCalorieGoal
        let eaten = foodDataManager.totalCaloriesConsumed
        let progress = goal > 0 ? min(1, eaten / goal) : 0
        let remaining = goal - eaten
        let caption: String = {
            if remaining >= 0 {
                return "\(Int(remaining.rounded())) cal left today"
            }
            return "\(Int((-remaining).rounded())) cal over"
        }()
        
        return GoalProgressCard(
            icon: "fork.knife",
            title: "Daily calories",
            fill: HomeQuickActionPalette.goalsFill,
            iconColor: HomeQuickActionPalette.goalsIcon,
            value: "\(Int(eaten.rounded())) / \(Int(goal.rounded()))",
            detail: "Consumed toward your daily calorie goal",
            caption: caption,
            progress: progress,
            progressLabel: "\(Int((progress * 100).rounded()))%",
            onEdit: { editingCalories = true }
        )
        .accessibilityLabel("Daily calories. \(Int(eaten.rounded())) of \(Int(goal.rounded())) consumed. \(caption)")
    }
    
    private var macrosCard: some View {
        let protein = foodDataManager.totalProtein
        let carbs = foodDataManager.totalCarbs
        let fat = foodDataManager.totalFat
        let sodium = foodDataManager.totalSodium
        let proteinGoal = calorieGoalManager.dailyProteinGoal
        let carbsGoal = calorieGoalManager.dailyCarbsGoal
        let fatGoal = calorieGoalManager.dailyFatGoal
        let sodiumGoal = calorieGoalManager.dailySodiumGoal
        
        let proteinProgress = calorieGoalManager.progress(consumed: protein, goal: proteinGoal)
        let carbsProgress = calorieGoalManager.progress(consumed: carbs, goal: carbsGoal)
        let fatProgress = calorieGoalManager.progress(consumed: fat, goal: fatGoal)
        let sodiumProgress = calorieGoalManager.progress(consumed: sodium, goal: sodiumGoal)
        let progressSum = proteinProgress + carbsProgress + fatProgress + sodiumProgress
        let progress = progressSum / 4.0
        
        let proteinAmount = Int(protein.rounded())
        let proteinTarget = Int(proteinGoal.rounded())
        let carbsAmount = Int(carbs.rounded())
        let carbsTarget = Int(carbsGoal.rounded())
        let fatAmount = Int(fat.rounded())
        let fatTarget = Int(fatGoal.rounded())
        let sodiumAmount = Int(sodium.rounded())
        let sodiumTarget = Int(sodiumGoal.rounded())
        
        let value = "\(proteinAmount)/\(proteinTarget)g P"
        let detail = "\(carbsAmount)/\(carbsTarget)g carbs · \(fatAmount)/\(fatTarget)g fat"
        let caption = "\(sodiumAmount)/\(sodiumTarget)mg sodium"
        let percent = Int((progress * 100).rounded())
        
        return GoalProgressCard(
            icon: "chart.pie.fill",
            title: "Daily macros",
            fill: HomeQuickActionPalette.foodFill,
            iconColor: EmberColors.ember,
            value: value,
            detail: detail,
            caption: caption,
            progress: progress,
            progressLabel: "\(percent)%",
            onEdit: { editingMacros = true }
        )
        .accessibilityLabel("Daily macros. Protein \(proteinAmount) of \(proteinTarget) grams. Carbs \(carbsAmount) of \(carbsTarget) grams. Fat \(fatAmount) of \(fatTarget) grams. Sodium \(sodiumAmount) of \(sodiumTarget) milligrams.")
    }
    
    private func weightAccessibilityLabel(startText: String, goalText: String, currentText: String, timing: String) -> String {
        if weightManager.hasWeightGoal {
            let pct = Int((weightManager.goalProgress * 100).rounded())
            return "Lose weight. Current \(currentText), start \(startText), goal \(goalText). \(timing). \(pct) percent complete"
        }
        return "Lose weight. Not set. \(timing)"
    }
}

// MARK: - Shared card chrome

private struct GoalProgressCard: View {
    let icon: String
    let title: String
    let fill: Color
    let iconColor: Color
    let value: String
    let detail: String
    let caption: String
    let progress: Double
    let progressLabel: String
    let onEdit: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(fill)
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                .accessibilityHidden(true)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(EmberColors.cream)
                
                Spacer(minLength: 8)
                
                Button(action: onEdit) {
                    HStack(spacing: 4) {
                        Text("Edit")
                            .font(.system(size: 13, weight: .semibold))
                        Image(systemName: "pencil")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(EmberColors.ember)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(fill)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit \(title)")
            }
            
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(EmberColors.ember)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .monospacedDigit()
            
            Text(detail)
                .font(.subheadline)
                .foregroundColor(EmberColors.cream.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
            
            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(EmberColors.dusk)
                            .frame(height: 10)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [EmberColors.ember, EmberColors.emberAccent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, geometry.size.width * min(1, max(0, progress))), height: 10)
                    }
                }
                .frame(height: 10)
                
                HStack {
                    Text(caption)
                        .font(.caption)
                        .foregroundColor(EmberColors.muted)
                    Spacer()
                    Text(progressLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(EmberColors.ember)
                        .monospacedDigit()
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(EmberColors.lightPlum)
        )
    }
}

// MARK: - Weight editor (writes to WeightManager)

struct WeightGoalEditView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var weightManager: WeightManager
    
    @State private var startingInput: String = ""
    @State private var goalInput: String = ""
    @State private var paceInput: String = ""
    @State private var unit: WeightUnit = .lb
    @State private var timingMode: WeightGoalTiming = .weeklyPace
    @State private var targetDate: Date = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    @State private var draftStartingLb: Double?
    @State private var draftGoalLb: Double?
    @State private var draftPaceLb: Double = WeightManager.defaultWeeklyPaceLb
    
    var body: some View {
        NavigationView {
            ZStack {
                EmberColors.dusk.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 22) {
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
                        
                        goalField(title: "Starting weight", text: $startingInput, placeholder: "e.g. 182.4")
                        goalField(title: "Goal weight", text: $goalInput, placeholder: "e.g. 165.0")
                        
                        VStack(spacing: 10) {
                            Text("Target")
                                .font(.headline)
                                .foregroundColor(EmberColors.cream)
                            
                            Picker("Target", selection: $timingMode) {
                                ForEach(WeightGoalTiming.allCases) { mode in
                                    Text(mode.label).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                            
                            if timingMode == .weeklyPace {
                                VStack(spacing: 8) {
                                    TextField("Pace", text: $paceInput)
                                        .keyboardType(.decimalPad)
                                        .font(.system(size: 36, weight: .bold, design: .rounded))
                                        .foregroundColor(EmberColors.ember)
                                        .multilineTextAlignment(.center)
                                        .padding()
                                        .background(RoundedRectangle(cornerRadius: 16).fill(EmberColors.lightPlum))
                                    Text("\(unit.label) per week")
                                        .font(.subheadline)
                                        .foregroundColor(EmberColors.cream.opacity(0.7))
                                }
                                .padding(.horizontal)
                            } else {
                                DatePicker(
                                    "Reach goal by",
                                    selection: $targetDate,
                                    in: Date()...,
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.graphical)
                                .padding(.horizontal, 8)
                                .tint(EmberColors.ember)
                            }
                        }
                        
                        WeightProjectionChart(
                            startingWeightLb: draftOrParsedStarting ?? weightManager.startingWeightLb,
                            currentWeightLb: weightManager.currentWeightLb,
                            history: weightManager.history,
                            unit: unit
                        )
                        .padding(.horizontal)
                        
                        Text("Saves to the same start and goal used on Home and in Weight settings.")
                            .font(.caption)
                            .foregroundColor(EmberColors.muted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Lose weight")
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
                timingMode = weightManager.timingMode
                draftStartingLb = weightManager.startingWeightLb
                draftGoalLb = weightManager.goalWeightLb
                draftPaceLb = weightManager.weeklyPaceLb
                if let date = weightManager.targetDate {
                    targetDate = date
                }
                refreshInputs(from: unit)
            }
        }
    }
    
    private var draftOrParsedStarting: Double? {
        let trimmed = startingInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        if let value = WeightManager.parseBodyWeight(trimmed) { return unit.toPounds(value) }
        return draftStartingLb
    }
    
    private func goalField(title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(EmberColors.cream)
            TextField(placeholder, text: text)
                .keyboardType(.decimalPad)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(EmberColors.ember)
                .multilineTextAlignment(.center)
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(EmberColors.lightPlum))
            Text(unit.label)
                .font(.subheadline)
                .foregroundColor(EmberColors.cream.opacity(0.7))
        }
        .padding(.horizontal)
    }
    
    private func syncDraftFromInputs(using inputUnit: WeightUnit) {
        let startingTrimmed = startingInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if startingTrimmed.isEmpty {
            draftStartingLb = nil
        } else if let s = WeightManager.parseBodyWeight(startingTrimmed) {
            draftStartingLb = inputUnit.toPounds(s)
        }
        
        let goalTrimmed = goalInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if goalTrimmed.isEmpty {
            draftGoalLb = nil
        } else if let g = WeightManager.parseBodyWeight(goalTrimmed) {
            draftGoalLb = inputUnit.toPounds(g)
        }
        
        if let pace = WeightManager.parseDecimal(paceInput) {
            draftPaceLb = inputUnit.toPounds(pace)
        }
    }
    
    private func refreshInputs(from displayUnit: WeightUnit) {
        if let lb = draftStartingLb {
            startingInput = WeightManager.format(displayUnit.fromPounds(lb))
        } else {
            startingInput = ""
        }
        if let lb = draftGoalLb {
            goalInput = WeightManager.format(displayUnit.fromPounds(lb))
        } else {
            goalInput = ""
        }
        paceInput = WeightManager.format(displayUnit.fromPounds(draftPaceLb))
    }
    
    private func save() {
        syncDraftFromInputs(using: unit)
        weightManager.unit = unit
        
        if let lb = draftStartingLb {
            weightManager.setStartingWeight(unit.fromPounds(lb))
        } else {
            weightManager.clearStarting()
        }
        
        if let lb = draftGoalLb {
            weightManager.setGoalWeight(unit.fromPounds(lb))
        } else {
            weightManager.clearGoal()
        }
        
        weightManager.weeklyPaceLb = max(0.05, draftPaceLb)
        if timingMode == .targetDate {
            weightManager.setTargetDate(targetDate)
        } else {
            weightManager.timingMode = .weeklyPace
        }
        isPresented = false
    }
}

// MARK: - Workout editor

struct WorkoutGoalEditView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var workoutGoalManager: WorkoutGoalManager
    
    @State private var isEnabled = true
    @State private var minutesInput = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                EmberColors.dusk.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Toggle(isOn: $isEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Workout daily")
                                .font(.headline)
                                .foregroundColor(EmberColors.cream)
                            Text("Count logged workouts toward a daily minutes target.")
                                .font(.caption)
                                .foregroundColor(EmberColors.muted)
                        }
                    }
                    .tint(EmberColors.ember)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16).fill(EmberColors.lightPlum))
                    .padding(.horizontal)
                    
                    if isEnabled {
                        VStack(spacing: 8) {
                            Text("Target minutes")
                                .font(.headline)
                                .foregroundColor(EmberColors.cream)
                            
                            TextField("30", text: $minutesInput)
                                .keyboardType(.numberPad)
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(EmberColors.ember)
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 16).fill(EmberColors.lightPlum))
                            
                            Text("minutes / day")
                                .font(.subheadline)
                                .foregroundColor(EmberColors.cream.opacity(0.7))
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding(.top, 12)
            }
            .navigationTitle("Workout daily")
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
                isEnabled = workoutGoalManager.isEnabled
                minutesInput = String(workoutGoalManager.targetMinutes)
            }
        }
    }
    
    private func save() {
        workoutGoalManager.isEnabled = isEnabled
        if let minutes = Int(minutesInput.trimmingCharacters(in: .whitespacesAndNewlines)), minutes > 0 {
            workoutGoalManager.targetMinutes = minutes
        }
        isPresented = false
    }
}

// MARK: - Macro editor

struct MacroGoalEditView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var calorieGoalManager: CalorieGoalManager
    
    @State private var proteinInput = ""
    @State private var carbsInput = ""
    @State private var fatInput = ""
    @State private var sodiumInput = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                EmberColors.dusk.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 22) {
                        Text("Set daily protein, carbs, fat, and sodium targets used on Food, Home, and Progress.")
                            .font(.subheadline)
                            .foregroundColor(EmberColors.muted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        macroField(title: "Protein", text: $proteinInput, unit: "g / day", placeholder: "150")
                        macroField(title: "Carbs", text: $carbsInput, unit: "g / day", placeholder: "250")
                        macroField(title: "Fat", text: $fatInput, unit: "g / day", placeholder: "65")
                        macroField(title: "Sodium", text: $sodiumInput, unit: "mg / day", placeholder: "2300")
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Daily macros")
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
                proteinInput = String(Int(calorieGoalManager.dailyProteinGoal.rounded()))
                carbsInput = String(Int(calorieGoalManager.dailyCarbsGoal.rounded()))
                fatInput = String(Int(calorieGoalManager.dailyFatGoal.rounded()))
                sodiumInput = String(Int(calorieGoalManager.dailySodiumGoal.rounded()))
            }
        }
    }
    
    private func macroField(title: String, text: Binding<String>, unit: String, placeholder: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(EmberColors.cream)
            
            TextField(placeholder, text: text)
                .keyboardType(.numberPad)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(EmberColors.ember)
                .multilineTextAlignment(.center)
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(EmberColors.lightPlum))
            
            Text(unit)
                .font(.subheadline)
                .foregroundColor(EmberColors.cream.opacity(0.7))
        }
        .padding(.horizontal)
    }
    
    private func save() {
        if let protein = parsedGoal(proteinInput) {
            calorieGoalManager.dailyProteinGoal = protein
        }
        if let carbs = parsedGoal(carbsInput) {
            calorieGoalManager.dailyCarbsGoal = carbs
        }
        if let fat = parsedGoal(fatInput) {
            calorieGoalManager.dailyFatGoal = fat
        }
        if let sodium = parsedGoal(sodiumInput) {
            calorieGoalManager.dailySodiumGoal = sodium
        }
        isPresented = false
    }
    
    private func parsedGoal(_ raw: String) -> Double? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Double(trimmed), value > 0 else { return nil }
        return value
    }
}
