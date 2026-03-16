import Foundation

enum DailyGoals {
    static let defaultCalories: Double = 2000
    static let defaultProtein: Double  = 150
    static let defaultCarbs: Double    = 200
    static let defaultFat: Double      = 65

    enum Keys {
        static let calories = "goals.calories"
        static let protein  = "goals.protein"
        static let carbs    = "goals.carbs"
        static let fat      = "goals.fat"
    }
}
