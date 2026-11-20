// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import Combine
import CoreGraphics
import Foundation

/// Monitors Caps Lock / held Shift state, hardware & UI display brightness changes,
/// keyboard backlight keys, and paste events for the Dynamic Island and halo overlay.
final class NotchInputFeedbackService: ObservableObject {
    static let shared = NotchInputFeedbackService()
    static let pasteTriggeredNotification = Notification.Name("VorssaintDidPaste")

    @Published private(set) var modifierIndicator: NotchModifierIndicator? = nil

    let brightnessChanged = PassthroughSubject<Double, Never>()
    let keyboardLightKeyPressed = PassthroughSubject<Void, Never>()
    let pasteTriggered = PassthroughSubject<Void, Never>()

    private var running = false
    private var screensAsleep = false
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var pasteNotificationObserver: NSObjectProtocol?
    private var workspaceObservers: [NSObjectProtocol] = []
    private var pollTimer: Timer?
    private var shiftHoldWork: DispatchWorkItem?
    private var brightnessBurstWorks: [DispatchWorkItem] = []

    private var modifierTracker = NotchModifierHoldTracker()
    private var brightnessDetector = NotchBrightnessChangeDetector()
    private var pasteDetector = NotchPasteDetector()
    private var lastBrightnessPollAt: TimeInterval = 0

    private init() {}

    func syncWithPreferences() {
        if NotchSupport.isEnabled() {
            start()
        } else {
            stop()
        }
    }

    func start() {
        guard !running else { return }
        running = true
        screensAsleep = false

        let now = ProcessInfo.processInfo.systemUptime
        if let initialBrightness = readSystemBrightness() {
            _ = brightnessDetector.observe(level: initialBrightness, at: now)
        }
        lastBrightnessPollAt = now
        pollModifierFlags(at: now)

        let mask: NSEvent.EventTypeMask = [.flagsChanged, .keyDown, .systemDefined]
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handle(event)
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handle(event)
            return event
        }

        pasteNotificationObserver = NotificationCenter.default.addObserver(
            forName: Self.pasteTriggeredNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.triggerPaste()
        }

        let workspace = NSWorkspace.shared.notificationCenter
        workspaceObservers = [
            workspace.addObserver(forName: NSWorkspace.screensDidSleepNotification, object: nil, queue: .main) { [weak self] _ in
                self?.screensAsleep = true
            },
            workspace.addObserver(forName: NSWorkspace.screensDidWakeNotification, object: nil, queue: .main) { [weak self] _ in
                guard let self else { return }
                self.screensAsleep = false
                if let level = self.readSystemBrightness() {
                    self.brightnessDetector.noteHandled(level: level, at: ProcessInfo.processInfo.systemUptime)
                }
            }
        ]

        let timer = Timer(timeInterval: 0.15, repeats: true) { [weak self] _ in
            self?.timerTick()
        }
        timer.tolerance = 0.04
        RunLoop.main.add(timer, forMode: .common)
        pollTimer = timer
    }

    func stop() {
        guard running else { return }
        running = false
        pollTimer?.invalidate()
        pollTimer = nil
        shiftHoldWork?.cancel()
        shiftHoldWork = nil
        cancelBrightnessBursts()
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        globalMonitor = nil
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        localMonitor = nil
        if let pasteNotificationObserver { NotificationCenter.default.removeObserver(pasteNotificationObserver) }
        pasteNotificationObserver = nil
        let workspace = NSWorkspace.shared.notificationCenter
        for observer in workspaceObservers { workspace.removeObserver(observer) }
        workspaceObservers = []
        screensAsleep = false
        modifierTracker = NotchModifierHoldTracker()
        brightnessDetector = NotchBrightnessChangeDetector()
        pasteDetector = NotchPasteDetector()
        if modifierIndicator != nil { modifierIndicator = nil }
    }

    /// Marks an adjustment already performed by `BrightnessService` so polling does not re-fire it.
    func noteObservedBrightness(_ level: Double) {
        let work = { [weak self] in
            guard let self, self.running else { return }
            self.brightnessDetector.noteHandled(level: level, at: ProcessInfo.processInfo.systemUptime)
        }
        if Thread.isMainThread { work() } else { DispatchQueue.main.async(execute: work) }
    }

    private func handle(_ event: NSEvent) {
        guard running else { return }
        switch event.type {
        case .flagsChanged:
            let flags = event.modifierFlags
            let capsLock = flags.contains(.capsLock)
                || CGEventSource.flagsState(.combinedSessionState).contains(.maskAlphaShift)
            let shiftDown = flags.contains(.shift)
            let otherDown = !flags.intersection([.command, .control, .option]).isEmpty
            applyModifierFlags(capsLock: capsLock, shiftDown: shiftDown, otherModifiersDown: otherDown,
                               at: ProcessInfo.processInfo.systemUptime)
        case .keyDown:
            if !event.isARepeat,
               NotchPasteDetector.isPasteKey(
                   keyCode: event.keyCode,
                   charactersIgnoringModifiers: event.charactersIgnoringModifiers,
                   command: event.modifierFlags.contains(.command),
                   control: event.modifierFlags.contains(.control)
               ) {
                triggerPaste()
            } else if BrightnessSupport.isBrightnessKeyCode(Int(event.keyCode)),
                      event.modifierFlags.intersection([.command, .control, .option, .shift]).isEmpty {
                noteBrightnessKeyPressed()
            }
        case .systemDefined:
            if let press = BrightnessSupport.brightnessKeyEvent(subtype: Int(event.subtype.rawValue), data1: event.data1),
               press.isKeyDown {
                noteBrightnessKeyPressed()
            } else if BrightnessSupport.isKeyboardLightPress(subtype: Int(event.subtype.rawValue), data1: event.data1) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
                    guard let self, self.running else { return }
                    self.keyboardLightKeyPressed.send()
                }
            }
        default:
            break
        }
    }

    private func timerTick() {
        guard running, !screensAsleep else { return }
        let now = ProcessInfo.processInfo.systemUptime
        pollModifierFlags(at: now)
        if now - lastBrightnessPollAt >= 0.24 {
            lastBrightnessPollAt = now
            sampleSystemBrightness(forceBoundaryOnKey: false)
        }
    }

    private func pollModifierFlags(at now: TimeInterval) {
        let flags = CGEventSource.flagsState(.combinedSessionState)
        let capsLock = flags.contains(.maskAlphaShift)
        let shiftDown = flags.contains(.maskShift)
        let otherDown = !flags.isDisjoint(with: [.maskCommand, .maskControl, .maskAlternate])
        applyModifierFlags(capsLock: capsLock, shiftDown: shiftDown, otherModifiersDown: otherDown, at: now)
    }

    private func applyModifierFlags(capsLock: Bool, shiftDown: Bool, otherModifiersDown: Bool, at now: TimeInterval) {
        let next = modifierTracker.update(capsLock: capsLock, shiftDown: shiftDown, otherModifiersDown: otherModifiersDown, at: now)
        if next != modifierIndicator {
            modifierIndicator = next
        }
        if shiftDown, !otherModifiersDown, next != .shift, next != .both {
            if shiftHoldWork == nil {
                let work = DispatchWorkItem { [weak self] in
                    guard let self, self.running else { return }
                    self.shiftHoldWork = nil
                    self.pollModifierFlags(at: ProcessInfo.processInfo.systemUptime)
                }
                shiftHoldWork = work
                DispatchQueue.main.asyncAfter(deadline: .now() + NotchModifierHoldTracker.shiftHoldDelay + 0.01, execute: work)
            }
        } else {
            shiftHoldWork?.cancel()
            shiftHoldWork = nil
        }
    }

    private func noteBrightnessKeyPressed() {
        let now = ProcessInfo.processInfo.systemUptime
        brightnessDetector.noteKeyPress(at: now)
        cancelBrightnessBursts()
        let offsets: [(TimeInterval, Bool)] = [(0.02, false), (0.08, false), (0.18, true)]
        brightnessBurstWorks = offsets.map { delay, forceBoundary in
            let work = DispatchWorkItem { [weak self] in
                self?.sampleSystemBrightness(forceBoundaryOnKey: forceBoundary)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
            return work
        }
    }

    private func cancelBrightnessBursts() {
        for work in brightnessBurstWorks { work.cancel() }
        brightnessBurstWorks.removeAll()
    }

    private func sampleSystemBrightness(forceBoundaryOnKey: Bool) {
        guard running, !screensAsleep, let level = readSystemBrightness() else { return }
        let now = ProcessInfo.processInfo.systemUptime
        if let detected = brightnessDetector.observe(level: level, at: now, forceBoundaryOnKey: forceBoundaryOnKey) {
            brightnessChanged.send(detected)
        }
    }

    private func readSystemBrightness() -> Double? {
        guard let read = BrightnessBridge.getBrightness else { return nil }
        var ids = [CGDirectDisplayID](repeating: 0, count: 8)
        var count: UInt32 = 0
        let target: CGDirectDisplayID
        if CGGetOnlineDisplayList(8, &ids, &count) == .success, count > 0,
           let builtIn = ids.prefix(Int(count)).first(where: { CGDisplayIsBuiltin($0) != 0 }) {
            target = builtIn
        } else {
            target = CGMainDisplayID()
        }
        guard target != kCGNullDirectDisplay, CGDisplayIsAsleep(target) == 0 else { return nil }
        var value: Float = -1
        guard read(target, &value) == 0, value.isFinite, value >= 0, value <= 1 else { return nil }
        return Double(value)
    }

    private func triggerPaste() {
        guard running, pasteDetector.recordPaste(at: ProcessInfo.processInfo.systemUptime) else { return }
        let send = { [weak self] in
            guard let self, self.running else { return }
            self.pasteTriggered.send()
        }
        if Thread.isMainThread { send() } else { DispatchQueue.main.async(execute: send) }
    }
}
