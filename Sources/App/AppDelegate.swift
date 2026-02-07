import AppKit
import ApplicationServices
import AVFoundation

final class AppDelegate: NSObject, NSApplicationDelegate {
    private lazy var statusChip = StatusChipController()
    private let recorder = AudioRecorder()
    private let transcriber: SpeechTranscriber
    private let textImprover: TextImprover
    private let typer = TextTyper()

    private var keyMonitor: PushToTalkKeyMonitor?
    private var permissionPollTimer: Timer?
    private var voiceLevelTimer: Timer?
    private var pendingStopWorkItem: DispatchWorkItem?
    private var isRecording = false
    private var isProcessing = false
    private var processingStartedAt: Date?

    private let config: AppConfig

    override init() {
        config = AppConfig()
        configureAppLogger(config: config)

        switch config.aiMode {
        case .local:
            textImprover = OllamaClient(config: config)
        case .cloud:
            textImprover = GeminiClient(config: config)
        }
        transcriber = SpeechTranscriber(config: config)

        super.init()
        var metadata = config.startupMetadata()
        metadata["app_version"] = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        metadata["app_build"] = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
        metadata["os_version"] = ProcessInfo.processInfo.operatingSystemVersionString
        appLogInfo("application config loaded", metadata: metadata, source: "startup")

        if config.aiMode == .local, config.localSTTModelPath == nil {
            appLogWarning(
                "local mode requires LOCAL_STT_MODEL_PATH for transcription",
                metadata: ["command": config.localSTTCommand],
                source: "startup"
            )
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusChip.setState(.idle)
        appLogInfo("application did finish launching", source: "lifecycle")

        requestAccessibilityPermissionPromptIfNeeded()
        requestAudioPermission()
        startMonitoringIfTrusted()
        refreshPermissionStateIfNeeded(source: "launch")
        
        // verify dashboard
        openDashboard()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        appLog("Application terminating, saving state...")
        // Force save is handled by AppState didSet, but we can verify or trigger a final save if we add explicit method
        // Since didSet is synchronous, it should have triggered on last change.
        // But let's add an explicit flush if needed, or simply log.
        // Also cleanup resources
        _ = recorder.stop() // Assuming recorder is the audioManager equivalent
        permissionPollTimer?.invalidate()
        voiceLevelTimer?.invalidate()
        pendingStopWorkItem?.cancel()
    }

    private func requestAccessibilityPermissionPromptIfNeeded() {
        guard !AXIsProcessTrusted() else {
            appLogDebug("accessibility already granted; skipping prompt", source: "permissions")
            return
        }

        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [promptKey: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        appLogInfo("requested accessibility permission prompt", source: "permissions")
    }

    private func requestAudioPermission() {
        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        if micStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                appLogInfo(
                    "microphone permission response",
                    metadata: ["granted": granted ? "1" : "0"],
                    source: "permissions"
                )
                DispatchQueue.main.async {
                    self?.refreshPermissionStateIfNeeded(source: "microphone-request-response")
                }
            }
        } else {
            appLogDebug(
                "microphone permission already set",
                metadata: ["status": String(micStatus.rawValue)],
                source: "permissions"
            )
            refreshPermissionStateIfNeeded(source: "microphone-already-set")
        }
    }

    private func startMonitoringIfTrusted() {
        if AXIsProcessTrusted() {
            appLogInfo("accessibility permission granted", source: "permissions")
            refreshPermissionStateIfNeeded(source: "accessibility-granted")
            permissionPollTimer?.invalidate()
            let monitor = PushToTalkKeyMonitor(triggerKey: config.triggerKey) { [weak self] pressed in
                self?.handleTrigger(pressed: pressed)
            }
            keyMonitor = monitor
            monitor.start()
            return
        }

        permissionPollTimer?.invalidate()
        statusChip.setState(.permission)
        appLogWarning("waiting for accessibility permission", source: "permissions")
        permissionPollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard AXIsProcessTrusted() else { return }
            timer.invalidate()
            appLogInfo("accessibility permission detected", source: "permissions")
            self?.startMonitoringIfTrusted()
            self?.refreshPermissionStateIfNeeded(source: "accessibility-detected")
        }
    }

    private func handleTrigger(pressed: Bool) {
        if pressed {
            if let workItem = pendingStopWorkItem {
                workItem.cancel()
                pendingStopWorkItem = nil
                statusChip.setState(.active)
                appLogDebug("cancelled pending stop; continuing recording", source: "pipeline")
                return
            }
            startRecordingIfPossible()
        } else {
            stopRecordingAndProcess()
        }
    }

    private func startRecordingIfPossible() {
        guard !isRecording, !isProcessing else {
            appLogDebug(
                "start ignored",
                metadata: ["isRecording": "\(isRecording)", "isProcessing": "\(isProcessing)"],
                source: "pipeline"
            )
            return
        }

        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        switch micStatus {
        case .authorized:
            break
        case .notDetermined:
            appLogWarning("microphone permission not determined; requesting access", source: "permissions")
            statusChip.setState(.permission)
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                appLogInfo(
                    "microphone permission response",
                    metadata: ["granted": granted ? "1" : "0"],
                    source: "permissions"
                )
                DispatchQueue.main.async {
                    self?.refreshPermissionStateIfNeeded(source: "start-recording-mic-response")
                }
            }
            return
        case .restricted, .denied:
            appLogError(
                "microphone permission not authorized",
                metadata: ["status": String(micStatus.rawValue)],
                source: "permissions"
            )
            statusChip.setState(.permission)
            return
        @unknown default:
            appLogError("microphone permission status unknown; blocking recording", source: "permissions")
            statusChip.setState(.permission)
            return
        }

        do {
            try recorder.start()
            isRecording = true
            statusChip.setState(.active)
            startVoiceLevelUpdates()
        } catch {
            var metadata: [String: String] = ["error": error.localizedDescription]
            if case let AudioRecorder.RecorderError.failedToStart(attempts, lastError) = error {
                metadata["attempts"] = attempts.joined(separator: ",")
                metadata["last_error"] = lastError ?? "none"
            }
            appLogError(
                "failed to start recording",
                metadata: metadata,
                source: "audio"
            )
            failAndReset()
        }
    }

    private func stopRecordingAndProcess() {
        guard isRecording else {
            appLogDebug("stop ignored: recording is not active", source: "pipeline")
            return
        }
        guard pendingStopWorkItem == nil else { return }

        let workItem = DispatchWorkItem { [weak self] in
            self?.finalizeStopAndProcess()
        }
        pendingStopWorkItem = workItem
        appLogDebug(
            "scheduled recording stop",
            metadata: ["tail_ms": String(config.recordingTailMS)],
            source: "pipeline"
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(config.recordingTailMS), execute: workItem)
    }

    private func handleTranscriptionResult(_ result: Result<String, Error>, sourceAudioURL: URL) {
        if let transcribeMS = elapsedMilliseconds(since: processingStartedAt) {
            appLogInfo("transcription stage finished", metadata: ["transcribe_ms": String(transcribeMS)], source: "pipeline")
        }

        switch result {
        case .success(let transcript):
            if config.aiMode == .cloud, config.cloudSinglePass {
                typeAndFinish(transcript, sourceAudioURL: sourceAudioURL)
                return
            }

            let cleanupStartedAt = Date()
            textImprover.improve(
                transcript: transcript,
                targetLanguage: config.targetLanguage
            ) { [weak self] improved in
                DispatchQueue.main.async {
                    if let cleanupMS = self?.elapsedMilliseconds(since: cleanupStartedAt) {
                        appLogInfo("cleanup stage finished", metadata: ["cleanup_ms": String(cleanupMS)], source: "pipeline")
                    }

                    switch improved {
                    case .success(let cleaned):
                        self?.typeAndFinish(cleaned, sourceAudioURL: sourceAudioURL)
                    case .failure:
                        if self?.config.targetLanguage != nil {
                            appLogWarning("translation failed; using raw transcript", source: "ai")
                        } else {
                            appLogWarning("cleanup failed; using raw transcript", source: "ai")
                        }
                        self?.typeAndFinish(transcript, sourceAudioURL: sourceAudioURL)
                    }
                }
            }
        case .failure(let error):
            cleanupAudio(sourceAudioURL)
            if case let SpeechTranscriber.TranscriberError.rateLimited(message) = error {
                isProcessing = false
                processingStartedAt = nil
                appLogWarning(
                    "transcription rate-limited; dropped utterance",
                    metadata: ["error": message],
                    source: "pipeline"
                )
                statusChip.setState(.idle)
                return
            }
            failAndReset()
        }
    }

    private var dashboardWindowController: DashboardWindowController?

    private func typeAndFinish(_ text: String, sourceAudioURL: URL) {
        statusChip.setState(.typing)
        typer.type(text)
        
        // Update AppState with new transcript
        DispatchQueue.main.async {
            AppState.shared.addTranscript(text)
        }
        
        cleanupAudio(sourceAudioURL)
        isProcessing = false
        var metadata: [String: String] = [:]
        if let totalMS = elapsedMilliseconds(since: processingStartedAt) {
            metadata["total_ms"] = String(totalMS)
        }
        appLogInfo("pipeline finished", metadata: metadata, source: "pipeline")
        processingStartedAt = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.statusChip.setState(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                self?.statusChip.setState(.idle)
            }
        }
    }
    
    @objc func openDashboard() {
        if dashboardWindowController == nil {
            dashboardWindowController = DashboardWindowController()
        }
        dashboardWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func cleanupAudio(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
        appLogDebug("deleted temp audio", metadata: ["file": url.lastPathComponent], source: "audio")
    }

    private func failAndReset() {
        pendingStopWorkItem?.cancel()
        pendingStopWorkItem = nil
        stopVoiceLevelUpdates()
        isRecording = false
        isProcessing = false
        var metadata: [String: String] = [:]
        if let totalMS = elapsedMilliseconds(since: processingStartedAt) {
            metadata["total_ms"] = String(totalMS)
        }
        appLogError("pipeline failed; resetting to idle", metadata: metadata, source: "pipeline")
        processingStartedAt = nil
        statusChip.setState(.error)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.statusChip.setState(.idle)
        }
    }

    private func refreshPermissionStateIfNeeded(source: String) {
        guard !isRecording, !isProcessing else { return }

        let accessibilityGranted = AXIsProcessTrusted()
        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)

        if accessibilityGranted && micStatus == .authorized {
            statusChip.setState(.idle)
            appLogDebug(
                "permission state resolved",
                metadata: ["accessibility": "1", "microphone": "authorized", "source_step": source],
                source: "permissions"
            )
            return
        }

        if !accessibilityGranted || micStatus == .denied || micStatus == .restricted {
            statusChip.setState(.permission)
            appLogWarning(
                "permission still missing",
                metadata: [
                    "accessibility": accessibilityGranted ? "1" : "0",
                    "microphone_status": String(micStatus.rawValue),
                    "source_step": source
                ],
                source: "permissions"
            )
        }
    }

    private func elapsedMilliseconds(since start: Date?) -> Int? {
        guard let start else { return nil }
        return Int(Date().timeIntervalSince(start) * 1000)
    }

    private func finalizeStopAndProcess() {
        pendingStopWorkItem = nil
        guard isRecording else { return }
        isRecording = false
        stopVoiceLevelUpdates()

        guard let audioURL = recorder.stop() else {
            appLogError("missing audio URL after stop", source: "audio")
            failAndReset()
            return
        }

        isProcessing = true
        processingStartedAt = Date()
        statusChip.setState(.transcribing)

        transcriber.transcribe(fileURL: audioURL, targetLanguage: config.targetLanguage) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleTranscriptionResult(result, sourceAudioURL: audioURL)
            }
        }
    }

    private func startVoiceLevelUpdates() {
        stopVoiceLevelUpdates()
        let timer = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self else { return }
            if let level = self.recorder.averagePowerLevel() {
                self.statusChip.setVoiceLevel(level)
            }
        }
        voiceLevelTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func stopVoiceLevelUpdates() {
        voiceLevelTimer?.invalidate()
        voiceLevelTimer = nil
    }
}
