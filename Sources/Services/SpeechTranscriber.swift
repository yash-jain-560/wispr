import Foundation

final class SpeechTranscriber {
    enum TranscriberError: Error {
        case missingAPIKey
        case invalidURL
        case invalidResponse
        case emptyResponse
        case localModelNotConfigured
        case localExecutionFailed(String)
        case rateLimited(String)
    }

    private let config: AppConfig

    init(config: AppConfig) {
        self.config = config
    }

    func transcribe(fileURL: URL, targetLanguage: String?, completion: @escaping (Result<String, Error>) -> Void) {
        switch config.aiMode {
        case .cloud:
            transcribeWithGemini(fileURL: fileURL, targetLanguage: targetLanguage, completion: completion)
        case .local:
            transcribeWithLocalWhisper(fileURL: fileURL, completion: completion)
        }
    }

    private func transcribeWithGemini(
        fileURL: URL,
        targetLanguage: String?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let apiKey = config.geminiAPIKey, !apiKey.isEmpty else {
            appLogError("gemini transcription missing API key", source: "transcriber")
            completion(.failure(TranscriberError.missingAPIKey))
            return
        }

        let audioData: Data
        do {
            audioData = try Data(contentsOf: fileURL)
        } catch {
            completion(.failure(error))
            return
        }

        let candidateMimes = mimeTypes(for: fileURL)
        var candidateModels = [config.geminiTranscribeModel]
        if
            let fallbackModel = config.geminiTranscribeFallbackModel,
            !fallbackModel.isEmpty,
            fallbackModel != config.geminiTranscribeModel
        {
            candidateModels.append(fallbackModel)
        }

        let prompt = cloudPrompt(targetLanguage: targetLanguage)

        func attempt(modelIndex: Int, mimeIndex: Int, rateLimitRetries: Int) {
            guard modelIndex < candidateModels.count else {
                completion(.failure(TranscriberError.invalidResponse))
                return
            }

            let model = candidateModels[modelIndex]
            guard mimeIndex < candidateMimes.count else {
                attempt(modelIndex: modelIndex + 1, mimeIndex: 0, rateLimitRetries: 0)
                return
            }

            let mimeType = candidateMimes[mimeIndex]

            guard var components = URLComponents(string: "\(config.geminiURL)/v1beta/models/\(model):generateContent") else {
                completion(.failure(TranscriberError.invalidURL))
                return
            }
            components.queryItems = [URLQueryItem(name: "key", value: apiKey)]

            guard let endpoint = components.url else {
                completion(.failure(TranscriberError.invalidURL))
                return
            }

            let body = GeminiGenerateContentRequest(
                contents: [
                    .init(role: "user", parts: [
                        .text(prompt),
                        .inlineData(.init(mimeType: mimeType, data: audioData.base64EncodedString()))
                    ])
                ],
                generationConfig: .init(temperature: 0.0)
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
                    appLogError(
                        "gemini transcription request failed",
                        metadata: ["error": error.localizedDescription, "model": model, "mime_type": mimeType],
                        source: "transcriber"
                    )
                    completion(.failure(error))
                    return
                }

                let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode), let data else {
                    let errorBody = self.extractGeminiError(from: data)
                    let hasMimeFallback = mimeIndex + 1 < candidateMimes.count
                    if status == 400, hasMimeFallback {
                        appLogWarning(
                            "gemini transcription rejected mime type, retrying",
                            metadata: [
                                "status": String(status),
                                "model": model,
                                "mime_type": mimeType,
                                "next_mime_type": candidateMimes[mimeIndex + 1],
                                "error": errorBody
                            ],
                            source: "transcriber"
                        )
                        attempt(modelIndex: modelIndex, mimeIndex: mimeIndex + 1, rateLimitRetries: rateLimitRetries)
                        return
                    }

                    if status == 429 {
                        if modelIndex + 1 < candidateModels.count {
                            appLogWarning(
                                "gemini transcription rate-limited, switching model",
                                metadata: [
                                    "status": String(status),
                                    "model": model,
                                    "next_model": candidateModels[modelIndex + 1],
                                    "mime_type": mimeType,
                                    "error": errorBody
                                ],
                                source: "transcriber"
                            )
                            attempt(modelIndex: modelIndex + 1, mimeIndex: 0, rateLimitRetries: 0)
                            return
                        }

                        if rateLimitRetries < 1, let retryAfter = self.extractRetryAfterSeconds(response: response, errorMessage: errorBody), retryAfter > 0, retryAfter <= 2.0 {
                            appLogWarning(
                                "gemini transcription rate-limited, retrying shortly",
                                metadata: [
                                    "status": String(status),
                                    "model": model,
                                    "mime_type": mimeType,
                                    "retry_after_s": String(format: "%.2f", retryAfter)
                                ],
                                source: "transcriber"
                            )
                            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + retryAfter) {
                                attempt(modelIndex: modelIndex, mimeIndex: mimeIndex, rateLimitRetries: rateLimitRetries + 1)
                            }
                            return
                        }

                        completion(.failure(TranscriberError.rateLimited(errorBody)))
                        return
                    }

                    appLogError(
                        "gemini transcription invalid response",
                        metadata: [
                            "status": String(status),
                            "model": model,
                            "mime_type": mimeType,
                            "error": errorBody
                        ],
                        source: "transcriber"
                    )
                    completion(.failure(TranscriberError.invalidResponse))
                    return
                }

                do {
                    let payload = try JSONDecoder().decode(GeminiGenerateContentResponse.self, from: data)
                    let combined = payload.candidates?
                        .first?
                        .content?
                        .parts?
                        .compactMap(\.text)
                        .joined(separator: "\n")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    guard
                        let text = combined,
                        !text.isEmpty
                    else {
                        appLogWarning("gemini transcription empty response", source: "transcriber")
                        completion(.failure(TranscriberError.emptyResponse))
                        return
                    }

                    let transcript = self.normalizeTranscript(text)
                    appLogInfo(
                        "gemini transcription success",
                        metadata: [
                            "chars": String(transcript.count),
                            "model": model,
                            "mime_type": mimeType,
                            "single_pass": self.config.cloudSinglePass ? "1" : "0"
                        ],
                        source: "transcriber"
                    )
                    completion(.success(transcript))
                } catch {
                    appLogError(
                        "gemini transcription decode failed",
                        metadata: ["error": error.localizedDescription, "model": model, "mime_type": mimeType],
                        source: "transcriber"
                    )
                    completion(.failure(error))
                }
            }.resume()
        }

        attempt(modelIndex: 0, mimeIndex: 0, rateLimitRetries: 0)
    }

    private func transcribeWithLocalWhisper(fileURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        guard let modelPath = config.localSTTModelPath, !modelPath.isEmpty else {
            appLogError(
                "local transcription model path is not configured",
                metadata: ["env": "LOCAL_STT_MODEL_PATH"],
                source: "transcriber"
            )
            completion(.failure(TranscriberError.localModelNotConfigured))
            return
        }

        let outputBase = FileManager.default.temporaryDirectory
            .appendingPathComponent("ptt-transcript-\(UUID().uuidString)")
        let outputTXT = outputBase.appendingPathExtension("txt")

        var args = [
            config.localSTTCommand,
            "-m", modelPath,
            "-f", fileURL.path,
            "-otxt",
            "-of", outputBase.path,
            "-np"
        ]
        if let language = config.localSTTLanguage {
            args += ["-l", language]
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = args

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        process.terminationHandler = { finishedProcess in
            let outData = stdout.fileHandleForReading.readDataToEndOfFile()
            let errData = stderr.fileHandleForReading.readDataToEndOfFile()
            let outText = String(data: outData, encoding: .utf8) ?? ""
            let errText = String(data: errData, encoding: .utf8) ?? ""

            if finishedProcess.terminationStatus != 0 {
                let message = errText.isEmpty ? outText : errText
                appLogError(
                    "local transcription command failed",
                    metadata: [
                        "status": String(finishedProcess.terminationStatus),
                        "message": message.trimmingCharacters(in: .whitespacesAndNewlines)
                    ],
                    source: "transcriber"
                )
                completion(.failure(TranscriberError.localExecutionFailed(message)))
                return
            }

            guard
                let transcriptData = try? Data(contentsOf: outputTXT),
                let transcriptRaw = String(data: transcriptData, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                !transcriptRaw.isEmpty
            else {
                appLogWarning("local transcription empty response", source: "transcriber")
                completion(.failure(TranscriberError.emptyResponse))
                return
            }

            try? FileManager.default.removeItem(at: outputTXT)
            let transcript = self.normalizeTranscript(transcriptRaw)
            appLogInfo(
                "local transcription success",
                metadata: ["chars": String(transcript.count)],
                source: "transcriber"
            )
            completion(.success(transcript))
        }

        do {
            try process.run()
        } catch {
            appLogError(
                "failed to launch local transcription command",
                metadata: [
                    "command": config.localSTTCommand,
                    "error": error.localizedDescription
                ],
                source: "transcriber"
            )
            completion(.failure(TranscriberError.localExecutionFailed(error.localizedDescription)))
        }
    }

    private func mimeTypes(for fileURL: URL) -> [String] {
        switch fileURL.pathExtension.lowercased() {
        case "m4a":
            return ["audio/m4a", "audio/mp4"]
        case "wav":
            return ["audio/wav"]
        case "mp3":
            return ["audio/mpeg"]
        default:
            return ["application/octet-stream"]
        }
    }

    private func extractGeminiError(from data: Data?) -> String {
        guard let data, !data.isEmpty else {
            return "empty error body"
        }

        if
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let error = object["error"] as? [String: Any]
        {
            let message = (error["message"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let message, !message.isEmpty {
                return message
            }
        }

        if let raw = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !raw.isEmpty
        {
            return String(raw.prefix(300))
        }

        return "unreadable error body"
    }

    private func extractRetryAfterSeconds(response: URLResponse?, errorMessage: String) -> TimeInterval? {
        if
            let http = response as? HTTPURLResponse,
            let retryAfterHeader = http.value(forHTTPHeaderField: "Retry-After"),
            let seconds = TimeInterval(retryAfterHeader),
            seconds > 0
        {
            return seconds
        }

        let lowercased = errorMessage.lowercased()
        guard let range = lowercased.range(of: "retry in ") else { return nil }
        let suffix = lowercased[range.upperBound...]
        guard let end = suffix.firstIndex(of: "s") else { return nil }
        let token = suffix[..<end].trimmingCharacters(in: .whitespacesAndNewlines)
        return TimeInterval(token)
    }

    private func cloudPrompt(targetLanguage: String?) -> String {
        if config.cloudSinglePass {
            if let targetLanguage, !targetLanguage.isEmpty {
                return """
                You are a realtime dictation assistant.
                Transcribe the audio accurately.
                Do not omit any spoken words or details.
                Clean punctuation, capitalization, and obvious speech disfluencies.
                Translate the final text into \(targetLanguage).
                Return only the final text with no explanation.
                """
            }

            return """
            You are a realtime dictation assistant.
            Transcribe the audio accurately.
            Do not omit any spoken words or details.
            Clean punctuation, capitalization, and obvious speech disfluencies.
            Return only the final text with no explanation.
            """
        }

        return """
        You are a speech transcription engine.
        Transcribe this audio exactly.
        Keep words in the spoken language.
        Return only plain transcript text.
        """
    }

    private func normalizeTranscript(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: "```", with: "")
            .replacingOccurrences(of: "Transcript:", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct GeminiGenerateContentRequest: Encodable {
    struct Content: Encodable {
        let role: String?
        let parts: [Part]
    }

    struct Part: Encodable {
        let text: String?
        let inlineData: InlineData?

        enum CodingKeys: String, CodingKey {
            case text
            case inlineData
        }

        static func text(_ value: String) -> Part {
            Part(text: value, inlineData: nil)
        }

        static func inlineData(_ value: InlineData) -> Part {
            Part(text: nil, inlineData: value)
        }
    }

    struct InlineData: Encodable {
        let mimeType: String
        let data: String

        enum CodingKeys: String, CodingKey {
            case mimeType
            case data
        }
    }

    struct GenerationConfig: Encodable {
        let temperature: Double
    }

    let contents: [Content]
    let generationConfig: GenerationConfig
}

private struct GeminiGenerateContentResponse: Decodable {
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
