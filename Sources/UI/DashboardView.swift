import SwiftUI

struct DashboardView: View {
    @ObservedObject var appState = AppState.shared
    @State private var selection: SidebarView.SidebarItem = .home
    @State private var showSettings = false
    
    var colorScheme: ColorScheme? {
        switch appState.appTheme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            SidebarView(selection: $selection, showSettings: $showSettings)
            
            ZStack {
                Color(nsColor: .windowBackgroundColor).ignoresSafeArea()
                
                switch selection {
                case .home:
                    HomeView()
                case .style:
                    StyleView()
                case .help:
                     HelpView()
                default:
                    HomeView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .cornerRadius(10)
            .padding(.top, 10)
            .padding(.trailing, 10)
            .padding(.bottom, 10)
            
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
        .frame(minWidth: 1000, minHeight: 700)
        .preferredColorScheme(colorScheme)
    }
}
