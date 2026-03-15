import SwiftUI

struct BarcodeLookupView: View {
    @Environment(\.appServices) private var services

    let onSelect: (FoodDraft) -> Void

    @State private var manualCode = ""
    @State private var isLookingUp = false
    @State private var errorMessage: String?
    @State private var lastScannedCode: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GlassCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Scan or type a barcode")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("We match UPC and GTIN codes against USDA branded food records.")
                        .foregroundStyle(AppTheme.mist)
                }
            }

            BarcodeScannerPanel { code in
                manualCode = code
                lastScannedCode = code
                Task { await lookup(code: code) }
            }

            HStack(spacing: 12) {
                TextField("Enter UPC", text: $manualCode)
                    .keyboardType(.numberPad)
                    .padding(14)
                    .background(AppTheme.background.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                Button("Lookup") {
                    Task { await lookup(code: manualCode) }
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.ember)
            }

            if isLookingUp {
                ProgressView("Looking up \(lastScannedCode ?? manualCode)...")
                    .tint(AppTheme.gold)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.error)
            }
        }
    }

    @MainActor
    private func lookup(code: String) async {
        let cleaned = code.filter(\.isNumber)
        guard cleaned.count >= 8 else {
            errorMessage = "Enter at least 8 digits for a UPC or GTIN."
            return
        }

        isLookingUp = true
        errorMessage = nil

        do {
            if let result = try await services.usda.lookupBarcode(cleaned) {
                onSelect(FoodDraft.fromUSDA(result, source: .barcode))
            } else {
                errorMessage = "No branded USDA match was found for \(cleaned)."
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLookingUp = false
    }
}

