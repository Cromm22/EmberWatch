import Foundation

struct FoodProduct: Identifiable, Equatable, Sendable {
    let id = UUID()
    let barcode: String
    let name: String
    let servingSize: String
    let caloriesPer100g: Double
    let proteinPer100g: Double
    let carbsPer100g: Double
    let fatPer100g: Double
    let servingSizeGrams: Double?
    
    var caloriesPerServing: Double {
        guard let grams = servingSizeGrams, grams > 0 else {
            return caloriesPer100g
        }
        return (caloriesPer100g * grams) / 100.0
    }
    
    var proteinPerServing: Double {
        guard let grams = servingSizeGrams, grams > 0 else {
            return proteinPer100g
        }
        return (proteinPer100g * grams) / 100.0
    }
    
    var carbsPerServing: Double {
        guard let grams = servingSizeGrams, grams > 0 else {
            return carbsPer100g
        }
        return (carbsPer100g * grams) / 100.0
    }
    
    var fatPerServing: Double {
        guard let grams = servingSizeGrams, grams > 0 else {
            return fatPer100g
        }
        return (fatPer100g * grams) / 100.0
    }
    
    var hasValidMacros: Bool {
        return caloriesPer100g > 0 || proteinPer100g > 0 || carbsPer100g > 0 || fatPer100g > 0
    }
}

@MainActor
class FoodLookupService: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    /// Bumped on each new search so stale responses are ignored.
    private var searchGeneration = 0
    private var activeSearchTask: Task<[FoodProduct], Never>?
    
    private static let maxResults = 20
    private static let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 12
        config.timeoutIntervalForResource = 18
        config.waitsForConnectivity = false
        config.urlCache = nil
        return URLSession(configuration: config)
    }()
    
    func cancelSearch() {
        searchGeneration += 1
        activeSearchTask?.cancel()
        activeSearchTask = nil
        isLoading = false
    }
    
    func lookupBarcode(_ barcode: String) async -> FoodProduct? {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            if let product = try await Self.lookupOpenFoodFacts(barcode: barcode) {
                if product.hasValidMacros {
                    return product
                }
            }
            
            if let product = try await Self.lookupUSDA(barcode: barcode) {
                if product.hasValidMacros {
                    return product
                }
            }
            
            errorMessage = "Not in the database. Add it by hand."
            return nil
        } catch is CancellationError {
            return nil
        } catch {
            errorMessage = "Lookup failed. Check your connection and try again."
            return nil
        }
    }
    
    /// Text / name search across Open Food Facts then USDA. Returns up to 20 products.
    /// Never blocks the main thread for network/JSON — work runs off-main; only state updates hop back.
    func searchFoods(query: String) async -> [FoodProduct] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            cancelSearch()
            errorMessage = nil
            return []
        }
        
        activeSearchTask?.cancel()
        searchGeneration += 1
        let generation = searchGeneration
        
        isLoading = true
        errorMessage = nil
        
        let task = Task.detached(priority: .userInitiated) { () -> Result<[FoodProduct], Error> in
            do {
                try Task.checkCancellation()
                var results: [FoodProduct] = []
                var seenNames = Set<String>()
                
                let off = try await Self.searchOpenFoodFacts(query: trimmed)
                try Task.checkCancellation()
                for product in off {
                    let key = product.name.lowercased()
                    if !seenNames.contains(key), product.hasValidMacros {
                        seenNames.insert(key)
                        results.append(product)
                        if results.count >= Self.maxResults { break }
                    }
                }
                
                if results.count < 8 {
                    let usda = try await Self.searchUSDA(query: trimmed)
                    try Task.checkCancellation()
                    for product in usda {
                        let key = product.name.lowercased()
                        if !seenNames.contains(key), product.hasValidMacros {
                            seenNames.insert(key)
                            results.append(product)
                            if results.count >= Self.maxResults { break }
                        }
                    }
                }
                
                return .success(Array(results.prefix(Self.maxResults)))
            } catch is CancellationError {
                return .failure(CancellationError())
            } catch {
                return .failure(error)
            }
        }
        activeSearchTask = Task {
            switch await task.value {
            case .success(let r): return r
            case .failure: return []
            }
        }
        
        let outcome = await task.value
        
        // Stale generation — a newer keystroke owns the UI now.
        guard generation == searchGeneration else {
            return []
        }
        
        isLoading = false
        activeSearchTask = nil
        
        switch outcome {
        case .success(let results):
            if results.isEmpty {
                errorMessage = "No foods found for “\(trimmed)”."
            } else {
                errorMessage = nil
            }
            return results
        case .failure(let error):
            if error is CancellationError {
                return []
            }
            errorMessage = "Search failed. Check your connection and try again."
            return []
        }
    }
    
    // MARK: - Network (nonisolated / off main)
    
    nonisolated private static func lookupOpenFoodFacts(barcode: String) async throws -> FoodProduct? {
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(barcode).json") else {
            return nil
        }
        
        let (data, _) = try await session.data(from: url)
        try Task.checkCancellation()
        let response = try JSONDecoder().decode(OFFResponse.self, from: data)
        
        guard response.status == 1,
              let product = response.product,
              let nutriments = product.nutriments else {
            return nil
        }
        
        return makeOFFProduct(product, nutriments: nutriments, fallbackBarcode: barcode)
    }
    
    nonisolated private static func lookupUSDA(barcode: String) async throws -> FoodProduct? {
        let apiKey = "DEMO_KEY"
        guard let url = URL(string: "https://api.nal.usda.gov/fdc/v1/foods/search?query=\(barcode)&api_key=\(apiKey)") else {
            return nil
        }
        
        let (data, _) = try await session.data(from: url)
        try Task.checkCancellation()
        let response = try JSONDecoder().decode(USDAResponse.self, from: data)
        guard let food = response.foods.first else { return nil }
        return makeUSDAProduct(food)
    }
    
    nonisolated private static func searchOpenFoodFacts(query: String) async throws -> [FoodProduct] {
        var components = URLComponents(string: "https://world.openfoodfacts.org/cgi/search.pl")!
        // Limit payload size — banana returns huge product blobs without `fields`.
        components.queryItems = [
            URLQueryItem(name: "search_terms", value: query),
            URLQueryItem(name: "search_simple", value: "1"),
            URLQueryItem(name: "action", value: "process"),
            URLQueryItem(name: "json", value: "1"),
            URLQueryItem(name: "page_size", value: "20"),
            URLQueryItem(name: "fields", value: "code,product_name,serving_size,serving_quantity,nutriments")
        ]
        guard let url = components.url else { return [] }
        
        let (data, _) = try await session.data(from: url)
        try Task.checkCancellation()
        
        // Decode off main; large JSON must never touch the UI thread.
        let response = try JSONDecoder().decode(OFFSearchResponse.self, from: data)
        var out: [FoodProduct] = []
        for product in response.products ?? [] {
            guard let nutriments = product.nutriments,
                  let item = makeOFFProduct(product, nutriments: nutriments, fallbackBarcode: "off-search") else {
                continue
            }
            out.append(item)
            if out.count >= maxResults { break }
        }
        return out
    }
    
    nonisolated private static func searchUSDA(query: String) async throws -> [FoodProduct] {
        let apiKey = "DEMO_KEY"
        var components = URLComponents(string: "https://api.nal.usda.gov/fdc/v1/foods/search")!
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "pageSize", value: "15"),
            URLQueryItem(name: "api_key", value: apiKey)
        ]
        guard let url = components.url else { return [] }
        
        let (data, _) = try await session.data(from: url)
        try Task.checkCancellation()
        let response = try JSONDecoder().decode(USDAResponse.self, from: data)
        return response.foods.compactMap { makeUSDAProduct($0) }.prefix(maxResults).map { $0 }
    }
    
    nonisolated private static func makeOFFProduct(_ product: OFFProduct, nutriments: OFFNutriments, fallbackBarcode: String) -> FoodProduct? {
        let calories = nutriments.energyKcal100g ?? 0
        let protein = nutriments.proteins100g ?? 0
        let carbs = nutriments.carbohydrates100g ?? 0
        let fat = nutriments.fat100g ?? 0
        guard calories > 0 || protein > 0 || carbs > 0 || fat > 0 else { return nil }
        let name = product.productName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !name.isEmpty else { return nil }
        return FoodProduct(
            barcode: product.code ?? fallbackBarcode,
            name: name,
            servingSize: product.servingSize ?? "100g",
            caloriesPer100g: calories,
            proteinPer100g: protein,
            carbsPer100g: carbs,
            fatPer100g: fat,
            servingSizeGrams: product.servingQuantityValue
        )
    }
    
    nonisolated private static func makeUSDAProduct(_ food: USDAFood) -> FoodProduct? {
        let nutrients = food.foodNutrients
        let calories = nutrients.first(where: { $0.resolvedId == 1008 })?.value ?? 0
        let protein = nutrients.first(where: { $0.resolvedId == 1003 })?.value ?? 0
        let carbs = nutrients.first(where: { $0.resolvedId == 1005 })?.value ?? 0
        let fat = nutrients.first(where: { $0.resolvedId == 1004 })?.value ?? 0
        guard calories > 0 || protein > 0 || carbs > 0 || fat > 0 else { return nil }
        let servingSize = food.servingSize ?? 100
        return FoodProduct(
            barcode: "usda-\(food.fdcId ?? 0)",
            name: food.description,
            servingSize: "\(Int(servingSize))g",
            caloriesPer100g: calories,
            proteinPer100g: protein,
            carbsPer100g: carbs,
            fatPer100g: fat,
            servingSizeGrams: servingSize
        )
    }
}

// MARK: - DTOs

struct OFFSearchResponse: Codable, Sendable {
    let products: [OFFProduct]?
}

struct OFFResponse: Codable, Sendable {
    let status: Int
    let product: OFFProduct?
}

struct OFFProduct: Codable, Sendable {
    let code: String?
    let productName: String?
    let servingSize: String?
    let servingQuantity: FlexibleDouble?
    let nutriments: OFFNutriments?
    
    enum CodingKeys: String, CodingKey {
        case code
        case productName = "product_name"
        case servingSize = "serving_size"
        case servingQuantity = "serving_quantity"
        case nutriments
    }
    
    var servingQuantityValue: Double? {
        servingQuantity?.value
    }
}

/// OFF sometimes returns serving_quantity as number or string.
struct FlexibleDouble: Codable, Sendable {
    let value: Double?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let d = try? container.decode(Double.self) {
            value = d
        } else if let i = try? container.decode(Int.self) {
            value = Double(i)
        } else if let s = try? container.decode(String.self) {
            value = Double(s.replacingOccurrences(of: ",", with: "."))
        } else {
            value = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

struct OFFNutriments: Codable, Sendable {
    let energyKcal100g: Double?
    let proteins100g: Double?
    let carbohydrates100g: Double?
    let fat100g: Double?
    
    enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case proteins100g = "proteins_100g"
        case carbohydrates100g = "carbohydrates_100g"
        case fat100g = "fat_100g"
    }
}

struct USDAResponse: Codable, Sendable {
    let foods: [USDAFood]
}

struct USDAFood: Codable, Sendable {
    let fdcId: Int?
    let description: String
    let servingSize: Double?
    let foodNutrients: [USDANutrient]
}

struct USDANutrient: Codable, Sendable {
    let nutrientId: Int?
    let nutrientNumber: String?
    let value: Double?
    
    var resolvedId: Int? {
        if let nutrientId { return nutrientId }
        if let nutrientNumber, let n = Int(nutrientNumber) { return n }
        return nil
    }
}
