import SwiftUI

struct SidebarView: View {
    @Binding var selection: SidebarItem
    @Binding var showSettings: Bool
    
    enum SidebarItem {
        case home, style, settings, help
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            // Header
            HStack {
                Image(systemName: "mic.fill")
                    .foregroundColor(.white) // Adaptive
                Text("Wispr")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .padding(.top, 20)
            .padding(.bottom, 30)
            .padding(.leading, 20)
            
            // Navigation
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    SidebarButton(title: "Home", icon: "square.grid.2x2", isSelected: selection == .home) { selection = .home }
                    SidebarButton(title: "Style", icon: "textformat", isSelected: selection == .style) { selection = .style }
                }
                .padding(.horizontal, 10)
            }
            
            Spacer()
            
            // Footer
            VStack(spacing: 4) {
                SidebarButton(title: "Settings", icon: "gearshape", isSelected: false) { 
                    showSettings = true 
                }
                SidebarButton(title: "Help", icon: "questionmark.circle", isSelected: selection == .help) { selection = .help }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 20)
        }
        .frame(width: 250)
        .background(Color(nsColor: .windowBackgroundColor)) // Dark side
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(Color(nsColor: .separatorColor)),
            alignment: .trailing
        )
    }
}

struct SidebarButton: View {
    let title: String
    let icon: String
    var isSelected: Bool = false
    var action: () -> Void = {}
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .frame(width: 20, height: 20)
                
                Text(title)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                
                Spacer()
            }
            .foregroundColor(isSelected ? .primary : .secondary)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color(nsColor: .controlColor) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
