import SwiftUI

struct StyleView: View {
    @State private var selectedStyle: String = "Normal"
    
    let styles = [
        "Normal": "Standard formatting with punctuation.",
        "Casual": "Relaxed tone, allows slang and contractions.",
        "Professional": "Formal tone, precise grammar, no slang.",
        "Academic": "Complex sentence structures, expanded vocabulary.",
        "Bullet Points": "Formats dictation into concise bulleted lists."
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Style")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)
                .padding(.horizontal, 40)
            
            Text("Choose how Wispr formats your dictation.")
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            
            Divider().padding(.horizontal, 40)
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(styles.keys.sorted(), id: \.self) { key in
                        StyleCard(title: key, description: styles[key]!, isSelected: selectedStyle == key) {
                            selectedStyle = key
                        }
                    }
                }
                .padding(40)
            }
        }
    }
}

struct StyleCard: View {
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding(16)
            .background(isSelected ? Color.blue : Color(nsColor: .controlBackgroundColor))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
