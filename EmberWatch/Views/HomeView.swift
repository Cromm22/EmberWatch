import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var foodDataManager: FoodDataManager
    @EnvironmentObject var calorieGoalManager: CalorieGoalManager
    @State private var showingGoalSettings = false
    
    var remainingCalories: Double {
        calorieGoalManager.calculateRemainingCalories(
            burned: healthKitManager.totalCaloriesBurned,
            consumed: foodDataManager.totalCaloriesConsumed
        )
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                EmberColors.darkPlum
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        emberAvatarCard
                        
                        remainingCaloriesCard
                        
                        dailySummaryCard
                        
                        quickStatsCard
                    }
                    .padding()
                }
            }
            .navigationTitle("Ember")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(EmberColors.darkPlum, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingGoalSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(EmberColors.cream)
                    }
                }
            }
            .sheet(isPresented: $showingGoalSettings) {
                GoalSettingsView(isPresented: $showingGoalSettings)
                    .environmentObject(calorieGoalManager)
            }
            .onAppear {
                healthKitManager.fetchTodayWorkouts()
                foodDataManager.fetchTodayEntries()
            }
            .refreshable {
                healthKitManager.fetchTodayWorkouts()
                foodDataManager.fetchTodayEntries()
            }
        }
    }
    
    private var emberAvatarCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                EmberColors.ember.opacity(0.55),
                                EmberColors.ember.opacity(0.18),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 110
                        )
                    )
                    .frame(width: 200, height: 200)
                
                Circle()
                    .stroke(EmberColors.ember.opacity(0.35), lineWidth: 2)
                    .frame(width: 148, height: 148)
                
                Image("AvatarSprout")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 168, height: 168)
                    .shadow(color: EmberColors.ember.opacity(0.45), radius: 16, y: 6)
                    .accessibilityLabel("Sprout avatar")
            }
            .padding(.top, 8)
            
            Text("Sprout")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(EmberColors.cream)
            
            Text("Your Ember")
                .font(.subheadline)
                .foregroundColor(EmberColors.cream.opacity(0.75))
            
            Text("Level \(calorieGoalManager.currentLevel)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(EmberColors.cream)
            
            VStack(spacing: 8) {
                HStack {
                    Text("XP: \(calorieGoalManager.currentXP) / \(calorieGoalManager.xpForNextLevel())")
                        .font(.caption)
                        .foregroundColor(EmberColors.cream.opacity(0.7))
                    
                    Spacer()
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(EmberColors.darkPlum)
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [EmberColors.flame, Color.orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * calorieGoalManager.xpProgress(), height: 8)
                    }
                }
                .frame(height: 8)
            }
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
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
                
                Text("Remaining Calories")
                    .font(.headline)
                    .foregroundColor(EmberColors.cream)
                
                Spacer()
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(Int(remainingCalories))")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(remainingCalories >= 0 ? EmberColors.flame : Color.orange)
                
                Text("cal")
                    .font(.title3)
                    .foregroundColor(EmberColors.cream.opacity(0.7))
                
                Spacer()
            }
            
            Text(remainingCalories >= 0 ? "You're on track!" : "You're over your goal")
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
                .foregroundColor(EmberColors.flame)
            
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
    
    var body: some View {
        NavigationView {
            ZStack {
                EmberColors.darkPlum
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("Daily Calorie Goal")
                            .font(.headline)
                            .foregroundColor(EmberColors.cream)
                        
                        TextField("Enter goal", text: $goalInput)
                            .keyboardType(.numberPad)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(EmberColors.flame)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(EmberColors.lightPlum)
                            )
                    }
                    .padding()
                    
                    Text("This is your base calorie budget. Exercise adds to this amount, and food subtracts from it.")
                        .font(.subheadline)
                        .foregroundColor(EmberColors.cream.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(EmberColors.darkPlum, for: .navigationBar)
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
                    .foregroundColor(EmberColors.flame)
                }
            }
            .onAppear {
                goalInput = String(Int(calorieGoalManager.dailyCalorieGoal))
            }
        }
    }
}
