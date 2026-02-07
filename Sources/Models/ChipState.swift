import AppKit

enum ChipState {
    case idle
    case active
    case transcribing
    case typing
    case success
    case permission
    case error

    var title: String {
        switch self {
        case .idle:
            return "idle"
        case .active:
            return "active"
        case .transcribing:
            return "transcribing"
        case .typing:
            return "typing"
        case .success:
            return "success"
        case .permission:
            return "no access"
        case .error:
            return "error"
        }
    }

    var backgroundColor: NSColor {
        switch self {
        case .idle:
            return NSColor.black.withAlphaComponent(0.82)
        case .active:
            return NSColor.systemGreen.withAlphaComponent(0.85)
        case .transcribing:
            return NSColor.systemOrange.withAlphaComponent(0.88)
        case .typing:
            return NSColor.systemBlue.withAlphaComponent(0.88)
        case .success:
            return NSColor.systemMint.withAlphaComponent(0.92)
        case .permission:
            return NSColor.systemYellow.withAlphaComponent(0.9)
        case .error:
            return NSColor.systemRed.withAlphaComponent(0.9)
        }
    }
}
