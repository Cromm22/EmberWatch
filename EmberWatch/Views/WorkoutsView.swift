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

struct WorkoutsView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var showingQuickAdd = false
    @State private var flamePulse = false
    
    private var flamePhase: WorkoutFlamePhase {
        WorkoutFlamePhase(calories: healthKitManager.totalCaloriesBurned)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                EmberColors.dusk
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        caloriesSummaryCard
                        
                        quickAddButtons
                        
                        if healthKitManager.workouts.isEmpty && !healthKitManager.isLoading {
                            emptyStateView
                        } else {
                            workoutsList
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(EmberColors.dusk, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showingQuickAdd) {
                QuickAddWorkoutView(isPresented: $showingQuickAdd)
                    .environmentObject(healthKitManager)
            }
            .onAppear {
                healthKitManager.fetchTodayWorkouts()
                updateFlamePulse()
            }
            .onChange(of: healthKitManager.totalCaloriesBurned) { _, _ in
                updateFlamePulse()
            }
            .refreshable {
                healthKitManager.fetchTodayWorkouts()
            }
        }
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
    
    private var quickAddButtons: some View {
        VStack(spacing: 12) {
            Text("Quick Add")
                .font(.headline)
                .foregroundColor(EmberColors.cream)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
            
            Button(action: { showingQuickAdd = true }) {
                HStack {
                    Image(systemName: "bolt.circle.fill")
                        .font(.title2)
                    
                    Text("Log Workout")
                        .font(.headline)
                }
                .foregroundColor(EmberColors.cream)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(EmberColors.ember)
                )
            }
        }
    }
    
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
            Text("Today's Activity")
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
                    
                    Text(workout.formattedStartTime)
                        .font(.caption)
                        .foregroundColor(EmberColors.cream.opacity(0.6))
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
                
                WorkoutStatItem(icon: "flame.fill", label: "Calories", value: "\(Int(workout.caloriesBurned))")
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

struct QuickAddWorkoutView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    private let workoutTypes: [(name: String, type: HKWorkoutActivityType, icon: String)] = [
        ("Outdoor walk", .walking, "figure.walk"),
        ("Indoor walk", .walking, "figure.walk"),
        ("Functional strength training", .functionalStrengthTraining, "dumbbell.fill"),
        ("Pool swim", .swimming, "figure.pool.swim"),
        ("High Intensity Interval training", .highIntensityIntervalTraining, "bolt.fill"),
        ("Outdoor cycle", .cycling, "bicycle")
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                EmberColors.dusk
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(workoutTypes, id: \.name) { workout in
                            Button(action: {
                                selectWorkout(workout.type)
                            }) {
                                HStack(spacing: 16) {
                                    Image(systemName: workout.icon)
                                        .font(.title2)
                                        .foregroundColor(EmberColors.ember)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            Circle()
                                                .fill(EmberColors.dusk)
                                        )
                                    
                                    Text(workout.name)
                                        .font(.headline)
                                        .foregroundColor(EmberColors.cream)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.subheadline)
                                        .foregroundColor(EmberColors.cream.opacity(0.5))
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(EmberColors.lightPlum)
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Quick Add")
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
            }
        }
    }
    
    private func selectWorkout(_ type: HKWorkoutActivityType) {
        isPresented = false
    }
}

struct ManualWorkoutView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    @State private var workoutName = ""
    @State private var duration = ""
    @State private var calories = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                EmberColors.dusk
                    .ignoresSafeArea()
                
                Form {
                    Section {
                        TextField("Workout Name", text: $workoutName)
                            .foregroundColor(EmberColors.cream)
                    } header: {
                        Text("Details")
                    }
                    .listRowBackground(EmberColors.lightPlum)
                    
                    Section {
                        TextField("Duration (minutes)", text: $duration)
                            .keyboardType(.numberPad)
                            .foregroundColor(EmberColors.cream)
                        
                        TextField("Calories Burned", text: $calories)
                            .keyboardType(.numberPad)
                            .foregroundColor(EmberColors.cream)
                    } header: {
                        Text("Metrics")
                    }
                    .listRowBackground(EmberColors.lightPlum)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Log Workout")
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
                    Button("Add") {
                        addWorkout()
                    }
                    .foregroundColor(EmberColors.ember)
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        !workoutName.isEmpty && Double(calories) != nil
    }
    
    private func addWorkout() {
        isPresented = false
    }
}
