import SwiftUI

enum AppTheme {
    static let background = Color(red: 0.04, green: 0.05, blue: 0.07)
    static let backgroundSecondary = Color(red: 0.08, green: 0.10, blue: 0.12)
    static let cardBase = Color(red: 0.11, green: 0.13, blue: 0.16)
    static let cardOverlay = Color.white.opacity(0.05)
    static let stroke = Color.white.opacity(0.08)
    static let ember = Color(red: 0.97, green: 0.52, blue: 0.29)
    static let jade = Color(red: 0.22, green: 0.78, blue: 0.68)
    static let gold = Color(red: 0.94, green: 0.82, blue: 0.50)
    static let mist = Color.white.opacity(0.74)
    static let error = Color(red: 0.96, green: 0.44, blue: 0.44)

    static let pageGradient = LinearGradient(
        colors: [
            Color(red: 0.03, green: 0.03, blue: 0.05),
            Color(red: 0.05, green: 0.08, blue: 0.09),
            Color(red: 0.08, green: 0.06, blue: 0.04)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let heroGradient = LinearGradient(
        colors: [
            Color(red: 0.15, green: 0.20, blue: 0.19),
            Color(red: 0.23, green: 0.13, blue: 0.09),
            Color(red: 0.11, green: 0.14, blue: 0.18)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardGradient = LinearGradient(
        colors: [
            cardBase,
            backgroundSecondary
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

