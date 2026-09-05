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
    let brand: String?
    let source: FoodSource
    
    enum FoodSource: String, Sendable {
        case openFoodFacts = "OFF"
        case usda = "USDA"
        case nutritionix = "Nutritionix"
        case curated = "Curated"
    }
    
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
    
    nonisolated private static let maxResults = 20
    nonisolated private static let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 12
        config.timeoutIntervalForResource = 18
        config.waitsForConnectivity = false
        config.urlCache = nil
        return URLSession(configuration: config)
    }()
    
    // Nutritionix credentials from Info.plist
    nonisolated private static let nutritionixAppId: String? = {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "NUTRITIONIX_APP_ID") as? String,
              !value.trimmingCharacters(in: .whitespaces).isEmpty else {
            return nil
        }
        return value
    }()
    
    nonisolated private static let nutritionixApiKey: String? = {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "NUTRITIONIX_API_KEY") as? String,
              !value.trimmingCharacters(in: .whitespaces).isEmpty else {
            return nil
        }
        return value
    }()
    
    nonisolated private static var hasNutritionix: Bool {
        nutritionixAppId != nil && nutritionixApiKey != nil
    }
    
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
    
    /// Text / name search across Nutritionix (if available), curated chains, Open Food Facts, then USDA.
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
                var seenKeys = Set<String>()
                
                let brandQuery = Self.extractBrandQuery(trimmed)
                
                // 1. Curated chain seed (instant, guaranteed hits)
                let curated = Self.searchCuratedChains(query: trimmed, brandQuery: brandQuery)
                for product in curated {
                    let key = Self.dedupeKey(product)
                    if !seenKeys.contains(key) {
                        seenKeys.insert(key)
                        results.append(product)
                    }
                }
                
                // 2. Nutritionix (preferred for restaurant/branded foods)
                if Self.hasNutritionix {
                    let nix = try await Self.searchNutritionix(query: trimmed)
                    try Task.checkCancellation()
                    for product in nix {
                        let key = Self.dedupeKey(product)
                        if !seenKeys.contains(key), product.hasValidMacros {
                            seenKeys.insert(key)
                            results.append(product)
                            if results.count >= Self.maxResults { break }
                        }
                    }
                }
                
                // 3. Open Food Facts with brand-aware ranking
                if results.count < Self.maxResults {
                    let off = try await Self.searchOpenFoodFacts(query: trimmed)
                    try Task.checkCancellation()
                    let ranked = Self.rankAndFilterResults(off, query: trimmed, brandQuery: brandQuery)
                    for product in ranked {
                        let key = Self.dedupeKey(product)
                        if !seenKeys.contains(key), product.hasValidMacros {
                            seenKeys.insert(key)
                            results.append(product)
                            if results.count >= Self.maxResults { break }
                        }
                    }
                }
                
                // 4. USDA fallback
                if results.count < 8 {
                    let usda = try await Self.searchUSDA(query: trimmed)
                    try Task.checkCancellation()
                    for product in usda {
                        let key = Self.dedupeKey(product)
                        if !seenKeys.contains(key), product.hasValidMacros {
                            seenKeys.insert(key)
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
                errorMessage = "No foods found for \"\(trimmed)\"."
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
    
    /// Returns true if the product has incomplete nutrition data and should be enriched.
    func needsDetailEnrichment(_ product: FoodProduct) -> Bool {
        return !product.hasValidMacros
    }
    
    /// Enriches a product by fetching detailed nutrition data from USDA or OFF.
    /// Returns the enriched product on success, or nil on failure.
    func enrichFoodDetail(_ product: FoodProduct) async -> FoodProduct? {
        errorMessage = nil
        
        let task = Task.detached(priority: .userInitiated) { () -> Result<FoodProduct?, Error> in
            do {
                try Task.checkCancellation()
                
                if product.barcode.starts(with: "usda-"),
                   let fdcIdStr = product.barcode.split(separator: "-").last,
                   let fdcId = Int(fdcIdStr) {
                    if let enriched = try await Self.fetchUSDAFood(fdcId: fdcId) {
                        return .success(enriched)
                    }
                }
                
                if !product.barcode.starts(with: "usda-"), !product.barcode.starts(with: "off-"), !product.barcode.starts(with: "nix-") {
                    if let enriched = try await Self.lookupOpenFoodFacts(barcode: product.barcode) {
                        return .success(enriched)
                    }
                    if let enriched = try await Self.lookupUSDA(barcode: product.barcode) {
                        return .success(enriched)
                    }
                }
                
                return .success(nil)
            } catch is CancellationError {
                return .failure(CancellationError())
            } catch {
                return .failure(error)
            }
        }
        
        let outcome = await task.value
        
        switch outcome {
        case .success(let enriched):
            return enriched
        case .failure(let error):
            if error is CancellationError {
                return nil
            }
            errorMessage = "Could not load details. Check your connection."
            return nil
        }
    }
    
    // MARK: - Brand Detection & Ranking
    
    /// Extract brand query from search string (e.g. "mcdonalds" from "mcdonalds big mac")
    nonisolated private static func extractBrandQuery(_ query: String) -> String? {
        let normalized = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if query starts with or is a known brand
        let knownBrands = [
            "mcdonalds", "mcdonald's", "mcd", "chipotle", "starbucks",
            "wendy's", "wendys", "taco bell", "subway", "burger king",
            "kfc", "pizza hut", "dominos", "domino's", "panera", "chick-fil-a",
            "five guys", "in-n-out", "shake shack", "dunkin", "krispy kreme"
        ]
        
        for brand in knownBrands {
            if normalized == brand || normalized.hasPrefix(brand + " ") {
                return brand
            }
        }
        
        // If query is short (likely a brand name itself), treat it as a brand
        if normalized.count <= 15 && !normalized.contains(" ") {
            return normalized
        }
        
        return nil
    }
    
    /// Rank and filter OFF results based on brand affinity
    nonisolated private static func rankAndFilterResults(_ products: [FoodProduct], query: String, brandQuery: String?) -> [FoodProduct] {
        guard let brand = brandQuery else {
            return products
        }
        
        let brandNorm = brand.lowercased().replacingOccurrences(of: "'", with: "")
        
        var branded: [FoodProduct] = []
        var weakMatch: [FoodProduct] = []
        
        for product in products {
            let productName = product.name.lowercased()
            let productBrand = (product.brand ?? "").lowercased().replacingOccurrences(of: "'", with: "")
            
            // Strong brand match: brand field matches or name starts with brand
            if productBrand.contains(brandNorm) || productName.hasPrefix(brandNorm) || productName.hasPrefix(brand.lowercased()) {
                branded.append(product)
            }
            // Weak match: brand appears somewhere in name
            else if productName.contains(brandNorm) {
                weakMatch.append(product)
            }
            // Drop: completely unrelated
        }
        
        // For brand queries, strongly prefer branded results
        if !branded.isEmpty {
            return branded + weakMatch.prefix(3)
        }
        
        // If no strong matches, return weak matches but limit them
        return Array(weakMatch.prefix(10))
    }
    
    /// Dedupe key for products (name + brand)
    nonisolated private static func dedupeKey(_ product: FoodProduct) -> String {
        let name = product.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let brand = (product.brand ?? "").lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(brand):\(name)"
    }
    
    // MARK: - Curated Chain Seed
    
    nonisolated private static func searchCuratedChains(query: String, brandQuery: String?) -> [FoodProduct] {
        let norm = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Only return curated hits if the query clearly targets that chain
        guard let brand = brandQuery else { return [] }
        
        let curatedItems: [(brand: String, items: [(name: String, cal: Double, protein: Double, carbs: Double, fat: Double, serving: String, grams: Double)])] = [
            ("mcdonalds", [
                ("Big Mac", 563, 26, 46, 30, "1 sandwich", 219),
                ("Quarter Pounder with Cheese", 520, 30, 41, 26, "1 burger", 199),
                ("Chicken McNuggets (10 pc)", 420, 24, 25, 24, "10 pieces", 163),
                ("Medium Fries", 320, 4, 43, 15, "medium", 111),
                ("McChicken", 400, 14, 39, 21, "1 sandwich", 146)
            ]),
            ("chipotle", [
                ("Chicken Burrito Bowl", 520, 40, 42, 19, "1 bowl", 450),
                ("Steak Burrito", 790, 43, 80, 28, "1 burrito", 600),
                ("Chicken Burrito", 750, 41, 78, 25, "1 burrito", 590),
                ("Carnitas Tacos (3)", 510, 30, 42, 21, "3 tacos", 390),
                ("Guacamole", 230, 2, 8, 22, "side", 113)
            ]),
            ("starbucks", [
                ("Pike Place Roast (Grande)", 5, 1, 0, 0, "grande", 473),
                ("Caffe Latte (Grande)", 190, 13, 18, 7, "grande", 473),
                ("Bacon Egg & Gouda Breakfast Sandwich", 370, 18, 36, 16, "1 sandwich", 147),
                ("Pumpkin Spice Latte (Grande)", 380, 14, 50, 14, "grande", 473),
                ("Blueberry Muffin", 350, 5, 55, 11, "1 muffin", 113)
            ]),
            ("wendys", [
                ("Dave's Single", 570, 29, 39, 34, "1 burger", 246),
                ("Spicy Chicken Sandwich", 510, 28, 50, 20, "1 sandwich", 215),
                ("10 Piece Nuggets", 420, 21, 24, 26, "10 pieces", 150),
                ("Medium Fries", 350, 5, 45, 17, "medium", 117)
            ]),
            ("taco bell", [
                ("Crunchy Taco", 170, 8, 13, 10, "1 taco", 78),
                ("Bean Burrito", 380, 14, 54, 10, "1 burrito", 198),
                ("Chicken Quesadilla", 510, 27, 38, 26, "1 quesadilla", 184),
                ("Nachos BellGrande", 740, 19, 77, 38, "1 serving", 308)
            ]),
            ("subway", [
                ("Turkey Breast 6-inch", 280, 18, 40, 4.5, "6-inch", 216),
                ("Italian B.M.T. 6-inch", 410, 19, 42, 18, "6-inch", 236),
                ("Veggie Delite 6-inch", 230, 9, 40, 2.5, "6-inch", 204),
                ("Footlong Meatball Marinara", 960, 44, 120, 36, "footlong", 568)
            ])
        ]
        
        var results: [FoodProduct] = []
        for (chainBrand, items) in curatedItems {
            if brand.lowercased().contains(chainBrand) || chainBrand.contains(brand.lowercased()) {
                for item in items {
                    let grams = item.grams
                    results.append(FoodProduct(
                        barcode: "curated-\(chainBrand)-\(item.name.replacingOccurrences(of: " ", with: "-").lowercased())",
                        name: item.name,
                        servingSize: item.serving,
                        caloriesPer100g: (item.cal / grams) * 100,
                        proteinPer100g: (item.protein / grams) * 100,
                        carbsPer100g: (item.carbs / grams) * 100,
                        fatPer100g: (item.fat / grams) * 100,
                        servingSizeGrams: grams,
                        brand: chainBrand.capitalized,
                        source: .curated
                    ))
                }
                break
            }
        }
        return results
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
    
    nonisolated private static func fetchUSDAFood(fdcId: Int) async throws -> FoodProduct? {
        let apiKey = "DEMO_KEY"
        guard let url = URL(string: "https://api.nal.usda.gov/fdc/v1/food/\(fdcId)?api_key=\(apiKey)") else {
            return nil
        }
        
        let (data, _) = try await session.data(from: url)
        try Task.checkCancellation()
        let detail = try JSONDecoder().decode(USDAFoodDetail.self, from: data)
        return makeUSDADetailProduct(detail)
    }
    
    nonisolated private static func searchOpenFoodFacts(query: String) async throws -> [FoodProduct] {
        var components = URLComponents(string: "https://world.openfoodfacts.org/cgi/search.pl")!
        // Include brands, brands_tags for better filtering
        components.queryItems = [
            URLQueryItem(name: "search_terms", value: query),
            URLQueryItem(name: "search_simple", value: "1"),
            URLQueryItem(name: "action", value: "process"),
            URLQueryItem(name: "json", value: "1"),
            URLQueryItem(name: "page_size", value: "30"),
            URLQueryItem(name: "fields", value: "code,product_name,brands,brands_tags,serving_size,serving_quantity,nutriments,countries_tags")
        ]
        guard let url = components.url else { return [] }
        
        let (data, _) = try await session.data(from: url)
        try Task.checkCancellation()
        
        let response = try JSONDecoder().decode(OFFSearchResponse.self, from: data)
        var out: [FoodProduct] = []
        for product in response.products ?? [] {
            guard let nutriments = product.nutriments,
                  let item = makeOFFProduct(product, nutriments: nutriments, fallbackBarcode: "off-search") else {
                continue
            }
            out.append(item)
            if out.count >= 30 { break }
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
    
    nonisolated private static func searchNutritionix(query: String) async throws -> [FoodProduct] {
        guard let appId = nutritionixAppId, let apiKey = nutritionixApiKey else {
            return []
        }
        
        guard let url = URL(string: "https://trackapi.nutritionix.com/v2/search/instant") else {
            return []
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(appId, forHTTPHeaderField: "x-app-id")
        request.setValue(apiKey, forHTTPHeaderField: "x-app-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["query": query]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await session.data(for: request)
        try Task.checkCancellation()
        
        let response = try JSONDecoder().decode(NutritionixSearchResponse.self, from: data)
        var out: [FoodProduct] = []
        
        // Branded foods
        for item in response.branded ?? [] {
            if let product = makeNutritionixProduct(item) {
                out.append(product)
                if out.count >= 15 { break }
            }
        }
        
        // Common foods (restaurant items)
        for item in response.common ?? [] {
            // For common items, we need to fetch details (skip for now to keep it fast)
            // Could enhance later with natural language endpoint
        }
        
        return out
    }
    
    nonisolated private static func makeOFFProduct(_ product: OFFProduct, nutriments: OFFNutriments, fallbackBarcode: String) -> FoodProduct? {
        let calories = nutriments.energyKcal100g ?? 0
        let protein = nutriments.proteins100g ?? 0
        let carbs = nutriments.carbohydrates100g ?? 0
        let fat = nutriments.fat100g ?? 0
        guard calories > 0 || protein > 0 || carbs > 0 || fat > 0 else { return nil }
        let name = product.productName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !name.isEmpty else { return nil }
        
        let brand = product.brands?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return FoodProduct(
            barcode: product.code ?? fallbackBarcode,
            name: name,
            servingSize: product.servingSize ?? "100g",
            caloriesPer100g: calories,
            proteinPer100g: protein,
            carbsPer100g: carbs,
            fatPer100g: fat,
            servingSizeGrams: product.servingQuantityValue,
            brand: brand,
            source: .openFoodFacts
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
            servingSizeGrams: servingSize,
            brand: nil,
            source: .usda
        )
    }
    
    nonisolated private static func makeUSDADetailProduct(_ detail: USDAFoodDetail) -> FoodProduct? {
        let nutrients = detail.foodNutrients
        let calories = nutrients.first(where: { $0.nutrient?.id == 1008 })?.amount ?? 0
        let protein = nutrients.first(where: { $0.nutrient?.id == 1003 })?.amount ?? 0
        let carbs = nutrients.first(where: { $0.nutrient?.id == 1005 })?.amount ?? 0
        let fat = nutrients.first(where: { $0.nutrient?.id == 1004 })?.amount ?? 0
        guard calories > 0 || protein > 0 || carbs > 0 || fat > 0 else { return nil }
        let servingSize = detail.servingSize ?? 100
        return FoodProduct(
            barcode: "usda-\(detail.fdcId)",
            name: detail.description,
            servingSize: "\(Int(servingSize))g",
            caloriesPer100g: calories,
            proteinPer100g: protein,
            carbsPer100g: carbs,
            fatPer100g: fat,
            servingSizeGrams: servingSize,
            brand: nil,
            source: .usda
        )
    }
    
    nonisolated private static func makeNutritionixProduct(_ item: NutritionixBrandedItem) -> FoodProduct? {
        let calories = item.nfCalories ?? 0
        let protein = item.nfProtein ?? 0
        let carbs = item.nfTotalCarbohydrate ?? 0
        let fat = item.nfTotalFat ?? 0
        let servingGrams = item.servingWeightGrams ?? 100
        
        // Convert to per 100g
        let cal100 = (calories / servingGrams) * 100
        let pro100 = (protein / servingGrams) * 100
        let carb100 = (carbs / servingGrams) * 100
        let fat100 = (fat / servingGrams) * 100
        
        guard cal100 > 0 || pro100 > 0 || carb100 > 0 || fat100 > 0 else { return nil }
        
        let name = item.foodName ?? item.brandName ?? "Unknown"
        let brand = item.brandName
        let servingSize = item.servingUnit ?? "\(Int(servingGrams))g"
        
        return FoodProduct(
            barcode: "nix-\(item.nixItemId ?? "")",
            name: name,
            servingSize: servingSize,
            caloriesPer100g: cal100,
            proteinPer100g: pro100,
            carbsPer100g: carb100,
            fatPer100g: fat100,
            servingSizeGrams: servingGrams,
            brand: brand,
            source: .nutritionix
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
    let brands: String?
    let brandsTags: [String]?
    let servingSize: String?
    let servingQuantity: FlexibleDouble?
    let nutriments: OFFNutriments?
    let countriesTags: [String]?
    
    enum CodingKeys: String, CodingKey {
        case code
        case productName = "product_name"
        case brands
        case brandsTags = "brands_tags"
        case servingSize = "serving_size"
        case servingQuantity = "serving_quantity"
        case nutriments
        case countriesTags = "countries_tags"
    }
    
    var servingQuantityValue: Double? {
        servingQuantity?.value
    }
}

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
    let amount: Double?
    let nutrient: USDANutrientInfo?
    
    var resolvedId: Int? {
        if let nutrientId { return nutrientId }
        if let nutrientNumber, let n = Int(nutrientNumber) { return n }
        return nil
    }
}

struct USDANutrientInfo: Codable, Sendable {
    let id: Int?
}

struct USDAFoodDetail: Codable, Sendable {
    let fdcId: Int
    let description: String
    let servingSize: Double?
    let foodNutrients: [USDANutrient]
}

// MARK: - Nutritionix DTOs

struct NutritionixSearchResponse: Codable, Sendable {
    let common: [NutritionixCommonItem]?
    let branded: [NutritionixBrandedItem]?
}

struct NutritionixCommonItem: Codable, Sendable {
    let foodName: String?
    let servingUnit: String?
    let tagId: String?
    
    enum CodingKeys: String, CodingKey {
        case foodName = "food_name"
        case servingUnit = "serving_unit"
        case tagId = "tag_id"
    }
}

struct NutritionixBrandedItem: Codable, Sendable {
    let foodName: String?
    let brandName: String?
    let servingUnit: String?
    let servingWeightGrams: Double?
    let nfCalories: Double?
    let nfTotalFat: Double?
    let nfTotalCarbohydrate: Double?
    let nfProtein: Double?
    let nixItemId: String?
    
    enum CodingKeys: String, CodingKey {
        case foodName = "food_name"
        case brandName = "brand_name"
        case servingUnit = "serving_unit"
        case servingWeightGrams = "serving_weight_grams"
        case nfCalories = "nf_calories"
        case nfTotalFat = "nf_total_fat"
        case nfTotalCarbohydrate = "nf_total_carbohydrate"
        case nfProtein = "nf_protein"
        case nixItemId = "nix_item_id"
    }
}
