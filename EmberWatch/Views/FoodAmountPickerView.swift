import SwiftUI

/// Shared amount-unit picker for confirm-serving and edit-serving sheets.
/// Split into small subviews so the SwiftUI type checker stays happy.
struct FoodAmountPickerView: View {
    @Binding var unit: FoodAmountUnit
    @Binding var quantity: Double
    let servingSizeGrams: Double
    let gramsPerCup: Double
    var gramsPerCupIsEstimated: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            header
            unitPicker
            quantityEditor
            conversionCaption
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(EmberColors.lightPlum)
        )
        .onAppear {
            normalizeHalfCupIfNeeded()
        }
    }

    private var header: some View {
        Text("Amount")
            .font(.headline)
            .foregroundColor(EmberColors.cream)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var unitPicker: some View {
        Picker("Unit", selection: unitBinding) {
            ForEach(FoodAmountUnit.pickerCases) { item in
                Text(item.pickerTitle).tag(item)
            }
        }
        .pickerStyle(.segmented)
        .colorMultiply(EmberColors.ember)
    }
    
    private var unitBinding: Binding<FoodAmountUnit> {
        Binding(
            get: { displayedUnit },
            set: { newUnit in
                unit = newUnit
                quantity = FoodAmountMath.defaultQuantity(
                    for: newUnit,
                    servingSizeGrams: servingSizeGrams
                )
            }
        )
    }

    private var displayedUnit: FoodAmountUnit {
        FoodAmountMath.pickerSelection(unit: unit, quantity: quantity).unit
    }

    private func normalizeHalfCupIfNeeded() {
        guard unit == .halfCup else { return }
        let mapped = FoodAmountMath.pickerSelection(unit: unit, quantity: quantity)
        unit = mapped.unit
        quantity = mapped.quantity
    }

    @ViewBuilder
    private var quantityEditor: some View {
        switch displayedUnit {
        case .servings:
            ServingsQuantityEditor(quantity: $quantity)
        case .grams:
            GramsQuantityEditor(
                quantity: $quantity,
                servingSizeGrams: servingSizeGrams
            )
        case .cup, .halfCup:
            CupQuantityEditor(quantity: $quantity)
        }
    }

    private var conversionCaption: some View {
        Text(captionText)
            .font(.caption)
            .foregroundColor(EmberColors.cream.opacity(0.65))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var captionText: String {
        switch unit {
        case .servings:
            if servingSizeGrams > 0 {
                return "1 serving = \(Int(servingSizeGrams.rounded())) g"
            }
            return "Uses this food’s default serving"
        case .grams:
            return "Nutrition scales with gram weight"
        case .cup, .halfCup:
            return FoodCupWeight.pickerCaption(
                gramsPerCup: gramsPerCup,
                isEstimated: gramsPerCupIsEstimated
            )
        }
    }
}

private struct ServingsQuantityEditor: View {
    @Binding var quantity: Double

    private let presets: [Double] = [0.5, 1.0, 1.5, 2.0, 3.0]

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(presets, id: \.self) { preset in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            quantity = preset
                        }
                    } label: {
                        Text(FoodAmountMath.formatQuantity(preset))
                            .font(.headline)
                            .foregroundColor(isSelected(preset) ? EmberColors.cream : EmberColors.cream.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isSelected(preset) ? EmberColors.ember : EmberColors.dusk)
                            )
                    }
                }
            }

            HStack {
                Text("Servings")
                    .foregroundColor(EmberColors.cream.opacity(0.7))
                Spacer()
                Button {
                    quantity = max(0.25, roundedQuarter(quantity) - 0.25)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(EmberColors.ember)
                }
                Text(FoodAmountMath.formatQuantity(quantity))
                    .font(.headline)
                    .foregroundColor(EmberColors.cream)
                    .frame(minWidth: 48)
                Button {
                    quantity = min(10, roundedQuarter(quantity) + 0.25)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(EmberColors.ember)
                }
            }
        }
    }

    private func isSelected(_ preset: Double) -> Bool {
        abs(quantity - preset) < 0.001
    }

    private func roundedQuarter(_ value: Double) -> Double {
        (value * 4).rounded() / 4
    }
}

private struct GramsQuantityEditor: View {
    @Binding var quantity: Double
    let servingSizeGrams: Double

    var body: some View {
        VStack(spacing: 12) {
            gramPresetRow
            gramStepperRow
        }
    }

    private var gramPresetRow: some View {
        HStack(spacing: 8) {
            ForEach(gramPresets, id: \.self) { grams in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        quantity = grams
                    }
                } label: {
                    Text("\(Int(grams.rounded()))g")
                        .font(.headline)
                        .foregroundColor(isSelected(grams) ? EmberColors.cream : EmberColors.cream.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isSelected(grams) ? EmberColors.ember : EmberColors.dusk)
                        )
                }
            }
        }
    }

    private var gramStepperRow: some View {
        HStack {
            Text("Adjust")
                .foregroundColor(EmberColors.cream.opacity(0.7))
            Spacer()
            Button {
                quantity = max(1, quantity - 10)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title2)
                    .foregroundColor(EmberColors.ember)
            }
            Text("\(Int(quantity.rounded()))g")
                .font(.headline)
                .foregroundColor(EmberColors.cream)
                .frame(minWidth: 60)
            Button {
                quantity = min(5000, quantity + 10)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(EmberColors.ember)
            }
        }
    }

    private var gramPresets: [Double] {
        let base = servingSizeGrams > 0 ? servingSizeGrams : 100
        return [base * 0.5, base, base * 1.5, base * 2.0, base * 3.0]
    }

    private func isSelected(_ grams: Double) -> Bool {
        abs(quantity - grams) < 1.0
    }
}

private struct CupQuantityEditor: View {
    @Binding var quantity: Double

    private let presets: [Double] = [0.5, 1.0, 1.5, 2.0, 3.0]

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(presets, id: \.self) { preset in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            quantity = preset
                        }
                    } label: {
                        Text(FoodAmountMath.formatQuantity(preset))
                            .font(.headline)
                            .foregroundColor(isSelected(preset) ? EmberColors.cream : EmberColors.cream.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isSelected(preset) ? EmberColors.ember : EmberColors.dusk)
                            )
                    }
                }
            }

            HStack {
                Text("Cups")
                    .foregroundColor(EmberColors.cream.opacity(0.7))
                Spacer()
                Button {
                    quantity = max(0.25, roundedQuarter(quantity) - 0.25)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(EmberColors.ember)
                }
                Text(FoodAmountMath.displayLabel(unit: .cup, quantity: quantity))
                    .font(.headline)
                    .foregroundColor(EmberColors.cream)
                    .frame(minWidth: 72)
                Button {
                    quantity = min(10, roundedQuarter(quantity) + 0.25)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(EmberColors.ember)
                }
            }
        }
    }

    private func isSelected(_ preset: Double) -> Bool {
        abs(quantity - preset) < 0.001
    }

    private func roundedQuarter(_ value: Double) -> Double {
        (value * 4).rounded() / 4
    }
}
