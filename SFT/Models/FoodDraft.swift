import Foundation

struct FoodDraft: Identifiable, Hashable, Sendable {
    let id: UUID
    var name: String
    var brand: String
    var servingDescription: String
    var servings: Double
    var consumedAt: Date
    var meal: MealSlot
    var source: FoodSourceKind
    var notes: String
    var barcode: String
    var usdaFDCID: Int?
    var nutrition: NutritionFacts

    init(
        id: UUID = UUID(),
        name: String,
        brand: String = "",
        servingDescription: String = "1 serving",
        servings: Double = 1,
        consumedAt: Date = .now,
        meal: MealSlot = .suggested(for: .now),
        source: FoodSourceKind,
        notes: String = "",
        barcode: String = "",
        usdaFDCID: Int? = nil,
        nutrition: NutritionFacts
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.servingDescription = servingDescription
        self.servings = servings
        self.consumedAt = consumedAt
        self.meal = meal
        self.source = source
        self.notes = notes
        self.barcode = barcode
        self.usdaFDCID = usdaFDCID
        self.nutrition = nutrition
    }

    var displayTitle: String {
        brand.nilIfBlank.map { "\(name) • \($0)" } ?? name
    }

    mutating func rescaleNutrition(from oldServings: Double, to newServings: Double) {
        let safeOld = max(oldServings, 0.01)
        let safeNew = max(newServings, 0.01)
        nutrition = nutrition.scaled(by: safeNew / safeOld)
        servings = safeNew
    }

    static func fromUSDA(_ item: FoodSearchItem, source: FoodSourceKind, now: Date = .now) -> FoodDraft {
        FoodDraft(
            name: item.title,
            brand: item.brandName,
            servingDescription: item.servingDescription,
            consumedAt: now,
            meal: .suggested(for: now),
            source: source,
            barcode: item.gtinUpc,
            usdaFDCID: item.fdcId,
            nutrition: item.nutrition
        )
    }
}

