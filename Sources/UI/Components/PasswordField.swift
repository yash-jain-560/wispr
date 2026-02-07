import SwiftUI
import AppKit

struct PasswordField: View {
    let title: String
    @Binding var text: String
    @State private var isVisible: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                if isVisible {
                    TextField("", text: $text)
                        .textFieldStyle(.plain)
                } else {
                    SecureField("", text: $text)
                        .textFieldStyle(.plain)
                }
                
                Spacer()
                
                // Toggle Visibility
                Button(action: { isVisible.toggle() }) {
                    Image(systemName: isVisible ? "eye.slash" : "eye")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                
                // Paste Button
                Button(action: pasteFromClipboard) {
                    Image(systemName: "doc.on.clipboard")
                        .foregroundColor(.secondary)
                        .help("Paste from Clipboard")
                }
                .buttonStyle(.plain)
            }
            .padding(6)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private func pasteFromClipboard() {
        if let string = NSPasteboard.general.string(forType: .string) {
            self.text = string
        }
    }
}
