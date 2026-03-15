import SwiftData
import SwiftUI

struct DashboardView: View {
    @Environment(\.appServices) private var services
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FoodLogEntry.consumedAt, order: .reverse) private var entries: [FoodLogEntry]

    @State private var activeAddMode: AddFoodMode?
    @State private var isHealthKitRequestRunning = false

    private var todayEntries: [FoodLogEntry] {
        entries.filter { Calendar.current.isDate($0.consumedAt, inSameDayAs: .now) }
    }

    private var totals: NutritionFacts {
        todayEntries.reduce(into: .zero) { partial, entry in
            partial.add(entry.nutrition)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    hero
                    quickActions
                    configCards
                    mealsSection
                }
                .padding(20)
            }
            .background(AppTheme.pageGradient.ignoresSafeArea())
            .navigationBarHidden(true)
            .safeAreaInset(edge: .bottom) {
                Button {
                    activeAddMode = .search
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Food")
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(AppTheme.gold)
                    .clipShape(Capsule())
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .shadow(color: AppTheme.gold.opacity(0.28), radius: 18, x: 0, y: 10)
                }
                .buttonStyle(.plain)
                .background(.clear)
            }
        }
        .sheet(item: $activeAddMode) { mode in
            AddFoodSheet(initialMode: mode)
                .presentationDetents([.large])
        }
    }

    private var hero: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Formatting.dayHeadline(.now))
                            .font(.system(size: 18, weight: .semibold, design: .serif))
                            .foregroundStyle(AppTheme.gold)
                        Text("Simple Food Tracking")
                            .font(.system(size: 34, weight: .bold, design: .serif))
                            .foregroundStyle(.white)
                        Text("Manual entry, USDA barcode lookup, and Anthropic-powered photo analysis in one focused iPhone app.")
                            .foregroundStyle(AppTheme.mist)
                    }
                    Spacer()
                }

                HStack(spacing: 10) {
                    StatChip(title: "Calories", value: Formatting.calories(totals.calories), tint: AppTheme.ember, systemImage: "flame.fill")
                    StatChip(title: "Protein", value: Formatting.grams(totals.protein), tint: AppTheme.jade, systemImage: "bolt.heart.fill")
                }

                HStack(spacing: 10) {
                    StatChip(title: "Carbs", value: Formatting.grams(totals.carbs), tint: AppTheme.gold, systemImage: "leaf.fill")
                    StatChip(title: "Fat", value: Formatting.grams(totals.fat), tint: AppTheme.ember, systemImage: "drop.fill")
                }
            }
            .background(AppTheme.heroGradient)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
    }

    private var quickActions: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Quick Add")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)

                HStack(spacing: 12) {
                    quickActionButton(for: .search, tint: AppTheme.jade)
                    quickActionButton(for: .scan, tint: AppTheme.ember)
                    quickActionButton(for: .photo, tint: AppTheme.gold)
                }
            }
        }
    }

    @ViewBuilder
    private var configCards: some View {
        if !services.config.isPhotoAnalysisConfigured {
            GlassCard {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Photo analysis setup", systemImage: "sparkles")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("Add an OpenRouter key in `Config/LocalSecrets.xcconfig` to enable Anthropic photo estimates.")
                        .foregroundStyle(AppTheme.mist)
                }
            }
        }

        GlassCard {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("HealthKit Sync")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("Sync calories, macros, fiber, sugar, and sodium when you save an entry.")
                        .foregroundStyle(AppTheme.mist)
                }

                Spacer()

                Button {
                    Task { await requestHealthKitAccess() }
                } label: {
                    if isHealthKitRequestRunning {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Connect")
                            .fontWeight(.semibold)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.jade)
            }
        }
    }

    private var mealsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if todayEntries.isEmpty {
                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Nothing logged yet")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("Start with text search, a barcode scan, or a photo and keep the app focused on food only.")
                            .foregroundStyle(AppTheme.mist)
                    }
                }
            } else {
                ForEach(MealSlot.allCases) { meal in
                    let mealEntries = todayEntries.filter { $0.meal == meal }
                    if !mealEntries.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Label(meal.title, systemImage: meal.systemImage)
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.white)

                            ForEach(mealEntries) { entry in
                                FoodLogRow(entry: entry) {
                                    delete(entry)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func quickActionButton(for mode: AddFoodMode, tint: Color) -> some View {
        Button {
            activeAddMode = mode
        } label: {
            VStack(spacing: 10) {
                Image(systemName: mode.systemImage)
                    .font(.title2.weight(.bold))
                Text(mode.title)
                    .font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(tint.opacity(0.15))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(tint.opacity(0.22), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    @MainActor
    private func requestHealthKitAccess() async {
        isHealthKitRequestRunning = true
        defer { isHealthKitRequestRunning = false }
        try? await services.healthKit.requestAuthorization()
    }

    private func delete(_ entry: FoodLogEntry) {
        modelContext.delete(entry)
        try? modelContext.save()
    }
}

private struct FoodLogRow: View {
    let entry: FoodLogEntry
    let onDelete: () -> Void

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(entry.displayTitle)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)

                        Text([entry.servingDescription.nilIfBlank, Formatting.time(entry.consumedAt)]
                            .compactMap { $0 }
                            .joined(separator: " • "))
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.mist)
                    }

                    Spacer()

                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash")
                            .font(.headline.weight(.semibold))
                    }
                    .tint(AppTheme.error)
                }

                HStack(spacing: 10) {
                    sourceBadge(title: entry.source.title, tint: tint(for: entry.source))
                    if entry.healthKitSyncedAt == nil {
                        sourceBadge(title: "HealthKit pending", tint: AppTheme.gold)
                    }
                }

                HStack(spacing: 8) {
                    macroChip("Cal", Formatting.calories(entry.calories))
                    macroChip("P", Formatting.compactNumber(entry.protein))
                    macroChip("C", Formatting.compactNumber(entry.carbs))
                    macroChip("F", Formatting.compactNumber(entry.fat))
                    if entry.fiber > 0 {
                        macroChip("Fi", Formatting.compactNumber(entry.fiber))
                    }
                }

                if let notes = entry.notes.nilIfBlank {
                    Text(notes)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.mist)
                }
            }
        }
    }

    private func tint(for source: FoodSourceKind) -> Color {
        switch source {
        case .manual: AppTheme.jade
        case .barcode: AppTheme.ember
        case .photo: AppTheme.gold
        }
    }

    private func sourceBadge(title: String, tint: Color) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(tint.opacity(0.16))
            .clipShape(Capsule())
    }

    private func macroChip(_ title: String, _ value: String) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .foregroundStyle(AppTheme.mist)
            Text(value)
                .foregroundStyle(.white)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(AppTheme.background.opacity(0.6))
        .clipShape(Capsule())
    }
}

