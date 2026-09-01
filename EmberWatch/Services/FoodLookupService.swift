import Foundation

struct FoodProduct: Identifiable, Equatable {
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
    
    func lookupBarcode(_ barcode: String) async -> FoodProduct? {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        if let product = await lookupOpenFoodFacts(barcode: barcode) {
            if product.hasValidMacros {
                return product
            }
        }
        
        if let product = await lookupUSDA(barcode: barcode) {
            if product.hasValidMacros {
                return product
            }
        }
        
        errorMessage = "Not in the database. Add it by hand."
        return nil
    }
    
    private func lookupOpenFoodFacts(barcode: String) async -> FoodProduct? {
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(barcode).json") else {
            return nil
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(OFFResponse.self, from: data)
            
            guard response.status == 1,
                  let product = response.product,
                  let nutriments = product.nutriments else {
                return nil
            }
            
            let calories = nutriments.energyKcal100g ?? 0
            let protein = nutriments.proteins100g ?? 0
            let carbs = nutriments.carbohydrates100g ?? 0
            let fat = nutriments.fat100g ?? 0
            
            guard calories > 0 || protein > 0 || carbs > 0 || fat > 0 else {
                return nil
            }
            
            let servingSize = product.servingSize ?? "100g"
            let servingGrams = product.servingQuantity
            
            return FoodProduct(
                barcode: barcode,
                name: product.productName ?? "Unknown Product",
                servingSize: servingSize,
                caloriesPer100g: calories,
                proteinPer100g: protein,
                carbsPer100g: carbs,
                fatPer100g: fat,
                servingSizeGrams: servingGrams
            )
        } catch {
            print("Open Food Facts lookup failed: \(error)")
            return nil
        }
    }
    
    private func lookupUSDA(barcode: String) async -> FoodProduct? {
        let apiKey = "DEMO_KEY"
        guard let url = URL(string: "https://api.nal.usda.gov/fdc/v1/foods/search?query=\(barcode)&api_key=\(apiKey)") else {
            return nil
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(USDAResponse.self, from: data)
            
            guard let food = response.foods.first else {
                return nil
            }
            
            let nutrients = food.foodNutrients
            let calories = nutrients.first(where: { $0.nutrientId == 1008 })?.value ?? 0
            let protein = nutrients.first(where: { $0.nutrientId == 1003 })?.value ?? 0
            let carbs = nutrients.first(where: { $0.nutrientId == 1005 })?.value ?? 0
            let fat = nutrients.first(where: { $0.nutrientId == 1004 })?.value ?? 0
            
            guard calories > 0 || protein > 0 || carbs > 0 || fat > 0 else {
                return nil
            }
            
            let servingSize = food.servingSize ?? 100
            
            return FoodProduct(
                barcode: barcode,
                name: food.description,
                servingSize: "\(Int(servingSize))g",
                caloriesPer100g: calories,
                proteinPer100g: protein,
                carbsPer100g: carbs,
                fatPer100g: fat,
                servingSizeGrams: servingSize
            )
        } catch {
            print("USDA lookup failed: \(error)")
            return nil
        }
    }
}

struct OFFResponse: Codable {
    let status: Int
    let product: OFFProduct?
}

struct OFFProduct: Codable {
    let productName: String?
    let servingSize: String?
    let servingQuantity: Double?
    let nutriments: OFFNutriments?
    
    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case servingSize = "serving_size"
        case servingQuantity = "serving_quantity"
        case nutriments
    }
}

struct OFFNutriments: Codable {
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

struct USDAResponse: Codable {
    let foods: [USDAFood]
}

struct USDAFood: Codable {
    let description: String
    let servingSize: Double?
    let foodNutrients: [USDANutrient]
}

struct USDANutrient: Codable {
    let nutrientId: Int
    let value: Double
}
