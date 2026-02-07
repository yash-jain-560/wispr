import SwiftUI

struct CarouselView: View {
    @State private var currentIndex = 0
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    let slides: [SlideData] = [
        SlideData(
            title: "Smart Formatting",
            description: "Hold fn to dictate. Wispr automatically fixes punctuation, capitalization, and grammar in real-time.",
            icon: "wand.and.stars"
        ),
        SlideData(
            title: "Style Control",
            description: "Choose your voice. Switch between Casual, Professional, or Academic styles in the Style tab.",
            icon: "textformat.alt"
        ),
        SlideData(
            title: "Privacy First",
            description: "Your data stays yours. Use Local AI (Ollama) mode for completely offline processing.",
            icon: "lock.shield"
        )
    ]
    
    var body: some View {
        ZStack {
            ForEach(0..<slides.count, id: \.self) { index in
                if index == currentIndex {
                    SlideCard(data: slides[index])
                        .transition(.opacity) // Simple fade
                        .id(index) // Ensure identity for transition
                }
            }
        }
        .frame(height: 220)
        .background(Color(nsColor: .windowBackgroundColor))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
        )
        .overlay(alignment: .bottom) {
            // Paging dots
            HStack(spacing: 8) {
                ForEach(0..<slides.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentIndex ? Color.primary : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .onTapGesture {
                            withAnimation {
                                currentIndex = index
                            }
                        }
                }
            }
            .padding(.bottom, 16)
        }
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentIndex = (currentIndex + 1) % slides.count
            }
        }
    }
}

struct SlideData {
    let title: String
    let description: String
    let icon: String
}

struct SlideCard: View {
    let data: SlideData
    
    var body: some View {
        HStack(spacing: 32) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: data.icon)
                        .font(.title2)
                        .foregroundColor(.accentColor)
                    Text(data.title)
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                Text(data.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
            }
            .padding(32)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color(nsColor: .controlBackgroundColor), Color(nsColor: .windowBackgroundColor)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}
