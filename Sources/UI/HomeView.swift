import SwiftUI

struct HomeView: View {
    @ObservedObject var appState = AppState.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Header & Stats
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome back, Yash")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 24) {
                        StatPill(icon: "flame.fill", text: "\(appState.streakDays) days", color: .orange)
                        StatPill(icon: "text.quote", text: "\(appState.totalWords) words", color: .blue)
                        StatPill(icon: "speedometer", text: "\(appState.wpm) wpm", color: .yellow)
                    }
                }
                
                // Carousel
                CarouselView()
                    .frame(height: 220)
                    .background(Color.yellow.opacity(0.1)) // Fallback if asset missing, adaptive-ish
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                    )
                
                // Timeline
                VStack(alignment: .leading, spacing: 16) {
                    Text("TODAY")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .tracking(1)
                    
                    LazyVStack(spacing: 0) {
                        ForEach(appState.recentTranscripts) { item in
                            TimelineItemView(item: item)
                        }
                        
                        // Mock Items for UI visualization if empty
                        if appState.recentTranscripts.isEmpty {
                            TimelineItemView(item: TranscriptionItem(text: "The implementation is as perfect as I wanted, but it's opening on the web. I am building a Mac application."))
                            TimelineItemView(item: TranscriptionItem(text: "This is the reference screenshot of what the configuration panel will look like."))
                        }
                    }
                    .background(Color(nsColor: .windowBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                    )
                }
            }
            .padding(40)
        }
    }
}

struct StatPill: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 14))
            Text(text)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
        }
    }
}

struct TimelineItemView: View {
    let item: TranscriptionItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            Text(item.timestamp, style: .time)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(item.text)
                .font(.system(size: 14))
                .foregroundColor(.primary)
                .lineLimit(nil)
            
            Spacer()
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(nsColor: .separatorColor)),
            alignment: .bottom
        )
    }
}
