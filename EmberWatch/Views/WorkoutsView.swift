import SwiftUI
import HealthKit

enum WorkoutFlamePhase {
    case idle
    case growing
    case glowing
    case blazing
    
    init(calories: Double) {
        switch calories {
        case ..<800:
            self = .idle
        case 800..<1200:
            self = .growing
        case 1200..<2000:
            self = .glowing
        default:
            self = .blazing
        }
    }
    
    var scale: CGFloat {
        switch self {
        case .idle: return 1.0
        case .growing: return 1.2
        case .glowing: return 1.5
        case .blazing: return 2.0
        }
    }
    
    var showsGlow: Bool {
        switch self {
        case .idle, .growing: return false
        case .glowing, .blazing: return true
        }
    }
    
    var pulses: Bool {
        self == .blazing
    }
}

private struct QuickAddExercise: Identifiable, Hashable {
    let id: String
    let name: String
    let type: HKWorkoutActivityType
    let icon: String
}

/// Which primary metric field (besides time + calories) a Quick Add drawer shows.
private enum QuickAddMetricField {
    case none
    case distanceMiles
    case laps
    case distanceMiKm
}

struct WorkoutsView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var levelManager: LevelManager
    @EnvironmentObject var emberTalkManager: EmberTalkManager
    @State private var flamePulse = false
    
    /// Only one Quick Add drawer open at a time.
    @State private var expandedQuickAddID: String? = nil
    @State private var distanceText = ""
    @State private var timeText = "30"
    @State private var caloriesText = ""
    /// Persisted mi/km preference for rowing Quick Add drawers.
    @AppStorage("emberwatch.rowingDistanceUnit") private var rowingUnitRaw: String = WorkoutDistanceUnit.miles.rawValue
    @FocusState private var focusedQuickField: QuickAddField?
    
    private enum QuickAddField: Hashable {
        case distance, time, calories
    }
    
    private var rowingUnit: WorkoutDistanceUnit {
        get { WorkoutDistanceUnit(rawValue: rowingUnitRaw) ?? .miles }
        nonmutating set { rowingUnitRaw = newValue.rawValue }
    }
    
    private let quickAddExercises: [QuickAddExercise] = [
        QuickAddExercise(id: "outdoor-walk", name: "Outdoor walk", type: .walking, icon: "figure.walk"),
        QuickAddExercise(id: "indoor-walk", name: "Indoor walk", type: .walking, icon: "figure.walk"),
        QuickAddExercise(id: "strength", name: "Functional strength training", type: .functionalStrengthTraining, icon: "dumbbell.fill"),
        QuickAddExercise(id: "pool-swim", name: "Pool swim", type: .swimming, icon: "figure.pool.swim"),
        QuickAddExercise(id: "hiit", name: "High intensity interval training", type: .highIntensityIntervalTraining, icon: "bolt.fill"),
        QuickAddExercise(id: "outdoor-cycle", name: "Outdoor cycle", type: .cycling, icon: "bicycle"),
        QuickAddExercise(id: "other", name: "Other", type: .other, icon: "ellipsis.circle"),
        QuickAddExercise(id: "elliptical", name: "Elliptical", type: .elliptical, icon: "figure.elliptical"),
        QuickAddExercise(id: "indoor-run", name: "Indoor run", type: .running, icon: "figure.run"),
        QuickAddExercise(id: "outdoor-run", name: "Outdoor run", type: .running, icon: "figure.run"),
        QuickAddExercise(id: "outdoor-rowing", name: "Outdoor rowing", type: .rowing, icon: "figure.rower"),
        QuickAddExercise(id: "open-water-swim", name: "Open water swim", type: .swimming, icon: "figure.open.water.swim"),
        QuickAddExercise(id: "indoor-cycle", name: "Indoor cycle", type: .cycling, icon: "figure.indoor.cycle"),
        QuickAddExercise(id: "triathlon", name: "Triathlon", type: .swimBikeRun, icon: "figure.mixed.cardio"),
        QuickAddExercise(id: "hiking", name: "Hiking", type: .hiking, icon: "figure.hiking"),
        QuickAddExercise(id: "stair-stepper", name: "Stair stepper", type: .stairClimbing, icon: "figure.stairs"),
        QuickAddExercise(id: "indoor-rowing", name: "Indoor rowing", type: .rowing, icon: "figure.rower"),
        QuickAddExercise(id: "yoga", name: "Yoga", type: .yoga, icon: "figure.yoga")
    ]
    
    private var flamePhase: WorkoutFlamePhase {
        WorkoutFlamePhase(calories: healthKitManager.totalCaloriesBurned)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                EmberColors.dusk
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        caloriesSummaryCard
                        
                        if healthKitManager.workouts.isEmpty && !healthKitManager.isLoading {
                            emptyStateView
                        } else {
                            workoutsList
                        }
                        
                        quickAddSection
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
                                Capsule().fill(
                                    LinearGradient(
                                        colors: [EmberColors.gold, EmberColors.ember],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            )
                            .padding(.top, 8)
                        Spacer()
                    }
                    .zIndex(20)
                }
            }
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(EmberColors.dusk, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedQuickField = nil
                    }
                    .foregroundColor(EmberColors.ember)
                }
            }
            .onAppear {
                healthKitManager.fetchTodayWorkouts()
                updateFlamePulse()
                syncXP()
            }
            .onChange(of: healthKitManager.totalCaloriesBurned) { _, _ in
                updateFlamePulse()
                syncXP()
            }
            .onChange(of: healthKitManager.workouts.map(\.id)) { _, _ in
                syncXP()
            }
            .refreshable {
                healthKitManager.fetchTodayWorkouts()
                syncXP()
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private func syncXP() {
        _ = levelManager.processBurnedCalories(healthKitManager.totalCaloriesBurned)
        _ = levelManager.processWorkouts(ids: healthKitManager.workouts.map { $0.id.uuidString })
    }
    
    private func updateFlamePulse() {
        if flamePhase.pulses {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                flamePulse = true
            }
        } else {
            withAnimation(.easeInOut(duration: 0.35)) {
                flamePulse = false
            }
        }
    }
    
    // MARK: - Quick Add field matrix
    
    private func metricField(for exercise: QuickAddExercise) -> QuickAddMetricField {
        switch exercise.id {
        case "strength", "hiit", "elliptical", "stair-stepper", "yoga":
            return .none
        case "pool-swim", "open-water-swim":
            return .laps
        case "outdoor-rowing", "indoor-rowing":
            return .distanceMiKm
        default:
            return .distanceMiles
        }
    }
    
    // MARK: - Quick Add (accordion drawers)
    
    private var quickAddSection: some View {
        VStack(spacing: 12) {
            Text("Quick Add")
                .font(.headline)
                .foregroundColor(EmberColors.cream)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
            
            VStack(spacing: 10) {
                ForEach(quickAddExercises) { exercise in
                    quickAddRow(exercise)
                }
            }
        }
    }
    
    private func quickAddRow(_ exercise: QuickAddExercise) -> some View {
        let isExpanded = expandedQuickAddID == exercise.id
        
        return VStack(alignment: .leading, spacing: 0) {
            Button {
                toggleQuickAdd(exercise)
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: exercise.icon)
                        .font(.title2)
                        .foregroundColor(EmberColors.ember)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(EmberColors.dusk)
                        )
                    
                    Text(exercise.name)
                        .font(.headline)
                        .foregroundColor(EmberColors.cream)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(EmberColors.cream.opacity(0.5))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                quickAddDrawer(for: exercise)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity
                        )
                    )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(EmberColors.lightPlum)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isExpanded ? EmberColors.ember.opacity(0.45) : Color.clear,
                            lineWidth: 1
                        )
                )
        )
        .animation(.easeInOut(duration: 0.28), value: isExpanded)
    }
    
    private func quickAddDrawer(for exercise: QuickAddExercise) -> some View {
        let metric = metricField(for: exercise)
        
        return VStack(alignment: .leading, spacing: 12) {
            Divider()
                .background(EmberColors.cream.opacity(0.2))
            
            switch metric {
            case .none:
                EmptyView()
            case .distanceMiles:
                drawerField(
                    title: "Distance",
                    unit: "mi",
                    placeholder: "0",
                    text: $distanceText,
                    keyboard: .decimalPad,
                    field: .distance
                )
            case .laps:
                drawerField(
                    title: "Laps",
                    unit: "laps",
                    placeholder: "0",
                    text: $distanceText,
                    keyboard: .numberPad,
                    field: .distance
                )
            case .distanceMiKm:
                drawerFieldWithUnitToggle(
                    title: "Distance",
                    placeholder: "0",
                    text: $distanceText,
                    field: .distance
                )
            }
            
            drawerField(
                title: "Time",
                unit: "min",
                placeholder: "30",
                text: $timeText,
                keyboard: .numberPad,
                field: .time
            )
            
            drawerField(
                title: "Calories burned",
                unit: "cal",
                placeholder: "0",
                text: $caloriesText,
                keyboard: .numberPad,
                field: .calories
            )
            
            Button {
                logQuickAdd(exercise)
            } label: {
                Text("Log")
                    .font(.headline)
                    .foregroundColor(EmberColors.cream)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(canLogQuickAdd(for: exercise) ? EmberColors.ember : EmberColors.ember.opacity(0.35))
                    )
            }
            .buttonStyle(.plain)
            .disabled(!canLogQuickAdd(for: exercise))
            .padding(.top, 4)
        }
    }
    
    private func drawerField(
        title: String,
        unit: String,
        placeholder: String,
        text: Binding<String>,
        keyboard: UIKeyboardType,
        field: QuickAddField
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(EmberColors.cream.opacity(0.7))
            
            HStack(spacing: 8) {
                TextField(placeholder, text: text)
                    .keyboardType(keyboard)
                    .focused($focusedQuickField, equals: field)
                    .foregroundColor(EmberColors.cream)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(EmberColors.dusk)
                    )
                
                Text(unit)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(EmberColors.cream.opacity(0.55))
                    .frame(minWidth: 40, alignment: .leading)
            }
        }
    }
    
    /// Distance field with mi / km segmented toggle (rowing). Preference persists via AppStorage.
    private func drawerFieldWithUnitToggle(
        title: String,
        placeholder: String,
        text: Binding<String>,
        field: QuickAddField
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(EmberColors.cream.opacity(0.7))
            
            HStack(spacing: 8) {
                TextField(placeholder, text: text)
                    .keyboardType(.decimalPad)
                    .focused($focusedQuickField, equals: field)
                    .foregroundColor(EmberColors.cream)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(EmberColors.dusk)
                    )
                
                Picker("Unit", selection: Binding(
                    get: { rowingUnit },
                    set: { rowingUnit = $0 }
                )) {
                    Text("mi").tag(WorkoutDistanceUnit.miles)
                    Text("km").tag(WorkoutDistanceUnit.kilometers)
                }
                .pickerStyle(.segmented)
                .frame(width: 100)
            }
        }
    }
    
    private func canLogQuickAdd(for exercise: QuickAddExercise) -> Bool {
        let minutes = Int(timeText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        let caloriesOK: Bool = {
            let trimmed = caloriesText.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return true } // blank → 0
            return Double(trimmed) != nil
        }()
        let metric = metricField(for: exercise)
        let distanceOK: Bool = {
            if metric == .none { return true }
            let trimmed = distanceText.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return true }
            return Double(trimmed) != nil
        }()
        return minutes > 0 && caloriesOK && distanceOK
    }
    
    private func toggleQuickAdd(_ exercise: QuickAddExercise) {
        focusedQuickField = nil
        withAnimation(.easeInOut(duration: 0.28)) {
            if expandedQuickAddID == exercise.id {
                expandedQuickAddID = nil
            } else {
                expandedQuickAddID = exercise.id
                resetQuickAddFields()
            }
        }
    }
    
    private func resetQuickAddFields() {
        distanceText = ""
        timeText = "30"
        caloriesText = ""
    }
    
    private func logQuickAdd(_ exercise: QuickAddExercise) {
        focusedQuickField = nil
        
        let minutes = max(1, Int(timeText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 30)
        let caloriesTrimmed = caloriesText.trimmingCharacters(in: .whitespacesAndNewlines)
        let calories = Double(caloriesTrimmed) ?? 0
        
        let metric = metricField(for: exercise)
        let distanceTrimmed = distanceText.trimmingCharacters(in: .whitespacesAndNewlines)
        let rawDistance = Double(distanceTrimmed).flatMap { $0 > 0 ? $0 : nil }
        
        let distanceValue: Double?
        let unit: WorkoutDistanceUnit
        switch metric {
        case .none:
            distanceValue = nil
            unit = .miles
        case .distanceMiles:
            distanceValue = rawDistance
            unit = .miles
        case .laps:
            distanceValue = rawDistance
            unit = .laps
        case .distanceMiKm:
            distanceValue = rawDistance
            unit = rowingUnit
        }
        
        let workout = WorkoutData(
            workoutType: exercise.type,
            duration: TimeInterval(minutes * 60),
            caloriesBurned: max(0, calories),
            startDate: Date(),
            customName: exercise.name.capitalizedWordsPreservingAcronyms,
            distanceMiles: distanceValue,
            distanceUnit: unit,
            isLocal: true
        )
        
        // Local list only — does not write HealthKit / Active Energy.
        healthKitManager.addLocalWorkout(workout)
        // LevelManager workout XP path (deduped by id).
        _ = levelManager.awardWorkout(id: workout.id.uuidString)
        
        emberTalkManager.showWorkoutPhrase()
        
        withAnimation(.easeInOut(duration: 0.28)) {
            expandedQuickAddID = nil
            resetQuickAddFields()
        }
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    // MARK: - Summary / list
    
    private var caloriesSummaryCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.system(size: 40))
                .foregroundColor(EmberColors.ember)
                .scaleEffect(flamePhase.scale * (flamePulse ? 1.08 : 1.0))
                .shadow(
                    color: flamePhase.showsGlow
                        ? EmberColors.ember.opacity(flamePulse ? 0.85 : 0.55)
                        : .clear,
                    radius: flamePhase.showsGlow ? (flamePulse ? 22 : 14) : 0
                )
                .shadow(
                    color: flamePhase.showsGlow
                        ? Color.orange.opacity(flamePulse ? 0.45 : 0.25)
                        : .clear,
                    radius: flamePhase.showsGlow ? (flamePulse ? 32 : 20) : 0
                )
                .animation(.easeInOut(duration: 0.45), value: flamePhase.scale)
                .animation(.easeInOut(duration: 0.45), value: flamePhase.showsGlow)
            
            if healthKitManager.isLoading {
                ProgressView()
                    .tint(EmberColors.cream)
            } else {
                Text("\(Int(healthKitManager.totalCaloriesBurned))")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(EmberColors.cream)
                
                Text("calories burned")
                    .font(.subheadline)
                    .foregroundColor(EmberColors.cream.opacity(0.7))
                
                if !healthKitManager.workouts.isEmpty {
                    Text("\(healthKitManager.workouts.count) workout\(healthKitManager.workouts.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(EmberColors.cream.opacity(0.6))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(EmberColors.lightPlum)
        )
    }
    
    private var workoutsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's activity")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(EmberColors.cream)
                .padding(.horizontal, 4)
            
            ForEach(healthKitManager.workouts) { workout in
                WorkoutDetailRow(workout: workout)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.walk")
                .font(.system(size: 60))
                .foregroundColor(EmberColors.cream.opacity(0.5))
            
            Text("No workouts today")
                .font(.title3)
                .foregroundColor(EmberColors.cream.opacity(0.7))
            
            Text("Your workouts will appear here")
                .font(.subheadline)
                .foregroundColor(EmberColors.cream.opacity(0.5))
        }
        .padding(.top, 40)
    }
}

private extension String {
    /// Title-style capitalize while keeping Chris’s Quick Add labels / acronyms readable.
    var capitalizedWordsPreservingAcronyms: String {
        let lower = self
        if lower.localizedCaseInsensitiveContains("High intensity interval")
            || lower.localizedCaseInsensitiveContains("High intensity hit interval") {
            return "High Intensity Interval Training"
        }
        if lower.localizedCaseInsensitiveContains("Functional strength") {
            return "Functional Strength Training"
        }
        if lower.localizedCaseInsensitiveContains("Open water swim") {
            return "Open Water Swim"
        }
        return lower.split(separator: " ").map { part -> String in
            let s = String(part)
            if s.uppercased() == "HIIT" { return "HIIT" }
            return s.prefix(1).uppercased() + s.dropFirst().lowercased()
        }.joined(separator: " ")
    }
}

struct WorkoutDetailRow: View {
    let workout: WorkoutData
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Image(systemName: workout.iconName)
                    .font(.title2)
                    .foregroundColor(EmberColors.ember)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(EmberColors.dusk)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.displayName)
                        .font(.headline)
                        .foregroundColor(EmberColors.cream)
                    
                    HStack(spacing: 6) {
                        Text(workout.formattedStartTime)
                            .font(.caption)
                            .foregroundColor(EmberColors.cream.opacity(0.6))
                        if workout.isLocal {
                            Text("· Quick Add")
                                .font(.caption)
                                .foregroundColor(EmberColors.ember.opacity(0.85))
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            
            Divider()
                .background(EmberColors.cream.opacity(0.2))
            
            HStack(spacing: 0) {
                WorkoutStatItem(icon: "clock.fill", label: "Duration", value: workout.formattedDuration)
                
                Divider()
                    .background(EmberColors.cream.opacity(0.2))
                    .frame(height: 40)
                
                WorkoutStatItem(icon: "flame.fill", label: "Calories", value: "\(Int(workout.caloriesBurned)) cal")
                
                if let distance = workout.formattedDistance {
                    Divider()
                        .background(EmberColors.cream.opacity(0.2))
                        .frame(height: 40)
                    
                    WorkoutStatItem(
                        icon: workout.distanceUnit == .laps ? "water.waves" : "figure.walk",
                        label: workout.distanceUnit.statLabel,
                        value: distance
                    )
                }
            }
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(EmberColors.lightPlum)
        )
    }
}

struct WorkoutStatItem: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Spacer()
            
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(EmberColors.ember)
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(EmberColors.cream)
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(EmberColors.cream.opacity(0.7))
            }
            
            Spacer()
        }
    }
}
