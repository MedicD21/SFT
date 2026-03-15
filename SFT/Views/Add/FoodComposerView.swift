import SwiftData
import SwiftUI

struct FoodComposerView: View {
    @Environment(\.appServices) private var services
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let onSaved: () -> Void

    @State private var draft: FoodDraft
    @State private var syncToHealthKit = true
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(draft: FoodDraft, onSaved: @escaping () -> Void) {
        self.onSaved = onSaved
        _draft = State(initialValue: draft)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Review Entry")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.white)

                            TextField("Food name", text: $draft.name)
                                .textFieldStyle(.plain)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.white)

                            TextField("Brand (optional)", text: $draft.brand)
                                .padding(14)
                                .background(AppTheme.background.opacity(0.7))
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                            TextField("Serving description", text: $draft.servingDescription)
                                .padding(14)
                                .background(AppTheme.background.opacity(0.7))
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Servings")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(AppTheme.mist)
                                    TextField("1", value: $draft.servings, format: .number.precision(.fractionLength(0...2)))
                                        .keyboardType(.decimalPad)
                                        .padding(14)
                                        .background(AppTheme.background.opacity(0.7))
                                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Meal")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(AppTheme.mist)
                                    Picker("Meal", selection: $draft.meal) {
                                        ForEach(MealSlot.allCases) { meal in
                                            Text(meal.title).tag(meal)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(14)
                                    .background(AppTheme.background.opacity(0.7))
                                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                }
                            }

                            DatePicker("Logged At", selection: $draft.consumedAt, displayedComponents: [.date, .hourAndMinute])
                                .foregroundStyle(.white)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Nutrition")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.white)
                            NutritionEditorView(nutrition: $draft.nutrition)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Notes")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.white)
                            TextField("Optional notes", text: $draft.notes, axis: .vertical)
                                .lineLimit(3...6)
                                .padding(14)
                                .background(AppTheme.background.opacity(0.7))
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                            Toggle(isOn: $syncToHealthKit) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Sync to HealthKit")
                                        .foregroundStyle(.white)
                                    Text("Writes calories, protein, carbs, fat, fiber, sugar, and sodium.")
                                        .font(.footnote)
                                        .foregroundStyle(AppTheme.mist)
                                }
                            }
                            .tint(AppTheme.jade)
                        }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(AppTheme.error)
                    }
                }
                .padding(20)
            }
            .background(AppTheme.pageGradient.ignoresSafeArea())
            .navigationTitle("Compose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(AppTheme.mist)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Save")
                                .fontWeight(.bold)
                        }
                    }
                    .disabled(isSaving || draft.name.nilIfBlank == nil)
                }
            }
        }
        .onChange(of: draft.servings) { oldValue, newValue in
            guard newValue > 0 else {
                draft.servings = max(oldValue, 1)
                return
            }
            if oldValue != newValue {
                draft.rescaleNutrition(from: oldValue, to: newValue)
            }
        }
    }

    @MainActor
    private func save() async {
        let cleanedName = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedName.isEmpty else {
            errorMessage = "Add a food name before saving."
            return
        }

        isSaving = true
        errorMessage = nil
        draft.name = cleanedName.cleanedFoodName
        draft.brand = draft.brand.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.servingDescription = draft.servingDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.notes = draft.notes.trimmingCharacters(in: .whitespacesAndNewlines)

        let entry = FoodLogEntry(draft: draft)
        modelContext.insert(entry)

        do {
            try modelContext.save()
        } catch {
            errorMessage = "Local save failed: \(error.localizedDescription)"
            isSaving = false
            return
        }

        if syncToHealthKit {
            do {
                try await services.healthKit.requestAuthorization()
                try await services.healthKit.save(draft)
                entry.healthKitSyncedAt = .now
                try? modelContext.save()
            } catch {
                entry.healthKitSyncedAt = nil
                try? modelContext.save()
            }
        }

        isSaving = false
        onSaved()
        dismiss()
    }
}
