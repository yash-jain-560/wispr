import Foundation

protocol TextImprover {
    func improve(
        transcript: String,
        targetLanguage: String?,
        completion: @escaping (Result<String, Error>) -> Void
    )
}

final class OllamaClient: TextImprover {
    struct GenerateRequest: Encodable {
        let model: String
        let prompt: String
        let stream: Bool
    }

    struct GenerateResponse: Decodable {
        let response: String?
        let error: String?
    }

    enum OllamaError: Error {
        case invalidResponse
        case serverError(String)
        case emptyResponse
    }

    private let endpoint: URL
    private let model: String

    init(config: AppConfig) {
        endpoint = URL(string: "\(config.ollamaURL)/api/generate")!
        model = config.ollamaModel
        appLogInfo(
            "ollama client initialized",
            metadata: [
                "model": model,
                "endpoint": endpoint.absoluteString
            ],
            source: "startup"
        )
    }

    func improve(
        transcript: String,
        targetLanguage: String?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let prompt = CleanupPromptBuilder.build(transcript: transcript, targetLanguage: targetLanguage)
        let body = GenerateRequest(model: model, prompt: prompt, stream: false)

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                appLog("ollama request failed: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode), let data else {
                appLog("ollama invalid response")
                completion(.failure(OllamaError.invalidResponse))
                return
            }

            do {
                let payload = try JSONDecoder().decode(GenerateResponse.self, from: data)
                if let message = payload.error {
                    appLog("ollama server error: \(message)")
                    completion(.failure(OllamaError.serverError(message)))
                    return
                }

                guard let text = payload.response?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
                    appLog("ollama returned empty response")
                    completion(.failure(OllamaError.emptyResponse))
                    return
                }

                appLog("ollama cleanup success (\(text.count) chars)")
                completion(.success(text))
            } catch {
                appLog("ollama decode failed: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }.resume()
    }
}

final class GeminiClient: TextImprover {
    struct GenerateContentRequest: Encodable {
        struct Content: Encodable {
            struct Part: Encodable {
                let text: String
            }

            let parts: [Part]
        }

        struct GenerationConfig: Encodable {
            let temperature: Double
        }

        let contents: [Content]
        let generationConfig: GenerationConfig
    }

    struct GenerateContentResponse: Decodable {
        struct Candidate: Decodable {
            struct Content: Decodable {
                struct Part: Decodable {
                    let text: String?
                }

                let parts: [Part]?
            }

            let content: Content?
        }

        let candidates: [Candidate]?
    }

    enum GeminiError: Error {
        case missingAPIKey
        case invalidURL
        case invalidResponse
        case emptyResponse
    }

    private let apiKey: String?
    private let baseURL: String
    private let model: String

    init(config: AppConfig) {
        // Initial config fallback, but we primarily use AppState dynamically
        apiKey = config.geminiAPIKey
        baseURL = config.geminiURL
        model = config.geminiModel
    }

    func improve(
        transcript: String,
        targetLanguage: String?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        // Read dynamic config from AppState
        let state = AppState.shared
        let dynamicKey = state.geminiKey.isEmpty ? apiKey : state.geminiKey
        let dynamicModel = state.geminiModel.isEmpty ? model : state.geminiModel
        
        guard let finalKey = dynamicKey, !finalKey.isEmpty else {
            appLog("gemini missing API key")
            completion(.failure(GeminiError.missingAPIKey))
            return
        }

        guard var components = URLComponents(string: "\(baseURL)/v1beta/models/\(dynamicModel):generateContent") else {
            completion(.failure(GeminiError.invalidURL))
            return
        }

        components.queryItems = [URLQueryItem(name: "key", value: finalKey)]
        guard let endpoint = components.url else {
            completion(.failure(GeminiError.invalidURL))
            return
        }

        let body = GenerateContentRequest(
            contents: [
                .init(parts: [.init(text: CleanupPromptBuilder.build(transcript: transcript, targetLanguage: targetLanguage, style: state.selectedStyle))])
            ],
            generationConfig: .init(temperature: 0.1)
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                appLog("gemini request failed: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode), let data else {
                appLog("gemini invalid response")
                completion(.failure(GeminiError.invalidResponse))
                return
            }

            do {
                let payload = try JSONDecoder().decode(GenerateContentResponse.self, from: data)
                guard
                    let text = payload.candidates?.first?.content?.parts?.first?.text?
                        .trimmingCharacters(in: .whitespacesAndNewlines),
                    !text.isEmpty
                else {
                    appLog("gemini returned empty response")
                    completion(.failure(GeminiError.emptyResponse))
                    return
                }

                appLog("gemini cleanup success (\(text.count) chars)")
                completion(.success(text))
            } catch {
                appLog("gemini decode failed: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }.resume()
    }
}
