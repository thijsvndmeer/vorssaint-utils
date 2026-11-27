// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import CoreGraphics
import Foundation
import Metal

enum NotchLightsTests {
    static func run(_ suite: TestSuite) {
        defaultsAndBackup(suite)
        rayMath(suite)
        bayerMatrix(suite)
        overlayGeometry(suite)
        uniformMemoryLayout(suite)
        metalShaderCompilation(suite)
        fluidLevelSpring(suite)
        brightnessChangeDetector(suite)
        modifierHoldTracker(suite)
        pasteDetector(suite)
        contourLineOwnership(suite)
    }

    private static func defaultsAndBackup(_ suite: TestSuite) {
        let keys = [
            DefaultsKey.notchLightsEnabled,
            DefaultsKey.notchHaloStyle,
            DefaultsKey.notchHaloArmWidth,
            DefaultsKey.notchHaloThickness,
            DefaultsKey.notchHaloEntry,
            DefaultsKey.notchHaloMotion,
            DefaultsKey.notchHaloTransition,
            DefaultsKey.notchEdgeWaveEnabled,
            DefaultsKey.notchLightSurfaceStyle,
            DefaultsKey.notchLightsAgentActivity,
            DefaultsKey.notchLightsMusicActivity,
            DefaultsKey.notchLightsCopySweep,
            DefaultsKey.notchLightsNotices,
            DefaultsKey.notchOutlineTheme,
            DefaultsKey.notchLightsRestingOutline,
            DefaultsKey.notchLightsLevelBars,
            DefaultsKey.notchLightsFullWidthLevelBars,
            DefaultsKey.notchLightsFullWidthAgents,
            DefaultsKey.notchLightsFullWidthMusic,
            DefaultsKey.notchLightsFullWidthModifiers,
            DefaultsKey.notchLightsFullWidthCopy,
            DefaultsKey.notchLightsFullWidthNotices,
            DefaultsKey.notchLightsFullWidthResting
        ]
        suite.expect(keys.allSatisfy { Defaults.registeredDefaults[$0] != nil },
                     "all island light defaults are registered")
        suite.expect(SettingsBackupSupport.exportKeys().isSuperset(of: keys),
                     "all island light keys export cleanly with notch backups")
        suite.expect(NotchOutlineTheme.allCases.count == 8
                        && NotchLevelPrismPalette.volume != NotchLevelPrismPalette.sunlight
                        && NotchLevelPrismPalette.silence != NotchLevelPrismPalette.volume,
                     "outline themes and Glance audio/brightness/silence prism palettes are distinct")
        suite.expect(NotchLightsSupport.clampedThickness(0.1) == 0.6
                        && NotchLightsSupport.clampedThickness(4.5) == 2.0
                        && NotchLightsSupport.clampedThickness(.nan) == 1.0,
                     "thickness clamps strictly to 0.6...2.0 with finite fallback")
        suite.expect(NotchHaloArmWidth.extraWide.points <= NotchLightsSupport.maxArmRun
                        && NotchHaloArmWidth.narrow.glowSpread < NotchHaloArmWidth.medium.glowSpread
                        && NotchHaloArmWidth.medium.glowSpread < NotchHaloArmWidth.wide.glowSpread
                        && NotchHaloArmWidth.wide.glowSpread < NotchHaloArmWidth.extraWide.glowSpread,
                     "arm reach caps at 520pt and glow spread increases strictly across presets")
        suite.expect(NotchHaloEntryMode.sweep.duration(fast: true) < NotchHaloEntryMode.sweep.duration(fast: false)
                        && NotchHaloEntryMode.trace.duration(fast: false) <= 0.30
                        && NotchHaloTransitionEffect.off.duration(fast: false) == 0
                        && NotchHaloTransitionEffect.hybrid.duration(fast: true) < NotchHaloTransitionEffect.hybrid.duration(fast: false),
                     "quick entry and transition timings scale cleanly and stay snappy")
    }

    private static func rayMath(_ suite: TestSuite) {
        let leftA = NotchLightsSupport.armRays(armRun: 130, thicknessScale: 1.0, intensity: 1.0, sign: -1.0)
        let leftB = NotchLightsSupport.armRays(armRun: 130, thicknessScale: 1.0, intensity: 1.0, sign: -1.0)
        let right = NotchLightsSupport.armRays(armRun: 130, thicknessScale: 1.0, intensity: 1.0, sign: 1.0)
        suite.expect(leftA == leftB, "organic ray generation is deterministic across frames")
        suite.expect((5...34).contains(leftA.count), "ray count per arm stays within 5...34")
        suite.expect(leftA.allSatisfy { $0.xOffset < 0 } && right.allSatisfy { $0.xOffset > 0 },
                     "left and right arm rays preserve horizontal sign symmetry")

        let wideRays = NotchLightsSupport.armRays(armRun: 600, thicknessScale: 2.0, intensity: 1.0, sign: 1.0)
        suite.expect(wideRays.count <= 34 && wideRays.allSatisfy { $0.width >= 2.6 },
                     "wide ray counts cap at 34 and scale linearly with thickness")
    }

    private static func bayerMatrix(_ suite: TestSuite) {
        let matrix = NotchLightsSupport.bayer8x8
        suite.expect(matrix.count == 64 && Set(matrix).count == 64,
                     "8x8 Bayer matrix contains 64 distinct ordered dithering thresholds")
        suite.expect(matrix.min() == 0.0 && matrix.max() == 63.0 / 64.0,
                     "Bayer thresholds normalize cleanly across 0/64...63/64")
    }

    private static func overlayGeometry(_ suite: TestSuite) {
        let screen = CGRect(x: 0, y: 0, width: 1728, height: 1117)
        let notched = NotchGeometry(screen: screen, safeAreaTop: 38, cameraWidth: 185, silhouette: .notch)
        let notchedFrame = NotchLightsSupport.overlayFrame(
            geometry: notched, closedSize: CGSize(width: 240, height: 38), armRun: 130, thicknessScale: 1.0
        )
        suite.expect(abs(notchedFrame.midX - screen.midX) <= 1.0 && notchedFrame.maxY == screen.maxY,
                     "notched overlay hugs the top screen center above the island")

        let capsule = NotchGeometry(screen: screen, safeAreaTop: 0, cameraWidth: 0, silhouette: .capsule)
        let capsuleFrame = NotchLightsSupport.overlayFrame(
            geometry: capsule, closedSize: CGSize(width: 180, height: 26), armRun: 130, thicknessScale: 1.0
        )
        suite.expect(capsuleFrame.width > 180 + 260 && capsuleFrame.height > 26 + 90,
                     "floating capsule overlay allows bloom margins around arms and contour")

        let closedSize = CGSize(width: 240, height: 38)
        let exactAttached = NotchLightsSupport.overlayLayout(
            islandScreenRect: notched.frame(for: closedSize),
            floatingGap: notched.floatingGap,
            armRun: 130,
            thicknessScale: 1.0
        )
        suite.expect(exactAttached.islandRect.minY == 0
                        && exactAttached.islandRect.size == closedSize
                        && abs(exactAttached.islandRect.midX - exactAttached.overlayScreenRect.width / 2) <= 0.5
                        && exactAttached.shoulder == NotchLayout.shoulder(height: closedSize.height),
                     "attached halo overlay maps NotchShape origin and shoulder geometry cleanly")

        let capSize = CGSize(width: 180, height: 24)
        let exactCapsule = NotchLightsSupport.overlayLayout(
            islandScreenRect: capsule.frame(for: capSize),
            floatingGap: capsule.floatingGap,
            armRun: 130,
            thicknessScale: 1.0
        )
        suite.expect(exactCapsule.floatingGap == capsule.floatingGap
                        && exactCapsule.islandRect.minY > 0
                        && exactCapsule.islandRect.size == capSize,
                     "floating capsule halo reserves top bloom room and preserves capsule gap")

        let fullCentered = NotchLightsSupport.overlayLayout(
            islandScreenRect: notched.frame(for: closedSize),
            floatingGap: notched.floatingGap,
            armRun: 130,
            thicknessScale: 1.0,
            screenFrame: screen,
            fullWidth: true
        )
        suite.expect(fullCentered.overlayScreenRect.minX == screen.minX
                        && fullCentered.overlayScreenRect.width == screen.width
                        && fullCentered.islandRect.minY == 0
                        && fullCentered.islandRect.size == closedSize
                        && abs(fullCentered.islandRect.midX - screen.width / 2) <= 0.5,
                     "full-width overlay covers full screen width while keeping centered island local rect")

        let shiftedScreen = CGRect(x: 100, y: 0, width: 1728, height: 1117)
        let shiftedIsland = CGRect(x: 780, y: 1079, width: 280, height: 38)
        let fullShifted = NotchLightsSupport.overlayLayout(
            islandScreenRect: shiftedIsland,
            floatingGap: nil,
            armRun: 130,
            thicknessScale: 1.0,
            screenFrame: shiftedScreen,
            fullWidth: true
        )
        suite.expect(fullShifted.overlayScreenRect.minX == shiftedScreen.minX
                        && fullShifted.overlayScreenRect.width == shiftedScreen.width
                        && abs(fullShifted.islandRect.minX - (shiftedIsland.minX - shiftedScreen.minX)) <= 0.5
                        && fullShifted.islandRect.size == shiftedIsland.size,
                     "full-width overlay maps shifted/asymmetric island origin inside screen-wide panel")
    }

    private static func uniformMemoryLayout(_ suite: TestSuite) {
        suite.expect(MemoryLayout<NotchEdgeWaveUniforms>.stride == 80,
                     "EdgeWave Metal uniform struct matches 80-byte 16-byte-aligned layout")
    }

    private static func metalShaderCompilation(_ suite: TestSuite) {
        guard let device = MTLCreateSystemDefaultDevice() else { return }
        do {
            let library = try device.makeLibrary(source: NotchEdgeWaveShaderSource.metalSource, options: nil)
            let vertex = library.makeFunction(name: "edgeWaveVertex")
            let fragment = library.makeFunction(name: "edgeWaveFragment")
            suite.expect(vertex != nil && fragment != nil,
                         "EdgeWave MSL shader compiles at runtime with vertex and fragment entry points")
        } catch {
            suite.expect(false, "EdgeWave MSL runtime compilation failed: \(error)")
        }
    }

    private static func fluidLevelSpring(_ suite: TestSuite) {
        var spring = NotchFluidLevelSpring()
        spring.retarget(to: 0.25, at: 10.0, continuing: false)
        let s0 = spring.sample(at: 10.0)
        suite.expect(abs(s0.value - 0.25) < 0.0001 && s0.energy >= 0.5,
                     "initial level activation lands immediately with non-zero kinetic energy")

        spring.retarget(to: 0.75, at: 10.0, continuing: true)
        let midUp = spring.sample(at: 10.06)
        suite.expect(midUp.value > 0.25 && midUp.value < 0.75 && midUp.velocity > 0,
                     "continuing upward retarget glides smoothly without overshoot")

        // Mid-flight reverse preserves C1 continuous position & velocity.
        spring.retarget(to: 0.20, at: 10.06, continuing: true)
        let revAtSwitch = spring.sample(at: 10.06)
        let revLater = spring.sample(at: 10.14)
        let settled = spring.sample(at: 10.60)
        suite.expect(abs(revAtSwitch.value - midUp.value) < 0.0001
                        && abs(revAtSwitch.velocity - midUp.velocity) < 0.0001
                        && revLater.value < revAtSwitch.value
                        && abs(settled.value - 0.20) < 0.001,
                     "reverse retarget preserves C1 continuity and settles critically onto target")

        let reduced = spring.sample(at: 10.01, reduceMotion: true)
        suite.expect(reduced.value == 0.20 && reduced.velocity == 0 && reduced.energy == 0,
                     "Reduce Motion snaps level immediately without spring energy")
    }

    private static func brightnessChangeDetector(_ suite: TestSuite) {
        var detector = NotchBrightnessChangeDetector()
        suite.expect(detector.observe(level: 0.50, at: 1.0) == nil,
                     "initial brightness sample seeds baseline quietly")
        suite.expect(detector.observe(level: 0.504, at: 2.0) == nil,
                     "small ambient auto-brightness drift outside key window stays ignored")
        suite.expect(detector.observe(level: 0.5625, at: 3.0) == 0.5625,
                     "standard step brightness change triggers feedback")

        // Deduped when BrightnessService already handled the exact adjustment.
        detector.noteHandled(level: 0.625, at: 4.0)
        suite.expect(detector.observe(level: 0.625, at: 4.10) == nil,
                     "recent handled brightness write does not double-fire")

        // Boundary press at 100% / 0% fires once right after a key press.
        detector.noteHandled(level: 1.0, at: 5.0)
        detector.noteKeyPress(at: 5.5)
        suite.expect(detector.observe(level: 1.0, at: 5.6, forceBoundaryOnKey: true) == 1.0,
                     "repeating key at upper boundary reports HUD without stall")
    }

    private static func modifierHoldTracker(_ suite: TestSuite) {
        var tracker = NotchModifierHoldTracker()
        suite.expect(tracker.update(capsLock: true, shiftDown: false, otherModifiersDown: false, at: 1.0) == .capsLock,
                     "Caps Lock ON reports immediately")
        suite.expect(tracker.update(capsLock: false, shiftDown: false, otherModifiersDown: false, at: 1.1) == nil,
                     "Caps Lock OFF clears indicator immediately")

        // Brief Shift tap (< 0.22s) never flickers during fast typing.
        suite.expect(tracker.update(capsLock: false, shiftDown: true, otherModifiersDown: false, at: 2.0) == nil,
                     "initial Shift press waits for hold debounce threshold")
        suite.expect(tracker.tick(at: 2.15) == nil,
                     "Shift held under 220ms does not trigger indicator")
        suite.expect(tracker.tick(at: 2.23) == .shift,
                     "Shift held at least 220ms activates Shift indicator")

        // Holding Shift together with Command cancels Shift indicator.
        suite.expect(tracker.update(capsLock: true, shiftDown: true, otherModifiersDown: false, at: 2.5) == .both,
                     "Caps Lock ON + held Shift reports combined indicator")
        suite.expect(tracker.update(capsLock: true, shiftDown: true, otherModifiersDown: true, at: 2.6) == .capsLock,
                     "Cmd/Ctrl/Opt cancels Shift hold while keeping Caps Lock indicator")
    }

    private static func pasteDetector(_ suite: TestSuite) {
        suite.expect(NotchPasteDetector.isPasteKey(keyCode: 9, charactersIgnoringModifiers: "v", command: true, control: false)
                        && !NotchPasteDetector.isPasteKey(keyCode: 9, charactersIgnoringModifiers: "v", command: false, control: false)
                        && !NotchPasteDetector.isPasteKey(keyCode: 9, charactersIgnoringModifiers: "v", command: true, control: true)
                        && !NotchPasteDetector.isPasteKey(keyCode: 8, charactersIgnoringModifiers: "c", command: true, control: false),
                     "paste key detection matches Command-V without Control")

        var detector = NotchPasteDetector()
        suite.expect(detector.recordPaste(at: 10.0)
                        && !detector.recordPaste(at: 10.12)
                        && detector.recordPaste(at: 10.26),
                     "paste burst detector debounces duplicates inside 250ms window")
    }

    private static func contourLineOwnership(_ suite: TestSuite) {
        // Priority order: level > clipboard > preview > modifier > notice > agent > music > resting
        suite.expect(NotchContourLineState.resolveOwner(levelKind: .volume, levelMuted: false, clipboardPaste: true, previewActive: true, modifier: .shift, noticeActive: true, agentActive: true, musicActive: true, restingActive: true) == .level(kind: .volume, muted: false),
                     "level HUD takes top priority over all other bar owners")
        suite.expect(NotchContourLineState.resolveOwner(levelKind: nil, levelMuted: false, clipboardPaste: false, previewActive: true, modifier: .capsLock, noticeActive: true, agentActive: true, musicActive: true, restingActive: true) == .clipboard(isPaste: false),
                     "clipboard copy takes priority over preview, modifier, notice, agent, music, and resting")
        suite.expect(NotchContourLineState.resolveOwner(levelKind: nil, levelMuted: false, clipboardPaste: true, previewActive: true, modifier: .capsLock, noticeActive: true, agentActive: true, musicActive: true, restingActive: true) == .clipboard(isPaste: true),
                     "clipboard paste takes priority over preview, modifier, notice, agent, music, and resting")
        suite.expect(NotchContourLineState.resolveOwner(levelKind: nil, levelMuted: false, clipboardPaste: nil, previewActive: true, modifier: .capsLock, noticeActive: true, agentActive: true, musicActive: true, restingActive: true) == .preview,
                     "preview takes priority over modifier, notice, agent, music, and resting")
        suite.expect(NotchContourLineState.resolveOwner(levelKind: nil, levelMuted: false, clipboardPaste: nil, previewActive: false, modifier: .capsLock, noticeActive: true, agentActive: true, musicActive: true, restingActive: true) == .modifier(.capsLock),
                     "modifier indicator takes priority over notice, agent, music, and resting")
        suite.expect(NotchContourLineState.resolveOwner(levelKind: nil, levelMuted: false, clipboardPaste: nil, previewActive: false, modifier: nil, noticeActive: true, agentActive: true, musicActive: true, restingActive: true) == .notice,
                     "notice owns contour bar above ambient agent, music, and resting")
        suite.expect(NotchContourLineState.resolveOwner(levelKind: nil, levelMuted: false, clipboardPaste: nil, previewActive: false, modifier: nil, noticeActive: false, agentActive: true, musicActive: true, restingActive: true) == .agent,
                     "agent owns contour bar above music and resting outline")
        suite.expect(NotchContourLineState.resolveOwner(levelKind: nil, levelMuted: false, clipboardPaste: nil, previewActive: false, modifier: nil, noticeActive: false, agentActive: false, musicActive: true, restingActive: true) == .music,
                     "music owns contour bar when no higher priority signal or agent is active")
        suite.expect(NotchContourLineState.resolveOwner(levelKind: nil, levelMuted: false, clipboardPaste: nil, previewActive: false, modifier: nil, noticeActive: false, agentActive: false, musicActive: false, restingActive: true) == .resting,
                     "resting outline owns contour bar when nothing else is active")

        let agentP = NotchLevelPrismPalette(halo: .running)
        let copyP = NotchLevelPrismPalette(halo: .running)
        let pasteP = NotchLevelPrismPalette(halo: .paste)
        let musicA = NotchHaloPalette.matching(r: 0.90, g: 0.20, b: 0.35)
        let musicPA = NotchLevelPrismPalette(halo: musicA)
        let musicB = NotchHaloPalette.matching(r: 0.25, g: 0.85, b: 0.45)
        let musicPB = NotchLevelPrismPalette(halo: musicB)
        let shiftP = NotchModifierIndicator.shift.prismPalette

        // Agent enters full-width over 0.18s returning .entered
        var state = NotchContourLineState()
        let cAgentEnter = state.update(owner: .agent, palette: agentP, fullWidth: true, liveLevel: 0, at: 10.0)
        let sStart = state.sample(at: 10.0, liveLevel: 0)
        let sMidIn = state.sample(at: 10.09, liveLevel: 0)
        let sAgentSettled = state.sample(at: 10.18, liveLevel: 0)
        suite.expect(cAgentEnter == .entered
                        && sStart.fillExtent == 1.0 && sStart.railOpacity == 0.0 && sStart.armSpan == 1.0
                        && sMidIn.opacity > 0.0 && sMidIn.opacity < 1.0
                        && abs(sAgentSettled.opacity - 1.0) < 0.0001
                        && sAgentSettled.palette == agentP
                        && sAgentSettled.armSpan == 1.0,
                     "agent enters as full-width contour line over 0.18s")

        // Live width toggle on same owner animates armSpan 1 -> 0 smoothly without transition burst
        let cWidthOnly = state.update(owner: .agent, palette: agentP, fullWidth: false, liveLevel: 0, at: 10.30)
        let sWidthMid = state.sample(at: 10.41, liveLevel: 0)
        let sWidthDone = state.sample(at: 10.52, liveLevel: 0)
        suite.expect(cWidthOnly == .none && sWidthMid.armSpan > 0.0 && sWidthMid.armSpan < 1.0 && sWidthDone.armSpan == 0.0,
                     "toggling full-width setting animates armSpan smoothly without firing transition burst")

        // Shift takes over full-width while active (armSpan 0 -> 1, .transitioned)
        let cShift = state.update(owner: .modifier(.shift), palette: shiftP, fullWidth: true, liveLevel: 0, at: 10.60)
        let sShiftMid = state.sample(at: 10.69, liveLevel: 0)
        let sShiftDone = state.sample(at: 10.78, liveLevel: 0)
        suite.expect(cShift == .transitioned
                        && abs(sShiftMid.opacity - 1.0) < 0.0001
                        && sShiftMid.fillExtent == 1.0
                        && sShiftMid.railOpacity == 0.0
                        && sShiftMid.armSpan > 0.0 && sShiftMid.armSpan < 1.0
                        && sShiftMid.palette.lead.r > agentP.lead.r
                        && sShiftDone.palette == shiftP
                        && sShiftDone.armSpan == 1.0,
                     "modifier cleanly overwrites agent line color and smoothly extends to full width")

        // Quick clipboard paste takes over active bar in 0.10s (.transitioned) and snaps back to music in 0.16s (.none)
        let cMusicDrop = state.update(owner: .music, palette: musicPA, fullWidth: true, liveLevel: 0, at: 11.00)
        let sReturnMusic = state.sample(at: 11.22, liveLevel: 0)
        suite.expect(cMusicDrop == .none
                        && abs(sReturnMusic.opacity - 1.0) < 0.0001
                        && sReturnMusic.palette == musicPA
                        && sReturnMusic.armSpan == 1.0,
                     "music reclaims contour cleanly without transition burst when modifier releases")

        let cPasteOver = state.update(owner: .clipboard(isPaste: true), palette: pasteP, fullWidth: false, liveLevel: 0, at: 11.40)
        let sPasteMid = state.sample(at: 11.45, liveLevel: 0)
        let sPasteDone = state.sample(at: 11.50, liveLevel: 0)
        suite.expect(cPasteOver == .transitioned
                        && sPasteMid.armSpan > 0.0 && sPasteMid.armSpan < 1.0
                        && abs(sPasteDone.opacity - 1.0) < 0.0001
                        && sPasteDone.palette == pasteP
                        && sPasteDone.armSpan == 0.0,
                     "quick clipboard paste takes over active bar within 0.10s")

        let cPasteReturn = state.update(owner: .music, palette: musicPA, fullWidth: true, liveLevel: 0, at: 11.78)
        let sPasteReturnDone = state.sample(at: 11.94, liveLevel: 0)
        suite.expect(cPasteReturn == .none
                        && sPasteReturnDone.palette == musicPA
                        && sPasteReturnDone.armSpan == 1.0,
                     "expiring clipboard restores music bar cleanly within 0.16s without re-triggering burst")

        // Idle clipboard copy enters in 0.10s and exits in 0.18s
        var idleClipState = NotchContourLineState()
        let cClipEnter = idleClipState.update(owner: .clipboard(isPaste: false), palette: copyP, fullWidth: true, liveLevel: 0, at: 11.0)
        let sClipIn = idleClipState.sample(at: 11.10, liveLevel: 0)
        let cClipExit = idleClipState.update(owner: nil, palette: nil, fullWidth: false, liveLevel: 0, at: 11.38)
        let sClipFadeMid = idleClipState.sample(at: 11.47, liveLevel: 0)
        let sClipFadeDone = idleClipState.sample(at: 11.56, liveLevel: 0)
        suite.expect(cClipEnter == .entered && abs(sClipIn.opacity - 1.0) < 0.0001
                        && cClipExit == .exited && sClipFadeMid.opacity > 0.0 && sClipFadeMid.opacity < 1.0
                        && sClipFadeDone.opacity == 0.0 && !sClipFadeDone.isActive,
                     "idle clipboard enters in 0.10s and exits cleanly in 0.18s")

        // Volume level bar overwrites full-width music, tracks spring, expands back
        let cVol = state.update(owner: .level(kind: .volume, muted: false), palette: .volume, fullWidth: false, liveLevel: 0.45, at: 12.00)
        let sVolMid = state.sample(at: 12.07, liveLevel: 0.45)
        let sVolDone = state.sample(at: 12.14, liveLevel: 0.45)
        suite.expect(cVol == .none
                        && abs(sVolMid.opacity - 1.0) < 0.0001
                        && sVolMid.fillExtent > 0.45 && sVolMid.fillExtent < 1.0
                        && sVolMid.railOpacity > 0.0 && sVolMid.railOpacity < 1.0
                        && sVolMid.armSpan > 0.0 && sVolMid.armSpan < 1.0
                        && abs(sVolDone.fillExtent - 0.45) < 0.0001
                        && abs(sVolDone.railOpacity - 1.0) < 0.0001
                        && sVolDone.armSpan == 0.0
                        && sVolDone.palette == .volume,
                     "notch-only volume overwrites full-width music, morphs trim & collapses armSpan smoothly")

        let sVolTrack = state.sample(at: 12.40, liveLevel: 0.72)
        suite.expect(abs(sVolTrack.fillExtent - 0.72) < 0.0001,
                     "settled level owner tracks live 120Hz spring extent directly")

        state.update(owner: .music, palette: musicPA, fullWidth: true, liveLevel: 0.72, at: 13.00)
        let sBackMid = state.sample(at: 13.10, liveLevel: 0.72)
        let sBackDone = state.sample(at: 13.26, liveLevel: 0.72)
        suite.expect(abs(sBackMid.opacity - 1.0) < 0.0001
                        && sBackMid.fillExtent > 0.72 && sBackMid.fillExtent < 1.0
                        && sBackMid.railOpacity > 0.0 && sBackMid.railOpacity < 1.0
                        && sBackMid.armSpan > 0.0 && sBackMid.armSpan < 1.0
                        && abs(sBackDone.fillExtent - 1.0) < 0.0001
                        && abs(sBackDone.railOpacity) < 0.0001
                        && sBackDone.armSpan == 1.0
                        && sBackDone.palette == musicPA,
                     "expiring level bar expands back to full-width music line cleanly")

        let cSong = state.update(owner: .music, palette: musicPB, fullWidth: true, liveLevel: 0, at: 14.00)
        let sSongMid = state.sample(at: 14.13, liveLevel: 0)
        let sSongDone = state.sample(at: 14.26, liveLevel: 0)
        suite.expect(cSong == .transitioned
                        && abs(sSongMid.opacity - 1.0) < 0.0001
                        && sSongMid.palette.lead.r < musicPA.lead.r && sSongMid.palette.lead.r > musicPB.lead.r
                        && sSongDone.palette == musicPB,
                     "song change smoothly morphs contour palette and emits transition event")

        // Pausing full-width music preserves armSpan == 1.0 while fading out over 0.30s
        let cFade = state.update(owner: nil, palette: nil, fullWidth: false, liveLevel: 0, at: 15.00)
        let sFadeMid = state.sample(at: 15.15, liveLevel: 0)
        let sFadeDone = state.sample(at: 15.30, liveLevel: 0)
        suite.expect(cFade == .exited
                        && sFadeMid.opacity > 0.0 && sFadeMid.opacity < 1.0 && sFadeMid.isActive && sFadeMid.armSpan == 1.0
                        && sFadeDone.opacity == 0.0 && !sFadeDone.isActive,
                     "fading out full-width line preserves armSpan while opacity drops to zero")

        // Idle level bar pausing holds its fillExtent while fading out
        var idleLevelState = NotchContourLineState()
        idleLevelState.update(owner: .level(kind: .brightness, muted: false), palette: .sunlight, fullWidth: true, liveLevel: 0.35, at: 20.0, reduceMotion: true)
        idleLevelState.update(owner: nil, palette: nil, fullWidth: false, liveLevel: 0.35, at: 21.0)
        let sIdleLevelFade = idleLevelState.sample(at: 21.15, liveLevel: 0.35)
        suite.expect(abs(sIdleLevelFade.fillExtent - 0.35) < 0.0001
                        && sIdleLevelFade.armSpan == 1.0
                        && sIdleLevelFade.opacity > 0 && sIdleLevelFade.opacity < 1.0,
                     "expiring level bar when idle preserves trim extent and armSpan while fading out")

        // Reduce Motion snaps palette, opacity, fillExtent, and armSpan immediately
        var reduceState = NotchContourLineState()
        reduceState.update(owner: .agent, palette: agentP, fullWidth: true, liveLevel: 0, at: 30.0, reduceMotion: true)
        let rAgent = reduceState.sample(at: 30.0, liveLevel: 0, reduceMotion: true)
        reduceState.update(owner: .level(kind: .brightness, muted: false), palette: .sunlight, fullWidth: false, liveLevel: 0.62, at: 30.5, reduceMotion: true)
        let rBright = reduceState.sample(at: 30.5, liveLevel: 0.62, reduceMotion: true)
        suite.expect(rAgent.opacity == 1.0 && rAgent.palette == agentP && rAgent.armSpan == 1.0
                        && rBright.opacity == 1.0 && abs(rBright.fillExtent - 0.62) < 0.0001 && rBright.armSpan == 0.0 && rBright.palette == .sunlight,
                     "Reduce Motion snaps contour transitions including armSpan immediately")
    }
}
