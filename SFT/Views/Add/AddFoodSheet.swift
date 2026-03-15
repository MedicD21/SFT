import SwiftUI

struct AddFoodSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedMode: AddFoodMode
    @State private var draftToCompose: FoodDraft?

    init(initialMode: AddFoodMode) {
        _selectedMode = State(initialValue: initialMode)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Picker("Input method", selection: $selectedMode) {
                        ForEach(AddFoodMode.allCases) { mode in
                            Label(mode.title, systemImage: mode.systemImage)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    switch selectedMode {
                    case .search:
                        USDAFoodSearchView { draft in
                            draftToCompose = draft
                        }
                    case .scan:
                        BarcodeLookupView { draft in
                            draftToCompose = draft
                        }
                    case .photo:
                        FoodPhotoAnalysisView { draft in
                            draftToCompose = draft
                        }
                    }
                }
                .padding(20)
            }
            .background(AppTheme.pageGradient.ignoresSafeArea())
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppTheme.mist)
                }
            }
        }
        .sheet(item: $draftToCompose) { draft in
            FoodComposerView(draft: draft) {
                dismiss()
            }
            .presentationDetents([.large])
        }
    }
}

