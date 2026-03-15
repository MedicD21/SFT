import Foundation
import HealthKit

actor HealthKitService {
    private let store = HKHealthStore()

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw ServiceError.unsupportedDevice
        }

        let shareTypes = Set(nutritionTypes.map { $0 as HKSampleType })
        let readTypes = Set(nutritionTypes.map { $0 as HKObjectType })
        try await store.requestAuthorization(toShare: shareTypes, read: readTypes)
    }

    func save(_ draft: FoodDraft) async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw ServiceError.unsupportedDevice
        }

        let samples = buildSamples(for: draft)
        guard !samples.isEmpty else { return }
        try await store.save(samples)
    }

    private var nutritionTypes: [HKQuantityType] {
        [
            HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed),
            HKQuantityType.quantityType(forIdentifier: .dietaryProtein),
            HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates),
            HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal),
            HKQuantityType.quantityType(forIdentifier: .dietaryFiber),
            HKQuantityType.quantityType(forIdentifier: .dietarySugar),
            HKQuantityType.quantityType(forIdentifier: .dietarySodium)
        ]
        .compactMap { $0 }
    }

    private func buildSamples(for draft: FoodDraft) -> [HKQuantitySample] {
        let metadata: [String: Any] = [
            HKMetadataKeyFoodType: draft.displayTitle,
            HKMetadataKeySyncIdentifier: draft.id.uuidString,
            HKMetadataKeySyncVersion: 1,
            HKMetadataKeyWasUserEntered: true
        ]

        let date = draft.consumedAt
        var samples: [HKQuantitySample] = []

        if draft.nutrition.calories > 0,
           let type = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) {
            samples.append(HKQuantitySample(
                type: type,
                quantity: HKQuantity(unit: .kilocalorie(), doubleValue: draft.nutrition.calories),
                start: date,
                end: date,
                metadata: metadata
            ))
        }

        if draft.nutrition.protein > 0,
           let type = HKQuantityType.quantityType(forIdentifier: .dietaryProtein) {
            samples.append(makeGramSample(type: type, value: draft.nutrition.protein, date: date, metadata: metadata))
        }

        if draft.nutrition.carbs > 0,
           let type = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates) {
            samples.append(makeGramSample(type: type, value: draft.nutrition.carbs, date: date, metadata: metadata))
        }

        if draft.nutrition.fat > 0,
           let type = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal) {
            samples.append(makeGramSample(type: type, value: draft.nutrition.fat, date: date, metadata: metadata))
        }

        if draft.nutrition.fiber > 0,
           let type = HKQuantityType.quantityType(forIdentifier: .dietaryFiber) {
            samples.append(makeGramSample(type: type, value: draft.nutrition.fiber, date: date, metadata: metadata))
        }

        if draft.nutrition.sugar > 0,
           let type = HKQuantityType.quantityType(forIdentifier: .dietarySugar) {
            samples.append(makeGramSample(type: type, value: draft.nutrition.sugar, date: date, metadata: metadata))
        }

        if draft.nutrition.sodium > 0,
           let type = HKQuantityType.quantityType(forIdentifier: .dietarySodium) {
            samples.append(HKQuantitySample(
                type: type,
                quantity: HKQuantity(unit: .gramUnit(with: .milli), doubleValue: draft.nutrition.sodium),
                start: date,
                end: date,
                metadata: metadata
            ))
        }

        return samples
    }

    private func makeGramSample(
        type: HKQuantityType,
        value: Double,
        date: Date,
        metadata: [String: Any]
    ) -> HKQuantitySample {
        HKQuantitySample(
            type: type,
            quantity: HKQuantity(unit: .gram(), doubleValue: value),
            start: date,
            end: date,
            metadata: metadata
        )
    }
}
