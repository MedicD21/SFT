import SwiftUI

struct GoalsEditorView: View {
    @AppStorage(DailyGoals.Keys.calories) private var calories = DailyGoals.defaultCalories
    @AppStorage(DailyGoals.Keys.protein)  private var protein  = DailyGoals.defaultProtein
    @AppStorage(DailyGoals.Keys.carbs)    private var carbs    = DailyGoals.defaultCarbs
    @AppStorage(DailyGoals.Keys.fat)      private var fat      = DailyGoals.defaultFat
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Daily Targets")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.white)
                            Text("Set your personal goals. Macro chips on the dashboard will show your progress toward each target.")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.mist)
                        }
                    }

                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                        spacing: 12
                    ) {
                        goalField("Calories", value: $calories, suffix: "kcal", accent: AppTheme.ember)
                        goalField("Protein",  value: $protein,  suffix: "g",    accent: AppTheme.jade)
                        goalField("Carbs",    value: $carbs,    suffix: "g",    accent: AppTheme.gold)
                        goalField("Fat",      value: $fat,      suffix: "g",    accent: AppTheme.ember)
                    }
                }
                .padding(20)
            }
            .background(AppTheme.pageGradient.ignoresSafeArea())
            .navigationTitle("Daily Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.gold)
                }
            }
        }
    }

    private func goalField(_ title: String, value: Binding<Double>, suffix: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.mist)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                TextField("0", value: value, format: .number.precision(.fractionLength(0...0)))
                    .keyboardType(.numberPad)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                Text(suffix)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppTheme.mist)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(accent.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(accent.opacity(0.22), lineWidth: 1)
        )
    }
}
