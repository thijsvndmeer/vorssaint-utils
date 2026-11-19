// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import Combine
import Foundation
import SwiftUI

/// Orchestrates the click-through halo NSPanel directly behind Vorssaint's notch
/// island and triggers the screen-edge Metal wave on agent completions, alerts,
/// music playback, clipboard copies, and Settings previews.
final class NotchHaloController {
    static let shared = NotchHaloController()

    private let viewModel = NotchHaloViewModel()
    private let surfaceProbe = NotchLightSurfaceProbe()
    private let edgeWave = NotchEdgeWaveController()
    private var panel: NSPanel?
    private var hostingView: NSHostingView<NotchHaloView>?
    private var cancellables: Set<AnyCancellable> = []

    private var lastGeometry: NotchGeometry?
    private var lastClosedSize = CGSize(width: 185, height: 32)
    private var lastNotchWindowNumber: Int?
    private var lastVisible = false
    private var lastFullscreenHidden = false
    private weak var lastScreen: NSScreen?

    private init() {
        surfaceProbe.$isLightSurface
            .receive(on: DispatchQueue.main)
            .sink { [weak self] light in
                self?.viewModel.isLightSurface = light
            }
            .store(in: &cancellables)

        viewModel.$isVisible
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] visible in
                if !visible {
                    self?.panel?.orderOut(nil)
                }
            }
            .store(in: &cancellables)

        syncWithPreferences()
    }

    func syncWithPreferences() {
        viewModel.style = NotchLightsSupport.style()
        viewModel.armWidth = NotchLightsSupport.armWidth()
        viewModel.thicknessScale = NotchLightsSupport.thickness()
        viewModel.entryMode = NotchLightsSupport.entryMode()
        viewModel.motion = NotchLightsSupport.motion()
        viewModel.transitionEffect = NotchLightsSupport.transitionEffect()
        viewModel.surfaceStyle = NotchLightsSupport.lightSurfaceStyle()
        viewModel.isLightSurface = surfaceProbe.isLightSurface

        if !NotchLightsSupport.isEnabled() || !NotchSupport.isEnabled() {
            stop()
            return
        }
        repositionPanel()
    }

    func updateLayout(geometry: NotchGeometry, closedSize: CGSize, notchWindowNumber: Int?,
                      visible: Bool, fullscreenHidden: Bool, screen: NSScreen?) {
        lastGeometry = geometry
        lastClosedSize = closedSize
        lastNotchWindowNumber = notchWindowNumber
        lastVisible = visible
        lastFullscreenHidden = fullscreenHidden
        lastScreen = screen

        viewModel.notchSize = closedSize
        viewModel.floatingIsland = geometry.floats
        viewModel.topInset = geometry.floats ? 12 : 0
        repositionPanel()
    }

    func updateAgentSessions(_ live: [AgentLiveSession]) {
        guard NotchLightsSupport.isEnabled(), NotchSupport.isEnabled(), NotchLightsSupport.tracksAgents() else {
            if viewModel.state == .running { viewModel.deactivate() }
            return
        }
        if let active = live.first {
            let palette = Self.palette(from: active.provider.tint, fallback: .running)
            if viewModel.state != .running || viewModel.palette != palette || viewModel.autoFadeDeadline != nil {
                viewModel.beginOrTransition(to: .running, palette: palette, holdDuration: nil)
                repositionPanel()
            }
        } else if viewModel.state == .running && viewModel.autoFadeDeadline == nil {
            viewModel.autoFadeDeadline = Date().addingTimeInterval(0.45)
        }
    }

    func triggerAgentEvent(_ event: AgentUsageEvent) {
        guard NotchLightsSupport.isEnabled(), NotchSupport.isEnabled(), NotchLightsSupport.tracksAgents() else { return }
        switch event {
        case .finished:
            viewModel.beginOrTransition(to: .success, palette: .success, holdDuration: 2.4)
            triggerEdgeWave(palette: .success)
        case .limitWarning:
            viewModel.beginOrTransition(to: .warning, palette: .warning, holdDuration: 2.8)
            triggerEdgeWave(palette: .warning)
        case .limitReset:
            viewModel.beginOrTransition(to: .success, palette: .success, holdDuration: 2.0)
            triggerEdgeWave(palette: .success)
        case .budgetReached:
            viewModel.beginOrTransition(to: .error, palette: .error, holdDuration: 3.0)
            triggerEdgeWave(palette: .error)
        }
        repositionPanel()
    }

    func updateMusic(playing: Bool, tint: NotchArtworkTint?) {
        guard NotchLightsSupport.isEnabled(), NotchSupport.isEnabled(), NotchLightsSupport.tracksMusic() else {
            if viewModel.state == .music { viewModel.deactivate() }
            return
        }
        // Agent runs take visual precedence over background music playback aura.
        if viewModel.state == .running && viewModel.autoFadeDeadline == nil { return }
        if playing {
            let palette = tint.map { NotchHaloPalette.matching(r: $0.red, g: $0.green, b: $0.blue) } ?? .running
            if viewModel.state != .music || viewModel.palette != palette {
                viewModel.beginOrTransition(to: .music, palette: palette, holdDuration: nil)
                repositionPanel()
            }
        } else if viewModel.state == .music {
            viewModel.autoFadeDeadline = Date().addingTimeInterval(0.55)
        }
    }

    func triggerCopySweep() {
        guard NotchLightsSupport.isEnabled(), NotchSupport.isEnabled(), NotchLightsSupport.tracksCopy() else { return }
        viewModel.triggerCopySweep()
        repositionPanel()
    }

    func triggerNotice(_ notice: NotchNotice) {
        guard NotchLightsSupport.isEnabled(), NotchSupport.isEnabled(), NotchLightsSupport.tracksNotices() else { return }
        let palette: NotchHaloPalette = {
            if let agent = notice.agent {
                return Self.palette(from: agent.tint, fallback: .running)
            }
            switch notice.event {
            case .battery:
                return .warning
            case .timer, .watch:
                return .warning
            case .track:
                if let tint = NotchMusicService.shared.artworkTint {
                    return .matching(r: tint.red, g: tint.green, b: tint.blue)
                }
                return .running
            default:
                return .running
            }
        }()
        let hold = max(1.2, notice.event.duration)
        if viewModel.state == .idle {
            viewModel.beginOrTransition(to: .running, palette: palette, holdDuration: hold)
        }
        viewModel.triggerContourPulse(palette: palette, holdDuration: hold)
        if notice.event == .timer || notice.event == .watch {
            triggerEdgeWave(palette: palette)
        }
        repositionPanel()
    }

    func previewHalo() {
        syncWithPreferences()
        ensureFallbackLayout()
        viewModel.beginOrTransition(to: .running, palette: .running, holdDuration: 3.2)
        viewModel.triggerContourPulse(palette: .running, holdDuration: 3.2)
        repositionPanel(forceVisible: true)
    }

    func previewEdgeWave() {
        syncWithPreferences()
        ensureFallbackLayout()
        guard let screen = lastScreen ?? NSScreen.main,
              let geometry = lastGeometry else { return }
        edgeWave.trigger(
            palette: .running,
            on: screen,
            geometry: geometry,
            closedSize: lastClosedSize,
            inward: false,
            lightSurface: surfaceProbe.isLightSurface
        )
    }

    func stop() {
        edgeWave.stop()
        viewModel.deactivate()
        panel?.orderOut(nil)
    }

    // MARK: Internal layout & windowing

    private func triggerEdgeWave(palette: NotchHaloPalette, inward: Bool = false) {
        guard NotchLightsSupport.edgeWaveEnabled() else { return }
        ensureFallbackLayout()
        guard let screen = lastScreen ?? NSScreen.main,
              let geometry = lastGeometry else { return }
        edgeWave.trigger(
            palette: palette,
            on: screen,
            geometry: geometry,
            closedSize: lastClosedSize,
            inward: inward,
            lightSurface: surfaceProbe.isLightSurface
        )
    }

    private func ensureFallbackLayout() {
        if lastGeometry == nil, let screen = NSScreen.main {
            let safeTop = screen.safeAreaInsets.top
            let camWidth: CGFloat = safeTop > 0 ? 185 : 180
            let silhouette = NotchSilhouette(
                rawValue: UserDefaults.standard.string(forKey: DefaultsKey.notchSilhouette) ?? ""
            ) ?? .capsule
            let geom = NotchGeometry(
                screen: screen.frame,
                safeAreaTop: safeTop,
                cameraWidth: camWidth,
                layout: .compact,
                menuBarHeight: max(24, safeTop),
                silhouette: silhouette
            )
            lastGeometry = geom
            lastScreen = screen
            lastClosedSize = CGSize(width: geom.cameraWidth, height: geom.stripHeight)
            viewModel.notchSize = lastClosedSize
            viewModel.floatingIsland = geom.floats
            viewModel.topInset = geom.floats ? 12 : 0
        }
    }

    private func repositionPanel(forceVisible: Bool = false) {
        guard let geometry = lastGeometry else { return }
        let frame = NotchLightsSupport.overlayFrame(
            geometry: geometry,
            closedSize: lastClosedSize,
            armRun: viewModel.armWidth.points,
            thicknessScale: viewModel.thicknessScale
        )
        let pan = ensurePanel(frame: frame)
        pan.level = NotchPanel.normalLevel
        pan.setFrame(frame, display: false)
        hostingView?.frame = CGRect(origin: .zero, size: frame.size)

        let shouldShow = (forceVisible || (lastVisible && !lastFullscreenHidden))
            && NotchLightsSupport.isEnabled()
            && viewModel.isVisible
        guard shouldShow else {
            pan.orderOut(nil)
            return
        }

        if let notchWin = lastNotchWindowNumber, notchWin > 0 {
            pan.order(.below, relativeTo: notchWin)
        } else {
            pan.orderFrontRegardless()
        }
    }

    private func ensurePanel(frame: CGRect) -> NSPanel {
        if let panel { return panel }
        let pan = NSPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        pan.isReleasedWhenClosed = false
        pan.ignoresMouseEvents = true
        pan.isOpaque = false
        pan.backgroundColor = .clear
        pan.hasShadow = false
        pan.level = NotchPanel.normalLevel
        pan.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        let hosting = NSHostingView(rootView: NotchHaloView(model: viewModel))
        hosting.frame = CGRect(origin: .zero, size: frame.size)
        hosting.wantsLayer = true
        hosting.layer?.backgroundColor = NSColor.clear.cgColor
        pan.contentView = hosting
        self.panel = pan
        self.hostingView = hosting
        return pan
    }

    private static func palette(from color: Color, fallback: NotchHaloPalette) -> NotchHaloPalette {
        guard let ns = NSColor(color).usingColorSpace(.sRGB) else { return fallback }
        return NotchHaloPalette.matching(
            r: Double(ns.redComponent),
            g: Double(ns.greenComponent),
            b: Double(ns.blueComponent)
        )
    }
}
