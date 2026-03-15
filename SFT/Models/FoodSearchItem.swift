import Foundation

struct FoodSearchItem: Identifiable, Hashable, Sendable {
    let fdcId: Int
    let name: String
    let brandName: String
    let gtinUpc: String
    let dataType: String
    let servingDescription: String
    let nutrition: NutritionFacts

    var id: Int { fdcId }

    var title: String {
        name.localizedCapitalized
    }

    var subtitle: String {
        [brandName.nilIfBlank, servingDescription.nilIfBlank]
            .compactMap { $0 }
            .joined(separator: " • ")
    }
}

