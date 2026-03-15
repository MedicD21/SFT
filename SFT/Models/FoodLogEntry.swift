import Foundation
import SwiftData

@Model
final class FoodLogEntry {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var consumedAt: Date
    var mealRawValue: String
    var sourceRawValue: String
    var name: String
    var brand: String
    var servingDescription: String
    var servings: Double
    var notes: String
    var barcode: String
    var usdaFDCID: Int?
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var fiber: Double
    var sugar: Double
    var sodium: Double
    var healthKitSyncedAt: Date?

    init(draft: FoodDraft) {
        id = draft.id
        createdAt = .now
        consumedAt = draft.consumedAt
        mealRawValue = draft.meal.rawValue
        sourceRawValue = draft.source.rawValue
        name = draft.name
        brand = draft.brand
        servingDescription = draft.servingDescription
        servings = draft.servings
        notes = draft.notes
        barcode = draft.barcode
        usdaFDCID = draft.usdaFDCID
        calories = draft.nutrition.calories
        protein = draft.nutrition.protein
        carbs = draft.nutrition.carbs
        fat = draft.nutrition.fat
        fiber = draft.nutrition.fiber
        sugar = draft.nutrition.sugar
        sodium = draft.nutrition.sodium
        healthKitSyncedAt = nil
    }

    var meal: MealSlot {
        get { MealSlot(rawValue: mealRawValue) ?? .snack }
        set { mealRawValue = newValue.rawValue }
    }

    var source: FoodSourceKind {
        get { FoodSourceKind(rawValue: sourceRawValue) ?? .manual }
        set { sourceRawValue = newValue.rawValue }
    }

    var nutrition: NutritionFacts {
        get {
            NutritionFacts(
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat,
                fiber: fiber,
                sugar: sugar,
                sodium: sodium
            )
        }
        set {
            calories = newValue.calories
            protein = newValue.protein
            carbs = newValue.carbs
            fat = newValue.fat
            fiber = newValue.fiber
            sugar = newValue.sugar
            sodium = newValue.sodium
        }
    }

    var displayTitle: String {
        brand.nilIfBlank.map { "\(name) • \($0)" } ?? name
    }
}

