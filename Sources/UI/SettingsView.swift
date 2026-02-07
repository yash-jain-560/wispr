import SwiftUI
import AVFoundation

struct SettingsView: View {
    @ObservedObject var appState = AppState.shared
    @Environment(\.presentationMode) var presentationMode
    
    enum SettingsTab: String, CaseIterable {
        case general = "General"
        case apiKeys = "API Keys"
        case audio = "Audio"
    }
    
    @State private var selectedTab: SettingsTab = .general
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.plain)
                .foregroundColor(.blue)
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            HStack(alignment: .top, spacing: 0) {
                // Sidebar
                VStack(spacing: 1) {
                    ForEach(SettingsTab.allCases, id: \.self) { tab in
                        Button(action: { selectedTab = tab }) {
                            HStack {
                                Image(systemName: tabIcon(for: tab))
                                    .frame(width: 20)
                                Text(tab.rawValue)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(selectedTab == tab ? Color.blue.opacity(0.1) : Color.clear)
                            .foregroundColor(selectedTab == tab ? .blue : .primary)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .frame(width: 150)
                .background(Color(nsColor: .alternatingContentBackgroundColors[0]))
                
                Divider()
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        switch selectedTab {
                        case .general:
                            GeneralSettingsView()
                        case .apiKeys:
                            APISettingsView()
                        case .audio:
                            AudioSettingsView()
                        }
                    }
                    .padding(24)
                }
            }
        }
        .frame(width: 600, height: 400)
    }
    
    func tabIcon(for tab: SettingsTab) -> String {
        switch tab {
        case .general: return "gear"
        case .apiKeys: return "key"
        case .audio: return "waveform"
        }
    }
}

struct GeneralSettingsView: View {
    @ObservedObject var appState = AppState.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("General")
                .font(.headline)
            
            Picker("Theme", selection: $appState.appTheme) {
                ForEach(AppState.AppTheme.allCases) { theme in
                    Text(theme.rawValue).tag(theme)
                }
            }
            .pickerStyle(.segmented)
            .padding(.bottom)
            
            Text("Appears in Menu Bar")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct APISettingsView: View {
    @ObservedObject var appState = AppState.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("AI Provider Configuration")
                .font(.headline)
            
            Picker("Provider", selection: $appState.aiProvider) {
                Text("Gemini").tag("gemini")
                Text("OpenAI").tag("openai")
                Text("Anthropic").tag("anthropic")
                Text("Local (Ollama)").tag("local")
            }
            .pickerStyle(.segmented)
            
            Divider()
            
            if appState.aiProvider == "gemini" {
                PasswordField(title: "Gemini API Key", text: $appState.geminiKey)
                
                TextField("Model Name", text: $appState.geminiModel)
                    .textFieldStyle(.roundedBorder)
            } else if appState.aiProvider == "openai" {
                PasswordField(title: "OpenAI API Key", text: $appState.openaiKey)
            } else if appState.aiProvider == "anthropic" {
                PasswordField(title: "Anthropic API Key", text: $appState.anthropicKey)
            } else {
                Text("Ensure Ollama is running locally on default port 11434.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if appState.geminiKey.isEmpty && appState.aiProvider == "gemini" {
                Text("⚠️ API Key is required")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }
}

struct AudioSettingsView: View {
    @ObservedObject var appState = AppState.shared
    @State private var availableDevices: [AVCaptureDevice] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Audio Settings")
                .font(.headline)
            
            Text("Input Device")
                .foregroundColor(.secondary)
            
            Picker("Microphone", selection: $appState.selectedMicrophoneID) {
                Text("System Default").tag("default")
                ForEach(availableDevices, id: \.uniqueID) { device in
                    Text(device.localizedName).tag(device.uniqueID)
                }
            }
            .pickerStyle(.menu)
            
            Text("Wispr uses the selected microphone for dictation.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .onAppear {
            refreshDevices()
        }
    }
    
    private func refreshDevices() {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.microphone, .external],
            mediaType: .audio,
            position: .unspecified
        )
        self.availableDevices = discoverySession.devices
    }
}
