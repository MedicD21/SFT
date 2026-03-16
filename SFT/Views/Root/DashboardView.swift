import SwiftData
import SwiftUI

struct DashboardView: View {
    @Environment(\.appServices) private var services
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FoodLogEntry.consumedAt, order: .reverse) private var entries: [FoodLogEntry]

    @State private var activeAddMode: AddFoodMode?
    @State private var isHealthKitRequestRunning = false
    @State private var entryToEdit: FoodLogEntry?
    @State private var pendingDelete: FoodLogEntry?
    @State private var undoTask: Task<Void, Never>?

    @AppStorage(DailyGoals.Keys.calories) private var goalCalories = DailyGoals.defaultCalories
    @AppStorage(DailyGoals.Keys.protein)  private var goalProtein  = DailyGoals.defaultProtein
    @AppStorage(DailyGoals.Keys.carbs)    private var goalCarbs    = DailyGoals.defaultCarbs
    @AppStorage(DailyGoals.Keys.fat)      private var goalFat      = DailyGoals.defaultFat
    @State private var isGoalsEditorPresented = false

    private var todayEntries: [FoodLogEntry] {
        entries.filter { Calendar.current.isDate($0.consumedAt, inSameDayAs: .now) }
    }

    private var totals: NutritionFacts {
        todayEntries.reduce(into: .zero) { partial, entry in
            partial.add(entry.nutrition)
        }
    }

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            backgroundLayer
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    hero

                    VStack(alignment: .leading, spacing: 18) {
                        macroGrid
                        quickActions
                        configCards
                        mealsSection
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 24)
                }
            }
            .ignoresSafeArea(edges: .top)
            .scrollIndicators(.hidden)
        }
        .safeAreaInset(edge: .bottom) {
            addButtonBar
        }
        .fullScreenCover(item: $activeAddMode) { mode in
            AddFoodSheet(initialMode: mode)
        }
        .sheet(item: $entryToEdit) { entry in
            FoodComposerView(draft: .fromEntry(entry), editingEntry: entry) {}
                .presentationDetents([.large])
        }
        .sheet(isPresented: $isGoalsEditorPresented) {
            GoalsEditorView()
                .presentationDetents([.large])
        }
        .overlay(alignment: .top) {
            if pendingDelete != nil {
                undoBanner
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .animation(.spring(duration: 0.35), value: pendingDelete != nil)
    }

    private var backgroundLayer: some View {
        ZStack {
            AppTheme.pageGradient

            Circle()
                .fill(AppTheme.jade.opacity(0.18))
                .frame(width: 320, height: 320)
                .blur(radius: 90)
                .offset(x: -120, y: -220)

            Circle()
                .fill(AppTheme.ember.opacity(0.16))
                .frame(width: 280, height: 280)
                .blur(radius: 100)
                .offset(x: 150, y: -140)
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                Text(Formatting.dayHeadline(.now))
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundStyle(AppTheme.gold)

                Spacer(minLength: 12)

                Button {
                    isGoalsEditorPresented = true
                } label: {
                    Label("Goals", systemImage: "target")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppTheme.gold)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Text("Simple Food Tracking")
                .font(.system(size: 42, weight: .bold, design: .serif))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text("Manual entry, USDA barcode lookup, and Anthropic-powered photo analysis in one focused iPhone app.")
                .font(.body)
                .foregroundStyle(AppTheme.mist)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                heroPill("USDA", tint: AppTheme.jade)
                heroPill("Barcode", tint: AppTheme.ember)
                heroPill("Anthropic", tint: AppTheme.gold)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .padding(.bottom, 24)
        .background(heroBackground)
        .overlay(
            UnevenRoundedRectangle(
                cornerRadii: .init(
                    topLeading: 0,
                    bottomLeading: 32,
                    bottomTrailing: 32,
                    topTrailing: 0
                ),
                style: .continuous
            )
                .stroke(AppTheme.stroke, lineWidth: 1)
        )
        .clipShape(
            UnevenRoundedRectangle(
                cornerRadii: .init(
                    topLeading: 0,
                    bottomLeading: 32,
                    bottomTrailing: 32,
                    topTrailing: 0
                ),
                style: .continuous
            )
        )
    }

    private var macroGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            StatChip(title: "Calories", value: Formatting.calories(totals.calories), tint: AppTheme.ember, systemImage: "flame.fill", current: totals.calories, goal: goalCalories)
            StatChip(title: "Protein",  value: Formatting.grams(totals.protein),     tint: AppTheme.jade,  systemImage: "bolt.heart.fill", current: totals.protein, goal: goalProtein)
            StatChip(title: "Carbs",    value: Formatting.grams(totals.carbs),       tint: AppTheme.gold,  systemImage: "leaf.fill",       current: totals.carbs,   goal: goalCarbs)
            StatChip(title: "Fat",      value: Formatting.grams(totals.fat),         tint: AppTheme.ember, systemImage: "drop.fill",       current: totals.fat,     goal: goalFat)
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

    private var addButton: some View {
        Button {
            activeAddMode = .search
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3.weight(.bold))
                Text("Add Food")
                    .font(.title3.weight(.bold))
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(AppTheme.gold)
            .clipShape(Capsule())
            .shadow(color: AppTheme.gold.opacity(0.28), radius: 18, x: 0, y: 10)
        }
        .buttonStyle(.plain)
    }

    private var addButtonBar: some View {
        addButton
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 8)
            .background(.ultraThinMaterial)
    }

    private var heroBackground: some View {
        ZStack {
            AppTheme.heroGradient

            Circle()
                .fill(AppTheme.jade.opacity(0.2))
                .frame(width: 260, height: 260)
                .blur(radius: 70)
                .offset(x: -90, y: -90)

            Circle()
                .fill(AppTheme.ember.opacity(0.18))
                .frame(width: 240, height: 240)
                .blur(radius: 80)
                .offset(x: 130, y: 40)
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
                                FoodLogRow(entry: entry)
                                    .opacity(pendingDelete?.id == entry.id ? 0.35 : 1.0)
                                    .animation(.easeInOut(duration: 0.2), value: pendingDelete?.id)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            scheduleDelete(entry)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        .tint(AppTheme.error)
                                    }
                                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                        Button {
                                            entryToEdit = entry
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(AppTheme.jade)
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture { entryToEdit = entry }
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

    private func heroPill(_ title: String, tint: Color) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(tint.opacity(0.16))
            .clipShape(Capsule())
    }

    @MainActor
    private func requestHealthKitAccess() async {
        isHealthKitRequestRunning = true
        defer { isHealthKitRequestRunning = false }
        try? await services.healthKit.requestAuthorization()
    }

    private var undoBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "trash.fill")
                .foregroundStyle(AppTheme.error)
            Text("Entry deleted")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            Spacer()
            Button("Undo") {
                undoTask?.cancel()
                undoTask = nil
                withAnimation { pendingDelete = nil }
            }
            .font(.subheadline.weight(.bold))
            .foregroundStyle(AppTheme.jade)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.top, 60)
    }

    private func scheduleDelete(_ entry: FoodLogEntry) {
        undoTask?.cancel()
        withAnimation { pendingDelete = entry }
        undoTask = Task {
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                if let e = pendingDelete {
                    modelContext.delete(e)
                    try? modelContext.save()
                    withAnimation { pendingDelete = nil }
                }
            }
        }
    }
}

private struct FoodLogRow: View {
    let entry: FoodLogEntry

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

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.mist.opacity(0.5))
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
