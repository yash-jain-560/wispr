import Foundation
import SwiftUI
import Combine

struct TranscriptionItem: Identifiable, Codable, Hashable {
    let id: UUID
    let text: String
    let timestamp: Date
    
    init(id: UUID = UUID(), text: String, timestamp: Date = Date()) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
    }
}

struct SnippetEntry: Identifiable, Codable, Hashable {
    let id: UUID
    var keyword: String
    var replacement: String
    
    init(id: UUID = UUID(), keyword: String, replacement: String) {
        self.id = id
        self.keyword = keyword
        self.replacement = replacement
    }
}

struct NoteEntry: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var content: String
    var createdAt: Date
    
    init(id: UUID = UUID(), title: String, content: String, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
    }
}

// Data container for persistence
struct AppData: Codable {
    var recentTranscripts: [TranscriptionItem]
    var dictionaryEntries: [DictionaryEntry]
    var snippets: [SnippetEntry]
    var notes: [NoteEntry]
    var appTheme: AppState.AppTheme
    var totalWords: Int
    
    // Config
    var selectedStyle: String?
    var aiProvider: String?
    var openaiKey: String?
    var anthropicKey: String?
    var geminiKey: String?
    var geminiModel: String?
    var selectedMicrophoneID: String?
}

class AppState: ObservableObject {
    @Published var recentTranscripts: [TranscriptionItem] = [] {
        didSet { saveData() }
    }
    @Published var dictionaryEntries: [DictionaryEntry] = [] {
        didSet { saveData() }
    }
    @Published var snippets: [SnippetEntry] = [] {
        didSet { saveData() }
    }
    @Published var notes: [NoteEntry] = [] {
        didSet { saveData() }
    }
    
    // Theme
    @Published var appTheme: AppTheme = .system {
        didSet { saveData() }
    }
    
    // Config
    @Published var selectedStyle: String = "Normal" {
        didSet { saveData() }
    }
    @Published var aiProvider: String = "gemini" { // gemini, openai, anthropic
        didSet { saveData() }
    }
    @Published var openaiKey: String = "" {
        didSet { saveData() }
    }
    @Published var anthropicKey: String = "" {
        didSet { saveData() }
    }
    @Published var geminiKey: String = "" {
        didSet { saveData() }
    }
    @Published var geminiModel: String = "gemini-1.5-flash" {
        didSet { saveData() }
    }
    @Published var selectedMicrophoneID: String = "default" {
        didSet { saveData() }
    }
    
    enum AppTheme: String, CaseIterable, Identifiable, Codable {
        case system = "System"
        case light = "Light"
        case dark = "Dark"
        
        var id: String { rawValue }
    }
    
    // Derived Stats
    var streakDays: Int {
        // Simple logic: check unique days in recentTranscripts
        let calendar = Calendar.current
        let days = Set(recentTranscripts.map { calendar.startOfDay(for: $0.timestamp) })
        return days.count
    }
    
    var totalWords: Int {
        recentTranscripts.reduce(0) { $0 + $1.text.split(separator: " ").count }
    }
    
    // WPM is tricky without duration data, keeping it mocked or simple avg for now
    @Published var wpm: Int = 135 
    
    static let shared = AppState()
    
    private init() {
        loadData()
    }
    
    private func loadData() {
        if let data: AppData = PersistenceManager.shared.load() {
            self.recentTranscripts = data.recentTranscripts
            self.dictionaryEntries = data.dictionaryEntries
            self.snippets = data.snippets
            self.notes = data.notes
            self.appTheme = data.appTheme
            // self.totalWords is derived from transcripts, so no need to set it explicitly
            
            // Config
            self.selectedStyle = data.selectedStyle ?? "Normal"
            self.aiProvider = data.aiProvider ?? "gemini"
            self.openaiKey = data.openaiKey ?? ""
            self.anthropicKey = data.anthropicKey ?? ""
            self.geminiKey = data.geminiKey ?? ""
            self.geminiModel = data.geminiModel ?? "gemini-1.5-flash"
            self.selectedMicrophoneID = data.selectedMicrophoneID ?? "default"
        } else {
            // Seed initial data only if no file exists
            self.dictionaryEntries = [
                DictionaryEntry(text: "yaashjainn@gmail.com", type: .email, category: .personal),
                DictionaryEntry(text: "Wispr Flow", type: .jargon, category: .personal)
            ]
        }
    }
    
    private func saveData() {
        let data = AppData(
            recentTranscripts: recentTranscripts,
            dictionaryEntries: dictionaryEntries,
            snippets: snippets,
            notes: notes,
            appTheme: appTheme,
            totalWords: totalWords,
            selectedStyle: selectedStyle,
            aiProvider: aiProvider,
            openaiKey: openaiKey,
            anthropicKey: anthropicKey,
            geminiKey: geminiKey,
            geminiModel: geminiModel,
            selectedMicrophoneID: selectedMicrophoneID
        )
        PersistenceManager.shared.save(data)
    }
    
    func addTranscript(_ text: String) {
        let item = TranscriptionItem(text: text)
        // Prepend to show newest first
        recentTranscripts.insert(item, at: 0)
    }
    
    func addDictionaryEntry(_ entry: DictionaryEntry) {
        dictionaryEntries.append(entry)
    }
    
    func removeDictionaryEntry(at offsets: IndexSet) {
        dictionaryEntries.remove(atOffsets: offsets)
    }
    
    func addSnippet(_ snippet: SnippetEntry) {
        snippets.append(snippet)
    }
    
    func removeSnippet(at offsets: IndexSet) {
        snippets.remove(atOffsets: offsets)
    }
    
    func addNote(_ note: NoteEntry) {
        notes.append(note)
    }
    
    func removeNote(at offsets: IndexSet) {
        notes.remove(atOffsets: offsets)
    }
}
