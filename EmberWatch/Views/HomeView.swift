import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var foodDataManager: FoodDataManager
    @EnvironmentObject var calorieGoalManager: CalorieGoalManager
    @EnvironmentObject var waterManager: WaterManager
    @EnvironmentObject var avatarManager: AvatarManager
    @State private var showingGoalSettings = false
    @State private var showingAvatarPicker = false
    
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
                    VStack(spacing: 24) {
                        emberAvatarCard
                        
                        remainingCaloriesCard
                        
                        waterCard
                        
                        dailySummaryCard
                        
                        quickStatsCard
                    }
                    .padding()
                }
            }
            .navigationTitle("Ember")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(EmberColors.dusk, for: .navigationBar)
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
            .sheet(isPresented: $showingAvatarPicker) {
                AvatarPickerView()
                    .environmentObject(avatarManager)
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
            ZStack(alignment: .topTrailing) {
                EmberFlameAvatar(
                    level: calorieGoalManager.currentLevel,
                    size: 220,
                    style: avatarManager.selectedStyle
                )
                .onTapGesture {
                    showingAvatarPicker = true
                }
                
                Button(action: { showingAvatarPicker = true }) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(EmberColors.ember)
                        .background(
                            Circle()
                                .fill(EmberColors.dusk)
                                .frame(width: 34, height: 34)
                        )
                        .shadow(color: EmberColors.ember.opacity(0.3), radius: 8)
                }
                .padding(.top, 8)
                .padding(.trailing, 16)
            }
            
            Text("Your Ember")
                .font(.headline)
                .foregroundColor(EmberColors.cream.opacity(0.9))
            
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
                                    colors: [EmberColors.ember, Color.orange],
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
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(EmberColors.lightPlum)
        )
    }
    
    private var waterCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "drop.fill")
                    .foregroundColor(EmberColors.ember)
                
                Text("Stay Hydrated")
                    .font(.headline)
                    .foregroundColor(EmberColors.cream)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(waterManager.totalOz)) fl oz")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(EmberColors.cream)
                    
                    Text("\(waterManager.totalMl) mL")
                        .font(.caption)
                        .foregroundColor(EmberColors.cream.opacity(0.7))
                }
            }
            
            HStack(spacing: 8) {
                ForEach(0..<8, id: \.self) { index in
                    WaterGlassView(
                        isFilled: index < waterManager.glassesLogged,
                        onTap: {
                            if index < waterManager.glassesLogged {
                                waterManager.removeGlass()
                            } else if index == waterManager.glassesLogged {
                                waterManager.logGlass()
                            }
                        }
                    )
                }
            }
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
