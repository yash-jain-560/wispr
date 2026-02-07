import SwiftUI

struct SnippetsView: View {
    @ObservedObject var appState = AppState.shared
    @State private var showingAddSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text("Snippets")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { showingAddSheet = true }) {
                    Text("Add new")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(nsColor: .controlAccentColor).opacity(0.1)) // Adaptive
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 40)
            .padding(.horizontal, 40)
            
            Divider().padding(.horizontal, 40)
            
            // List
            if appState.snippets.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "scissors")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No snippets yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Create shortcuts for frequently used text.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(appState.snippets) { snippet in
                        HStack {
                            Text(snippet.keyword)
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.semibold)
                                .foregroundColor(Color.primary)
                                .padding(6)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(4)
                            
                            Spacer()
                            
                            Text(snippet.replacement)
                                .lineLimit(1)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: appState.removeSnippet)
                }
                .listStyle(.inset)
                .padding(.horizontal, 20)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddSnippetSheet(isPresented: $showingAddSheet)
        }
    }
}

struct AddSnippetSheet: View {
    @Binding var isPresented: Bool
    @State private var keyword = ""
    @State private var replacement = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("New Snippet")
                .font(.headline)
            
            TextField("Keyword (e.g. ;email)", text: $keyword)
                .textFieldStyle(.roundedBorder)
            
            TextEditor(text: $replacement)
                .font(.body)
                .border(Color.secondary.opacity(0.2))
                .frame(height: 100)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary.opacity(0.2)))

            HStack {
                Button("Cancel") { isPresented = false }
                Spacer()
                Button("Save") {
                    let newSnippet = SnippetEntry(keyword: keyword, replacement: replacement)
                    AppState.shared.addSnippet(newSnippet)
                    isPresented = false
                }
                .disabled(keyword.isEmpty || replacement.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 400, height: 300)
    }
}
