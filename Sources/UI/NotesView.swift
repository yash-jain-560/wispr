import SwiftUI

struct NotesView: View {
    @ObservedObject var appState = AppState.shared
    @State private var showingAddSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text("Notes")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { showingAddSheet = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.primary)
                        .padding(10)
                        .background(Color(nsColor: .controlAccentColor).opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 40)
            .padding(.horizontal, 40)
            
            Divider().padding(.horizontal, 40)
            
            // Grid or List
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 20) {
                    ForEach(appState.notes) { note in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(note.title)
                                .font(.headline)
                                .lineLimit(1)
                            
                            Text(note.content)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Spacer()
                            
                            Text(note.createdAt, style: .date)
                                .font(.caption2)
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                        .padding(16)
                        .frame(height: 150)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        .contextMenu {
                            Button("Delete", role: .destructive) {
                                if let index = appState.notes.firstIndex(of: note) {
                                    appState.removeNote(at: IndexSet(integer: index))
                                }
                            }
                        }
                    }
                }
                .padding(40)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddNoteSheet(isPresented: $showingAddSheet)
        }
    }
}

struct AddNoteSheet: View {
    @Binding var isPresented: Bool
    @State private var title = ""
    @State private var content = ""
    
    var body: some View {
        VStack(spacing: 16) {
            Text("New Note")
                .font(.headline)
            
            TextField("Title", text: $title)
                .textFieldStyle(.roundedBorder)
            
            TextEditor(text: $content)
                .frame(minHeight: 200)
                .border(Color.secondary.opacity(0.2))
            
            HStack {
                Button("Cancel") { isPresented = false }
                Spacer()
                Button("Save") {
                    let newNote = NoteEntry(title: title, content: content)
                    AppState.shared.addNote(newNote)
                    isPresented = false
                }
                .disabled(title.isEmpty)
            }
        }
        .padding()
        .frame(width: 450, height: 400)
    }
}
