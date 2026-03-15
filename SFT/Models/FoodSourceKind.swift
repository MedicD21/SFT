import Foundation

enum FoodSourceKind: String, CaseIterable, Codable, Identifiable, Sendable {
    case manual
    case barcode
    case photo

    var id: String { rawValue }

    var title: String {
        switch self {
        case .manual:
            return "Text"
        case .barcode:
            return "Barcode"
        case .photo:
            return "Photo AI"
        }
    }

    var systemImage: String {
        switch self {
        case .manual:
            return "text.magnifyingglass"
        case .barcode:
            return "barcode.viewfinder"
        case .photo:
            return "camera.macro"
        }
    }
}
