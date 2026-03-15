import Foundation

actor USDAFoodDataClient {
    private let apiKey: String
    private let session: URLSession

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    func searchFoods(matching query: String) async throws -> [FoodSearchItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var components = URLComponents(string: "https://api.nal.usda.gov/fdc/v1/foods/search")!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "query", value: trimmed),
            URLQueryItem(name: "pageSize", value: "20")
        ]

        let response: SearchResponse = try await fetch(from: components)
        return response.foods.map(\.asFoodSearchItem)
    }

    func lookupBarcode(_ code: String) async throws -> FoodSearchItem? {
        let sanitized = code.filter(\.isNumber)
        guard sanitized.count >= 8 else { return nil }

        var components = URLComponents(string: "https://api.nal.usda.gov/fdc/v1/foods/search")!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "query", value: sanitized),
            URLQueryItem(name: "pageSize", value: "10"),
            URLQueryItem(name: "dataType", value: "Branded")
        ]

        let response: SearchResponse = try await fetch(from: components)
        let exact = response.foods.first(where: { $0.gtinUpc == sanitized })
        return exact?.asFoodSearchItem ?? response.foods.first?.asFoodSearchItem
    }

    private func fetch<Response: Decodable>(from components: URLComponents) async throws -> Response {
        guard let url = components.url else {
            throw ServiceError.invalidRequest
        }

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            if let apiError = try? JSONDecoder().decode(APIErrorEnvelope.self, from: data) {
                throw ServiceError.apiError(apiError.error.message)
            }
            throw ServiceError.invalidResponse
        }

        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw ServiceError.decodingError
        }
    }
}

private struct SearchResponse: Decodable {
    let foods: [USDAFood]
}

private struct USDAFood: Decodable {
    let fdcId: Int
    let description: String
    let brandName: String?
    let brandOwner: String?
    let gtinUpc: String?
    let dataType: String?
    let householdServingFullText: String?
    let servingSize: Double?
    let servingSizeUnit: String?
    let foodNutrients: [USDANutrient]?

    var asFoodSearchItem: FoodSearchItem {
        FoodSearchItem(
            fdcId: fdcId,
            name: description.cleanedFoodName,
            brandName: (brandName ?? brandOwner ?? "").cleanedFoodName,
            gtinUpc: gtinUpc ?? "",
            dataType: dataType ?? "",
            servingDescription: householdServingFullText?.nilIfBlank
                ?? {
                    guard let servingSize, let servingSizeUnit else { return "1 serving" }
                    return "\(Formatting.compactNumber(servingSize)) \(servingSizeUnit.lowercased())"
                }(),
            nutrition: nutritionFacts
        )
    }

    private var nutritionFacts: NutritionFacts {
        var facts = NutritionFacts.zero
        for nutrient in foodNutrients ?? [] {
            let name = nutrient.nutrientName?.lowercased() ?? ""
            switch name {
            case "energy":
                facts.calories = nutrient.value ?? 0
            case "protein":
                facts.protein = nutrient.value ?? 0
            case "carbohydrate, by difference":
                facts.carbs = nutrient.value ?? 0
            case "total lipid (fat)":
                facts.fat = nutrient.value ?? 0
            case "fiber, total dietary":
                facts.fiber = nutrient.value ?? 0
            case "total sugars":
                facts.sugar = nutrient.value ?? 0
            case "sodium, na":
                facts.sodium = nutrient.value ?? 0
            default:
                continue
            }
        }
        return facts
    }
}

private struct USDANutrient: Decodable {
    let nutrientName: String?
    let value: Double?
    let unitName: String?
}

private struct APIErrorEnvelope: Decodable {
    let error: APIErrorPayload
}

private struct APIErrorPayload: Decodable {
    let code: String?
    let message: String
}
