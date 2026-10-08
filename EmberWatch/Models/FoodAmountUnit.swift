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

/// Gram weight of 1 US cup after FatSecret / USDA / density-table resolution.
struct ResolvedCupWeight: Equatable, Sendable {
    let grams: Double
    let isEstimated: Bool

    static let fallback = ResolvedCupWeight(grams: 240, isEstimated: true)
}

/// Lock-protected map so cup weights can be cached off the main actor.
private final class CupWeightCacheBox: @unchecked Sendable {
    static let shared = CupWeightCacheBox()
    private let lock = NSLock()
    private var map: [String: ResolvedCupWeight] = [:]

    func value(for key: String) -> ResolvedCupWeight? {
        lock.lock()
        defer { lock.unlock() }
        return map[key]
    }

    func store(_ value: ResolvedCupWeight, for key: String) {
        lock.lock()
        map[key] = value
        lock.unlock()
    }
}

enum FoodCupWeight: Sendable {
    /// USDA water-style cup when no serving, USDA portion, or density match exists.
    static let fallbackGramsPerCup: Double = 240
    /// US customary cup in milliliters.
    static let millilitersPerUSCup: Double = 236.6

    struct ServingInput: Equatable, Sendable {
        var description: String?
        var measurement: String?
        var metricAmount: Double?
        var metricUnit: String?
        var numberOfUnits: Double?
    }

    struct USDAPortionInput: Equatable, Sendable {
        var gramWeight: Double
        var amount: Double
        var measureText: String
    }

    static func resolvedGramsPerCup(
        explicit: Double?,
        servingSizeText: String?
    ) -> Double {
        resolve(
            foodName: "",
            explicitGrams: explicit,
            servingSizeText: servingSizeText
        ).grams
    }

    /// Resolution order: stored grams → FatSecret/OFF volume servings → USDA
    /// portions → density table → 240 g estimated fallback.
    static func resolve(
        cacheKey: String? = nil,
        foodName: String,
        explicitGrams: Double? = nil,
        isExplicitEstimated: Bool = false,
        servingSizeText: String? = nil,
        servings: [ServingInput] = [],
        usdaPortions: [USDAPortionInput] = [],
        usdaHouseholdText: String? = nil,
        usdaServingGrams: Double? = nil,
        usdaServingUnit: String? = nil
    ) -> ResolvedCupWeight {
        if let explicitGrams, explicitGrams > 0 {
            let resolved = ResolvedCupWeight(grams: explicitGrams, isEstimated: isExplicitEstimated)
            storeCached(resolved, key: cacheKey)
            return resolved
        }

        let hasSourceData = !servings.isEmpty
            || !usdaPortions.isEmpty
            || !(usdaHouseholdText ?? "").isEmpty
        if !hasSourceData, let cached = cachedValue(for: cacheKey) {
            return cached
        }

        let resolved = compute(
            foodName: foodName,
            servingSizeText: servingSizeText,
            servings: servings,
            usdaPortions: usdaPortions,
            usdaHouseholdText: usdaHouseholdText,
            usdaServingGrams: usdaServingGrams,
            usdaServingUnit: usdaServingUnit
        )
        storeCached(resolved, key: cacheKey)
        return resolved
    }

    static func gramsPerCup(
        description: String?,
        measurement: String?,
        metricAmount: Double?,
        metricUnit: String?,
        numberOfUnits: Double?
    ) -> Double? {
        let input = ServingInput(
            description: description,
            measurement: measurement,
            metricAmount: metricAmount,
            metricUnit: metricUnit,
            numberOfUnits: numberOfUnits
        )
        return gramsFromWeightMetric(input)?.gramsPerCup
    }

    static func gramsPerCup(fromServingSizeText text: String?) -> Double? {
        gramsPerCup(fromServingSizeText: text, foodName: "")
    }

    static func gramsPerCup(fromServingSizeText text: String?, foodName: String) -> Double? {
        guard let text, !text.isEmpty else { return nil }
        let lower = text.lowercased()
        guard let volume = parseVolume(in: lower, numberOfUnits: nil), volume.cups > 0 else {
            return nil
        }
        if let grams = extractMetric(from: lower, units: ["g", "gram", "grams"]), grams > 0 {
            return grams / volume.cups
        }
        if let ml = extractMetric(from: lower, units: ["ml", "milliliter", "millilitre", "milliliters", "millilitres"]), ml > 0 {
            let density = densityGramsPerMilliliter(foodName: foodName, knownDensities: [])
            return (ml * density) / volume.cups
        }
        if let flOz = extractMetric(from: lower, units: ["fl oz", "fl. oz"]), flOz > 0 {
            let density = densityGramsPerMilliliter(foodName: foodName, knownDensities: [])
            return (flOz * 29.5735 * density) / volume.cups
        }
        if let oz = extractMetric(from: lower, units: ["oz", "ounce"]), oz > 0 {
            return (oz * 28.3495) / volume.cups
        }
        return nil
    }

    static func pickerCaption(gramsPerCup: Double, isEstimated: Bool) -> String {
        let grams = max(gramsPerCup, 0)
        let rounded = Int(grams.rounded())
        if isEstimated {
            return "1 cup ≈ \(rounded) g (est.)"
        }
        return "1 cup ≈ \(rounded) g"
    }

    // MARK: - Cache

    private static func cachedValue(for key: String?) -> ResolvedCupWeight? {
        guard let key, !key.isEmpty else { return nil }
        return CupWeightCacheBox.shared.value(for: key)
    }

    private static func storeCached(_ value: ResolvedCupWeight, key: String?) {
        guard let key, !key.isEmpty else { return }
        CupWeightCacheBox.shared.store(value, for: key)
    }

    // MARK: - Pipeline

    private static func compute(
        foodName: String,
        servingSizeText: String?,
        servings: [ServingInput],
        usdaPortions: [USDAPortionInput],
        usdaHouseholdText: String?,
        usdaServingGrams: Double?,
        usdaServingUnit: String?
    ) -> ResolvedCupWeight {
        let weightCandidates = weightBasedCandidates(from: servings)
        if let best = pickBest(weightCandidates) {
            return ResolvedCupWeight(grams: best.gramsPerCup, isEstimated: false)
        }

        if let fromText = gramsPerCup(fromServingSizeText: servingSizeText, foodName: foodName), fromText > 0 {
            return ResolvedCupWeight(grams: fromText, isEstimated: false)
        }

        if let fromUSDA = gramsPerCup(fromUSDAPortions: usdaPortions) {
            return ResolvedCupWeight(grams: fromUSDA, isEstimated: false)
        }

        if let fromHousehold = gramsPerCup(
            householdText: usdaHouseholdText,
            servingGrams: usdaServingGrams,
            servingUnit: usdaServingUnit,
            foodName: foodName
        ) {
            return ResolvedCupWeight(grams: fromHousehold, isEstimated: false)
        }

        let knownDensities = densitiesFromServings(servings)
        if let fromML = milliliterBasedGramsPerCup(
            servings: servings,
            foodName: foodName,
            knownDensities: knownDensities
        ) {
            return ResolvedCupWeight(grams: fromML, isEstimated: false)
        }

        if let table = CupDensityTable.gramsPerCup(matching: foodName), table > 0 {
            return ResolvedCupWeight(grams: table, isEstimated: false)
        }

        return .fallback
    }

    private struct WeightCandidate {
        var gramsPerCup: Double
        var kindRank: Int
        var distanceFromOneCup: Double
    }

    private static func pickBest(_ candidates: [WeightCandidate]) -> WeightCandidate? {
        guard !candidates.isEmpty else { return nil }
        var best = candidates[0]
        var index = 1
        while index < candidates.count {
            let item = candidates[index]
            if item.kindRank < best.kindRank {
                best = item
            } else if item.kindRank == best.kindRank, item.distanceFromOneCup < best.distanceFromOneCup {
                best = item
            }
            index += 1
        }
        return best
    }

    private static func weightBasedCandidates(from servings: [ServingInput]) -> [WeightCandidate] {
        var candidates: [WeightCandidate] = []
        for serving in servings {
            guard let parsed = gramsFromWeightMetric(serving) else { continue }
            candidates.append(parsed)
        }
        return candidates
    }

    private static func gramsFromWeightMetric(_ serving: ServingInput) -> WeightCandidate? {
        guard let volume = volume(for: serving), volume.cups > 0 else { return nil }
        guard let grams = metricGrams(serving) else { return nil }
        return WeightCandidate(
            gramsPerCup: grams / volume.cups,
            kindRank: volume.kind.rank,
            distanceFromOneCup: abs(volume.cups - 1)
        )
    }

    private static func densitiesFromServings(_ servings: [ServingInput]) -> [Double] {
        var densities: [Double] = []
        for serving in servings {
            guard let volume = volume(for: serving), volume.milliliters > 0 else { continue }
            guard let grams = metricGrams(serving) else { continue }
            let density = grams / volume.milliliters
            if density > 0 {
                densities.append(density)
            }
        }
        return densities
    }

    private static func milliliterBasedGramsPerCup(
        servings: [ServingInput],
        foodName: String,
        knownDensities: [Double]
    ) -> Double? {
        var mlPerCupValues: [Double] = []
        for serving in servings {
            guard let volume = volume(for: serving), volume.cups > 0 else { continue }
            guard let ml = metricMilliliters(serving) else { continue }
            mlPerCupValues.append(ml / volume.cups)
        }
        guard let millilitersPerCup = mlPerCupValues.first, millilitersPerCup > 0 else {
            return nil
        }
        let density = densityGramsPerMilliliter(foodName: foodName, knownDensities: knownDensities)
        return millilitersPerCup * density
    }

    private static func densityGramsPerMilliliter(foodName: String, knownDensities: [Double]) -> Double {
        if let first = knownDensities.first, first > 0 {
            return first
        }
        if let table = CupDensityTable.gramsPerCup(matching: foodName), table > 0 {
            return table / millilitersPerUSCup
        }
        return 1
    }

    private static func gramsPerCup(fromUSDAPortions portions: [USDAPortionInput]) -> Double? {
        var candidates: [WeightCandidate] = []
        for portion in portions {
            guard portion.gramWeight > 0 else { continue }
            let text = portion.measureText.lowercased()
            guard let volume = parseVolume(in: text, numberOfUnits: portion.amount > 0 ? portion.amount : nil) else {
                continue
            }
            guard volume.cups > 0 else { continue }
            candidates.append(
                WeightCandidate(
                    gramsPerCup: portion.gramWeight / volume.cups,
                    kindRank: volume.kind.rank,
                    distanceFromOneCup: abs(volume.cups - 1)
                )
            )
        }
        return pickBest(candidates)?.gramsPerCup
    }

    private static func gramsPerCup(
        householdText: String?,
        servingGrams: Double?,
        servingUnit: String?,
        foodName: String
    ) -> Double? {
        guard let householdText, !householdText.isEmpty else { return nil }
        guard let volume = parseVolume(in: householdText.lowercased(), numberOfUnits: nil), volume.cups > 0 else {
            return nil
        }
        guard let amount = servingGrams, amount > 0 else { return nil }
        let unit = (servingUnit ?? "g").lowercased()
        if isGramUnit(unit) {
            return amount / volume.cups
        }
        if isMilliliterUnit(unit) {
            let density = densityGramsPerMilliliter(foodName: foodName, knownDensities: [])
            return (amount * density) / volume.cups
        }
        if unit == "oz" || unit == "ounce" || unit == "onz" {
            return (amount * 28.3495) / volume.cups
        }
        return nil
    }

    private static func metricGrams(_ serving: ServingInput) -> Double? {
        guard let amount = serving.metricAmount, amount > 0 else { return nil }
        let unit = (serving.metricUnit ?? "g").lowercased()
        if isGramUnit(unit) {
            return amount
        }
        if unit == "oz" || unit == "ounce" || unit == "ounces" {
            return amount * 28.3495
        }
        return nil
    }

    private static func metricMilliliters(_ serving: ServingInput) -> Double? {
        guard let amount = serving.metricAmount, amount > 0 else { return nil }
        let unit = (serving.metricUnit ?? "").lowercased()
        if isMilliliterUnit(unit) {
            return amount
        }
        return nil
    }

    private static func isGramUnit(_ unit: String) -> Bool {
        unit == "g" || unit == "gram" || unit == "grams" || unit == "grm"
    }

    private static func isMilliliterUnit(_ unit: String) -> Bool {
        unit == "ml" || unit == "milliliter" || unit == "millilitre"
            || unit == "milliliters" || unit == "millilitres" || unit == "mlt"
    }

    private static func volume(for serving: ServingInput) -> ParsedVolume? {
        let measurement = serving.measurement?.lowercased() ?? ""
        let description = serving.description?.lowercased() ?? ""
        if let fromDescription = parseVolume(in: description, numberOfUnits: serving.numberOfUnits) {
            return fromDescription
        }
        if let fromMeasurement = parseVolume(in: measurement, numberOfUnits: serving.numberOfUnits) {
            return fromMeasurement
        }
        let combined = measurement + " " + description
        return parseVolume(in: combined, numberOfUnits: serving.numberOfUnits)
    }

    private struct ParsedVolume {
        var kind: VolumeKind
        var units: Double

        var cups: Double {
            switch kind {
            case .cup: return units
            case .tablespoon: return units / 16.0
            case .teaspoon: return units / 48.0
            case .fluidOunce: return units / 8.0
            case .milliliter: return units / FoodCupWeight.millilitersPerUSCup
            }
        }

        var milliliters: Double {
            cups * FoodCupWeight.millilitersPerUSCup
        }
    }

    private enum VolumeKind {
        case cup
        case tablespoon
        case teaspoon
        case fluidOunce
        case milliliter

        var rank: Int {
            switch self {
            case .cup: return 0
            case .tablespoon: return 1
            case .teaspoon: return 2
            case .fluidOunce: return 3
            case .milliliter: return 4
            }
        }
    }

    private static func parseVolume(in text: String, numberOfUnits: Double?) -> ParsedVolume? {
        guard let kind = volumeKind(in: text) else { return nil }
        if let parsed = parseLeadingAmount(in: text, kind: kind), parsed > 0 {
            return ParsedVolume(kind: kind, units: parsed)
        }
        if let units = numberOfUnits, units > 0 {
            return ParsedVolume(kind: kind, units: units)
        }
        return ParsedVolume(kind: kind, units: 1)
    }

    private static func volumeKind(in text: String) -> VolumeKind? {
        let lower = text.lowercased()
        if containsAnyToken(["fl oz", "fl. oz", "fluid ounce", "fluid ounces"], in: lower) {
            return .fluidOunce
        }
        if containsCupWord(lower) {
            return .cup
        }
        if containsAnyToken(["tablespoon", "tablespoons", "tbsp", "tbs"], in: lower) {
            return .tablespoon
        }
        if containsAnyToken(["teaspoon", "teaspoons", "tsp"], in: lower) {
            return .teaspoon
        }
        if containsAnyToken(["milliliter", "millilitre", "milliliters", "millilitres", "ml"], in: lower) {
            return .milliliter
        }
        return nil
    }

    private static func containsAnyToken(_ tokens: [String], in text: String) -> Bool {
        for token in tokens {
            if CupDensityTable.containsWord(token, in: text) {
                return true
            }
        }
        return false
    }

    private static func parseLeadingAmount(in text: String, kind: VolumeKind) -> Double? {
        if let fraction = parseFraction(in: text) {
            return fraction
        }
        let markers: [String]
        switch kind {
        case .cup:
            markers = ["cups", "cup"]
        case .tablespoon:
            markers = ["tablespoons", "tablespoon", "tbsp", "tbs"]
        case .teaspoon:
            markers = ["teaspoons", "teaspoon", "tsp"]
        case .fluidOunce:
            markers = ["fluid ounces", "fluid ounce", "fl. oz", "fl oz"]
        case .milliliter:
            markers = ["milliliters", "millilitres", "milliliter", "millilitre", "ml"]
        }
        for marker in markers {
            if let range = text.range(of: marker) {
                let before = String(text[..<range.lowerBound])
                if let number = trailingNumber(in: before), number > 0 {
                    return number
                }
            }
        }
        return nil
    }

    private static func parseFraction(in text: String) -> Double? {
        if text.contains("1/2") || text.contains("½") || text.contains("half cup") {
            return 0.5
        }
        if text.contains("1/4") || text.contains("¼") || text.contains("quarter cup") {
            return 0.25
        }
        if text.contains("3/4") || text.contains("¾") {
            return 0.75
        }
        if text.contains("1/3") || text.contains("⅓") {
            return 1.0 / 3.0
        }
        if text.contains("2/3") || text.contains("⅔") {
            return 2.0 / 3.0
        }
        return nil
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
            var searchStart = text.startIndex
            while searchStart < text.endIndex,
                  let range = text.range(of: unit, range: searchStart..<text.endIndex) {
                let beforeOK: Bool
                if range.lowerBound == text.startIndex {
                    beforeOK = true
                } else {
                    let previous = text.index(before: range.lowerBound)
                    beforeOK = !text[previous].isLetter
                }
                let afterOK: Bool
                if range.upperBound == text.endIndex {
                    afterOK = true
                } else {
                    afterOK = !text[range.upperBound].isLetter
                }
                if beforeOK && afterOK {
                    let before = String(text[..<range.lowerBound])
                    if let number = trailingNumber(in: before), number > 0 {
                        return number
                    }
                }
                searchStart = range.upperBound
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
