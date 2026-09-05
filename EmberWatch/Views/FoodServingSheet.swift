import SwiftUI

struct FoodServingSheet: View {
    @Binding var isPresented: Bool
    let product: FoodProduct
    let onConfirm: (FoodEntry) -> Void
    
    @StateObject private var lookupService = FoodLookupService()
    @State private var enrichedProduct: FoodProduct?
    @State private var loadingState: LoadingState = .loading
    @State private var selectedMultiplier: Double = 1.0
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
                
                Text("\(String(format: "%.1f", selectedMultiplier))× serving")
                    .font(.subheadline)
                    .foregroundColor(EmberColors.ember)
            }
            
            HStack(spacing: 12) {
                NutritionValueCard(
                    label: "Calories",
                    value: Int(currentProduct.caloriesPerServing * selectedMultiplier),
                    unit: "cal",
                    color: EmberColors.ember
                )
                
                NutritionValueCard(
                    label: "Protein",
                    value: Int(currentProduct.proteinPerServing * selectedMultiplier),
                    unit: "g",
                    color: .orange
                )
            }
            
            HStack(spacing: 12) {
                NutritionValueCard(
                    label: "Carbs",
                    value: Int(currentProduct.carbsPerServing * selectedMultiplier),
                    unit: "g",
                    color: .blue
                )
                
                NutritionValueCard(
                    label: "Fat",
                    value: Int(currentProduct.fatPerServing * selectedMultiplier),
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
            
            let multipliers: [Double] = [0.5, 1.0, 1.5, 2.0, 3.0]
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
            name: currentProduct.name,
            calories: currentProduct.caloriesPerServing * selectedMultiplier,
            protein: currentProduct.proteinPerServing * selectedMultiplier,
            carbs: currentProduct.carbsPerServing * selectedMultiplier,
            fat: currentProduct.fatPerServing * selectedMultiplier,
            mealType: selectedMealType.rawValue,
            servings: selectedMultiplier,
            caloriesPerServing: currentProduct.caloriesPerServing,
            proteinPerServing: currentProduct.proteinPerServing,
            carbsPerServing: currentProduct.carbsPerServing,
            fatPerServing: currentProduct.fatPerServing
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
