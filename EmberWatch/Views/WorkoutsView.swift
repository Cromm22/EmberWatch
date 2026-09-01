import SwiftUI

struct WorkoutsView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    var body: some View {
        NavigationView {
            ZStack {
                EmberColors.darkPlum
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        caloriesSummaryCard
                        
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
            .toolbarBackground(EmberColors.darkPlum, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                healthKitManager.fetchTodayWorkouts()
            }
            .refreshable {
                healthKitManager.fetchTodayWorkouts()
            }
        }
    }
    
    private var caloriesSummaryCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.system(size: 40))
                .foregroundColor(EmberColors.flame)
            
            if healthKitManager.isLoading {
                ProgressView()
                    .tint(EmberColors.cream)
            } else {
                Text("\(Int(healthKitManager.totalCaloriesBurned))")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(EmberColors.cream)
                
                Text("calories burned today")
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
                    .foregroundColor(EmberColors.flame)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(EmberColors.darkPlum)
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
                    .foregroundColor(EmberColors.flame)
                
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
