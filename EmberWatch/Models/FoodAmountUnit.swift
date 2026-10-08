import Foundation

/// How a logged food amount is measured. Stored on `FoodEntry` as `rawValue`.
/// Empty / unknown stored strings fall back to grams or servings for old rows.
enum FoodAmountUnit: String, CaseIterable, Identifiable, Hashable, Sendable {
    case servings
    case grams
    case cup
    case halfCup

    var id: String { rawValue }

    /// Segmented-control labels only. Diary rows use `FoodAmountMath.displayLabel`.
    var pickerTitle: String {
        switch self {
        case .servings: return "Servings"
        case .grams: return "Grams"
        case .cup: return "Cups"
        case .halfCup: return "½ cup"
        }
    }

    /// Units shown in the amount segmented control. `halfCup` stays in the
    /// enum so old SwiftData rows still decode; half a cup is 1 cup × 0.5.
    static var pickerCases: [FoodAmountUnit] {
        [.servings, .grams, .cup]
    }
}

enum FoodCupWeight {
    /// USDA water-style cup when FatSecret/OFF do not list a cup serving.
    static let fallbackGramsPerCup: Double = 240

    static func resolvedGramsPerCup(
        explicit: Double?,
        servingSizeText: String?
    ) -> Double {
        if let explicit, explicit > 0 {
            return explicit
        }
        if let parsed = gramsPerCup(fromServingSizeText: servingSizeText), parsed > 0 {
            return parsed
        }
        return fallbackGramsPerCup
    }

    static func gramsPerCup(
        description: String?,
        measurement: String?,
        metricAmount: Double?,
        metricUnit: String?,
        numberOfUnits: Double?
    ) -> Double? {
        let cups = cupCount(
            description: description,
            measurement: measurement,
            numberOfUnits: numberOfUnits
        )
        guard let cups, cups > 0 else { return nil }
        guard let metricAmount, metricAmount > 0 else { return nil }
        let unit = (metricUnit ?? "g").lowercased()
        let grams: Double
        if unit == "g" || unit == "gram" || unit == "grams" || unit == "ml" || unit == "milliliter" || unit == "millilitre" {
            grams = metricAmount
        } else if unit == "oz" || unit == "ounce" {
            grams = metricAmount * 28.3495
        } else {
            return nil
        }
        return grams / cups
    }

    static func gramsPerCup(fromServingSizeText text: String?) -> Double? {
        guard let text, !text.isEmpty else { return nil }
        let lower = text.lowercased()
        guard containsCupWord(lower) else { return nil }
        let cups = parseCupCount(in: lower) ?? 1
        guard cups > 0 else { return nil }
        if let grams = extractMetric(from: lower, units: ["g", "gram"]), grams > 0 {
            return grams / cups
        }
        if let ml = extractMetric(from: lower, units: ["ml", "milliliter", "millilitre"]), ml > 0 {
            return ml / cups
        }
        if let oz = extractMetric(from: lower, units: ["fl oz", "oz"]), oz > 0 {
            return (oz * 28.3495) / cups
        }
        return nil
    }

    private static func cupCount(
        description: String?,
        measurement: String?,
        numberOfUnits: Double?
    ) -> Double? {
        let measurementText = measurement?.lowercased() ?? ""
        let descriptionText = description?.lowercased() ?? ""
        let combined = measurementText + " " + descriptionText
        guard containsCupWord(combined) else { return nil }

        if let parsed = parseCupCount(in: descriptionText) {
            return parsed
        }
        if let parsed = parseCupCount(in: measurementText) {
            return parsed
        }
        if let units = numberOfUnits, units > 0 {
            return units
        }
        return 1
    }

    static func containsCupWord(_ text: String) -> Bool {
        if text.contains("cupcake") || text.contains("cup cake") {
            return false
        }
        let parts = text.split { !$0.isLetter }
        for part in parts {
            if part == "cup" || part == "cups" {
                return true
            }
        }
        return false
    }

    static func parseCupCount(in text: String) -> Double? {
        let lower = text.lowercased()
        guard containsCupWord(lower) else { return nil }

        if lower.contains("1/2") || lower.contains("½") || lower.contains("half cup") {
            return 0.5
        }
        if lower.contains("1/4") || lower.contains("¼") || lower.contains("quarter cup") {
            return 0.25
        }
        if lower.contains("3/4") || lower.contains("¾") {
            return 0.75
        }
        if lower.contains("1/3") || lower.contains("⅓") {
            return 1.0 / 3.0
        }
        if lower.contains("2/3") || lower.contains("⅔") {
            return 2.0 / 3.0
        }

        if let range = lower.range(of: "cup") {
            let before = String(lower[..<range.lowerBound])
            if let number = trailingNumber(in: before), number > 0 {
                return number
            }
        }
        return nil
    }

    private static func trailingNumber(in text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        var digits = ""
        var sawDot = false
        for character in trimmed.reversed() {
            if character.isNumber {
                digits.insert(character, at: digits.startIndex)
                continue
            }
            if character == ".", !sawDot {
                sawDot = true
                digits.insert(character, at: digits.startIndex)
                continue
            }
            if !digits.isEmpty {
                break
            }
            if character.isWhitespace || character == "(" || character == ")" {
                continue
            }
            break
        }
        if digits.isEmpty {
            return nil
        }
        return Double(digits)
    }

    private static func extractMetric(from text: String, units: [String]) -> Double? {
        for unit in units {
            if let range = text.range(of: unit) {
                let before = String(text[..<range.lowerBound])
                if let number = trailingNumber(in: before), number > 0 {
                    return number
                }
            }
        }
        return nil
    }
}

enum FoodAmountMath {
    static func gramBase(servingSizeGrams: Double) -> Double {
        if servingSizeGrams > 0 {
            return servingSizeGrams
        }
        return 100
    }

    static func totalGrams(
        unit: FoodAmountUnit,
        quantity: Double,
        servingSizeGrams: Double,
        gramsPerCup: Double
    ) -> Double {
        let qty = max(quantity, 0)
        let cupGrams = gramsPerCup > 0 ? gramsPerCup : FoodCupWeight.fallbackGramsPerCup
        switch unit {
        case .servings:
            return gramBase(servingSizeGrams: servingSizeGrams) * qty
        case .grams:
            return qty
        case .cup:
            return cupGrams * qty
        case .halfCup:
            return cupGrams * 0.5 * qty
        }
    }

    static func servingsMultiplier(
        unit: FoodAmountUnit,
        quantity: Double,
        servingSizeGrams: Double,
        gramsPerCup: Double
    ) -> Double {
        if unit == .servings {
            return max(quantity, 0.01)
        }
        let grams = totalGrams(
            unit: unit,
            quantity: quantity,
            servingSizeGrams: servingSizeGrams,
            gramsPerCup: gramsPerCup
        )
        let base = gramBase(servingSizeGrams: servingSizeGrams)
        guard base > 0 else { return max(quantity, 0.01) }
        return max(grams / base, 0.01)
    }

    static func formatQuantity(_ value: Double) -> String {
        if abs(value - 0.25) < 0.001 {
            return "0.25"
        }
        if abs(value - 0.5) < 0.001 {
            return "0.5"
        }
        if abs(value - 0.75) < 0.001 {
            return "0.75"
        }
        if abs(value - 1.5) < 0.001 {
            return "1.5"
        }
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value))"
        }
        let rounded = (value * 100).rounded() / 100
        return String(format: "%g", rounded)
    }

    static func displayLabel(unit: FoodAmountUnit, quantity: Double) -> String {
        let qty = quantity > 0 ? quantity : 1
        switch unit {
        case .grams:
            return "\(Int(qty.rounded())) g"
        case .servings:
            if abs(qty - 1) < 0.001 {
                return "1 serving"
            }
            return "\(formatQuantity(qty)) servings"
        case .cup:
            if abs(qty - 0.25) < 0.001 {
                return "1/4 cup"
            }
            if abs(qty - 0.5) < 0.001 {
                return "1/2 cup"
            }
            if abs(qty - 0.75) < 0.001 {
                return "3/4 cup"
            }
            if abs(qty - 1) < 0.001 {
                return "1 cup"
            }
            return "\(formatQuantity(qty)) cups"
        case .halfCup:
            if abs(qty - 1) < 0.001 {
                return "1/2 cup"
            }
            if abs(qty - 2) < 0.001 {
                return "1 cup"
            }
            return "\(formatQuantity(qty)) × 1/2 cup"
        }
    }

    static func defaultQuantity(for unit: FoodAmountUnit, servingSizeGrams: Double) -> Double {
        switch unit {
        case .servings:
            return 1
        case .grams:
            if servingSizeGrams > 0 {
                return servingSizeGrams
            }
            return 100
        case .cup, .halfCup:
            return 1
        }
    }

    /// Maps stored `halfCup` rows onto the cup picker (quantity × 0.5).
    static func pickerSelection(
        unit: FoodAmountUnit,
        quantity: Double
    ) -> (unit: FoodAmountUnit, quantity: Double) {
        if unit == .halfCup {
            return (.cup, max(quantity, 0) * 0.5)
        }
        return (unit, quantity)
    }
}
