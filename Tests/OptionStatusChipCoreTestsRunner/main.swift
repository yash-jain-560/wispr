import Foundation
import OptionStatusChipCore

struct TestFailure: Error {
    let message: String
}

func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() {
        throw TestFailure(message: message)
    }
}

func testDefaultsConfig() throws {
    let config = AppConfig(environment: [:])
    try expect(config.triggerKey == .option, "Default triggerKey should be option")
    try expect(config.aiMode == .cloud, "Default aiMode should be cloud")
    try expect(config.targetLanguage == nil, "Default targetLanguage should be nil")
    try expect(config.geminiTranscribeModel == "gemini-2.5-flash", "Default geminiTranscribeModel should be gemini-2.5-flash")
    try expect(config.geminiTranscribeFallbackModel == "gemini-2.0-flash", "Default geminiTranscribeFallbackModel should be gemini-2.0-flash")
    try expect(config.cloudSinglePass == true, "cloudSinglePass should default to true")
    try expect(config.recordingTailMS == 220, "recordingTailMS should default to 220")
    try expect(config.logLevel == .info, "Default logLevel should be info")
    try expect(config.showSecretsInLogs == false, "showSecretsInLogs should default to false")
}

func testCustomConfigValues() throws {
    let config = AppConfig(environment: [
        "TRIGGER_KEY": "fn",
        "AI_MODE": "local",
        "TARGET_LANGUAGE": "Spanish",
        "GEMINI_API_KEY": "AIzaABCDEFGHIJKLMNOPQRSTUVWX123456",
        "GEMINI_MODEL": "gemini-pro",
        "GEMINI_TRANSCRIBE_MODEL": "gemini-2.0-flash",
        "GEMINI_TRANSCRIBE_FALLBACK_MODEL": "gemini-2.0-flash-lite",
        "GEMINI_URL": "https://example.test",
        "CLOUD_SINGLE_PASS": "0",
        "RECORDING_TAIL_MS": "340",
        "OLLAMA_URL": "http://localhost:11434",
        "OLLAMA_MODEL": "qwen2:1.5b",
        "LOCAL_STT_COMMAND": "my-whisper",
        "LOCAL_STT_MODEL_PATH": "/tmp/ggml-base.bin",
        "LOCAL_STT_LANGUAGE": "en",
        "LOG_LEVEL": "debug",
        "LOG_SHOW_SECRETS": "1"
    ])

    try expect(config.triggerKey == .fn, "Custom triggerKey parsing failed")
    try expect(config.aiMode == .local, "Custom aiMode parsing failed")
    try expect(config.targetLanguage == "Spanish", "Custom targetLanguage parsing failed")
    try expect(config.geminiAPIKey == "AIzaABCDEFGHIJKLMNOPQRSTUVWX123456", "Gemini API key parsing failed")
    try expect(config.geminiModel == "gemini-pro", "Gemini model parsing failed")
    try expect(config.geminiTranscribeModel == "gemini-2.0-flash", "Gemini transcribe model parsing failed")
    try expect(config.geminiTranscribeFallbackModel == "gemini-2.0-flash-lite", "Gemini transcribe fallback model parsing failed")
    try expect(config.geminiURL == "https://example.test", "Gemini URL parsing failed")
    try expect(config.cloudSinglePass == false, "CLOUD_SINGLE_PASS parsing failed")
    try expect(config.recordingTailMS == 340, "RECORDING_TAIL_MS parsing failed")
    try expect(config.ollamaURL == "http://localhost:11434", "Ollama URL parsing failed")
    try expect(config.ollamaModel == "qwen2:1.5b", "Ollama model parsing failed")
    try expect(config.localSTTCommand == "my-whisper", "LOCAL_STT_COMMAND parsing failed")
    try expect(config.localSTTModelPath == "/tmp/ggml-base.bin", "LOCAL_STT_MODEL_PATH parsing failed")
    try expect(config.localSTTLanguage == "en", "LOCAL_STT_LANGUAGE parsing failed")
    try expect(config.logLevel == .debug, "Log level parsing failed")
    try expect(config.showSecretsInLogs == true, "LOG_SHOW_SECRETS parsing failed")
}

func testInvalidConfigFallbacks() throws {
    let config = AppConfig(environment: [
        "TRIGGER_KEY": "invalid",
        "AI_MODE": "invalid",
        "TARGET_LANGUAGE": "   ",
        "LOCAL_STT_MODEL_PATH": "   "
    ])

    try expect(config.triggerKey == .option, "Invalid triggerKey should fallback to option")
    try expect(config.aiMode == .cloud, "Invalid aiMode should fallback to cloud")
    try expect(config.targetLanguage == nil, "Whitespace targetLanguage should become nil")
    try expect(config.localSTTModelPath == nil, "Whitespace LOCAL_STT_MODEL_PATH should become nil")
    try expect(config.logLevel == .info, "Invalid log level should fallback to info")
}

func testSecretRedaction() throws {
    let redacted = AppConfig(environment: [
        "GEMINI_API_KEY": "AIzaABCDEFGHIJKLMNOPQRSTUVWX123456"
    ])
    let shown = AppConfig(environment: [
        "GEMINI_API_KEY": "AIzaABCDEFGHIJKLMNOPQRSTUVWX123456",
        "LOG_SHOW_SECRETS": "1"
    ])

    try expect(redacted.formatSecret(redacted.geminiAPIKey).contains("..."), "Secret should be redacted")
    try expect(shown.formatSecret(shown.geminiAPIKey) == "AIzaABCDEFGHIJKLMNOPQRSTUVWX123456", "Secret should be visible when allowed")
}

func testStartupMetadataContainsImportantKeys() throws {
    let config = AppConfig(environment: [
        "AI_MODE": "cloud",
        "TRIGGER_KEY": "option",
        "TARGET_LANGUAGE": "English",
        "GEMINI_API_KEY": "AIzaABCDEFGHIJKLMNOPQRSTUVWX123456",
        "LOG_LEVEL": "warning"
    ])
    let metadata = config.startupMetadata()

    try expect(metadata["ai_mode"] == "cloud", "startup metadata should include ai_mode")
    try expect(metadata["trigger_key"] == "option", "startup metadata should include trigger_key")
    try expect(metadata["target_language"] == "English", "startup metadata should include target_language")
    try expect(metadata["gemini_api_key"]?.contains("...") == true, "startup metadata should include masked gemini_api_key")
    try expect(metadata["gemini_transcribe_model"] == "gemini-2.5-flash", "startup metadata should include gemini_transcribe_model")
    try expect(metadata["gemini_transcribe_fallback_model"] == "gemini-2.0-flash", "startup metadata should include gemini_transcribe_fallback_model")
    try expect(metadata["cloud_single_pass"] == "1", "startup metadata should include cloud_single_pass")
    try expect(metadata["recording_tail_ms"] == "220", "startup metadata should include recording_tail_ms")
    try expect(metadata["local_stt_command"] == "whisper-cli", "startup metadata should include local_stt_command")
    try expect(metadata["log_level"] == "warning", "startup metadata should include log_level")
}

func testPromptWithoutTargetLanguage() throws {
    let prompt = CleanupPromptBuilder.build(transcript: "hello world", targetLanguage: nil)

    try expect(prompt.contains("dictation cleanup assistant"), "Cleanup prompt missing assistant instruction")
    try expect(prompt.contains("hello world"), "Cleanup prompt missing transcript")
    try expect(!prompt.contains("Translate the text into"), "Cleanup prompt should not include translation instruction")
}

func testPromptWithTargetLanguage() throws {
    let prompt = CleanupPromptBuilder.build(transcript: "hola mundo", targetLanguage: "English")

    try expect(prompt.contains("dictation cleanup and translation assistant"), "Translation prompt missing assistant instruction")
    try expect(prompt.contains("Translate the text into English"), "Translation prompt missing target language")
    try expect(prompt.contains("hola mundo"), "Translation prompt missing transcript")
}

let tests: [(String, () throws -> Void)] = [
    ("DefaultsConfig", testDefaultsConfig),
    ("CustomConfigValues", testCustomConfigValues),
    ("InvalidConfigFallbacks", testInvalidConfigFallbacks),
    ("SecretRedaction", testSecretRedaction),
    ("StartupMetadataContainsImportantKeys", testStartupMetadataContainsImportantKeys),
    ("PromptWithoutTargetLanguage", testPromptWithoutTargetLanguage),
    ("PromptWithTargetLanguage", testPromptWithTargetLanguage)
]

var failures = 0
for (name, test) in tests {
    do {
        try test()
        print("[PASS] \(name)")
    } catch {
        failures += 1
        print("[FAIL] \(name): \(error)")
    }
}

if failures > 0 {
    print("\n\(failures) test(s) failed")
    exit(1)
}

print("\nAll \(tests.count) tests passed")
