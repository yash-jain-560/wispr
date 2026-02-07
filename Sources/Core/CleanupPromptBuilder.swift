import Foundation

public enum CleanupPromptBuilder {
    public static func build(transcript: String, targetLanguage: String?, style: String = "Normal") -> String {
        var styleInstruction = "Fix punctuation, capitalization, and obvious speech disfluencies."
        
        switch style {
        case "Casual":
            styleInstruction += " Keep the tone relaxed and conversational. Slang and contractions are allowed."
        case "Professional":
            styleInstruction += " Use formal professional tone. Remove slang and ensure precise grammar."
        case "Academic":
            styleInstruction += " Use complex sentence structures and expanded vocabulary suitable for academic writing."
        case "Bullet Points":
            styleInstruction = "Format the dictation into a concise list of bullet points. Fix punctuation and grammar."
        default:
            break
        }
        
        if let targetLanguage, !targetLanguage.isEmpty {
            return """
            You are a dictation cleanup and translation assistant.
            Detect the source language from the dictation text.
            Translate the text into \(targetLanguage).
            \(styleInstruction)
            Preserve the original meaning exactly.
            Return only the final translated text, with no explanation.

            Dictation:
            \(transcript)
            """
        }

        return """
        You are a dictation cleanup assistant.
        \(styleInstruction)
        Preserve the original meaning exactly.
        Return only the final cleaned text, with no explanation.

        Dictation:
        \(transcript)
        """
    }
}
