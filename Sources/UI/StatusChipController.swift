import AppKit

final class StatusChipController {
    private let window: NSPanel
    private let container: NSView
    private let waveformView = WaveformView(frame: NSRect(x: 0, y: 0, width: 64, height: 20))
    private let spinner = NSProgressIndicator(frame: NSRect(x: 0, y: 0, width: 18, height: 18))
    private let symbolView = NSImageView(frame: NSRect(x: 0, y: 0, width: 20, height: 20))
    private var renderTimer: Timer?
    private var currentState: ChipState = .idle

    init() {
        let initialFrame = NSRect(x: 0, y: 0, width: 120, height: 46)
        window = NSPanel(
            contentRect: initialFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .statusBar
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

        container = NSView(frame: initialFrame)
        container.wantsLayer = true
        container.layer?.cornerRadius = 23

        waveformView.frame.origin = NSPoint(x: (initialFrame.width - waveformView.frame.width) / 2, y: (initialFrame.height - waveformView.frame.height) / 2)
        waveformView.autoresizingMask = [.minXMargin, .maxXMargin, .minYMargin, .maxYMargin]
        container.addSubview(waveformView)

        spinner.style = .spinning
        spinner.controlSize = .small
        spinner.isDisplayedWhenStopped = false
        spinner.frame.origin = NSPoint(x: (initialFrame.width - spinner.frame.width) / 2, y: (initialFrame.height - spinner.frame.height) / 2)
        spinner.autoresizingMask = [.minXMargin, .maxXMargin, .minYMargin, .maxYMargin]
        container.addSubview(spinner)

        symbolView.imageScaling = .scaleProportionallyDown
        symbolView.contentTintColor = .white
        symbolView.frame.origin = NSPoint(x: (initialFrame.width - symbolView.frame.width) / 2, y: (initialFrame.height - symbolView.frame.height) / 2)
        symbolView.autoresizingMask = [.minXMargin, .maxXMargin, .minYMargin, .maxYMargin]
        container.addSubview(symbolView)

        window.contentView = container
        reposition()
        setState(.idle)
        window.orderFrontRegardless()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reposition),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    deinit {
        renderTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    func setState(_ state: ChipState) {
        currentState = state
        appLog("chip state -> \(state.title)")
        container.layer?.backgroundColor = state.backgroundColor.cgColor
        applyStateVisuals(state)
    }

    func setVoiceLevel(_ level: CGFloat) {
        guard currentState == .active else { return }
        waveformView.setVoiceLevel(level)
    }

    @objc private func reposition() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }

        let chipSize = NSSize(width: 120, height: 46)
        let inset: CGFloat = 20
        let frame = screen.visibleFrame
        let origin = NSPoint(
            x: frame.maxX - chipSize.width - inset,
            y: frame.minY + inset
        )
        window.setFrame(NSRect(origin: origin, size: chipSize), display: true)
    }

    private func applyStateVisuals(_ state: ChipState) {
        spinner.stopAnimation(nil)
        spinner.isHidden = true
        symbolView.isHidden = true

        switch state {
        case .idle:
            waveformView.isHidden = false
            waveformView.setMode(.idle)
            startRenderLoop()
        case .active:
            waveformView.isHidden = false
            waveformView.setMode(.active)
            startRenderLoop()
        case .transcribing, .typing:
            waveformView.isHidden = true
            spinner.isHidden = false
            spinner.startAnimation(nil)
            stopRenderLoop()
        case .success:
            waveformView.isHidden = true
            symbolView.isHidden = false
            symbolView.image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "success")
            stopRenderLoop()
        case .permission:
            waveformView.isHidden = true
            symbolView.isHidden = false
            symbolView.image = NSImage(systemSymbolName: "lock.fill", accessibilityDescription: "permission")
            stopRenderLoop()
        case .error:
            waveformView.isHidden = true
            symbolView.isHidden = false
            symbolView.image = NSImage(systemSymbolName: "exclamationmark.triangle.fill", accessibilityDescription: "error")
            stopRenderLoop()
        }
    }

    private func startRenderLoop() {
        guard renderTimer == nil else { return }
        let timer = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.waveformView.tick()
        }
        renderTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func stopRenderLoop() {
        renderTimer?.invalidate()
        renderTimer = nil
    }
}

private final class WaveformView: NSView {
    enum Mode {
        case idle
        case active
    }

    private var mode: Mode = .idle
    private var level: CGFloat = 0.08
    private var phase: CGFloat = 0

    override var isFlipped: Bool { true }

    func setMode(_ mode: Mode) {
        self.mode = mode
        if mode == .idle {
            level = 0.08
        }
        needsDisplay = true
    }

    func setVoiceLevel(_ level: CGFloat) {
        self.level = max(0.02, min(level, 1.0))
        needsDisplay = true
    }

    func tick() {
        phase += 0.35
        if mode == .idle {
            level = 0.08 + 0.02 * (sin(phase) + 1) / 2
        }
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        let barCount = 7
        let barWidth: CGFloat = 4
        let spacing: CGFloat = 4
        let totalWidth = CGFloat(barCount) * barWidth + CGFloat(barCount - 1) * spacing
        let originX = (bounds.width - totalWidth) / 2
        let centerY = bounds.height / 2
        let maxHeight: CGFloat = mode == .active ? 18 : 9
        let minHeight: CGFloat = 4

        let baseColor: NSColor = mode == .active ? .white : NSColor.white.withAlphaComponent(0.65)
        context.setFillColor(baseColor.cgColor)

        for index in 0 ..< barCount {
            let i = CGFloat(index)
            let wave = (sin(phase + i * 0.75) + 1) / 2
            let intensity = (0.35 + 0.65 * wave) * level
            let height = minHeight + (maxHeight - minHeight) * intensity
            let x = originX + i * (barWidth + spacing)
            let y = centerY - height / 2
            let rect = CGRect(x: x, y: y, width: barWidth, height: height)
            let path = CGPath(roundedRect: rect, cornerWidth: barWidth / 2, cornerHeight: barWidth / 2, transform: nil)
            context.addPath(path)
            context.fillPath()
        }
    }
}
