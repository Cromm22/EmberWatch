import SwiftUI

struct ServingSizePickerView: View {
    @Binding var isPresented: Bool
    let product: FoodProduct
    let onConfirm: (FoodEntry) -> Void
    
    @State private var selectedUnit: FoodAmountUnit = .grams
    @State private var selectedQuantity: Double = 100
    @State private var selectedMealType: MealType = MealType.suggested()
    
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
            if let grams = product.servingSizeGrams, grams > 0 {
                selectedUnit = .grams
                selectedQuantity = grams
            } else {
                selectedUnit = .servings
                selectedQuantity = 1
            }
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
                
                Text(amountLabel)
                    .font(.subheadline)
                    .foregroundColor(EmberColors.ember)
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
            
            HStack(spacing: 12) {
                NutritionValueCard(
                    label: "Sodium",
                    value: Int(calculatedSodium),
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
    }
    
    private var amountServings: Double {
        FoodAmountMath.servingsMultiplier(
            unit: selectedUnit,
            quantity: selectedQuantity,
            servingSizeGrams: product.servingSizeGrams ?? 0,
            gramsPerCup: product.resolvedGramsPerCup
        )
    }
    
    private var amountLabel: String {
        FoodAmountMath.displayLabel(unit: selectedUnit, quantity: selectedQuantity)
    }
    
    private var calculatedCalories: Double {
        product.caloriesPerServing * amountServings
    }
    
    private var calculatedProtein: Double {
        product.proteinPerServing * amountServings
    }
    
    private var calculatedCarbs: Double {
        product.carbsPerServing * amountServings
    }
    
    private var calculatedFat: Double {
        product.fatPerServing * amountServings
    }
    
    private var calculatedSodium: Double {
        product.sodiumPerServing * amountServings
    }
    
    private var servingSizeCard: some View {
        FoodAmountPickerView(
            unit: $selectedUnit,
            quantity: $selectedQuantity,
            servingSizeGrams: product.servingSizeGrams ?? 0,
            gramsPerCup: product.resolvedGramsPerCup
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
    
    private func confirmServing() {
        let cupGrams = product.resolvedGramsPerCup
        let entry = FoodEntry(
            name: product.name,
            calories: calculatedCalories,
            protein: calculatedProtein,
            carbs: calculatedCarbs,
            fat: calculatedFat,
            sodium: calculatedSodium,
            mealType: selectedMealType.rawValue,
            servings: amountServings,
            caloriesPerServing: product.caloriesPerServing,
            proteinPerServing: product.proteinPerServing,
            carbsPerServing: product.carbsPerServing,
            fatPerServing: product.fatPerServing,
            sodiumPerServing: product.sodiumPerServing,
            servingSizeGrams: product.servingSizeGrams ?? 0,
            amountUnit: selectedUnit.rawValue,
            amountQuantity: selectedQuantity,
            gramsPerCup: cupGrams
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
