import Foundation

struct NutritionFacts: Codable, Hashable, Sendable {
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var fiber: Double
    var sugar: Double
    var sodium: Double

    static let zero = NutritionFacts(
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        fiber: 0,
        sugar: 0,
        sodium: 0
    )

    func scaled(by factor: Double) -> NutritionFacts {
        NutritionFacts(
            calories: calories * factor,
            protein: protein * factor,
            carbs: carbs * factor,
            fat: fat * factor,
            fiber: fiber * factor,
            sugar: sugar * factor,
            sodium: sodium * factor
        )
    }

    mutating func add(_ other: NutritionFacts) {
        calories += other.calories
        protein += other.protein
        carbs += other.carbs
        fat += other.fat
        fiber += other.fiber
        sugar += other.sugar
        sodium += other.sodium
    }

    static func + (lhs: NutritionFacts, rhs: NutritionFacts) -> NutritionFacts {
        var combined = lhs
        combined.add(rhs)
        return combined
    }
}

