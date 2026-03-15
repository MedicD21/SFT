import Foundation

actor OpenRouterFoodPhotoAnalyzer {
    private let config: AppConfig
    private let session: URLSession

    init(config: AppConfig, session: URLSession = .shared) {
        self.config = config
        self.session = session
    }

    func analyzePhoto(imageData: Data, mimeType: String = "image/jpeg", capturedAt: Date = .now) async throws -> FoodDraft {
        guard let apiKey = config.openRouterAPIKey else {
            throw ServiceError.invalidConfiguration("Add an OpenRouter API key before using photo analysis.")
        }

        let imageURL = "data:\(mimeType);base64,\(imageData.base64EncodedString())"

        let body: [String: Any] = [
            "model": config.openRouterPhotoModel,
            "temperature": 0.2,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": """
                            Analyze this food photo for a food tracking app.
                            Estimate a single loggable entry that best represents the visible food or drink.
                            Use US nutrition-label style estimates for the consumed portion, not per 100g.
                            If multiple items are visible, combine them into a single clear meal description.
                            Return only JSON that matches the schema.
                            """
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": imageURL
                            ]
                        ]
                    ]
                ]
            ],
            "response_format": [
                "type": "json_schema",
                "json_schema": [
                    "name": "food_photo_analysis",
                    "strict": true,
                    "schema": [
                        "type": "object",
                        "additionalProperties": false,
                        "properties": [
                            "name": [
                                "type": "string",
                                "description": "Short food name for the entry."
                            ],
                            "brand": [
                                "type": "string",
                                "description": "Brand if clearly visible, otherwise an empty string."
                            ],
                            "servingDescription": [
                                "type": "string",
                                "description": "Human-friendly serving estimate such as 1 bowl or 2 tacos."
                            ],
                            "mealSuggestion": [
                                "type": "string",
                                "enum": ["breakfast", "lunch", "dinner", "snack"]
                            ],
                            "confidence": [
                                "type": "number",
                                "minimum": 0,
                                "maximum": 1
                            ],
                            "nutrition": [
                                "type": "object",
                                "additionalProperties": false,
                                "properties": [
                                    "calories": ["type": "number"],
                                    "protein": ["type": "number"],
                                    "carbs": ["type": "number"],
                                    "fat": ["type": "number"],
                                    "fiber": ["type": "number"],
                                    "sugar": ["type": "number"],
                                    "sodium": ["type": "number"]
                                ],
                                "required": ["calories", "protein", "carbs", "fat", "fiber", "sugar", "sodium"]
                            ],
                            "notes": [
                                "type": "string",
                                "description": "Very short note about uncertainty or assumptions."
                            ]
                        ],
                        "required": ["name", "brand", "servingDescription", "mealSuggestion", "confidence", "nutrition", "notes"]
                    ]
                ]
            ]
        ]

        guard let url = URL(string: "https://openrouter.ai/api/v1/chat/completions") else {
            throw ServiceError.invalidRequest
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.openRouterAppName, forHTTPHeaderField: "X-Title")
        if let referer = config.openRouterHTTPReferer {
            request.setValue(referer, forHTTPHeaderField: "HTTP-Referer")
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            if let apiError = try? JSONDecoder().decode(OpenRouterErrorEnvelope.self, from: data) {
                throw ServiceError.apiError(apiError.error.message)
            }
            throw ServiceError.invalidResponse
        }

        let completion = try JSONDecoder().decode(OpenRouterCompletionResponse.self, from: data)
        guard let content = completion.choices.first?.message.content?.nilIfBlank else {
            throw ServiceError.decodingError
        }

        let analysisData = try extractJSON(from: content)
        let payload = try JSONDecoder().decode(PhotoAnalysisPayload.self, from: analysisData)

        return FoodDraft(
            name: payload.name.cleanedFoodName,
            brand: payload.brand.cleanedFoodName,
            servingDescription: payload.servingDescription,
            consumedAt: capturedAt,
            meal: MealSlot(rawValue: payload.mealSuggestion.lowercased()) ?? .suggested(for: capturedAt),
            source: .photo,
            notes: payload.notes,
            nutrition: payload.nutrition
        )
    }

    private func extractJSON(from rawContent: String) throws -> Data {
        let trimmed = rawContent.trimmingCharacters(in: .whitespacesAndNewlines)
        if let data = trimmed.data(using: .utf8),
           (try? JSONSerialization.jsonObject(with: data)) != nil {
            return data
        }

        guard let start = trimmed.firstIndex(of: "{"),
              let end = trimmed.lastIndex(of: "}") else {
            throw ServiceError.decodingError
        }

        let json = String(trimmed[start...end])
        guard let data = json.data(using: .utf8) else {
            throw ServiceError.decodingError
        }
        return data
    }
}

private struct OpenRouterCompletionResponse: Decodable {
    let choices: [OpenRouterChoice]
}

private struct OpenRouterChoice: Decodable {
    let message: OpenRouterMessage
}

private struct OpenRouterMessage: Decodable {
    let content: String?
}

private struct OpenRouterErrorEnvelope: Decodable {
    let error: OpenRouterErrorPayload
}

private struct OpenRouterErrorPayload: Decodable {
    let message: String
}

private struct PhotoAnalysisPayload: Decodable {
    let name: String
    let brand: String
    let servingDescription: String
    let mealSuggestion: String
    let confidence: Double
    let nutrition: NutritionFacts
    let notes: String
}

