import SwiftUI

/// Native port of the web Ember SVG companion (Avatar.tsx).
struct EmberFlameAvatar: View {
    var level: Int = 1
    var size: CGFloat = 220
    var style: AvatarStyle = AvatarStyle.presets[0]
    
    @State private var pulse = false
    @State private var sparkle = false
    
    private var blaze: Bool { style.forceBlaze || level >= 5 }
    
    var body: some View {
        ZStack {
            // Soft ember aura under the flame
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: style.auraColor).opacity(0.55),
                            Color(hex: style.auraColor).opacity(0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: size * 0.55
                    )
                )
                .frame(width: size * 0.9, height: size * 0.45)
                .offset(y: size * 0.28)
                .blur(radius: 18)
                .scaleEffect(pulse ? 1.08 : 0.92)
                .opacity(pulse ? 0.9 : 0.65)
            
            FlameSVG(blaze: blaze, style: style)
                .frame(width: size, height: size * 1.15)
                .scaleEffect(pulse ? 1.03 : 0.97)
                .shadow(color: Color(hex: style.outerColors[2]).opacity(0.55), radius: 22, y: 8)
            
            // Sparks
            Circle()
                .fill(Color(hex: style.sparkColors[0]))
                .frame(width: 7, height: 7)
                .offset(x: -size * 0.28, y: -size * 0.22)
                .opacity(sparkle ? 1 : 0.35)
                .scaleEffect(sparkle ? 1.2 : 0.7)
            
            Circle()
                .fill(Color(hex: style.sparkColors[1]))
                .frame(width: 5.5, height: 5.5)
                .offset(x: size * 0.3, y: -size * 0.26)
                .opacity(sparkle ? 0.4 : 1)
                .scaleEffect(sparkle ? 0.7 : 1.15)
            
            // Side sparks (optional)
            if style.hasSideSparks {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color(hex: style.sparkColors[0]))
                        .frame(width: 4, height: 4)
                        .offset(
                            x: size * (index % 2 == 0 ? -0.35 : 0.35),
                            y: size * (-0.05 + CGFloat(index) * 0.08)
                        )
                        .opacity(sparkle ? 0.8 : 0.3)
                        .scaleEffect(sparkle ? 1.3 : 0.8)
                }
            }
            
            // Circlet accessory (optional)
            if style.hasCirclet {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(hex: style.sparkColors[0]).opacity(0.8),
                                Color(hex: style.sparkColors[1]).opacity(0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.5
                    )
                    .frame(width: size * 0.28, height: size * 0.28)
                    .offset(y: -size * 0.38)
                    .rotationEffect(.degrees(sparkle ? 5 : -5))
            }

            if style.hasHorns {
                Path { path in
                    path.move(to: CGPoint(x: size * 0.32, y: size * 0.18))
                    path.addLine(to: CGPoint(x: size * 0.22, y: -size * 0.02))
                    path.addLine(to: CGPoint(x: size * 0.38, y: size * 0.12))
                    path.closeSubpath()
                }
                .fill(Color(hex: style.outerColors[2]))
                .opacity(0.95)
                Path { path in
                    path.move(to: CGPoint(x: size * 0.68, y: size * 0.18))
                    path.addLine(to: CGPoint(x: size * 0.78, y: -size * 0.02))
                    path.addLine(to: CGPoint(x: size * 0.62, y: size * 0.12))
                    path.closeSubpath()
                }
                .fill(Color(hex: style.outerColors[2]))
                .opacity(0.95)
            }
        }
        .frame(width: size, height: size * 1.2)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                sparkle = true
            }
        }
        .accessibilityLabel("Ember companion")
    }
}

private struct FlameSVG: View {
    var blaze: Bool
    var style: AvatarStyle
    
    var body: some View {
        Canvas { context, size in
            let sx = size.width / 200
            let sy = size.height / 240
            
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: x * sx, y: y * sy)
            }
            
            // Outer flame gradient
            let outerRect = CGRect(origin: .zero, size: size)
            let outerGradient = Gradient(stops: [
                .init(color: Color(hex: style.outerColors[0]), location: 0),
                .init(color: Color(hex: style.outerColors[1]), location: 0.38),
                .init(color: Color(hex: style.outerColors[2]), location: 0.78),
                .init(color: Color(hex: style.outerColors[3]), location: 1)
            ])
            
            if blaze {
                var left = Path()
                left.move(to: p(38, 118))
                left.addCurve(to: p(58, 48), control1: p(18, 92), control2: p(28, 54))
                left.addCurve(to: p(52, 122), control1: p(48, 78), control2: p(42, 98))
                left.closeSubpath()
                context.fill(left, with: .linearGradient(outerGradient, startPoint: p(50, 40), endPoint: p(50, 130)))
                
                var right = Path()
                right.move(to: p(162, 118))
                right.addCurve(to: p(142, 48), control1: p(182, 92), control2: p(172, 54))
                right.addCurve(to: p(148, 122), control1: p(152, 78), control2: p(158, 98))
                right.closeSubpath()
                context.fill(right, with: .linearGradient(outerGradient, startPoint: p(150, 40), endPoint: p(150, 130)))
            }
            
            // Main body
            var body = Path()
            if blaze {
                body.move(to: p(100, 16))
                body.addCurve(to: p(168, 148), control1: p(132, 40), control2: p(176, 78))
                body.addCurve(to: p(100, 232), control1: p(160, 196), control2: p(124, 226))
                body.addCurve(to: p(32, 148), control1: p(76, 226), control2: p(40, 196))
                body.addCurve(to: p(100, 16), control1: p(24, 78), control2: p(68, 40))
            } else {
                body.move(to: p(100, 28))
                body.addCurve(to: p(154, 164), control1: p(138, 56), control2: p(168, 108))
                body.addCurve(to: p(100, 228), control1: p(142, 204), control2: p(116, 224))
                body.addCurve(to: p(46, 164), control1: p(84, 224), control2: p(58, 204))
                body.addCurve(to: p(100, 28), control1: p(32, 108), control2: p(62, 56))
            }
            context.fill(body, with: .linearGradient(outerGradient, startPoint: p(100, 20), endPoint: p(100, 230)))
            
            // Inner flame
            let innerGradient = Gradient(stops: [
                .init(color: Color(hex: style.innerColors[0]), location: 0),
                .init(color: Color(hex: style.innerColors[1]), location: 0.55),
                .init(color: Color(hex: style.innerColors[2]), location: 1)
            ])
            var inner = Path()
            if blaze {
                inner.move(to: p(100, 58))
                inner.addCurve(to: p(140, 158), control1: p(124, 78), control2: p(148, 112))
                inner.addCurve(to: p(100, 208), control1: p(134, 186), control2: p(112, 204))
                inner.addCurve(to: p(60, 158), control1: p(88, 204), control2: p(66, 186))
                inner.addCurve(to: p(100, 58), control1: p(52, 112), control2: p(76, 78))
            } else {
                inner.move(to: p(100, 72))
                inner.addCurve(to: p(132, 158), control1: p(122, 90), control2: p(140, 122))
                inner.addCurve(to: p(100, 202), control1: p(126, 182), control2: p(110, 198))
                inner.addCurve(to: p(68, 158), control1: p(90, 198), control2: p(74, 182))
                inner.addCurve(to: p(100, 72), control1: p(60, 122), control2: p(78, 90))
            }
            context.fill(inner, with: .linearGradient(innerGradient, startPoint: p(100, 60), endPoint: p(100, 210)))
            
            // Hot core
            let coreY: CGFloat = blaze ? 150 : 158
            let coreRx: CGFloat = blaze ? 28 : 22
            let coreRy: CGFloat = blaze ? 34 : 28
            let core = Path(ellipseIn: CGRect(
                x: (100 - coreRx) * sx,
                y: (coreY - coreRy) * sy,
                width: coreRx * 2 * sx,
                height: coreRy * 2 * sy
            ))
            let coreGradient = Gradient(stops: [
                .init(color: Color(hex: style.coreColors[0]), location: 0),
                .init(color: Color(hex: style.coreColors[1]), location: 0.7),
                .init(color: Color(hex: style.coreColors[2]).opacity(0.2), location: 1)
            ])
            context.fill(core, with: .radialGradient(coreGradient, center: p(100, coreY), startRadius: 0, endRadius: coreRx * sx * 1.4))
            
            // Eyes
            let eyeY: CGFloat = blaze ? 138 : 146
            drawEye(context: context, cx: 82 * sx, cy: eyeY * sy, scale: sx, eyeStyle: style.eyeStyle)
            drawEye(context: context, cx: 118 * sx, cy: eyeY * sy, scale: sx, wide: true, eyeStyle: style.eyeStyle)
            
            // Smile
            let mouthY: CGFloat = blaze ? 174 : 174
            var smile = Path()
            smile.move(to: p(86, mouthY - 2))
            smile.addQuadCurve(to: p(114, mouthY - 2), control: p(100, mouthY + 10))
            context.stroke(
                smile,
                with: .color(Color(hex: "#2a1208")),
                style: StrokeStyle(lineWidth: 3.2 * sx, lineCap: .round)
            )
        }
    }
    
    private func drawEye(context: GraphicsContext, cx: CGFloat, cy: CGFloat, scale: CGFloat, wide: Bool = false, eyeStyle: AvatarStyle.EyeStyle) {
        let rx: CGFloat = 8 * scale
        let ry: CGFloat = eyeStyle == .sleepy ? 6 * scale : (eyeStyle == .excited ? 9 * scale : 8 * scale)
        let white = Path(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2))
        context.fill(white, with: .color(Color(hex: "#fff8ee")))
        
        let pupilR = eyeStyle == .wide ? 4 * scale : (eyeStyle == .excited ? 4.2 * scale : 3.4 * scale)
        let px = cx + (wide ? 1.2 * scale : 0)
        let py = cy + (eyeStyle == .sleepy ? 1.5 * scale : 1 * scale)
        let pupil = Path(ellipseIn: CGRect(x: px - pupilR, y: py - pupilR, width: pupilR * 2, height: pupilR * 2))
        context.fill(pupil, with: .color(Color(hex: "#2a1208")))
        
        let hl = Path(ellipseIn: CGRect(
            x: cx + 2.4 * scale - 1.6 * scale,
            y: cy - 2.2 * scale - 1.6 * scale,
            width: 3.2 * scale,
            height: 3.2 * scale
        ))
        context.fill(hl, with: .color(.white))
    }
}

#Preview {
    ZStack {
        Color(hex: "#100814").ignoresSafeArea()
        EmberFlameAvatar(level: 1, size: 240)
    }
}
