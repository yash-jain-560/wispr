import Foundation

struct DictionaryEntry: Identifiable, Codable, Hashable {
    let id: UUID
    var text: String
    var type: EntryType
    var category: EntryCategory
    var createdAt: Date

    enum EntryType: String, CaseIterable, Codable {
        case text = "Text"
        case email = "Email"
        case jargon = "Jargon"
        case name = "Name"
    }

    enum EntryCategory: String, CaseIterable, Codable {
        case personal = "Personal"
        case team = "Shared with team"
    }
    
    init(id: UUID = UUID(), text: String, type: EntryType = .text, category: EntryCategory = .personal, createdAt: Date = Date()) {
        self.id = id
        self.text = text
        self.type = type
        self.category = category
        self.createdAt = createdAt
    }
}
