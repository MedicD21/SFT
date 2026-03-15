import XCTest
@testable import SFT

final class NutritionFactsTests: XCTestCase {
    func testScaledNutritionUsesMultiplier() {
        let base = NutritionFacts(
            calories: 400,
            protein: 30,
            carbs: 20,
            fat: 10,
            fiber: 5,
            sugar: 4,
            sodium: 480
        )

        let result = base.scaled(by: 1.5)

        XCTAssertEqual(result.calories, 600)
        XCTAssertEqual(result.protein, 45)
        XCTAssertEqual(result.carbs, 30)
        XCTAssertEqual(result.fat, 15)
        XCTAssertEqual(result.fiber, 7.5)
        XCTAssertEqual(result.sugar, 6)
        XCTAssertEqual(result.sodium, 720)
    }

    func testDraftRescalesCurrentNutrition() {
        var draft = FoodDraft(
            name: "Bowl",
            source: .manual,
            nutrition: NutritionFacts(calories: 500, protein: 25, carbs: 50, fat: 12, fiber: 7, sugar: 5, sodium: 800)
        )

        draft.rescaleNutrition(from: 1, to: 2)

        XCTAssertEqual(draft.servings, 2)
        XCTAssertEqual(draft.nutrition.calories, 1000)
        XCTAssertEqual(draft.nutrition.protein, 50)
    }
}
