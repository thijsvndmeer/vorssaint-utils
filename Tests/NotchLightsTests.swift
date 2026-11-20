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
            DefaultsKey.notchLightsLevelBars
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
        suite.expect(NotchHaloArmWidth.extraWide.points <= NotchLightsSupport.maxArmRun,
                     "extra-wide arm reach stays within 520pt cap")
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
        // Priority order: level > modifier > fullHalo > music > resting
        suite.expect(NotchContourLineState.resolveOwner(levelKind: .volume, levelMuted: false, modifier: .shift, musicActive: true, restingActive: true, fullHaloActive: true) == .level(kind: .volume, muted: false),
                     "level HUD takes top priority over modifier, full halo, music, and resting")
        suite.expect(NotchContourLineState.resolveOwner(levelKind: nil, levelMuted: false, modifier: .capsLock, musicActive: true, restingActive: true, fullHaloActive: true) == .modifier(.capsLock),
                     "modifier indicator takes priority over full halo, music, and resting")
        suite.expect(NotchContourLineState.resolveOwner(levelKind: nil, levelMuted: false, modifier: nil, musicActive: true, restingActive: true, fullHaloActive: true) == nil,
                     "full halo suppresses ambient music and resting contour owners")
        suite.expect(NotchContourLineState.resolveOwner(levelKind: nil, levelMuted: false, modifier: nil, musicActive: true, restingActive: true, fullHaloActive: false) == .music,
                     "music owns contour line when no higher priority signal or full halo is active")
        suite.expect(NotchContourLineState.resolveOwner(levelKind: nil, levelMuted: false, modifier: nil, musicActive: false, restingActive: true, fullHaloActive: false) == .resting,
                     "resting outline owns contour line when nothing else is active")

        // Transition scenarios
        let musicA = NotchHaloPalette.matching(r: 0.90, g: 0.20, b: 0.35)
        let musicPA = NotchLevelPrismPalette(halo: musicA)
        let musicB = NotchHaloPalette.matching(r: 0.25, g: 0.85, b: 0.45)
        let musicPB = NotchLevelPrismPalette(halo: musicB)
        let shiftP = NotchModifierIndicator.shift.prismPalette

        var state = NotchContourLineState()
        state.update(owner: .music, palette: musicPA, liveLevel: 0, at: 10.0)
        let sStart = state.sample(at: 10.0, liveLevel: 0)
        let sMidIn = state.sample(at: 10.10, liveLevel: 0)
        let sMusicSettled = state.sample(at: 10.20, liveLevel: 0)
        suite.expect(sStart.fillExtent == 1.0 && sStart.railOpacity == 0.0
                        && sMidIn.opacity > 0.0 && sMidIn.opacity < 1.0
                        && abs(sMusicSettled.opacity - 1.0) < 0.0001
                        && sMusicSettled.palette == musicPA
                        && sMusicSettled.fillExtent == 1.0
                        && sMusicSettled.railOpacity == 0.0,
                     "music enters from idle as a full contour line without rail over 0.20s")

        // Shift takes over smoothly without opacity dip
        state.update(owner: .modifier(.shift), palette: shiftP, liveLevel: 0, at: 10.50)
        let sShiftMid = state.sample(at: 10.61, liveLevel: 0)
        let sShiftDone = state.sample(at: 10.73, liveLevel: 0)
        suite.expect(abs(sShiftMid.opacity - 1.0) < 0.0001
                        && sShiftMid.fillExtent == 1.0
                        && sShiftMid.railOpacity == 0.0
                        && sShiftMid.palette.lead.r < musicPA.lead.r && sShiftMid.palette.lead.r > shiftP.lead.r
                        && sShiftDone.palette == shiftP,
                     "modifier cleanly overwrites active music line color with constant opacity")

        // Release Shift -> returns to music color cleanly
        state.update(owner: .music, palette: musicPA, liveLevel: 0, at: 11.00)
        let sReturnMusic = state.sample(at: 11.23, liveLevel: 0)
        suite.expect(abs(sReturnMusic.opacity - 1.0) < 0.0001 && sReturnMusic.palette == musicPA,
                     "releasing modifier returns contour line smoothly to music color")

        // Volume takes over while Music plays: morphs extent & fades in rail cleanly
        state.update(owner: .level(kind: .volume, muted: false), palette: .volume, liveLevel: 0.45, at: 12.00)
        let sVolMid = state.sample(at: 12.08, liveLevel: 0.45)
        let sVolDone = state.sample(at: 12.17, liveLevel: 0.45)
        suite.expect(abs(sVolMid.opacity - 1.0) < 0.0001
                        && sVolMid.fillExtent > 0.45 && sVolMid.fillExtent < 1.0
                        && sVolMid.railOpacity > 0.0 && sVolMid.railOpacity < 1.0
                        && abs(sVolDone.fillExtent - 0.45) < 0.0001
                        && abs(sVolDone.railOpacity - 1.0) < 0.0001
                        && sVolDone.palette == .volume,
                     "volume overwrites music contour line, morphs trim to liveLevel, and brings in dim rail")

        // Live spring update after transition settled tracks 1:1
        let sVolTrack = state.sample(at: 12.40, liveLevel: 0.72)
        suite.expect(abs(sVolTrack.fillExtent - 0.72) < 0.0001,
                     "settled level owner tracks live 120Hz spring extent directly")

        // Expire Volume back to Music -> expands back to full 1.0 and removes rail
        state.update(owner: .music, palette: musicPA, liveLevel: 0.72, at: 13.00)
        let sBackMid = state.sample(at: 13.12, liveLevel: 0.72)
        let sBackDone = state.sample(at: 13.33, liveLevel: 0.72)
        suite.expect(abs(sBackMid.opacity - 1.0) < 0.0001
                        && sBackMid.fillExtent > 0.72 && sBackMid.fillExtent < 1.0
                        && sBackMid.railOpacity > 0.0 && sBackMid.railOpacity < 1.0
                        && abs(sBackDone.fillExtent - 1.0) < 0.0001
                        && abs(sBackDone.railOpacity) < 0.0001
                        && sBackDone.palette == musicPA,
                     "expiring level bar expands back to full music line cleanly")

        // Song-to-song tint shift blends smoothly at constant opacity
        state.update(owner: .music, palette: musicPB, liveLevel: 0, at: 14.00)
        let sSongMid = state.sample(at: 14.16, liveLevel: 0)
        let sSongDone = state.sample(at: 14.33, liveLevel: 0)
        suite.expect(abs(sSongMid.opacity - 1.0) < 0.0001
                        && sSongMid.palette.lead.r < musicPA.lead.r && sSongMid.palette.lead.r > musicPB.lead.r
                        && sSongDone.palette == musicPB,
                     "song change smoothly morphs contour palette without restarting opacity")

        // Pausing music when idle fades opacity cleanly to zero
        state.update(owner: nil, palette: nil, liveLevel: 0, at: 15.00)
        let sFadeMid = state.sample(at: 15.18, liveLevel: 0)
        let sFadeDone = state.sample(at: 15.37, liveLevel: 0)
        suite.expect(sFadeMid.opacity > 0.0 && sFadeMid.opacity < 1.0 && sFadeMid.isActive
                        && sFadeDone.opacity == 0.0 && !sFadeDone.isActive,
                     "pausing music without resting outline fades contour line cleanly to inactive")

        // Idle level bar pausing holds its fillExtent while fading out
        var idleLevelState = NotchContourLineState()
        idleLevelState.update(owner: .level(kind: .brightness, muted: false), palette: .sunlight, liveLevel: 0.35, at: 20.0, reduceMotion: true)
        idleLevelState.update(owner: nil, palette: nil, liveLevel: 0.35, at: 21.0)
        let sIdleLevelFade = idleLevelState.sample(at: 21.18, liveLevel: 0.35)
        suite.expect(abs(sIdleLevelFade.fillExtent - 0.35) < 0.0001 && sIdleLevelFade.opacity > 0 && sIdleLevelFade.opacity < 1.0,
                     "expiring level bar when idle preserves its trim extent while fading out")

        // Reduce Motion snaps palette, opacity, and fillExtent immediately
        var reduceState = NotchContourLineState()
        reduceState.update(owner: .music, palette: musicPA, liveLevel: 0, at: 30.0, reduceMotion: true)
        let rMusic = reduceState.sample(at: 30.0, liveLevel: 0, reduceMotion: true)
        reduceState.update(owner: .level(kind: .brightness, muted: false), palette: .sunlight, liveLevel: 0.62, at: 30.5, reduceMotion: true)
        let rBright = reduceState.sample(at: 30.5, liveLevel: 0.62, reduceMotion: true)
        suite.expect(rMusic.opacity == 1.0 && rMusic.palette == musicPA
                        && rBright.opacity == 1.0 && abs(rBright.fillExtent - 0.62) < 0.0001 && rBright.palette == .sunlight,
                     "Reduce Motion snaps contour transitions immediately")
    }
}
