// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// Traces Glance's continuous bottom-U notch contour with outward arm wings
/// (using 0.22 / 0.45 / 0.55 / 0.552 / 0.78 cubic curve handles), or the
/// rounded floating-capsule perimeter on non-notched displays.
struct NotchBottomUShape: Shape {
    var notchSize: CGSize
    var armRun: CGFloat
    var topY: CGFloat
    var floatingIsland: Bool

    func path(in rect: CGRect) -> Path {
        let midX = rect.midX
        let halfW = notchSize.width * 0.5
        let h = notchSize.height

        if floatingIsland {
            let capsuleRect = CGRect(
                x: midX - halfW,
                y: topY,
                width: notchSize.width,
                height: h
            )
            let radius = min(h * 0.48, 16)
            return Path(roundedRect: capsuleRect, cornerRadius: radius, style: .continuous)
        }

        let topShoulder: CGFloat = min(14, halfW * 0.22)
        let bottomCorner: CGFloat = min(16, h * 0.48)
        let leftArmStart = midX - halfW - armRun
        let leftEdge = midX - halfW
        let rightEdge = midX + halfW
        let rightArmEnd = midX + halfW + armRun
        let bottomY = topY + h

        var p = Path()
        p.move(to: CGPoint(x: leftArmStart, y: topY))
        p.addLine(to: CGPoint(x: leftEdge - topShoulder, y: topY))

        // Top-left transition into vertical wall
        p.addCurve(
            to: CGPoint(x: leftEdge, y: topY + topShoulder),
            control1: CGPoint(x: leftEdge - topShoulder * 0.45, y: topY),
            control2: CGPoint(x: leftEdge, y: topY + topShoulder * 0.45)
        )

        let straightDrop = max(0, h - topShoulder - bottomCorner)
        if straightDrop > 0.5 {
            p.addLine(to: CGPoint(x: leftEdge, y: topY + topShoulder + straightDrop))
        }

        // Bottom-left continuous curve
        p.addCurve(
            to: CGPoint(x: leftEdge + bottomCorner, y: bottomY),
            control1: CGPoint(x: leftEdge, y: bottomY - bottomCorner * 0.22),
            control2: CGPoint(x: leftEdge + bottomCorner * 0.45, y: bottomY)
        )

        p.addLine(to: CGPoint(x: rightEdge - bottomCorner, y: bottomY))

        // Bottom-right continuous curve
        p.addCurve(
            to: CGPoint(x: rightEdge, y: bottomY - bottomCorner),
            control1: CGPoint(x: rightEdge - bottomCorner * 0.45, y: bottomY),
            control2: CGPoint(x: rightEdge, y: bottomY - bottomCorner * 0.22)
        )

        if straightDrop > 0.5 {
            p.addLine(to: CGPoint(x: rightEdge, y: topY + topShoulder))
        }

        // Top-right transition out to right wing
        p.addCurve(
            to: CGPoint(x: rightEdge + topShoulder, y: topY),
            control1: CGPoint(x: rightEdge, y: topY + topShoulder * 0.45),
            control2: CGPoint(x: rightEdge + topShoulder * 0.45, y: topY)
        )

        p.addLine(to: CGPoint(x: rightArmEnd, y: topY))
        return p
    }
}

/// Tapered trapezoidal light beam used for Organic Rays.
struct NotchRayTrapezoid: Shape {
    var topInset: CGFloat = 0.3
    var bottomInset: CGFloat = 0.0

    func path(in rect: CGRect) -> Path {
        let topHalfInset = rect.width * topInset * 0.5
        let botHalfInset = rect.width * bottomInset * 0.5
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + topHalfInset, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - topHalfInset, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - botHalfInset, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX + botHalfInset, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// Crisp four-point prismatic corner star flare.
struct NotchPrismCornerFlare: View {
    let color: Color
    let coreColor: Color
    let scale: CGFloat
    let opacity: Double

    var body: some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.clear, color.opacity(0.85), coreColor, color.opacity(0.85), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 24 * scale, height: 1.6 * max(0.7, scale * 0.85))
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.clear, color.opacity(0.85), coreColor, color.opacity(0.85), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 1.6 * max(0.7, scale * 0.85), height: 22 * scale)
            Circle()
                .fill(coreColor.opacity(0.9))
                .frame(width: 4 * scale, height: 4 * scale)
                .blur(radius: 1.5)
        }
        .opacity(opacity)
    }
}
