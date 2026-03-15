import SwiftUI

struct AppServices: Sendable {
    let config: AppConfig
    let usda: USDAFoodDataClient
    let photoAnalyzer: OpenRouterFoodPhotoAnalyzer
    let healthKit: HealthKitService

    static let live = AppServices(config: AppConfig())

    init(config: AppConfig) {
        self.config = config
        usda = USDAFoodDataClient(apiKey: config.usdaAPIKey)
        photoAnalyzer = OpenRouterFoodPhotoAnalyzer(config: config)
        healthKit = HealthKitService()
    }
}

private struct AppServicesKey: EnvironmentKey {
    static let defaultValue = AppServices.live
}

extension EnvironmentValues {
    var appServices: AppServices {
        get { self[AppServicesKey.self] }
        set { self[AppServicesKey.self] = newValue }
    }
}

