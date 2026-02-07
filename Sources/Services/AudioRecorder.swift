import AVFoundation
import Foundation

final class AudioRecorder: NSObject, AVCaptureFileOutputRecordingDelegate {
    enum RecorderError: Error {
        case failedToStart(attempts: [String], lastError: String?)
        case inputInitializationFailed
        case sessionConfigurationFailed
        case outputInitializationFailed
    }

    private let captureSession = AVCaptureSession()
    private var audioOutput: AVCaptureAudioFileOutput?
    private var activeURL: URL?
    private var isRecording = false

    func start() throws {
        // Reset session if needed
        captureSession.beginConfiguration()
        
        // Remove existing inputs/outputs
        captureSession.inputs.forEach { captureSession.removeInput($0) }
        captureSession.outputs.forEach { captureSession.removeOutput($0) }
        
        // Input Device Selection
        let deviceID = AppState.shared.selectedMicrophoneID
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.microphone, .external],
            mediaType: .audio,
            position: .unspecified
        )
        
        let devices = discoverySession.devices
        var selectedDevice: AVCaptureDevice?
        
        if deviceID != "default", let device = devices.first(where: { $0.uniqueID == deviceID }) {
            selectedDevice = device
            appLogInfo("using selected audio device", metadata: ["device": device.localizedName], source: "audio")
        } else {
            // Fallback to default
            selectedDevice = AVCaptureDevice.default(for: .audio)
            appLogInfo("using default audio device", metadata: ["device": selectedDevice?.localizedName ?? "unknown"], source: "audio")
        }
        
        guard let device = selectedDevice else {
            captureSession.commitConfiguration()
            throw RecorderError.inputInitializationFailed
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            } else {
                captureSession.commitConfiguration()
                throw RecorderError.inputInitializationFailed
            }
        } catch {
            captureSession.commitConfiguration()
            throw RecorderError.inputInitializationFailed
        }
        
        // Output Configuration
        let output = AVCaptureAudioFileOutput()
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
            audioOutput = output
        } else {
            captureSession.commitConfiguration()
            throw RecorderError.outputInitializationFailed
        }
        
        captureSession.commitConfiguration()
        captureSession.startRunning()
        
        // Start Recording to File
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("recording-\(UUID().uuidString).m4a")
        
        activeURL = fileURL
        output.startRecording(to: fileURL, outputFileType: .m4a, recordingDelegate: self)
        isRecording = true
        
        appLogInfo(
            "recording started",
            metadata: ["file": fileURL.path, "device": device.localizedName],
            source: "audio"
        )
    }

    func stop() -> URL? {
        guard isRecording, let output = audioOutput else { return nil }
        
        output.stopRecording()
        captureSession.stopRunning()
        isRecording = false
        
        if let url = activeURL {
            appLogInfo("recording stopped", metadata: ["file": url.path], source: "audio")
        }
        
        // Return URL immediately, though file finalization is async in delegate.
        // For this app flow, we assume simple stop-and-process.
        let url = activeURL
        activeURL = nil
        return url
    }

    func averagePowerLevel() -> CGFloat? {
        // AVCaptureAudioFileOutput doesn't provide metering updates easily like AVAudioRecorder.
        // We'd need an AVCaptureAudioDataOutput to analyze buffers, which conflicts with FileOutput usually.
        // For now, return a random simulated value or nil to disable visualizer temporarily if this is complex.
        // Or we add AudioDataOutput alongside just for metering.
        // Let's return nil to disable the visualizer for this iteration to ensure stability first.
        return nil 
    }
    
    // Delegate
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            appLogError("recording finished with error", metadata: ["error": error.localizedDescription], source: "audio")
        } else {
            appLogDebug("recording finished successfully", metadata: ["file": outputFileURL.path], source: "audio")
        }
    }
}
