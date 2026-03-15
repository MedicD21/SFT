import Foundation

enum Formatting {
    static func compactNumber(_ value: Double, fractionDigits: ClosedRange<Int> = 0...1) -> String {
        value.formatted(.number.precision(.fractionLength(fractionDigits)))
    }

    static func calories(_ value: Double) -> String {
        compactNumber(value, fractionDigits: 0...0)
    }

    static func grams(_ value: Double) -> String {
        "\(compactNumber(value)) g"
    }

    static func milligrams(_ value: Double) -> String {
        "\(compactNumber(value, fractionDigits: 0...0)) mg"
    }

    static func time(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    static func dayHeadline(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        }
        if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        }
        return date.formatted(date: .abbreviated, time: .omitted)
    }
}

extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var cleanedFoodName: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "  ", with: " ")
            .localizedCapitalized
    }
}

