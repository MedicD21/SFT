import SwiftUI

struct USDAFoodSearchView: View {
    @Environment(\.appServices) private var services

    let onSelect: (FoodDraft) -> Void

    @State private var query = ""
    @State private var results: [FoodSearchItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GlassCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Search USDA FoodData Central")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("Text input and branded search both run against the USDA's US-based food database.")
                        .foregroundStyle(AppTheme.mist)
                    TextField("Chicken bowl, yogurt, cold brew...", text: $query)
                        .textInputAutocapitalization(.never)
                        .padding(14)
                        .background(AppTheme.background.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.error)
            }

            if isLoading {
                ProgressView("Searching...")
                    .tint(AppTheme.gold)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if query.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 {
                Text("Start typing to search branded and reference foods.")
                    .foregroundStyle(AppTheme.mist)
            } else if results.isEmpty {
                Text("No matches yet.")
                    .foregroundStyle(AppTheme.mist)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(results) { item in
                        Button {
                            onSelect(FoodDraft.fromUSDA(item, source: .manual))
                        } label: {
                            SearchResultCard(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .task(id: query) {
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.count >= 2 else {
                results = []
                errorMessage = nil
                return
            }

            isLoading = true
            errorMessage = nil

            do {
                try await Task.sleep(for: .milliseconds(350))
                results = try await services.usda.searchFoods(matching: trimmed)
            } catch is CancellationError {
                return
            } catch {
                errorMessage = error.localizedDescription
            }

            isLoading = false
        }
    }
}

private struct SearchResultCard: View {
    let item: FoodSearchItem

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                        if !item.subtitle.isEmpty {
                            Text(item.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.mist)
                        }
                    }

                    Spacer()

                    if !item.dataType.isEmpty {
                        Text(item.dataType)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.gold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AppTheme.gold.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 10) {
                    macroPill("Cal", Formatting.calories(item.nutrition.calories), tint: AppTheme.ember)
                    macroPill("P", Formatting.compactNumber(item.nutrition.protein), tint: AppTheme.jade)
                    macroPill("C", Formatting.compactNumber(item.nutrition.carbs), tint: AppTheme.gold)
                    macroPill("F", Formatting.compactNumber(item.nutrition.fat), tint: AppTheme.ember)
                }
            }
        }
    }

    private func macroPill(_ label: String, _ value: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.caption.weight(.bold))
            Text(value)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(tint.opacity(0.18))
        .clipShape(Capsule())
    }
}

