import SwiftUI

struct ServingSizePickerView: View {
    @Binding var isPresented: Bool
    let product: FoodProduct
    let onConfirm: (FoodEntry) -> Void
    
    @State private var selectedMultiplier: Double = 1.0
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
                    Button("Confirm") {
                        confirmServing()
                    }
                    .foregroundColor(EmberColors.ember)
                }
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
                
                Text("\(String(format: "%.1f", selectedMultiplier))× serving")
                    .font(.subheadline)
                    .foregroundColor(EmberColors.ember)
            }
            
            HStack(spacing: 12) {
                NutritionValueCard(
                    label: "Calories",
                    value: Int(product.caloriesPerServing * selectedMultiplier),
                    unit: "cal",
                    color: EmberColors.ember
                )
                
                NutritionValueCard(
                    label: "Protein",
                    value: Int(product.proteinPerServing * selectedMultiplier),
                    unit: "g",
                    color: .orange
                )
            }
            
            HStack(spacing: 12) {
                NutritionValueCard(
                    label: "Carbs",
                    value: Int(product.carbsPerServing * selectedMultiplier),
                    unit: "g",
                    color: .blue
                )
                
                NutritionValueCard(
                    label: "Fat",
                    value: Int(product.fatPerServing * selectedMultiplier),
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
    
    private var servingSizeCard: some View {
        VStack(spacing: 16) {
            Text("Serving Size")
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
            calories: product.caloriesPerServing * selectedMultiplier,
            protein: product.proteinPerServing * selectedMultiplier,
            carbs: product.carbsPerServing * selectedMultiplier,
            fat: product.fatPerServing * selectedMultiplier,
            mealType: selectedMealType.rawValue,
            servings: selectedMultiplier,
            caloriesPerServing: product.caloriesPerServing,
            proteinPerServing: product.proteinPerServing,
            carbsPerServing: product.carbsPerServing,
            fatPerServing: product.fatPerServing
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
