import SwiftUI

struct NutritionEditorView: View {
    @Binding var nutrition: NutritionFacts

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            numberField("Calories", value: binding(for: \.calories), accent: AppTheme.ember, suffix: nil, fractionDigits: 0...0)
            numberField("Protein", value: binding(for: \.protein), accent: AppTheme.jade)
            numberField("Carbs", value: binding(for: \.carbs), accent: AppTheme.gold)
            numberField("Fat", value: binding(for: \.fat), accent: AppTheme.ember)
            numberField("Fiber", value: binding(for: \.fiber), accent: AppTheme.jade)
            numberField("Sugar", value: binding(for: \.sugar), accent: AppTheme.gold)
            numberField("Sodium", value: binding(for: \.sodium), accent: AppTheme.ember, suffix: "mg", fractionDigits: 0...0)
        }
    }

    private func binding(for keyPath: WritableKeyPath<NutritionFacts, Double>) -> Binding<Double> {
        Binding(
            get: { nutrition[keyPath: keyPath] },
            set: { nutrition[keyPath: keyPath] = max(0, $0) }
        )
    }

    private func numberField(
        _ title: String,
        value: Binding<Double>,
        accent: Color,
        suffix: String? = "g",
        fractionDigits: ClosedRange<Int> = 0...1
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.mist)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                TextField("0", value: value, format: .number.precision(.fractionLength(fractionDigits)))
                    .keyboardType(.decimalPad)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)

                if let suffix {
                    Text(suffix)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AppTheme.mist)
                }
            }
        }
        .padding(14)
        .background(accent.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(accent.opacity(0.18), lineWidth: 1)
        )
    }
}
