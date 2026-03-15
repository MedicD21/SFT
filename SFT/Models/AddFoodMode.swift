import Foundation

enum AddFoodMode: String, CaseIterable, Identifiable, Sendable {
    case search
    case scan
    case photo

    var id: String { rawValue }

    var title: String {
        switch self {
        case .search:
            return "Search"
        case .scan:
            return "Scan"
        case .photo:
            return "Photo"
        }
    }

    var systemImage: String {
        switch self {
        case .search:
            return "magnifyingglass"
        case .scan:
            return "barcode.viewfinder"
        case .photo:
            return "camera.fill"
        }
    }
}
