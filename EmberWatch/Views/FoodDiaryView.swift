import SwiftUI
import SwiftData

struct FoodDiaryView: View {
    @EnvironmentObject var foodDataManager: FoodDataManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var calorieGoalManager: CalorieGoalManager
    @EnvironmentObject var emberTalkManager: EmberTalkManager
    @State private var showingAddFood = false
    @State private var showingBarcodeScanner = false
    @State private var scannedProduct: FoodProduct?
    @State private var showingFoodSearch = false
    @State private var entryToEdit: FoodEntry?
    @State private var copyToastMessage: String?
    
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
                
                List {
                    Section {
                        remainingCaloriesCard
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    
                    Section {
                        scanBarcodeButton
                        searchFoodButton
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    
                    Section {
                        macrosSummaryCard
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    
                    if !foodDataManager.recentFoodEntries.isEmpty {
                        Section {
                            ScrollView {
                                VStack(spacing: 8) {
                                    ForEach(foodDataManager.recentFoodEntries, id: \.id) { entry in
                                        RecentFoodRow(entry: entry)
                                            .environmentObject(foodDataManager)
                                            .environmentObject(emberTalkManager)
                                    }
                                }
                            }
                            .frame(height: 184)
                        } header: {
                            Text("Recents")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(EmberColors.cream.opacity(0.85))
                                .textCase(nil)
                        }
                        .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    
                    ForEach(MealType.allCases) { meal in
                        mealTypeSection(for: meal)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(EmberColors.dusk, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddFood = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(EmberColors.ember)
                    }
                    .accessibilityLabel("Add food")
                }
            }
            .sheet(isPresented: $showingAddFood) {
                AddFoodView(isPresented: $showingAddFood)
                    .environmentObject(foodDataManager)
                    .environmentObject(emberTalkManager)
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
                    .environmentObject(emberTalkManager)
            }
            .sheet(item: $scannedProduct) { product in
                FoodServingSheet(
                    isPresented: Binding(
                        get: { scannedProduct != nil },
                        set: { if !$0 { scannedProduct = nil } }
                    ),
                    product: product,
                    onConfirm: { entry in
                        foodDataManager.addFoodEntry(entry)
                        emberTalkManager.showFoodPhrase()
                        scannedProduct = nil
                    }
                )
            }
            .sheet(isPresented: Binding(
                get: { entryToEdit != nil },
                set: { if !$0 { entryToEdit = nil } }
            )) {
                if let entry = entryToEdit {
                    EditServingsView(entry: entry, isPresentedEntry: $entryToEdit)
                        .environmentObject(foodDataManager)
                }
            }
            .overlay(alignment: .bottom) {
                if let copyToastMessage {
                    Text(copyToastMessage)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(EmberColors.cream)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(EmberColors.dusk2.opacity(0.95))
                                .overlay(
                                    Capsule()
                                        .strokeBorder(EmberColors.ember.opacity(0.45), lineWidth: 1)
                                )
                        )
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .allowsHitTesting(false)
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
    
    private func mealTypeSection(for meal: MealType) -> some View {
        let items = foodDataManager.entries(forMealType: meal)
        return Section {
            if items.isEmpty {
                Text("Nothing logged")
                    .font(.caption)
                    .foregroundColor(EmberColors.cream.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(items, id: \.id) { entry in
                    FoodEntryRow(entry: entry) {
                        entryToEdit = entry
                    }
                    .environmentObject(foodDataManager)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            foodDataManager.deleteFoodEntry(entry)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(Color(red: 0.86, green: 0.22, blue: 0.27))
                    }
                }
            }
        } header: {
            HStack(spacing: 8) {
                Image(systemName: meal.icon)
                    .font(.subheadline)
                    .foregroundColor(EmberColors.ember)
                Text(meal.sectionTitle)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(EmberColors.cream)
                    .textCase(nil)
                Spacer()
                if !items.isEmpty {
                    Text("\(Int(items.reduce(0) { $0 + $1.calories })) cal")
                        .font(.caption)
                        .foregroundColor(EmberColors.cream.opacity(0.55))
                }
                if meal != .snack {
                    Button {
                        copyMealFromYesterday(meal)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.doc")
                                .font(.caption2)
                            Text("Copy")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(EmberColors.ember)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(EmberColors.dusk)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Copy yesterday's \(meal.rawValue)")
                }
            }
        }
    }
    
    private func copyMealFromYesterday(_ meal: MealType) {
        let count = foodDataManager.copyYesterdayMeal(toToday: meal)
        let message = count == 0 ? "Nothing to copy" : "Copied \(count) item\(count == 1 ? "" : "s")"
        withAnimation(.easeInOut(duration: 0.2)) {
            copyToastMessage = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeInOut(duration: 0.25)) {
                if copyToastMessage == message {
                    copyToastMessage = nil
                }
            }
        }
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
    var onTap: (() -> Void)? = nil
    @EnvironmentObject var foodDataManager: FoodDataManager
    
    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 16) {
                Image(systemName: mealTypeIcon)
                    .font(.title2)
                    .foregroundColor(EmberColors.ember)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(EmberColors.dusk)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.name)
                        .font(.headline)
                        .foregroundColor(EmberColors.cream)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 12) {
                        Label("\(Int(entry.calories)) cal", systemImage: "flame.fill")
                        if entry.servings != 1.0 {
                            Text(formatServings(entry.servings))
                                .font(.caption)
                                .foregroundColor(EmberColors.ember)
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(EmberColors.cream.opacity(0.7))
                }
                
                Spacer(minLength: 8)
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(entry.timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(EmberColors.cream.opacity(0.6))
                    
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(EmberColors.cream.opacity(0.35))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(EmberColors.lightPlum)
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint("Tap to edit servings. Swipe left to delete.")
    }
    
    private func formatServings(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value))× serv"
        }
        return String(format: "%.1f× serv", value)
    }
    
    private var mealTypeIcon: String {
        MealType(rawValue: entry.resolvedMealType)?.icon ?? "fork.knife"
    }
}

struct RecentFoodRow: View {
    let entry: FoodEntry
    @EnvironmentObject var foodDataManager: FoodDataManager
    @EnvironmentObject var emberTalkManager: EmberTalkManager
    
    var body: some View {
        Button(action: {
            let newEntry = FoodEntry(
                name: entry.name,
                calories: entry.calories,
                protein: entry.protein,
                carbs: entry.carbs,
                fat: entry.fat,
                mealType: MealType.suggested().rawValue,
                servings: entry.servings,
                caloriesPerServing: entry.effectiveCaloriesPerServing,
                proteinPerServing: entry.effectiveProteinPerServing,
                carbsPerServing: entry.effectiveCarbsPerServing,
                fatPerServing: entry.effectiveFatPerServing
            )
            foodDataManager.addFoodEntry(newEntry)
            emberTalkManager.showFoodPhrase()
        }) {
            HStack(spacing: 10) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.caption)
                    .foregroundColor(EmberColors.ember)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(EmberColors.dusk)
                    )
                
                Text(entry.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(EmberColors.cream)
                    .lineLimit(1)
                
                Spacer(minLength: 4)
                
                HStack(spacing: 6) {
                    Text("\(Int(entry.calories)) cal")
                        .font(.caption)
                        .foregroundColor(EmberColors.cream.opacity(0.7))
                    if entry.servings != 1.0 {
                        Text(formatRecentServings(entry.servings))
                            .font(.caption2)
                            .foregroundColor(EmberColors.ember.opacity(0.85))
                    }
                    Image(systemName: "plus.circle.fill")
                        .font(.body)
                        .foregroundColor(EmberColors.ember)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(EmberColors.lightPlum)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add \(entry.name), \(Int(entry.calories)) calories")
    }
    
    private func formatRecentServings(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value))×"
        }
        return String(format: "%.1f×", value)
    }
}

struct EditServingsView: View {
    let entry: FoodEntry
    @Binding var isPresentedEntry: FoodEntry?
    @EnvironmentObject var foodDataManager: FoodDataManager
    
    @State private var selectedMultiplier: Double = 1.0
    
    private let multipliers: [Double] = [0.5, 1.0, 1.5, 2.0, 3.0]
    
    private var caloriesPerServing: Double { entry.effectiveCaloriesPerServing }
    private var proteinPerServing: Double { entry.effectiveProteinPerServing }
    private var carbsPerServing: Double { entry.effectiveCarbsPerServing }
    private var fatPerServing: Double { entry.effectiveFatPerServing }
    
    var body: some View {
        NavigationView {
            ZStack {
                EmberColors.dusk
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 12) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 40))
                                .foregroundColor(EmberColors.ember)
                            
                            Text(entry.name)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(EmberColors.cream)
                                .multilineTextAlignment(.center)
                            
                            Text(entry.resolvedMealType)
                                .font(.subheadline)
                                .foregroundColor(EmberColors.cream.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(EmberColors.lightPlum)
                        )
                        
                        VStack(spacing: 16) {
                            HStack {
                                Text("Nutrition")
                                    .font(.headline)
                                    .foregroundColor(EmberColors.cream)
                                
                                Spacer()
                                
                                Text("\(formatMultiplier(selectedMultiplier)) serving")
                                    .font(.subheadline)
                                    .foregroundColor(EmberColors.ember)
                            }
                            
                            HStack(spacing: 12) {
                                NutritionValueCard(
                                    label: "Calories",
                                    value: Int(caloriesPerServing * selectedMultiplier),
                                    unit: "cal",
                                    color: EmberColors.ember
                                )
                                
                                NutritionValueCard(
                                    label: "Protein",
                                    value: Int(proteinPerServing * selectedMultiplier),
                                    unit: "g",
                                    color: .orange
                                )
                            }
                            
                            HStack(spacing: 12) {
                                NutritionValueCard(
                                    label: "Carbs",
                                    value: Int(carbsPerServing * selectedMultiplier),
                                    unit: "g",
                                    color: .blue
                                )
                                
                                NutritionValueCard(
                                    label: "Fat",
                                    value: Int(fatPerServing * selectedMultiplier),
                                    unit: "g",
                                    color: .yellow
                                )
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(EmberColors.lightPlum)
                        )
                        
                        VStack(spacing: 16) {
                            Text("Servings")
                                .font(.headline)
                                .foregroundColor(EmberColors.cream)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 12) {
                                ForEach(multipliers, id: \.self) { multiplier in
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedMultiplier = multiplier
                                        }
                                    }) {
                                        Text(formatMultiplier(multiplier))
                                            .font(.headline)
                                            .foregroundColor(selectedMultiplier == multiplier ? EmberColors.cream : EmberColors.cream.opacity(0.7))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(selectedMultiplier == multiplier ? EmberColors.ember : EmberColors.dusk)
                                            )
                                    }
                                }
                            }
                            
                            // Fine-tune stepper for values outside presets
                            HStack {
                                Text("Adjust")
                                    .foregroundColor(EmberColors.cream.opacity(0.7))
                                Spacer()
                                Button {
                                    selectedMultiplier = max(0.25, (selectedMultiplier * 4).rounded() / 4 - 0.25)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(EmberColors.ember)
                                }
                                Text(String(format: "%.2g×", selectedMultiplier))
                                    .font(.headline)
                                    .foregroundColor(EmberColors.cream)
                                    .frame(minWidth: 48)
                                Button {
                                    selectedMultiplier = min(10, (selectedMultiplier * 4).rounded() / 4 + 0.25)
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(EmberColors.ember)
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(EmberColors.lightPlum)
                        )
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Servings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(EmberColors.dusk, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresentedEntry = nil
                    }
                    .foregroundColor(EmberColors.cream)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        entry.applyServings(selectedMultiplier)
                        foodDataManager.updateFoodEntry(entry)
                        isPresentedEntry = nil
                    }
                    .foregroundColor(EmberColors.ember)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                selectedMultiplier = entry.servings > 0 ? entry.servings : 1.0
            }
        }
    }
    
    private func formatMultiplier(_ value: Double) -> String {
        if value == 0.5 {
            return "0.5×"
        } else if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value))×"
        } else {
            return String(format: "%.2g×", value)
        }
    }
}

struct AddFoodView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var foodDataManager: FoodDataManager
    @EnvironmentObject var emberTalkManager: EmberTalkManager
    
    @State private var foodName = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var selectedMealType: MealType = MealType.suggested()
    
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
        
        let proteinValue = Double(protein) ?? 0
        let carbsValue = Double(carbs) ?? 0
        let fatValue = Double(fat) ?? 0
        
        let entry = FoodEntry(
            name: foodName,
            calories: caloriesValue,
            protein: proteinValue,
            carbs: carbsValue,
            fat: fatValue,
            mealType: selectedMealType.rawValue,
            servings: 1.0,
            caloriesPerServing: caloriesValue,
            proteinPerServing: proteinValue,
            carbsPerServing: carbsValue,
            fatPerServing: fatValue
        )
        
        foodDataManager.addFoodEntry(entry)
        emberTalkManager.showFoodPhrase()
        isPresented = false
    }
}
