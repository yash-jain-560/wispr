import Foundation

public enum TriggerKey: String {
    case fn
    case option
}

public enum AIMode: String {
    case local
    case cloud
}

public enum LogLevel: String, CaseIterable {
    case debug
    case info
    case warning
    case error

    public var rank: Int {
        switch self {
        case .debug:
            return 10
        case .info:
            return 20
        case .warning:
            return 30
        case .error:
            return 40
        }
    }
}

public struct AppConfig {
    public let triggerKey: TriggerKey
    public let aiMode: AIMode
    public let targetLanguage: String?
    public let geminiAPIKey: String?
    public let geminiModel: String
    public let geminiTranscribeModel: String
    public let geminiTranscribeFallbackModel: String?
    public let geminiURL: String
    public let ollamaURL: String
    public let ollamaModel: String
    public let localSTTCommand: String
    public let localSTTModelPath: String?
    public let localSTTLanguage: String?
    public let cloudSinglePass: Bool
    public let recordingTailMS: Int
    public let logLevel: LogLevel
    public let showSecretsInLogs: Bool

    public init(environment: [String: String] = ProcessInfo.processInfo.environment) {
        let envTrigger = environment["TRIGGER_KEY"]?.lowercased()
        triggerKey = TriggerKey(rawValue: envTrigger ?? "option") ?? .option

        let envMode = environment["AI_MODE"]?.lowercased()
        aiMode = AIMode(rawValue: envMode ?? "cloud") ?? .cloud

        let language = environment["TARGET_LANGUAGE"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        targetLanguage = (language?.isEmpty == false) ? language : nil

        geminiAPIKey = environment["GEMINI_API_KEY"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        geminiModel = environment["GEMINI_MODEL"] ?? "gemini-2.5-flash"
        geminiTranscribeModel = environment["GEMINI_TRANSCRIBE_MODEL"] ?? "gemini-2.5-flash"
        let fallbackModel = environment["GEMINI_TRANSCRIBE_FALLBACK_MODEL"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        geminiTranscribeFallbackModel = (fallbackModel?.isEmpty == false) ? fallbackModel : "gemini-2.0-flash"
        geminiURL = environment["GEMINI_URL"] ?? "https://generativelanguage.googleapis.com"

        ollamaURL = environment["OLLAMA_URL"] ?? "http://127.0.0.1:11434"
        ollamaModel = environment["OLLAMA_MODEL"] ?? "qwen2.5:3b-instruct"
        localSTTCommand = environment["LOCAL_STT_COMMAND"] ?? "whisper-cli"

        let sttModel = environment["LOCAL_STT_MODEL_PATH"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        localSTTModelPath = (sttModel?.isEmpty == false) ? sttModel : nil

        let sttLanguage = environment["LOCAL_STT_LANGUAGE"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        localSTTLanguage = (sttLanguage?.isEmpty == false) ? sttLanguage : nil
        cloudSinglePass = (environment["CLOUD_SINGLE_PASS"] ?? "1") != "0"
        let tail = Int(environment["RECORDING_TAIL_MS"] ?? "") ?? 220
        recordingTailMS = max(0, min(tail, 1000))

        let envLogLevel = environment["LOG_LEVEL"]?.lowercased()
        logLevel = LogLevel(rawValue: envLogLevel ?? "info") ?? .info
        showSecretsInLogs = (environment["LOG_SHOW_SECRETS"] ?? "0") == "1"
    }

    public func startupMetadata() -> [String: String] {
        [
            "ai_mode": aiMode.rawValue,
            "trigger_key": triggerKey.rawValue,
            "target_language": targetLanguage ?? "none",
            "gemini_url": geminiURL,
            "gemini_model": geminiModel,
            "gemini_transcribe_model": geminiTranscribeModel,
            "gemini_transcribe_fallback_model": geminiTranscribeFallbackModel ?? "unset",
            "gemini_api_key": formatSecret(geminiAPIKey),
            "ollama_url": ollamaURL,
            "ollama_model": ollamaModel,
            "local_stt_command": localSTTCommand,
            "local_stt_model_path": localSTTModelPath ?? "unset",
            "local_stt_language": localSTTLanguage ?? "auto",
            "cloud_single_pass": cloudSinglePass ? "1" : "0",
            "recording_tail_ms": String(recordingTailMS),
            "log_level": logLevel.rawValue,
            "show_secrets_in_logs": showSecretsInLogs ? "1" : "0"
        ]
    }

    public func formatSecret(_ value: String?) -> String {
        guard let value, !value.isEmpty else {
            return "unset"
        }

        if showSecretsInLogs {
            return value
        }

        if value.count <= 8 {
            return "<redacted len=\(value.count)>"
        }

        let prefix = String(value.prefix(4))
        let suffix = String(value.suffix(4))
        return "\(prefix)...\(suffix) (len=\(value.count))"
    }
}
