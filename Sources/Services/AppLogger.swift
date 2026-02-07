import Foundation

protocol AppLogging {
    func log(level: LogLevel, message: String, metadata: [String: String], source: String)
}

final class DefaultAppLogger: AppLogging {
    private let queue = DispatchQueue(label: "OptionStatusChip.LogQueue", qos: .utility)
    private let logFileURL: URL
    private let formatter = ISO8601DateFormatter()
    private let sessionID = UUID().uuidString
    private let minimumLevel: LogLevel
    private let maxLogBytes: UInt64 = 5_000_000

    init(minimumLevel: LogLevel) {
        self.minimumLevel = minimumLevel
        let logsDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs", isDirectory: true)
        logFileURL = logsDir.appendingPathComponent("OptionStatusChip.log")
    }

    func log(level: LogLevel, message: String, metadata: [String: String], source: String) {
        guard level.rank >= minimumLevel.rank else { return }

        var fields = metadata
        fields["source"] = source
        fields["pid"] = String(ProcessInfo.processInfo.processIdentifier)
        fields["session"] = sessionID

        let ordered = fields.keys.sorted()
            .map { key in "\(key)=\(fields[key] ?? "")" }
            .joined(separator: " ")

        let line = "\(formatter.string(from: Date())) [\(level.rawValue.uppercased())] [OptionStatusChip] \(message)\(ordered.isEmpty ? "" : " | \(ordered)")"
        NSLog("%@", line)
        appendToFile(line)
    }

    private func appendToFile(_ line: String) {
        queue.async { [logFileURL] in
            let logsDir = logFileURL.deletingLastPathComponent()
            try? FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)
            self.rotateIfNeeded()

            if !FileManager.default.fileExists(atPath: logFileURL.path) {
                FileManager.default.createFile(atPath: logFileURL.path, contents: nil)
            }

            guard let handle = try? FileHandle(forWritingTo: logFileURL) else { return }
            defer { try? handle.close() }
            _ = try? handle.seekToEnd()

            if let data = (line + "\n").data(using: .utf8) {
                try? handle.write(contentsOf: data)
            }
        }
    }

    private func rotateIfNeeded() {
        guard
            let attrs = try? FileManager.default.attributesOfItem(atPath: logFileURL.path),
            let size = attrs[.size] as? UInt64,
            size >= maxLogBytes
        else {
            return
        }

        let backupURL = logFileURL.deletingPathExtension().appendingPathExtension("log.1")
        try? FileManager.default.removeItem(at: backupURL)
        try? FileManager.default.moveItem(at: logFileURL, to: backupURL)
    }
}

private var appLogger: AppLogging = DefaultAppLogger(minimumLevel: .info)

func configureAppLogger(config: AppConfig) {
    appLogger = DefaultAppLogger(minimumLevel: config.logLevel)
}

func appLog(_ message: String, metadata: [String: String] = [:], source: String = #function) {
    appLogInfo(message, metadata: metadata, source: source)
}

func appLogDebug(_ message: String, metadata: [String: String] = [:], source: String = #function) {
    appLogger.log(level: .debug, message: message, metadata: metadata, source: source)
}

func appLogInfo(_ message: String, metadata: [String: String] = [:], source: String = #function) {
    appLogger.log(level: .info, message: message, metadata: metadata, source: source)
}

func appLogWarning(_ message: String, metadata: [String: String] = [:], source: String = #function) {
    appLogger.log(level: .warning, message: message, metadata: metadata, source: source)
}

func appLogError(_ message: String, metadata: [String: String] = [:], source: String = #function) {
    appLogger.log(level: .error, message: message, metadata: metadata, source: source)
}
