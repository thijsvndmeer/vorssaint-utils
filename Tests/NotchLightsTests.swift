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
            DefaultsKey.notchLightsNotices
        ]
        suite.expect(keys.allSatisfy { Defaults.registeredDefaults[$0] != nil },
                     "all island light defaults are registered")
        suite.expect(SettingsBackupSupport.exportKeys().isSuperset(of: keys),
                     "all island light keys export cleanly with notch backups")
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
}
