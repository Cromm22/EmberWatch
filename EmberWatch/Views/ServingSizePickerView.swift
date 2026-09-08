import SwiftUI

struct ServingSizePickerView: View {
    @Binding var isPresented: Bool
    let product: FoodProduct
    let onConfirm: (FoodEntry) -> Void
    
    @State private var selectedMultiplier: Double = 1.0
    @State private var selectedGrams: Double = 0
    @State private var selectedMealType: MealType = MealType.suggested()
    
    private let multipliers: [Double] = [0.5, 1.0, 1.5, 2.0, 3.0]
    
    var body: some View {
        NavigationView {
            ZStack {
                EmberColors.dusk
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        productInfoCard
                        
                        nutritionCard
                        
                        servingSizeCard
                        
                        mealTypeCard
                    }
                    .padding()
                }
            }
            .navigationTitle("Confirm Serving")
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
                    Button("Confirm") {
                        confirmServing()
                    }
                    .foregroundColor(EmberColors.ember)
                }
            }
        }
        .presentationBackground(EmberColors.dusk)
        .onAppear {
            selectedGrams = product.servingSizeGrams ?? 100
        }
    }
    
    private var productInfoCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "barcode")
                .font(.system(size: 40))
                .foregroundColor(EmberColors.ember)
            
            Text(product.name)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(EmberColors.cream)
                .multilineTextAlignment(.center)
            
            Text(product.servingSize)
                .font(.subheadline)
                .foregroundColor(EmberColors.cream.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(EmberColors.lightPlum)
        )
    }
    
    private var nutritionCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Nutrition")
                    .font(.headline)
                    .foregroundColor(EmberColors.cream)
                
                Spacer()
                
                if let servingGrams = product.servingSizeGrams, servingGrams > 0 {
                    Text("\(Int(selectedGrams))g")
                        .font(.subheadline)
                        .foregroundColor(EmberColors.ember)
                } else {
                    Text("\(String(format: "%.1f", selectedMultiplier))× serving")
                        .font(.subheadline)
                        .foregroundColor(EmberColors.ember)
                }
            }
            
            HStack(spacing: 12) {
                NutritionValueCard(
                    label: "Calories",
                    value: Int(calculatedCalories),
                    unit: "cal",
                    color: EmberColors.ember
                )
                
                NutritionValueCard(
                    label: "Protein",
                    value: Int(calculatedProtein),
                    unit: "g",
                    color: .orange
                )
            }
            
            HStack(spacing: 12) {
                NutritionValueCard(
                    label: "Carbs",
                    value: Int(calculatedCarbs),
                    unit: "g",
                    color: .blue
                )
                
                NutritionValueCard(
                    label: "Fat",
                    value: Int(calculatedFat),
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
    }
    
    private var calculatedCalories: Double {
        if let servingGrams = product.servingSizeGrams, servingGrams > 0 {
            return (product.caloriesPer100g * selectedGrams) / 100.0
        }
        return product.caloriesPerServing * selectedMultiplier
    }
    
    private var calculatedProtein: Double {
        if let servingGrams = product.servingSizeGrams, servingGrams > 0 {
            return (product.proteinPer100g * selectedGrams) / 100.0
        }
        return product.proteinPerServing * selectedMultiplier
    }
    
    private var calculatedCarbs: Double {
        if let servingGrams = product.servingSizeGrams, servingGrams > 0 {
            return (product.carbsPer100g * selectedGrams) / 100.0
        }
        return product.carbsPerServing * selectedMultiplier
    }
    
    private var calculatedFat: Double {
        if let servingGrams = product.servingSizeGrams, servingGrams > 0 {
            return (product.fatPer100g * selectedGrams) / 100.0
        }
        return product.fatPerServing * selectedMultiplier
    }
    
    private var servingSizeCard: some View {
        VStack(spacing: 16) {
            Text("Serving Size")
                .font(.headline)
                .foregroundColor(EmberColors.cream)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if let servingGrams = product.servingSizeGrams, servingGrams > 0 {
                let gramPresets = [servingGrams * 0.5, servingGrams, servingGrams * 1.5, servingGrams * 2.0, servingGrams * 3.0]
                HStack(spacing: 12) {
                    ForEach(gramPresets, id: \.self) { grams in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedGrams = grams
                                selectedMultiplier = grams / servingGrams
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
                        selectedMultiplier = selectedGrams / servingGrams
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
                        selectedMultiplier = selectedGrams / servingGrams
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
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(EmberColors.lightPlum)
        )
    }
    
    private var mealTypeCard: some View {
        VStack(spacing: 16) {
            Text("Meal Type")
                .font(.headline)
                .foregroundColor(EmberColors.cream)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Picker("Meal Type", selection: $selectedMealType) {
                ForEach(MealType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .colorMultiply(EmberColors.ember)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(EmberColors.lightPlum)
        )
    }
    
    private func formatMultiplier(_ value: Double) -> String {
        if value == 0.5 {
            return "0.5×"
        } else if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value))×"
        } else {
            return "\(value)×"
        }
    }
    
    private func confirmServing() {
        let entry = FoodEntry(
            name: product.name,
            calories: calculatedCalories,
            protein: calculatedProtein,
            carbs: calculatedCarbs,
            fat: calculatedFat,
            mealType: selectedMealType.rawValue,
            servings: selectedMultiplier,
            caloriesPerServing: product.caloriesPerServing,
            proteinPerServing: product.proteinPerServing,
            carbsPerServing: product.carbsPerServing,
            fatPerServing: product.fatPerServing,
            servingSizeGrams: product.servingSizeGrams ?? 0
        )
        
        onConfirm(entry)
        isPresented = false
    }
}

struct NutritionValueCard: View {
    let label: String
    let value: Int
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundColor(EmberColors.cream.opacity(0.7))
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(value)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(EmberColors.cream.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(EmberColors.dusk)
        )
    }
}
