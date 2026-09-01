import SwiftUI
import SwiftData

struct FoodDiaryView: View {
    @EnvironmentObject var foodDataManager: FoodDataManager
    @State private var showingAddFood = false
    
    var body: some View {
        NavigationView {
            ZStack {
                EmberColors.darkPlum
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        caloriesSummaryCard
                        
                        macrosSummaryCard
                        
                        foodEntriesList
                    }
                    .padding()
                }
            }
            .navigationTitle("Food Diary")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(EmberColors.darkPlum, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddFood = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(EmberColors.flame)
                    }
                }
            }
            .sheet(isPresented: $showingAddFood) {
                AddFoodView(isPresented: $showingAddFood)
                    .environmentObject(foodDataManager)
            }
        }
    }
    
    private var caloriesSummaryCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "fork.knife")
                .font(.system(size: 40))
                .foregroundColor(EmberColors.flame)
            
            Text("\(Int(foodDataManager.totalCaloriesConsumed))")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundColor(EmberColors.cream)
            
            Text("calories consumed today")
                .font(.subheadline)
                .foregroundColor(EmberColors.cream.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(EmberColors.lightPlum)
        )
    }
    
    private var macrosSummaryCard: some View {
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
    
    private var foodEntriesList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Meals")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(EmberColors.cream)
                .padding(.horizontal, 4)
            
            if foodDataManager.todayFoodEntries.isEmpty {
                emptyStateView
            } else {
                ForEach(foodDataManager.todayFoodEntries, id: \.id) { entry in
                    FoodEntryRow(entry: entry)
                        .environmentObject(foodDataManager)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 60))
                .foregroundColor(EmberColors.cream.opacity(0.5))
            
            Text("No meals logged today")
                .font(.title3)
                .foregroundColor(EmberColors.cream.opacity(0.7))
            
            Text("Tap + to add your first meal")
                .font(.subheadline)
                .foregroundColor(EmberColors.cream.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}

struct MacroCard: View {
    let name: String
    let amount: Int
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text("\(amount)g")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(EmberColors.cream)
            
            Text(name)
                .font(.caption)
                .foregroundColor(EmberColors.cream.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(EmberColors.darkPlum)
        )
    }
}

struct FoodEntryRow: View {
    let entry: FoodEntry
    @EnvironmentObject var foodDataManager: FoodDataManager
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: mealTypeIcon)
                .font(.title2)
                .foregroundColor(EmberColors.flame)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(EmberColors.lightPlum)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.name)
                    .font(.headline)
                    .foregroundColor(EmberColors.cream)
                
                HStack(spacing: 16) {
                    Label("\(Int(entry.calories)) cal", systemImage: "flame.fill")
                    if entry.protein > 0 || entry.carbs > 0 || entry.fat > 0 {
                        Label("P:\(Int(entry.protein)) C:\(Int(entry.carbs)) F:\(Int(entry.fat))", systemImage: "chart.bar.fill")
                    }
                }
                .font(.subheadline)
                .foregroundColor(EmberColors.cream.opacity(0.7))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(entry.mealType)
                    .font(.caption)
                    .foregroundColor(EmberColors.flame)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(EmberColors.flame.opacity(0.2))
                    )
                
                Text(entry.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(EmberColors.cream.opacity(0.6))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(EmberColors.lightPlum)
        )
        .contextMenu {
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Delete Entry", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                foodDataManager.deleteFoodEntry(entry)
            }
        } message: {
            Text("Are you sure you want to delete this food entry?")
        }
    }
    
    private var mealTypeIcon: String {
        switch entry.mealType {
        case "Breakfast":
            return "sunrise.fill"
        case "Lunch":
            return "sun.max.fill"
        case "Dinner":
            return "moon.stars.fill"
        case "Snack":
            return "cup.and.saucer.fill"
        default:
            return "fork.knife"
        }
    }
}

struct AddFoodView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var foodDataManager: FoodDataManager
    
    @State private var foodName = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var selectedMealType: MealType = .snack
    
    var body: some View {
        NavigationView {
            ZStack {
                EmberColors.darkPlum
                    .ignoresSafeArea()
                
                Form {
                    Section {
                        TextField("Food Name", text: $foodName)
                            .foregroundColor(EmberColors.cream)
                        
                        Picker("Meal Type", selection: $selectedMealType) {
                            ForEach(MealType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .foregroundColor(EmberColors.cream)
                    } header: {
                        Text("Food Details")
                    }
                    .listRowBackground(EmberColors.lightPlum)
                    
                    Section {
                        TextField("Calories", text: $calories)
                            .keyboardType(.decimalPad)
                            .foregroundColor(EmberColors.cream)
                    } header: {
                        Text("Calories (required)")
                    }
                    .listRowBackground(EmberColors.lightPlum)
                    
                    Section {
                        TextField("Protein (g)", text: $protein)
                            .keyboardType(.decimalPad)
                            .foregroundColor(EmberColors.cream)
                        
                        TextField("Carbs (g)", text: $carbs)
                            .keyboardType(.decimalPad)
                            .foregroundColor(EmberColors.cream)
                        
                        TextField("Fat (g)", text: $fat)
                            .keyboardType(.decimalPad)
                            .foregroundColor(EmberColors.cream)
                    } header: {
                        Text("Macros (optional)")
                    }
                    .listRowBackground(EmberColors.lightPlum)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add Food")
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
                    Button("Add") {
                        addFood()
                    }
                    .foregroundColor(EmberColors.flame)
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        !foodName.isEmpty && Double(calories) != nil
    }
    
    private func addFood() {
        guard let caloriesValue = Double(calories) else { return }
        
        let entry = FoodEntry(
            name: foodName,
            calories: caloriesValue,
            protein: Double(protein) ?? 0,
            carbs: Double(carbs) ?? 0,
            fat: Double(fat) ?? 0,
            mealType: selectedMealType.rawValue
        )
        
        foodDataManager.addFoodEntry(entry)
        isPresented = false
    }
}
