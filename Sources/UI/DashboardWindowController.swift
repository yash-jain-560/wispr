import AppKit
import SwiftUI

class DashboardWindowController: NSWindowController {
    convenience init() {
        let dashboardView = DashboardView()
        let hostingController = NSHostingController(rootView: dashboardView)
        
        // Window setup
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1100, height: 750),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.center()
        window.title = "Wispr Dashboard"
        window.contentViewController = hostingController
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        
        self.init(window: window)
    }
}
