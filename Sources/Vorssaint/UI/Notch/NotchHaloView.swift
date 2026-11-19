// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import Combine
import SwiftUI

/// Live animation state backing the notch laser/halo overlay panel.
final class NotchHaloViewModel: ObservableObject {
    @Published var state: NotchHaloState = .idle
    @Published var palette: NotchHaloPalette = .running
    @Published var previousPalette: NotchHaloPalette = .running

    @Published var style: NotchHaloStyle = .rays
    @Published var armWidth: NotchHaloArmWidth = .medium
    @Published var thicknessScale: Double = 1.0
    @Published var entryMode: NotchHaloEntryMode = .sweep
    @Published var motion: NotchHaloMotion = .ondulation
    @Published var transitionEffect: NotchHaloTransitionEffect = .hybrid
    @Published var surfaceStyle: NotchLightSurfaceStyle = .neon
    @Published var isLightSurface: Bool = false

    @Published var notchSize: CGSize = CGSize(width: 185, height: 32)
    @Published var floatingIsland: Bool = false
    @Published var topInset: CGFloat = 0

    @Published var isVisible: Bool = false
    @Published var isAnimating: Bool = false

    var entryStart: Date = .distantPast
    var transitionStart: Date = .distantPast
    var copySweepStart: Date = .distantPast
    var contourPulseStart: Date = .distantPast
    var ignitionStart: Date = .distantPast
    var autoFadeDeadline: Date?

    func beginOrTransition(to newState: NotchHaloState, palette newPalette: NotchHaloPalette, holdDuration: TimeInterval? = nil) {
        let now = Date()
        let wasIdle = state == .idle || !isVisible
        previousPalette = palette
        palette = newPalette
        state = newState
        isVisible = true
        isAnimating = true

        if wasIdle {
            entryStart = now
            if entryMode == .blast {
                ignitionStart = now
            }
        } else if transitionEffect != .off {
            transitionStart = now
        }

        autoFadeDeadline = holdDuration.map { now.addingTimeInterval($0) }
    }

    func triggerCopySweep(palette sweepPalette: NotchHaloPalette? = nil) {
        let now = Date()
        if state == .idle {
            palette = sweepPalette ?? NotchHaloPalette.running
            autoFadeDeadline = now.addingTimeInterval(0.95)
        }
        copySweepStart = now
        isVisible = true
        isAnimating = true
    }

    func triggerContourPulse(palette pulsePalette: NotchHaloPalette, holdDuration: TimeInterval = 1.35) {
        let now = Date()
        contourPulseStart = now
        if state == .idle || state == .copy {
            beginOrTransition(to: .running, palette: pulsePalette, holdDuration: holdDuration)
        } else if autoFadeDeadline != nil {
            beginOrTransition(to: state, palette: pulsePalette, holdDuration: holdDuration)
        }
    }

    func deactivate() {
        state = .idle
        autoFadeDeadline = nil
        isVisible = false
        isAnimating = false
    }
}

/// Renders Glance's complete halo, entrance curves, state transition bursts,
/// ignition ember particles, copy laser wipe, contour pulse, and light-surface adaptation.
struct NotchHaloView: View {
    @ObservedObject var model: NotchHaloViewModel

    var body: some View {
        Group {
            if model.isVisible {
                TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !model.isAnimating)) { context in
                    frame(at: context.date)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func frame(at now: Date) -> some View {
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        let adapted = model.palette.adapted(lightSurface: model.isLightSurface, style: model.surfaceStyle)
        let adaptedPrev = model.previousPalette.adapted(lightSurface: model.isLightSurface, style: model.surfaceStyle)

        let entryElapsed = max(0, now.timeIntervalSince(model.entryStart))
        let transElapsed = max(0, now.timeIntervalSince(model.transitionStart))
        let copyElapsed = max(0, now.timeIntervalSince(model.copySweepStart))
        let pulseElapsed = max(0, now.timeIntervalSince(model.contourPulseStart))
        let ignitionElapsed = max(0, now.timeIntervalSince(model.ignitionStart))

        let armRun = model.armWidth.points
        let entryProgress = Self.entryReveal(mode: model.entryMode, elapsed: entryElapsed, reduceMotion: reduceMotion)

        let fadeMultiplier: Double = {
            guard let deadline = model.autoFadeDeadline else { return 1.0 }
            let remaining = deadline.timeIntervalSince(now)
            if remaining <= 0 { return 0.0 }
            if remaining < 0.45 { return remaining / 0.45 }
            return 1.0
        }()

        let activePalette: NotchHaloPalette = {
            if !reduceMotion, model.transitionEffect == .hueSlide || model.transitionEffect == .hybrid, transElapsed < 0.65 {
                let u = min(1, transElapsed / 0.65)
                return NotchHaloPalette(
                    primary: adaptedPrev.primary.blended(with: adapted.primary, amount: u),
                    secondary: adaptedPrev.secondary.blended(with: adapted.secondary, amount: u),
                    core: adaptedPrev.core.blended(with: adapted.core, amount: u),
                    rim: adaptedPrev.rim.blended(with: adapted.rim, amount: u)
                )
            }
            return adapted
        }()

        let intensity = min(1.35, model.thicknessScale * entryProgress * fadeMultiplier)
        let time = now.timeIntervalSinceReferenceDate
        let topY: CGFloat = model.topInset
        let params = NotchHaloRenderParams(
            palette: activePalette,
            notchSize: model.notchSize,
            topY: topY,
            armRun: armRun,
            thicknessScale: model.thicknessScale,
            intensity: intensity,
            time: time,
            motion: reduceMotion ? .none : model.motion,
            floatingIsland: model.floatingIsland
        )

        ZStack {
            // Primary Halo Style Layer
            if intensity > 0.005 {
                let styleLayer = NotchHaloStyleRenderer(style: model.style, params: params)
                if model.entryMode == .trace && entryElapsed < 0.72 && !reduceMotion {
                    styleLayer.mask(traceMask(progress: entryElapsed / 0.72, topY: topY, armRun: armRun))
                } else if model.entryMode == .sweep && entryElapsed < 0.56 && !reduceMotion {
                    styleLayer.mask(sweepEntranceMask(progress: entryElapsed / 0.56))
                } else {
                    styleLayer
                }
            }

            // Blast Entrance Ignition Dust (up to 3.54s ember decay)
            if !reduceMotion && model.entryMode == .blast && ignitionElapsed < 3.54 {
                NotchIgnitionDustView(
                    palette: adapted,
                    notchSize: model.notchSize,
                    topY: topY,
                    armRun: armRun,
                    thicknessScale: model.thicknessScale,
                    elapsed: ignitionElapsed
                )
            }

            // State Transition Effect Overlay
            if !reduceMotion && model.transitionEffect != .off && transElapsed < 0.92 {
                NotchHaloTransitionOverlay(
                    effect: model.transitionEffect,
                    palette: adapted,
                    notchSize: model.notchSize,
                    topY: topY,
                    armRun: armRun,
                    floatingIsland: model.floatingIsland,
                    elapsed: transElapsed
                )
            }

            // Contour Pulse (HUD notice flare)
            if !reduceMotion && pulseElapsed < 0.85 {
                let p = pulseElapsed / 0.85
                NotchBottomUShape(notchSize: model.notchSize, armRun: armRun * 0.65, topY: topY, floatingIsland: model.floatingIsland)
                    .stroke(adapted.core.color.opacity((1.0 - p) * 0.95), style: StrokeStyle(lineWidth: (4.5 - 2.0 * p) * CGFloat(model.thicknessScale), lineCap: .round))
                    .blur(radius: 3.0 + p * 6.0)
            }

            // Clipboard Copy Laser Sweep
            if copyElapsed < 0.78 {
                NotchCopySweepView(
                    palette: adapted,
                    notchSize: model.notchSize,
                    topY: topY,
                    armRun: armRun,
                    progress: copyElapsed / 0.78,
                    reduceMotion: reduceMotion
                )
            }
        }
        .modifier(NotchLightSurfaceFinish(isLightSurface: model.isLightSurface, surfaceStyle: model.surfaceStyle))
        .onChange(of: fadeMultiplier == 0 && copyElapsed >= 0.78 && pulseElapsed >= 0.85) { _, finished in
            if finished && model.autoFadeDeadline != nil {
                DispatchQueue.main.async {
                    model.deactivate()
                }
            }
        }
    }

    private static func entryReveal(mode: NotchHaloEntryMode, elapsed: TimeInterval, reduceMotion: Bool) -> Double {
        if reduceMotion { return min(1.0, elapsed / 0.25) }
        switch mode {
        case .sweep:
            // Two-stage swift rise inspired by 0.18s -> 0.51s curve.
            if elapsed < 0.18 { return (elapsed / 0.18) * 0.72 }
            if elapsed < 0.51 { return 0.72 + ((elapsed - 0.18) / 0.33) * 0.28 }
            return 1.0
        case .trace:
            return min(1.0, elapsed / 0.32)
        case .blast:
            if elapsed < 0.14 { return (elapsed / 0.14) * 1.25 }
            if elapsed < 0.55 { return 1.25 - ((elapsed - 0.14) / 0.41) * 0.25 }
            return 1.0
        }
    }

    private func sweepEntranceMask(progress: Double) -> some View {
        let clamped = min(1.0, max(0.02, progress))
        let spread = 0.08 + clamped * 0.92
        return GeometryReader { proxy in
            Rectangle()
                .fill(.white)
                .frame(width: proxy.size.width * spread, height: proxy.size.height)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .center)
                .blur(radius: 16 * (1.0 - clamped))
        }
    }

    private func traceMask(progress: Double, topY: CGFloat, armRun: CGFloat) -> some View {
        let u = min(1.0, max(0.0, progress))
        let halfSpan = max(0.01, u * 0.5)
        let shape = NotchBottomUShape(
            notchSize: model.notchSize,
            armRun: armRun,
            topY: topY,
            floatingIsland: model.floatingIsland
        )
        return ZStack {
            shape
                .trim(from: max(0, 0.5 - halfSpan), to: 0.5)
                .stroke(.white, style: StrokeStyle(lineWidth: 68, lineCap: .round))
            shape
                .trim(from: 0.5, to: min(1, 0.5 + halfSpan))
                .stroke(.white, style: StrokeStyle(lineWidth: 68, lineCap: .round))
        }
        .blur(radius: 10)
    }
}

/// Drifting incandescent ember sparks emitted during Blast entrances (3.54s lifetime).
struct NotchIgnitionDustView: View {
    let palette: NotchHaloPalette
    let notchSize: CGSize
    let topY: CGFloat
    let armRun: CGFloat
    let thicknessScale: Double
    let elapsed: TimeInterval

    var body: some View {
        Canvas { context, size in
            let midX = Double(size.width) * 0.5
            let progress = elapsed / 3.54
            let fade = max(0, 1.0 - progress * progress)
            let count = 36
            for i in 0..<count {
                let s = Double(i)
                let angle = (NotchLightsSupport.hash(s + 13.7) - 0.5) * .pi
                let speed = 35.0 + NotchLightsSupport.hash(s + 71.1) * 95.0
                let radius = (1.1 + NotchLightsSupport.hash(s + 42.3) * 1.9) * thicknessScale
                let startX = midX + (NotchLightsSupport.hash(s + 91.5) - 0.5) * Double(notchSize.width + armRun * 0.6)
                let startY = Double(topY + notchSize.height * 0.85)
                let x = startX + sin(angle) * speed * pow(progress, 0.72)
                let y = startY + abs(cos(angle)) * speed * 0.65 * pow(progress, 0.78) + progress * progress * 18.0
                let sparkle = 0.55 + 0.45 * sin(elapsed * 14.0 + s * 2.1)
                let color = i.isMultiple(of: 3) ? palette.core.color : palette.primary.color
                context.fill(
                    Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)),
                    with: .color(color.opacity(fade * sparkle))
                )
            }
        }
    }
}

/// Implements the 10 active transition burst visual layers when halo state shifts.
struct NotchHaloTransitionOverlay: View {
    let effect: NotchHaloTransitionEffect
    let palette: NotchHaloPalette
    let notchSize: CGSize
    let topY: CGFloat
    let armRun: CGFloat
    let floatingIsland: Bool
    let elapsed: TimeInterval

    var body: some View {
        GeometryReader { proxy in
            let midX = proxy.size.width * 0.5
            let centerY = topY + notchSize.height * 0.6
            switch effect {
            case .off, .hueSlide:
                EmptyView()
            case .whiteFlash:
                let p = min(1, elapsed / 0.45)
                NotchBottomUShape(notchSize: notchSize, armRun: armRun * 0.75, topY: topY, floatingIsland: floatingIsland)
                    .stroke(.white.opacity((1.0 - p) * 0.92), style: StrokeStyle(lineWidth: 6 + 10 * (1 - p), lineCap: .round))
                    .blur(radius: 6 + 8 * p)
            case .hybrid, .shockwave:
                let p = min(1, elapsed / 0.65)
                Ellipse()
                    .stroke(palette.core.color.opacity((1.0 - p) * 0.9), lineWidth: max(1, 5.0 * (1.0 - p)))
                    .frame(width: notchSize.width + p * (armRun * 2.2), height: notchSize.height + p * 88)
                    .position(x: midX, y: centerY)
                    .blur(radius: 3 + p * 6)
            case .pulse:
                let p = min(1, elapsed / 0.8)
                let beat = abs(sin(p * .pi * 2.0)) * (1.0 - p)
                NotchBottomUShape(notchSize: notchSize, armRun: armRun, topY: topY, floatingIsland: floatingIsland)
                    .stroke(palette.core.color.opacity(beat * 0.85), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .blur(radius: 10)
            case .supernova, .bigBang:
                let p = min(1, elapsed / 0.82)
                let radius = (notchSize.width * 0.4 + p * (armRun + 90))
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.white.opacity((1.0 - p) * 0.95), palette.primary.color.opacity((1.0 - p) * 0.65), .clear],
                            center: .center,
                            startRadius: 1,
                            endRadius: radius
                        )
                    )
                    .frame(width: radius * 2, height: radius * 1.1)
                    .position(x: midX, y: centerY)
                    .blur(radius: 6)
            case .rings:
                let p = min(1, elapsed / 0.88)
                ForEach(0..<3, id: \.self) { idx in
                    let rp = max(0, min(1, (p - Double(idx) * 0.14) / 0.72))
                    Ellipse()
                        .stroke(palette.primary.color.opacity((1.0 - rp) * 0.75), lineWidth: 2.5)
                        .frame(width: notchSize.width * (0.7 + rp * 1.8), height: notchSize.height * (0.8 + rp * 2.2))
                        .position(x: midX, y: centerY)
                        .blur(radius: 2 + rp * 4)
                }
            case .prism:
                let p = min(1, elapsed / 0.7)
                let colors: [Color] = [.red, .green, .blue]
                ForEach(0..<3, id: \.self) { idx in
                    NotchBottomUShape(notchSize: notchSize, armRun: armRun, topY: topY, floatingIsland: floatingIsland)
                        .stroke(colors[idx].opacity((1.0 - p) * 0.75), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .offset(x: CGFloat(idx - 1) * CGFloat(p * 14.0), y: CGFloat(p * 5.0))
                        .blur(radius: 4)
                }
            case .strobe:
                let p = min(1, elapsed / 0.55)
                let gate = sin(elapsed * 42.0) > 0 ? 1.0 : 0.15
                NotchBottomUShape(notchSize: notchSize, armRun: armRun, topY: topY, floatingIsland: floatingIsland)
                    .stroke(palette.core.color.opacity((1.0 - p) * gate), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .blur(radius: 4)
            }
        }
    }
}

/// Crisp horizontal laser beam sweep along the notch perimeter when text/files are copied.
struct NotchCopySweepView: View {
    let palette: NotchHaloPalette
    let notchSize: CGSize
    let topY: CGFloat
    let armRun: CGFloat
    let progress: Double
    let reduceMotion: Bool

    var body: some View {
        let p = min(1.0, max(0.0, progress))
        let alpha = sin(p * .pi)
        GeometryReader { proxy in
            let midX = proxy.size.width * 0.5
            let span = notchSize.width + armRun * 1.8
            let cursorX = reduceMotion ? midX : (midX - span * 0.5 + span * p)
            ZStack {
                NotchBottomUShape(notchSize: notchSize, armRun: armRun * 0.85, topY: topY, floatingIsland: false)
                    .trim(from: max(0, p - 0.14), to: min(1, p + 0.04))
                    .stroke(.white.opacity(alpha * 0.95), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                    .blur(radius: 2)
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [.white.opacity(alpha), palette.core.color.opacity(alpha * 0.85), .clear],
                            center: .center,
                            startRadius: 1,
                            endRadius: 28
                        )
                    )
                    .frame(width: 56, height: 22)
                    .position(x: cursorX, y: topY + notchSize.height * 0.85)
                    .blur(radius: 4)
            }
        }
    }
}
