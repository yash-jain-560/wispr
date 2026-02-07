import ApplicationServices
import Foundation

final class PushToTalkKeyMonitor {
    private enum KeyCode {
        static let leftOption: CGKeyCode = 58
        static let rightOption: CGKeyCode = 61
        static let fn: CGKeyCode = 63
    }

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var pollTimer: Timer?
    private var isPressed = false
    private let triggerKey: TriggerKey
    private let onStateChanged: (Bool) -> Void

    init(triggerKey: TriggerKey, onStateChanged: @escaping (Bool) -> Void) {
        self.triggerKey = triggerKey
        self.onStateChanged = onStateChanged
    }

    deinit {
        pollTimer?.invalidate()
    }

    func start() {
        guard eventTap == nil else {
            appLog("key monitor already active; ensuring poller is running")
            startStatePolling()
            return
        }

        let mask = CGEventMask(1 << CGEventType.flagsChanged.rawValue)
        let callback: CGEventTapCallBack = { _, type, event, userInfo in
            guard let userInfo else {
                return Unmanaged.passUnretained(event)
            }

            let monitor = Unmanaged<PushToTalkKeyMonitor>.fromOpaque(userInfo).takeUnretainedValue()
            return monitor.handleTap(type: type, event: event)
        }

        let userInfo = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: userInfo
        ) else {
            appLog("failed to create event tap; using polling fallback only")
            startStatePolling()
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)

        if let runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }

        CGEvent.tapEnable(tap: tap, enable: true)
        appLog("key monitor started with trigger=\(triggerKey.rawValue)")
        startStatePolling()
    }

    private func handleTap(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        guard type == .flagsChanged else {
            return Unmanaged.passUnretained(event)
        }

        updatePressedState(isTriggerPressed(in: event.flags))
        return Unmanaged.passUnretained(event)
    }

    private func startStatePolling() {
        guard pollTimer == nil else { return }

        let timer = Timer(timeInterval: 0.03, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.updatePressedState(self.isTriggerPressedNow())
        }
        pollTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func isTriggerPressed(in flags: CGEventFlags) -> Bool {
        switch triggerKey {
        case .fn:
            return flags.contains(.maskSecondaryFn)
        case .option:
            return flags.contains(.maskAlternate)
        }
    }

    private func isTriggerPressedNow() -> Bool {
        switch triggerKey {
        case .fn:
            return CGEventSource.keyState(.combinedSessionState, key: KeyCode.fn)
        case .option:
            let left = CGEventSource.keyState(.combinedSessionState, key: KeyCode.leftOption)
            let right = CGEventSource.keyState(.combinedSessionState, key: KeyCode.rightOption)
            if left || right {
                return true
            }
            let flags = CGEventSource.flagsState(.combinedSessionState)
            return isTriggerPressed(in: flags)
        }
    }

    private func updatePressedState(_ pressedNow: Bool) {
        guard pressedNow != isPressed else { return }
        isPressed = pressedNow
        appLog("trigger \(triggerKey.rawValue) -> \(pressedNow ? "pressed" : "released")")
        DispatchQueue.main.async { [onStateChanged] in
            onStateChanged(pressedNow)
        }
    }
}
