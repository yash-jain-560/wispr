import SwiftUI

struct DictionaryView: View {
    @ObservedObject var appState = AppState.shared
    @State private var selectedTab: DictionaryEntry.EntryCategory? = nil // nil = All
    @State private var searchText = ""
    @State private var showPromo = true
    @State private var showingAddSheet = false
    
    var filteredEntries: [DictionaryEntry] {
        var entries = appState.dictionaryEntries
        
        if let category = selectedTab {
            entries = entries.filter { $0.category == category }
        }
        
        if !searchText.isEmpty {
            entries = entries.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
        }
        
        return entries
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text("Dictionary")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    showingAddSheet = true // State to handle sheet
                }) {
                    Text("Add new")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.primary)
                        .colorInvert() // Text handles color
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 40)
            .padding(.horizontal, 40)
            .sheet(isPresented: $showingAddSheet) {
                AddDictionaryEntrySheet(isPresented: $showingAddSheet)
            }
            
            // Filter Tabs
            HStack(spacing: 24) {
                FilterTabButton(title: "All", isSelected: selectedTab == nil) { selectedTab = nil }
                FilterTabButton(title: "Personal", isSelected: selectedTab == .personal) { selectedTab = .personal }
                FilterTabButton(title: "Shared with team", isSelected: selectedTab == .team) { selectedTab = .team }
                
                Spacer()
                
                HStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    Image(systemName: "arrow.up.arrow.down")
                        .foregroundColor(.secondary)
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 10)
            
            Divider()
                .padding(.horizontal, 40)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Promo Card
                    if showPromo {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Wispr speaks the way you speak.")
                                    .font(.custom("Georgia", size: 28))
                                    .foregroundColor(Color(nsColor: .labelColor))
                                
                                Spacer()
                                
                                Button(action: { showPromo = false }) {
                                    Image(systemName: "xmark")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            
                            Text("Wispr learns your unique words and names — automatically or manually. **Add personal terms, company jargon, client names, or industry-specific lingo**. Share them with your team so everyone stays on the same page.")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                            
                            HStack(spacing: 12) {
                                TagPill(text: "Q3 Roadmap")
                                TagPill(text: "Wispr → Wispr", isStrike: true) // Simulating correction style
                                TagPill(text: "SF MOMA")
                                TagPill(text: "Figma Jam")
                                TagPill(text: "Company name")
                            }
                            .padding(.top, 8)
                            
                            Button(action: {}) {
                                Text("Add new word")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color.primary)
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 8)
                        }
                        .padding(24)
                        .background(Color.orange.opacity(0.05)) // Adaptive tint
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                        )
                    }
                    
                    // List
                    if filteredEntries.isEmpty {
                        Text("No entries found")
                            .foregroundColor(.secondary)
                            .padding(.top, 40)
                    } else {
                        List {
                            ForEach(filteredEntries) { entry in
                                DictionaryListRow(entry: entry)
                            }
                            .onDelete { indexSet in
                                // Map indexSet from filtered to actual index in AppState
                                // This is tricky with filtered lists, simplified for now:
                                // We will just remove from AppState by ID match.
                                indexSet.forEach { index in
                                    let entry = filteredEntries[index]
                                    if let idx = appState.dictionaryEntries.firstIndex(where: { $0.id == entry.id }) {
                                        appState.removeDictionaryEntry(at: IndexSet(integer: idx))
                                    }
                                }
                            }
                        }
                        .listStyle(.inset)
                        .background(Color(nsColor: .windowBackgroundColor))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }
}

struct FilterTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .primary : .secondary)
                .padding(.bottom, 8)
                .overlay(
                    Rectangle()
                        .frame(height: 2)
                        .foregroundColor(isSelected ? .black : .clear)
                        .offset(y: 10), // Push down to act as underline
                    alignment: .bottom
                )
        }
        .buttonStyle(.plain)
    }
}

struct DictionaryListRow: View {
    let entry: DictionaryEntry
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(entry.text)
                .font(.system(size: 14))
                .foregroundColor(.primary)
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
            
            Divider()
        }
    }
}

struct TagPill: View {
    let text: String
    var isStrike: Bool = false
    
    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .strikethrough(isStrike)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
            )
    }
}

struct AddDictionaryEntrySheet: View {
    @Binding var isPresented: Bool
    @State private var text = ""
    @State private var category: DictionaryEntry.EntryCategory = .personal
    @State private var type: DictionaryEntry.EntryType = .text
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add to Dictionary")
                .font(.headline)
            
            TextField("Word or Phrase", text: $text)
                .textFieldStyle(.roundedBorder)
            
            Picker("Category", selection: $category) {
                ForEach(DictionaryEntry.EntryCategory.allCases, id: \.self) { cat in
                    Text(cat.rawValue).tag(cat)
                }
            }
            
            Picker("Type", selection: $type) {
                ForEach(DictionaryEntry.EntryType.allCases, id: \.self) { t in
                    Text(t.rawValue).tag(t)
                }
            }
            
            HStack {
                Button("Cancel") { isPresented = false }
                Spacer()
                Button("Save") {
                    let entry = DictionaryEntry(text: text, type: type, category: category)
                    AppState.shared.addDictionaryEntry(entry)
                    isPresented = false
                }
                .disabled(text.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 350)
    }
}
