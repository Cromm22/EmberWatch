import SwiftUI
import SwiftData
import UIKit

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
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Calories")
                    .font(.headline)
                    .foregroundColor(EmberColors.cream)
                
                Text(remainingCalories >= 0 ? "remaining" : "over")
                    .font(.subheadline)
                    .foregroundColor(EmberColors.cream.opacity(0.7))
                    .accessibilityHidden(true)
            }
            
            Spacer(minLength: 8)
            
            Text("\(Int(remainingCalories))")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(remainingCalories >= 0 ? EmberColors.ember : Color.orange)
                .accessibilityLabel("\(Int(remainingCalories)) calories \(remainingCalories >= 0 ? "remaining" : "over")")
            
            Image(systemName: remainingCalories >= 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundColor(remainingCalories >= 0 ? Color.green : Color.orange)
                .accessibilityHidden(true)
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
            
            DailyMacrosGrid(
                protein: foodDataManager.totalProtein,
                carbs: foodDataManager.totalCarbs,
                fat: foodDataManager.totalFat,
                sodium: foodDataManager.totalSodium,
                proteinTarget: calorieGoalManager.dailyProteinGoal,
                carbsTarget: calorieGoalManager.dailyCarbsGoal,
                fatTarget: calorieGoalManager.dailyFatGoal,
                sodiumTarget: calorieGoalManager.dailySodiumGoal
            )
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
                            Text("Copy Yesterday")
                                .font(.caption2)
                                .fontWeight(.medium)
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

struct DailyMacrosGrid: View {
    let protein: Double
    let carbs: Double
    let fat: Double
    let sodium: Double
    let proteinTarget: Double
    let carbsTarget: Double
    let fatTarget: Double
    let sodiumTarget: Double
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                MacroCard(
                    name: "Protein",
                    amount: Int(protein.rounded()),
                    target: Int(proteinTarget.rounded()),
                    unit: "g",
                    color: .orange,
                    icon: "flame.fill"
                )
                MacroCard(
                    name: "Carbs",
                    amount: Int(carbs.rounded()),
                    target: Int(carbsTarget.rounded()),
                    unit: "g",
                    color: .blue,
                    icon: "bolt.fill"
                )
            }
            HStack(spacing: 12) {
                MacroCard(
                    name: "Fat",
                    amount: Int(fat.rounded()),
                    target: Int(fatTarget.rounded()),
                    unit: "g",
                    color: .yellow,
                    icon: "drop.fill"
                )
                MacroCard(
                    name: "Sodium",
                    amount: Int(sodium.rounded()),
                    target: Int(sodiumTarget.rounded()),
                    unit: "mg",
                    color: .mint,
                    icon: "humidity.fill"
                )
            }
        }
    }
}

struct MacroCard: View {
    let name: String
    let amount: Int
    let target: Int
    let unit: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text("\(amount)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(EmberColors.cream)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .monospacedDigit()
            
            Text("/ \(target)\(unit)")
                .font(.caption)
                .foregroundColor(EmberColors.cream.opacity(0.7))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .monospacedDigit()
            
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name), \(amount) of \(target) \(unit)")
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
                        if entry.servingSizeGrams > 0 {
                            Text("\(Int(entry.effectiveGrams))g")
                                .font(.caption)
                                .foregroundColor(EmberColors.ember)
                        } else if entry.servings != 1.0 {
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
                sodium: entry.sodium,
                mealType: MealType.suggested().rawValue,
                servings: entry.servings,
                caloriesPerServing: entry.effectiveCaloriesPerServing,
                proteinPerServing: entry.effectiveProteinPerServing,
                carbsPerServing: entry.effectiveCarbsPerServing,
                fatPerServing: entry.effectiveFatPerServing,
                sodiumPerServing: entry.effectiveSodiumPerServing
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
                    if entry.servingSizeGrams > 0 {
                        Text("\(Int(entry.effectiveGrams))g")
                            .font(.caption2)
                            .foregroundColor(EmberColors.ember.opacity(0.85))
                    } else if entry.servings != 1.0 {
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
    @State private var selectedGrams: Double = 0
    
    private let multipliers: [Double] = [0.5, 1.0, 1.5, 2.0, 3.0]
    
    private var caloriesPerServing: Double { entry.effectiveCaloriesPerServing }
    private var proteinPerServing: Double { entry.effectiveProteinPerServing }
    private var carbsPerServing: Double { entry.effectiveCarbsPerServing }
    private var fatPerServing: Double { entry.effectiveFatPerServing }
    private var sodiumPerServing: Double { entry.effectiveSodiumPerServing }
    
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
                                
                                if entry.servingSizeGrams > 0 {
                                    Text("\(Int(selectedGrams))g")
                                        .font(.subheadline)
                                        .foregroundColor(EmberColors.ember)
                                } else {
                                    Text("\(formatMultiplier(selectedMultiplier)) serving")
                                        .font(.subheadline)
                                        .foregroundColor(EmberColors.ember)
                                }
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
                            
                            HStack(spacing: 12) {
                                NutritionValueCard(
                                    label: "Sodium",
                                    value: Int(sodiumPerServing * selectedMultiplier),
                                    unit: "mg",
                                    color: .mint
                                )
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(EmberColors.lightPlum)
                        )
                        
                        VStack(spacing: 16) {
                            Text(entry.servingSizeGrams > 0 ? "Serving Size" : "Servings")
                                .font(.headline)
                                .foregroundColor(EmberColors.cream)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            if entry.servingSizeGrams > 0 {
                                let gramPresets = [entry.servingSizeGrams * 0.5, entry.servingSizeGrams, entry.servingSizeGrams * 1.5, entry.servingSizeGrams * 2.0, entry.servingSizeGrams * 3.0]
                                HStack(spacing: 12) {
                                    ForEach(gramPresets, id: \.self) { grams in
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                selectedGrams = grams
                                                selectedMultiplier = grams / entry.servingSizeGrams
                                            }
                                        }) {
                                            Text("\(Int(grams))g")
                                                .font(.headline)
                                                .foregroundColor(abs(selectedGrams - grams) < 1.0 ? EmberColors.cream : EmberColors.cream.opacity(0.7))
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 12)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(abs(selectedGrams - grams) < 1.0 ? EmberColors.ember : EmberColors.dusk)
                                                )
                                        }
                                    }
                                }
                                
                                HStack {
                                    Text("Adjust")
                                        .foregroundColor(EmberColors.cream.opacity(0.7))
                                    Spacer()
                                    Button {
                                        selectedGrams = max(1, selectedGrams - 10)
                                        selectedMultiplier = selectedGrams / entry.servingSizeGrams
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(EmberColors.ember)
                                    }
                                    Text("\(Int(selectedGrams))g")
                                        .font(.headline)
                                        .foregroundColor(EmberColors.cream)
                                        .frame(minWidth: 60)
                                    Button {
                                        selectedGrams = min(1000, selectedGrams + 10)
                                        selectedMultiplier = selectedGrams / entry.servingSizeGrams
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(EmberColors.ember)
                                    }
                                }
                            } else {
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
                selectedGrams = entry.effectiveGrams > 0 ? entry.effectiveGrams : (entry.servingSizeGrams > 0 ? entry.servingSizeGrams : 100)
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

private enum ManualFoodVoiceField: Equatable {
    case name
    case calories
    case protein
    case carbs
    case fat
    case sodium
    case servingGrams
}

private struct ManualFoodVoiceRow: View {
    @ObservedObject var recognizer: SpeechRecognizer
    let placeholder: String
    @Binding var text: String
    let keyboard: UIKeyboardType
    let accessibilityName: String
    let isFieldListening: Bool
    let listeningCaption: String
    let onMicPress: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldRow
            if isFieldListening {
                Text(listeningCaption)
                    .font(.caption)
                    .foregroundColor(EmberColors.cream.opacity(0.6))
            }
        }
    }
    
    private var fieldRow: some View {
        HStack(spacing: 8) {
            TextField(placeholder, text: $text)
                .keyboardType(keyboard)
                .foregroundColor(EmberColors.cream)
            SpeechMicButton(
                recognizer: recognizer,
                accessibilityName: accessibilityName,
                listeningOverride: isFieldListening,
                onPress: onMicPress
            )
        }
    }
}

struct AddFoodView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var foodDataManager: FoodDataManager
    @EnvironmentObject var emberTalkManager: EmberTalkManager
    
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var voiceTarget: ManualFoodVoiceField?
    @State private var foodName = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var sodium = ""
    @State private var servingGrams = ""
    @State private var selectedMealType: MealType = MealType.suggested()
    
    var body: some View {
        NavigationView {
            ZStack {
                EmberColors.dusk
                    .ignoresSafeArea()
                
                Form {
                    foodDetailsSection
                    caloriesSection
                    macrosSection
                    servingSection
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
                        speechRecognizer.stopListening()
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
            .speechPermissionAlert(speechRecognizer)
            .onChange(of: speechRecognizer.transcript) { _, spoken in
                applyLiveTranscript(spoken)
            }
            .onChange(of: speechRecognizer.completedTranscript) { _, spoken in
                applyCompletedTranscript(spoken)
            }
            .onDisappear {
                speechRecognizer.stopListening()
            }
        }
    }
    
    private var foodDetailsSection: some View {
        Section {
            nameVoiceRow
            
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
    }
    
    private var caloriesSection: some View {
        Section {
            caloriesVoiceRow
        } header: {
            Text("Calories (required)")
        }
        .listRowBackground(EmberColors.lightPlum)
    }
    
    private var macrosSection: some View {
        Section {
            proteinVoiceRow
            carbsVoiceRow
            fatVoiceRow
            sodiumVoiceRow
        } header: {
            Text("Macros (optional)")
        }
        .listRowBackground(EmberColors.lightPlum)
    }
    
    private var servingSection: some View {
        Section {
            servingVoiceRow
        } header: {
            Text("Serving (optional)")
        }
        .listRowBackground(EmberColors.lightPlum)
    }
    
    private var nameVoiceRow: some View {
        ManualFoodVoiceRow(
            recognizer: speechRecognizer,
            placeholder: "Food Name",
            text: $foodName,
            keyboard: .default,
            accessibilityName: "Dictate food name",
            isFieldListening: isListening(to: .name),
            listeningCaption: listeningCaption,
            onMicPress: { toggleVoice(for: .name) }
        )
    }
    
    private var caloriesVoiceRow: some View {
        ManualFoodVoiceRow(
            recognizer: speechRecognizer,
            placeholder: "Calories",
            text: $calories,
            keyboard: .decimalPad,
            accessibilityName: "Dictate calories",
            isFieldListening: isListening(to: .calories),
            listeningCaption: listeningCaption,
            onMicPress: { toggleVoice(for: .calories) }
        )
    }
    
    private var proteinVoiceRow: some View {
        ManualFoodVoiceRow(
            recognizer: speechRecognizer,
            placeholder: "Protein (g)",
            text: $protein,
            keyboard: .decimalPad,
            accessibilityName: "Dictate protein",
            isFieldListening: isListening(to: .protein),
            listeningCaption: listeningCaption,
            onMicPress: { toggleVoice(for: .protein) }
        )
    }
    
    private var carbsVoiceRow: some View {
        ManualFoodVoiceRow(
            recognizer: speechRecognizer,
            placeholder: "Carbs (g)",
            text: $carbs,
            keyboard: .decimalPad,
            accessibilityName: "Dictate carbs",
            isFieldListening: isListening(to: .carbs),
            listeningCaption: listeningCaption,
            onMicPress: { toggleVoice(for: .carbs) }
        )
    }
    
    private var fatVoiceRow: some View {
        ManualFoodVoiceRow(
            recognizer: speechRecognizer,
            placeholder: "Fat (g)",
            text: $fat,
            keyboard: .decimalPad,
            accessibilityName: "Dictate fat",
            isFieldListening: isListening(to: .fat),
            listeningCaption: listeningCaption,
            onMicPress: { toggleVoice(for: .fat) }
        )
    }
    
    private var sodiumVoiceRow: some View {
        ManualFoodVoiceRow(
            recognizer: speechRecognizer,
            placeholder: "Sodium (mg)",
            text: $sodium,
            keyboard: .decimalPad,
            accessibilityName: "Dictate sodium",
            isFieldListening: isListening(to: .sodium),
            listeningCaption: listeningCaption,
            onMicPress: { toggleVoice(for: .sodium) }
        )
    }
    
    private var servingVoiceRow: some View {
        ManualFoodVoiceRow(
            recognizer: speechRecognizer,
            placeholder: "Serving (g)",
            text: $servingGrams,
            keyboard: .decimalPad,
            accessibilityName: "Dictate serving grams",
            isFieldListening: isListening(to: .servingGrams),
            listeningCaption: listeningCaption,
            onMicPress: { toggleVoice(for: .servingGrams) }
        )
    }
    
    private var listeningCaption: String {
        let spoken = speechRecognizer.transcript
        if spoken.isEmpty {
            return "Listening…"
        }
        return spoken
    }
    
    private var isValid: Bool {
        !foodName.isEmpty && Double(calories) != nil
    }
    
    private func isListening(to target: ManualFoodVoiceField) -> Bool {
        speechRecognizer.isListening && voiceTarget == target
    }
    
    private func toggleVoice(for target: ManualFoodVoiceField) {
        if speechRecognizer.isListening {
            let receiveTarget = voiceTarget
            speechRecognizer.stopListening()
            if let receiveTarget {
                applySpoken(speechRecognizer.completedTranscript, to: receiveTarget)
            }
            if receiveTarget == target {
                voiceTarget = nil
                return
            }
            // Drop the target before starting the next field so a late
            // completedTranscript onChange cannot write into the new field.
            voiceTarget = nil
            Task { @MainActor in
                self.voiceTarget = target
                await self.speechRecognizer.startListening()
            }
            return
        }
        voiceTarget = target
        Task { @MainActor in
            await speechRecognizer.startListening()
        }
    }
    
    private func applyLiveTranscript(_ spoken: String) {
        guard speechRecognizer.isListening else { return }
        guard voiceTarget == .name else { return }
        let trimmed = spoken.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return
        }
        foodName = trimmed
    }
    
    private func applyCompletedTranscript(_ spoken: String) {
        guard let target = voiceTarget else { return }
        applySpoken(spoken, to: target)
    }
    
    private func applySpoken(_ spoken: String, to target: ManualFoodVoiceField) {
        let trimmed = spoken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if target == .name {
            foodName = trimmed
            return
        }
        
        guard let value = SpokenNumberParser.parse(trimmed) else { return }
        let formatted = SpokenNumberParser.format(value)
        switch target {
        case .name:
            break
        case .calories:
            calories = formatted
        case .protein:
            protein = formatted
        case .carbs:
            carbs = formatted
        case .fat:
            fat = formatted
        case .sodium:
            sodium = formatted
        case .servingGrams:
            servingGrams = formatted
        }
    }
    
    private func addFood() {
        if speechRecognizer.isListening, let target = voiceTarget {
            speechRecognizer.stopListening()
            applySpoken(speechRecognizer.completedTranscript, to: target)
        } else {
            speechRecognizer.stopListening()
        }
        guard let caloriesValue = Double(calories) else { return }
        
        let proteinValue = Double(protein) ?? 0
        let carbsValue = Double(carbs) ?? 0
        let fatValue = Double(fat) ?? 0
        let sodiumValue = Double(sodium) ?? 0
        let servingValue = Double(servingGrams) ?? 0
        
        let entry = FoodEntry(
            name: foodName,
            calories: caloriesValue,
            protein: proteinValue,
            carbs: carbsValue,
            fat: fatValue,
            sodium: sodiumValue,
            mealType: selectedMealType.rawValue,
            servings: 1.0,
            caloriesPerServing: caloriesValue,
            proteinPerServing: proteinValue,
            carbsPerServing: carbsValue,
            fatPerServing: fatValue,
            sodiumPerServing: sodiumValue,
            servingSizeGrams: servingValue
        )
        
        foodDataManager.addFoodEntry(entry)
        emberTalkManager.showFoodPhrase()
        isPresented = false
    }
}
