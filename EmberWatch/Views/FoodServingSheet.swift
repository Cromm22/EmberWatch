import SwiftUI

struct FoodServingSheet: View {
    @Binding var isPresented: Bool
    let product: FoodProduct
    let onConfirm: (FoodEntry) -> Void
    
    @StateObject private var lookupService = FoodLookupService()
    @State private var enrichedProduct: FoodProduct?
    @State private var loadingState: LoadingState = .loading
    @State private var selectedUnit: FoodAmountUnit = .grams
    @State private var selectedQuantity: Double = 100
    @State private var selectedMealType: MealType = MealType.suggested()
    
    private enum LoadingState {
        case loading
        case ready
        case error(String)
    }
    
    private var currentProduct: FoodProduct {
        enrichedProduct ?? product
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                EmberColors.dusk
                    .ignoresSafeArea()
                
                contentView
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
                
                if case .ready = loadingState {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Confirm") {
                            confirmServing()
                        }
                        .foregroundColor(EmberColors.ember)
                    }
                }
            }
        }
        .presentationBackground(EmberColors.dusk)
        .onAppear {
            applyDefaultAmount(from: currentProduct)
            if product.hasValidMacros {
                loadingState = .ready
                Task.detached(priority: .background) {
                    await enrichInBackground()
                }
            } else {
                Task {
                    await enrichFoodDetail()
                }
            }
        }
        .onChange(of: enrichedProduct) { _, newValue in
            guard let newValue else { return }
            if selectedUnit == .grams {
                let oldDefault = product.servingSizeGrams ?? 100
                if abs(selectedQuantity - oldDefault) < 1, let grams = newValue.servingSizeGrams, grams > 0 {
                    selectedQuantity = grams
                }
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch loadingState {
        case .loading:
            loadingView
        case .ready:
            readyView
        case .error(let message):
            errorView(message: message)
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(EmberColors.ember)
                .scaleEffect(1.2)
            Text("Loading food…")
                .font(.headline)
                .foregroundColor(EmberColors.cream)
            Text(product.name)
                .font(.subheadline)
                .foregroundColor(EmberColors.cream.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(EmberColors.ember.opacity(0.7))
            
            Text(message)
                .font(.headline)
                .foregroundColor(EmberColors.cream)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            HStack(spacing: 12) {
                Button("Retry") {
                    Task {
                        await enrichFoodDetail()
                    }
                }
                .fontWeight(.semibold)
                .foregroundColor(EmberColors.cream)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Capsule().fill(EmberColors.ember))
                
                Button("Dismiss") {
                    isPresented = false
                }
                .foregroundColor(EmberColors.cream.opacity(0.8))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Capsule().strokeBorder(EmberColors.cream.opacity(0.35)))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var readyView: some View {
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
    
    private var productInfoCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "barcode")
                .font(.system(size: 40))
                .foregroundColor(EmberColors.ember)
            
            Text(currentProduct.name)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(EmberColors.cream)
                .multilineTextAlignment(.center)
            
            Text(currentProduct.servingSize)
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
            servingSizeGrams: currentProduct.servingSizeGrams ?? 0,
            gramsPerCup: currentProduct.resolvedGramsPerCup
        )
    }
    
    private var amountLabel: String {
        FoodAmountMath.displayLabel(unit: selectedUnit, quantity: selectedQuantity)
    }
    
    private var calculatedCalories: Double {
        currentProduct.caloriesPerServing * amountServings
    }
    
    private var calculatedProtein: Double {
        currentProduct.proteinPerServing * amountServings
    }
    
    private var calculatedCarbs: Double {
        currentProduct.carbsPerServing * amountServings
    }
    
    private var calculatedFat: Double {
        currentProduct.fatPerServing * amountServings
    }
    
    private var calculatedSodium: Double {
        currentProduct.sodiumPerServing * amountServings
    }
    
    private var servingSizeCard: some View {
        FoodAmountPickerView(
            unit: $selectedUnit,
            quantity: $selectedQuantity,
            servingSizeGrams: currentProduct.servingSizeGrams ?? 0,
            gramsPerCup: currentProduct.resolvedGramsPerCup
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
    
    private func applyDefaultAmount(from product: FoodProduct) {
        if let grams = product.servingSizeGrams, grams > 0 {
            selectedUnit = .grams
            selectedQuantity = grams
        } else {
            selectedUnit = .servings
            selectedQuantity = 1
        }
    }
    
    private func confirmServing() {
        let cupGrams = currentProduct.resolvedGramsPerCup
        let entry = FoodEntry(
            name: currentProduct.name,
            calories: calculatedCalories,
            protein: calculatedProtein,
            carbs: calculatedCarbs,
            fat: calculatedFat,
            sodium: calculatedSodium,
            mealType: selectedMealType.rawValue,
            servings: amountServings,
            caloriesPerServing: currentProduct.caloriesPerServing,
            proteinPerServing: currentProduct.proteinPerServing,
            carbsPerServing: currentProduct.carbsPerServing,
            fatPerServing: currentProduct.fatPerServing,
            sodiumPerServing: currentProduct.sodiumPerServing,
            servingSizeGrams: currentProduct.servingSizeGrams ?? 0,
            amountUnit: selectedUnit.rawValue,
            amountQuantity: selectedQuantity,
            gramsPerCup: cupGrams
        )
        
        onConfirm(entry)
        isPresented = false
    }
    
    @MainActor
    private func enrichFoodDetail() async {
        loadingState = .loading
        
        if let enriched = await lookupService.enrichFoodDetail(product) {
            enrichedProduct = enriched
            loadingState = .ready
        } else {
            let errorMsg = lookupService.errorMessage ?? "Could not load food details"
            loadingState = .error(errorMsg)
        }
    }
    
    private func enrichInBackground() async {
        if let enriched = await lookupService.enrichFoodDetail(product) {
            await MainActor.run {
                enrichedProduct = enriched
            }
        }
    }
}
