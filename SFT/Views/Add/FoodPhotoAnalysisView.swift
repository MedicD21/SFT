import PhotosUI
import SwiftUI
import UIKit

struct FoodPhotoAnalysisView: View {
    @Environment(\.appServices) private var services

    let onSelect: (FoodDraft) -> Void

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var previewImage: UIImage?
    @State private var imageData: Data?
    @State private var isCameraPresented = false
    @State private var isAnalyzing = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GlassCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Photo analysis")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("Anthropic vision runs only for photo-to-food estimation through OpenRouter. The result is always reviewable before saving.")
                        .foregroundStyle(AppTheme.mist)
                    Text("Model: \(services.config.openRouterPhotoModel)")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AppTheme.gold)
                }
            }

            if services.config.isPhotoAnalysisConfigured {
                HStack(spacing: 12) {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button {
                            isCameraPresented = true
                        } label: {
                            actionPill("Take Photo", systemImage: "camera.fill", tint: AppTheme.ember)
                        }
                    }

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        actionPill("Choose Photo", systemImage: "photo.stack.fill", tint: AppTheme.jade)
                    }
                }
            } else {
                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("OpenRouter key needed", systemImage: "key.fill")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("Set `OPENROUTER_API_KEY` in `Config/LocalSecrets.xcconfig` to enable photo analysis.")
                            .foregroundStyle(AppTheme.mist)
                    }
                }
            }

            if let previewImage {
                Image(uiImage: previewImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(AppTheme.stroke, lineWidth: 1)
                    )
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.error)
            }

            if let imageData, services.config.isPhotoAnalysisConfigured {
                Button {
                    Task { await analyze(imageData: imageData) }
                } label: {
                    HStack {
                        if isAnalyzing {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(isAnalyzing ? "Analyzing..." : "Analyze Food")
                            .font(.headline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.gold)
                .disabled(isAnalyzing)
            }
        }
        .sheet(isPresented: $isCameraPresented) {
            CameraCaptureView { image in
                updateImage(image)
            }
        }
        .task(id: selectedPhotoItem) {
            guard let selectedPhotoItem else { return }
            do {
                if let data = try await selectedPhotoItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    updateImage(image)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    nonisolated private func actionPill(_ title: String, systemImage: String, tint: Color) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(tint.opacity(0.16))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(tint.opacity(0.22), lineWidth: 1)
            )
    }

    @MainActor
    private func analyze(imageData: Data) async {
        isAnalyzing = true
        errorMessage = nil

        do {
            let draft = try await services.photoAnalyzer.analyzePhoto(imageData: imageData)
            onSelect(draft)
        } catch {
            errorMessage = error.localizedDescription
        }

        isAnalyzing = false
    }

    private func updateImage(_ image: UIImage) {
        previewImage = image
        imageData = image.jpegData(compressionQuality: 0.82)
        errorMessage = nil
    }
}
