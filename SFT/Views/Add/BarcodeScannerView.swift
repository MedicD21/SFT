import SwiftUI
import VisionKit

struct BarcodeScannerPanel: View {
    let onCodeDetected: (String) -> Void

    var body: some View {
        Group {
            if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                BarcodeScannerView(onCodeDetected: onCodeDetected)
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(AppTheme.stroke, lineWidth: 1)
                    )
            } else {
                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Live scanning unavailable", systemImage: "exclamationmark.triangle.fill")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("You can still type a barcode below and look it up against USDA FoodData Central.")
                            .foregroundStyle(AppTheme.mist)
                    }
                }
            }
        }
    }
}

struct BarcodeScannerView: UIViewControllerRepresentable {
    let onCodeDetected: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onCodeDetected: onCodeDetected)
    }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: [
                .barcode(symbologies: [.ean13, .ean8, .upce, .code128])
            ],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        controller.delegate = context.coordinator
        try? controller.startScanning()
        return controller
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        private let onCodeDetected: (String) -> Void
        private var didEmitCode = false

        init(onCodeDetected: @escaping (String) -> Void) {
            self.onCodeDetected = onCodeDetected
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            handle(addedItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            handle([item])
        }

        private func handle(_ items: [RecognizedItem]) {
            guard !didEmitCode else { return }

            for item in items {
                guard case .barcode(let barcode) = item,
                      let payload = barcode.payloadStringValue?.nilIfBlank else {
                    continue
                }

                didEmitCode = true
                onCodeDetected(payload)

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                    self.didEmitCode = false
                }
                return
            }
        }
    }
}

