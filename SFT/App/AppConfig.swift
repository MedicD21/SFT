import Foundation

struct AppConfig: Sendable {
    static let defaultPhotoModel = "anthropic/claude-sonnet-4.6"

    let openRouterAPIKey: String?
    let openRouterAppName: String
    let openRouterHTTPReferer: String?
    let openRouterPhotoModel: String
    let usdaAPIKey: String

    init(bundle: Bundle = .main) {
        openRouterAPIKey = bundle.trimmedString(forInfoDictionaryKey: "OpenRouterAPIKey")
        openRouterAppName = bundle.trimmedString(forInfoDictionaryKey: "OpenRouterAppName") ?? "SFT"
        openRouterHTTPReferer = bundle.trimmedString(forInfoDictionaryKey: "OpenRouterHTTPReferer")
        openRouterPhotoModel = bundle.trimmedString(forInfoDictionaryKey: "OpenRouterPhotoModel") ?? Self.defaultPhotoModel
        usdaAPIKey = bundle.trimmedString(forInfoDictionaryKey: "USDAAPIKey") ?? "DEMO_KEY"
    }

    var isPhotoAnalysisConfigured: Bool {
        guard let openRouterAPIKey else { return false }
        return !openRouterAPIKey.isEmpty
    }
}

private extension Bundle {
    func trimmedString(forInfoDictionaryKey key: String) -> String? {
        guard let rawValue = object(forInfoDictionaryKey: key) as? String else {
            return nil
        }

        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed.hasPrefix("$(") {
            return nil
        }

        return trimmed
    }
}

