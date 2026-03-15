import Foundation

enum ServiceError: LocalizedError {
    case invalidConfiguration(String)
    case invalidRequest
    case invalidResponse
    case apiError(String)
    case decodingError
    case unsupportedDevice

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration(let message): message
        case .invalidRequest: "The request could not be created."
        case .invalidResponse: "The server returned an unexpected response."
        case .apiError(let message): message
        case .decodingError: "The response could not be decoded."
        case .unsupportedDevice: "This feature is not available on this device."
        }
    }
}

