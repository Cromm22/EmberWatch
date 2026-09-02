import SwiftUI
import SwiftData

struct FoodDiaryView: View {
    @EnvironmentObject var foodDataManager: FoodDataManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var calorieGoalManager: CalorieGoalManager
    @State private var showingAddFood = false
    @State private var showingBarcodeScanner = false
    @State private var scannedProduct: FoodProduct?
    @State private var showingServingPicker = false
    @State private var showingFoodSearch = false
    
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
                        remainingCaloriesCard
                        
                        scanBarcodeButton
                        
                        searchFoodButton
                        
                        if !foodDataManager.recentFoodEntries.isEmpty {
                            recentsSection
                        }
                        
                        macrosSummaryCard
                        
                        foodEntriesList
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle("Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(EmberColors.dusk, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showingAddFood) {
                AddFoodView(isPresented: $showingAddFood)
                    .environmentObject(foodDataManager)
            }
            .sheet(isPresented: $showingBarcodeScanner) {
                BarcodeScannerView(
                    isPresented: $showingBarcodeScanner,
                    scannedProduct: $scannedProduct
                )
            }
            .sheet(isPresented: $showingFoodSearch) {
                FoodSearchView(isPresented: $showingFoodSearch)
                    .environmentObject(foodDataManager)
            }
            .sheet(isPresented: $showingServingPicker) {
                if let product = scannedProduct {
                    ServingSizePickerView(
                        isPresented: $showingServingPicker,
                        product: product,
                        onConfirm: { entry in
                            foodDataManager.addFoodEntry(entry)
                        }
                    )
                }
            }
            .onChange(of: scannedProduct) { newValue in
                if newValue != nil {
                    showingServingPicker = true
                }
            }
        }
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
            
            Text(remainingCalories >= 0 ? "remaining" : "over")
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
    
    private var scanBarcodeButton: some View {
        Button(action: { showingBarcodeScanner = true }) {
            HStack {
                Image(systemName: "barcode.viewfinder")
                    .font(.title2)
                
                Text("Scan barcode")
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
    
    private var searchFoodButton: some View {
        Button(action: { showingFoodSearch = true }) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                
                Text("Search foods")
                    .font(.headline)
            }
            .foregroundColor(EmberColors.cream)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(EmberColors.ember, lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(EmberColors.lightPlum)
                    )
            )
        }
    }
    
    private var recentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recents")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(EmberColors.cream)
                .padding(.horizontal, 4)
            
            ForEach(foodDataManager.recentFoodEntries, id: \.id) { entry in
                RecentFoodRow(entry: entry)
                    .environmentObject(foodDataManager)
            }
        }
    }
    
    private var caloriesSummaryCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "fork.knife")
                .font(.system(size: 40))
                .foregroundColor(EmberColors.ember)
            
            Text("\(Int(foodDataManager.totalCaloriesConsumed))")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundColor(EmberColors.cream)
            
            Text("cal consumed today")
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
            HStack {
                Text("Today's Meals")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(EmberColors.cream)
                
                Spacer()
                
                Button(action: { showingAddFood = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(EmberColors.ember)
                }
                .accessibilityLabel("Add food")
            }
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
            
            Text("Tap + above to add your first meal")
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
                .foregroundColor(EmberColors.ember)
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
                    .foregroundColor(EmberColors.ember)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(EmberColors.ember.opacity(0.2))
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

struct RecentFoodRow: View {
    let entry: FoodEntry
    @EnvironmentObject var foodDataManager: FoodDataManager
    
    var body: some View {
        Button(action: {
            let newEntry = FoodEntry(
                name: entry.name,
                calories: entry.calories,
                protein: entry.protein,
                carbs: entry.carbs,
                fat: entry.fat,
                mealType: entry.mealType
            )
            foodDataManager.addFoodEntry(newEntry)
        }) {
            HStack(spacing: 16) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title3)
                    .foregroundColor(EmberColors.ember)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(EmberColors.dusk)
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
                
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundColor(EmberColors.ember)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(EmberColors.lightPlum)
            )
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
                EmberColors.dusk
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
                        addFood()
                    }
                    .foregroundColor(EmberColors.ember)
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
