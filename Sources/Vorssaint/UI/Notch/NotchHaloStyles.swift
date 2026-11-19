// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

struct NotchHaloRenderParams {
    let palette: NotchHaloPalette
    let notchSize: CGSize
    let topY: CGFloat
    let armRun: CGFloat
    let thicknessScale: Double
    let intensity: Double
    let time: TimeInterval
    let motion: NotchHaloMotion
    let floatingIsland: Bool

    func motionMultiplier(atX normalizedX: Double, seed: Double = 0) -> Double {
        switch motion {
        case .none:
            return 1.0
        case .ondulation:
            return 0.78 + 0.22 * sin(time * 2.1 + normalizedX * 3.4 + seed)
        case .flux:
            let phase = NotchLightsSupport.fract(normalizedX * 0.5 - time * 0.35 + 10.0)
            let wave = 0.5 + 0.5 * cos((phase - 0.5) * .pi * 2.0)
            return 0.65 + 0.45 * wave
        case .ripple:
            return 0.74 + 0.26 * sin(abs(normalizedX) * 6.0 - time * 3.6)
        case .shimmer:
            return 0.76 + 0.24 * sin(time * 5.2 + seed * 1.7) * cos(time * 3.1 + normalizedX * 4.0)
        }
    }

    func contourMask(size: CGSize) -> some View {
        let halfW = notchSize.width * 0.5 + armRun
        return LinearGradient(
            stops: [
                .init(color: .clear, location: 0.0),
                .init(color: .white.opacity(0.72), location: max(0.06, 0.5 - Double(halfW * 0.88 / max(1, size.width)))),
                .init(color: .white, location: 0.5),
                .init(color: .white.opacity(0.72), location: min(0.94, 0.5 + Double(halfW * 0.88 / max(1, size.width)))),
                .init(color: .clear, location: 1.0)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

/// Active style dispatcher across all 7 halo modes.
struct NotchHaloStyleRenderer: View {
    let style: NotchHaloStyle
    let params: NotchHaloRenderParams

    var body: some View {
        switch style {
        case .classic:
            NotchClassicHaloView(params: params)
        case .pixelated:
            NotchPixelatedHaloView(params: params)
        case .volumetric:
            NotchVolumetricHaloView(params: params)
        case .rays:
            NotchOrganicRaysHaloView(params: params)
        case .bioluminescent:
            NotchBioluminescentHaloView(params: params)
        case .prism:
            NotchCrystallinePrismHaloView(params: params)
        case .nimbus:
            NotchNimbusHaloView(params: params)
        }
    }
}

// MARK: 1. Classic Organic Running Light

struct NotchClassicHaloView: View {
    let params: NotchHaloRenderParams

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let shape = NotchBottomUShape(
                notchSize: params.notchSize,
                armRun: params.armRun,
                topY: params.topY,
                floatingIsland: params.floatingIsland
            )
            let travel = sin(params.time * 1.45) * Double(params.armRun * 0.45)
            let scale = CGFloat(params.thicknessScale)

            ZStack {
                shape
                    .stroke(
                        LinearGradient(
                            colors: [
                                .clear,
                                params.palette.secondary.color.opacity(0.85),
                                params.palette.primary.color,
                                params.palette.core.color,
                                params.palette.primary.color,
                                params.palette.secondary.color.opacity(0.85),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 11 * scale, lineCap: .round, lineJoin: .round)
                    )
                    .blur(radius: 12 * scale)

                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [params.palette.core.color.opacity(0.9), params.palette.primary.color.opacity(0.45), .clear],
                            center: .center,
                            startRadius: 2,
                            endRadius: (params.notchSize.width * 0.65) * scale
                        )
                    )
                    .frame(width: (params.notchSize.width + params.armRun * 0.9) * scale, height: 34 * scale)
                    .position(x: w * 0.5 + travel, y: params.topY + params.notchSize.height + 4)
                    .blur(radius: 10 * scale)

                shape
                    .stroke(params.palette.core.color.opacity(0.9), style: StrokeStyle(lineWidth: 3.0 * scale, lineCap: .round))
                    .blur(radius: 2.5 * scale)
            }
            .mask(params.contourMask(size: proxy.size))
            .opacity(min(1, params.intensity * params.motionMultiplier(atX: 0)))
        }
    }
}

// MARK: 2. Pixelated Bayer 8x8 Halo

struct NotchPixelatedHaloView: View {
    let params: NotchHaloRenderParams

    var body: some View {
        Canvas { context, size in
            let midX = Double(size.width) * 0.5
            let halfW = Double(params.notchSize.width) * 0.5
            let notchH = Double(params.notchSize.height)
            let topY = Double(params.topY)
            let arm = Double(params.armRun)
            let spread = 26.0 * params.thicknessScale
            let step = 3.0
            let minX = max(0, midX - halfW - arm)
            let maxX = min(Double(size.width), midX + halfW + arm)
            let maxY = min(Double(size.height), topY + notchH + spread * 1.4)

            var gx = 0
            var x = minX
            while x < maxX {
                var gy = 0
                var y = max(0, topY - 4)
                while y < maxY {
                    let dxSide = max(0, abs(x - midX) - halfW)
                    let dArm = hypot(max(0, dxSide - arm), max(0, y - (topY + 4)))
                    let dNotch: Double
                    if abs(x - midX) <= halfW {
                        dNotch = abs(y - (topY + notchH))
                    } else {
                        let verticalD = abs(x - midX) - halfW
                        let bottomY = min(topY + notchH, max(topY, y))
                        let wallD = hypot(verticalD, y - bottomY)
                        dNotch = y < topY + 6 ? min(wallD, abs(y - topY)) : wallD
                    }
                    let d = params.floatingIsland ? hypot(dxSide, abs(y - (topY + notchH * 0.5)) - notchH * 0.4) : min(dNotch, dArm + dxSide * 0.03)
                    let armFade = max(0, 1.0 - max(0, abs(x - midX) - halfW) / max(1, arm))
                    let falloff = max(0, 1.0 - d / spread) * armFade * params.intensity
                    let nx = (x - midX) / max(1, halfW + arm)
                    let mod = falloff * params.motionMultiplier(atX: nx, seed: Double(gx + gy) * 0.1)
                    let threshold = NotchLightsSupport.bayer8x8[(gx & 7) + ((gy & 7) << 3)]
                    if mod > threshold + 0.06 {
                        let color = mod > 0.68 ? params.palette.core.color : (mod > 0.36 ? params.palette.primary.color : params.palette.secondary.color)
                        context.fill(
                            Path(CGRect(x: x, y: y, width: step - 0.5, height: step - 0.5)),
                            with: .color(color.opacity(min(1.0, 0.45 + mod * 0.55)))
                        )
                    }
                    y += step
                    gy += 1
                }
                x += step
                gx += 1
            }
        }
    }
}

// MARK: 3. Volumetric Multi-Layer Glow

struct NotchVolumetricHaloView: View {
    let params: NotchHaloRenderParams

    var body: some View {
        GeometryReader { proxy in
            let scale = CGFloat(params.thicknessScale)
            let shape = NotchBottomUShape(
                notchSize: params.notchSize,
                armRun: params.armRun,
                topY: params.topY,
                floatingIsland: params.floatingIsland
            )
            let pulse = params.motionMultiplier(atX: 0)

            ZStack {
                shape
                    .stroke(params.palette.secondary.color.opacity(0.45), style: StrokeStyle(lineWidth: 22 * scale, lineCap: .round, lineJoin: .round))
                    .blur(radius: 24 * scale)
                shape
                    .stroke(params.palette.rim.color.opacity(0.65), style: StrokeStyle(lineWidth: 14 * scale, lineCap: .round, lineJoin: .round))
                    .blur(radius: 14 * scale)
                shape
                    .stroke(params.palette.primary.color.opacity(0.85), style: StrokeStyle(lineWidth: 7 * scale, lineCap: .round, lineJoin: .round))
                    .blur(radius: 6 * scale)
                shape
                    .stroke(params.palette.core.color.opacity(0.95), style: StrokeStyle(lineWidth: 2.5 * scale, lineCap: .round, lineJoin: .round))
                    .blur(radius: 2.5 * scale)
            }
            .mask(params.contourMask(size: proxy.size))
            .opacity(min(1, params.intensity * pulse))
        }
    }
}

// MARK: 4. Organic Rays + Fog + Humidity Particles (Default Signature Glance Style)

struct NotchOrganicRaysHaloView: View {
    let params: NotchHaloRenderParams

    var body: some View {
        GeometryReader { proxy in
            let midX = proxy.size.width * 0.5
            let halfW = params.notchSize.width * 0.5
            let scale = CGFloat(params.thicknessScale)
            let shape = NotchBottomUShape(
                notchSize: params.notchSize,
                armRun: params.armRun,
                topY: params.topY,
                floatingIsland: params.floatingIsland
            )

            ZStack {
                // Soft arm fog foundation
                shape
                    .stroke(
                        LinearGradient(
                            colors: [
                                .clear,
                                params.palette.secondary.color.opacity(0.5),
                                params.palette.primary.color.opacity(0.78),
                                params.palette.secondary.color.opacity(0.5),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 10 * scale, lineCap: .round, lineJoin: .round)
                    )
                    .blur(radius: 11 * scale)
                    .mask(params.contourMask(size: proxy.size))

                // Left & right volumetric trapezoid shafts
                ForEach([-1.0, 1.0], id: \.self) { sign in
                    armRayGroup(sign: sign, midX: midX, halfW: halfW)
                }

                // Bottom-notch downward fan shafts
                ForEach(0..<7, id: \.self) { index in
                    bottomRayView(index: index, midX: midX, scale: scale)
                }

                // Crisp inner contour filament
                shape
                    .stroke(params.palette.core.color.opacity(0.85 * params.intensity), style: StrokeStyle(lineWidth: 2.0 * scale, lineCap: .round))
                    .blur(radius: 1.8 * scale)
                    .mask(params.contourMask(size: proxy.size))

                // Drifting humidity dust particles
                NotchRayHumidityParticles(
                    palette: params.palette,
                    notchSize: params.notchSize,
                    topY: params.topY,
                    armRun: params.armRun,
                    thicknessScale: params.thicknessScale,
                    time: params.time,
                    intensity: params.intensity
                )
            }
            .drawingGroup()
        }
    }

    @ViewBuilder
    private func armRayGroup(sign: Double, midX: CGFloat, halfW: CGFloat) -> some View {
        let rays = NotchLightsSupport.armRays(
            armRun: params.armRun,
            thicknessScale: params.thicknessScale,
            intensity: params.intensity,
            sign: sign
        )
        let edgeX = midX + CGFloat(sign) * halfW
        let gradient = LinearGradient(
            colors: [
                params.palette.core.color.opacity(0.95),
                params.palette.primary.color.opacity(0.85),
                params.palette.secondary.color.opacity(0.32),
                .clear
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        ForEach(rays, id: \.index) { ray in
            let nx = Double(ray.xOffset / max(1, params.armRun))
            let flicker = params.motionMultiplier(atX: nx, seed: ray.phase)
            let beamWidth = CGFloat(ray.width) * 2.2
            let beamHeight = CGFloat(ray.length) * CGFloat(0.85 + 0.15 * flicker)
            let blurRadius = CGFloat(max(1.2, ray.width * 0.85))
            let alpha = min(1.0, ray.opacity * params.intensity * 3.1 * flicker)
            NotchRayTrapezoid(topInset: 0.3, bottomInset: 0.0)
                .fill(gradient)
                .frame(width: beamWidth, height: beamHeight)
                .blur(radius: blurRadius)
                .rotationEffect(.degrees(ray.angleDegrees), anchor: .top)
                .position(x: edgeX + ray.xOffset, y: params.topY + CGFloat(ray.length) * 0.45)
                .opacity(alpha)
        }
    }

    @ViewBuilder
    private func bottomRayView(index: Int, midX: CGFloat, scale: CGFloat) -> some View {
        let frac = Double(index) / 6.0 - 0.5
        let x = midX + CGFloat(frac) * (params.notchSize.width * 0.82)
        let centerMod = params.motionMultiplier(atX: frac * 0.4, seed: Double(index) * 1.3)
        let rHeight = (36.0 + 18.0 * NotchLightsSupport.hash(Double(index) + 41.9)) * params.thicknessScale
        let gradient = LinearGradient(
            colors: [params.palette.core.color.opacity(0.92), params.palette.primary.color.opacity(0.75), .clear],
            startPoint: .top,
            endPoint: .bottom
        )
        let alpha = min(1.0, (0.36 + 0.14 * (1.0 - abs(frac))) * params.intensity * centerMod)
        NotchRayTrapezoid(topInset: 0.3, bottomInset: 0.0)
            .fill(gradient)
            .frame(width: 4.2 * scale, height: CGFloat(rHeight))
            .blur(radius: 3.5 * scale)
            .rotationEffect(.degrees(frac * 18.0), anchor: .top)
            .position(x: x, y: params.topY + params.notchSize.height + CGFloat(rHeight) * 0.42)
            .opacity(alpha)
    }
}

struct NotchRayHumidityParticles: View {
    let palette: NotchHaloPalette
    let notchSize: CGSize
    let topY: CGFloat
    let armRun: CGFloat
    let thicknessScale: Double
    let time: TimeInterval
    let intensity: Double

    var body: some View {
        Canvas { context, size in
            let midX = Double(size.width) * 0.5
            let span = Double(notchSize.width * 0.5 + armRun * 0.85)
            let count = 28
            for i in 0..<count {
                let s = Double(i)
                let rx = NotchLightsSupport.fract(sin(s * 12.9898 + 336.402) * 43758.5)
                let ry = NotchLightsSupport.fract(sin((s + 17.0) * 12.9898 + 336.402) * 43758.5)
                let rp = NotchLightsSupport.fract(sin((s + 53.0) * 12.9898 + 336.402) * 43758.5)
                let drift = sin(time * (0.7 + rp * 0.9) + s) * 8.0
                let fall = (time * (8.0 + rp * 10.0) + ry * 54.0).truncatingRemainder(dividingBy: 56.0)
                let x = midX + (rx * 2.0 - 1.0) * span + drift
                let baseY = abs(x - midX) < Double(notchSize.width * 0.52) ? Double(topY + notchSize.height) : Double(topY + 2)
                let y = baseY + fall * thicknessScale
                let fade = sin(min(.pi, (fall / 56.0) * .pi)) * (0.4 + 0.6 * ry) * intensity
                let r = (0.9 + rp * 1.4) * thicknessScale
                context.fill(
                    Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                    with: .color(palette.core.color.opacity(min(0.85, fade * 0.72)))
                )
            }
        }
    }
}

// MARK: 5. Bioluminescent Plankton Halo

struct NotchBioluminescentHaloView: View {
    let params: NotchHaloRenderParams

    var body: some View {
        GeometryReader { proxy in
            let shape = NotchBottomUShape(
                notchSize: params.notchSize,
                armRun: params.armRun,
                topY: params.topY,
                floatingIsland: params.floatingIsland
            )
            ZStack {
                shape
                    .stroke(params.palette.secondary.color.opacity(0.35 * params.intensity),
                            style: StrokeStyle(lineWidth: 10 * CGFloat(params.thicknessScale), lineCap: .round))
                    .blur(radius: 10)
                    .mask(params.contourMask(size: proxy.size))

                Canvas { context, size in
                    let midX = Double(size.width) * 0.5
                    let halfW = Double(params.notchSize.width) * 0.5
                    let notchH = Double(params.notchSize.height)
                    let topY = Double(params.topY)
                    let arm = Double(params.armRun)
                    let count = 64

                    for i in 0..<count {
                        let u = Double(i) / Double(max(1, count - 1)) * 2.0 - 1.0
                        let xAnchor = midX + u * (halfW + arm * 0.92)
                        let s = Double(i)
                        let r1 = NotchLightsSupport.hash(s + 11.3)
                        let r2 = NotchLightsSupport.hash(s + 29.7)
                        let r3 = NotchLightsSupport.hash(s + 47.1)
                        let dx = (r1 - 0.5) * 14.0 + sin(params.time * (0.9 + r3) + s) * 4.5
                        let x = xAnchor + dx
                        let onNotchBottom = abs(x - midX) <= halfW
                        let contourY = onNotchBottom ? (topY + notchH) : (topY + 4.0)
                        let y = contourY + (r2 * 22.0 - 2.0) * params.thicknessScale + cos(params.time * (1.1 + r1) + s) * 3.0
                        let glow = (0.35 + 0.65 * sin(params.time * (1.8 + r2 * 2.4) + s * 1.9) * 0.5 + 0.5)
                        let armFade = max(0.05, 1.0 - max(0.0, abs(x - midX) - halfW) / max(1.0, arm))
                        let radius = (1.3 + r3 * 2.8) * params.thicknessScale
                        let color = r1 > 0.65 ? params.palette.core.color : (r1 > 0.25 ? params.palette.primary.color : params.palette.secondary.color)
                        context.fill(
                            Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)),
                            with: .color(color.opacity(min(1.0, glow * armFade * params.intensity)))
                        )
                    }
                }
            }
        }
    }
}

// MARK: 6. Crystalline Prism + 4 Corner Cross Flares

struct NotchCrystallinePrismHaloView: View {
    let params: NotchHaloRenderParams

    var body: some View {
        GeometryReader { proxy in
            let midX = proxy.size.width * 0.5
            let halfW = params.notchSize.width * 0.5
            let bottomY = params.topY + params.notchSize.height
            let scale = CGFloat(params.thicknessScale)
            let shape = NotchBottomUShape(
                notchSize: params.notchSize,
                armRun: params.armRun,
                topY: params.topY,
                floatingIsland: params.floatingIsland
            )
            let flarePulse = params.motionMultiplier(atX: 0.25)

            ZStack {
                shape
                    .stroke(params.palette.rim.color.opacity(0.62), style: StrokeStyle(lineWidth: 4.2 * scale, lineCap: .round, lineJoin: .round))
                    .offset(x: -1.8, y: 1.5)
                    .blur(radius: 3.5 * scale)
                shape
                    .stroke(params.palette.secondary.color.opacity(0.65), style: StrokeStyle(lineWidth: 4.2 * scale, lineCap: .round, lineJoin: .round))
                    .offset(x: 1.8, y: 1.5)
                    .blur(radius: 3.5 * scale)
                shape
                    .stroke(params.palette.core.color.opacity(0.95), style: StrokeStyle(lineWidth: 2.0 * scale, lineCap: .round, lineJoin: .round))
                    .blur(radius: 1.4 * scale)

                let corners: [CGPoint] = [
                    CGPoint(x: midX - halfW, y: params.topY + 4),
                    CGPoint(x: midX + halfW, y: params.topY + 4),
                    CGPoint(x: midX - halfW + 4, y: bottomY),
                    CGPoint(x: midX + halfW - 4, y: bottomY)
                ]
                ForEach(0..<corners.count, id: \.self) { idx in
                    NotchPrismCornerFlare(
                        color: idx.isMultiple(of: 2) ? params.palette.primary.color : params.palette.secondary.color,
                        coreColor: params.palette.core.color,
                        scale: scale * CGFloat(0.85 + 0.15 * sin(params.time * 2.5 + Double(idx) * 1.4)),
                        opacity: min(1.0, params.intensity * flarePulse)
                    )
                    .position(corners[idx])
                }
            }
            .mask(params.contourMask(size: proxy.size))
            .opacity(params.intensity)
        }
    }
}

// MARK: 7. Photoreal Nimbus Cloud Halo

struct NotchNimbusHaloView: View {
    let params: NotchHaloRenderParams

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let lobes = 9
            ZStack {
                ForEach(0..<lobes, id: \.self) { idx in
                    let frac = Double(idx) / Double(lobes - 1) - 0.5
                    let drift = sin(params.time * 0.8 + Double(idx) * 1.1) * 10.0
                    let x = w * 0.5 + CGFloat(frac) * (params.notchSize.width + params.armRun * 1.4) + drift
                    let underNotch = abs(frac) < 0.25
                    let y = (underNotch ? params.topY + params.notchSize.height : params.topY + 6) + CGFloat(4.0 * params.thicknessScale)
                    let radius = (32.0 + 18.0 * NotchLightsSupport.hash(Double(idx) + 19.4)) * params.thicknessScale
                    let color = idx.isMultiple(of: 2) ? params.palette.primary.color : params.palette.secondary.color
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [params.palette.core.color.opacity(0.45), color.opacity(0.62), .clear],
                                center: .center,
                                startRadius: 2,
                                endRadius: radius
                            )
                        )
                        .frame(width: radius * 2.4, height: radius * 1.25)
                        .position(x: x, y: y)
                        .blur(radius: 12 * CGFloat(params.thicknessScale))
                        .opacity(params.motionMultiplier(atX: frac * 1.6, seed: Double(idx)))
                }
            }
            .mask(params.contourMask(size: proxy.size))
            .opacity(min(1, params.intensity * 0.92))
        }
    }
}
