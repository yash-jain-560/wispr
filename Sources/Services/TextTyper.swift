import ApplicationServices

final class TextTyper {
    func type(_ text: String) {
        guard !text.isEmpty else { return }
        guard AXIsProcessTrusted() else { return }
        guard let source = CGEventSource(stateID: .combinedSessionState) else { return }

        appLog("typing text (\(text.count) chars)")
        for character in text {
            postUnicode(String(character), source: source)
        }
    }

    private func postUnicode(_ string: String, source: CGEventSource) {
        let utf16 = Array(string.utf16)
        guard !utf16.isEmpty else { return }

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) else {
            return
        }

        utf16.withUnsafeBufferPointer { buffer in
            guard let base = buffer.baseAddress else { return }
            keyDown.keyboardSetUnicodeString(stringLength: buffer.count, unicodeString: base)
            keyUp.keyboardSetUnicodeString(stringLength: buffer.count, unicodeString: base)
        }

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}
