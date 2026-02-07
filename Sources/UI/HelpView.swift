import SwiftUI

struct HelpView: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: 16) {
                Text("Need Help?")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Wispr Flow is your AI-powered dictation assistant.\nFor full documentation and support, verify our guide online.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            
            Link(destination: URL(string: "https://thewebvale.com")!) {
                HStack {
                    Text("Visit thewebvale.com")
                    Image(systemName: "arrow.up.right")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(24)
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .padding()
    }
}
