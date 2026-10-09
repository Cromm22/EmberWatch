import SwiftUI

/// Home / sheet companion. Built from many small subviews so the type checker
/// never sees a long modifier chain with mixed arithmetic.
struct CompanionAvatarView: View {
    var species: CompanionSpecies
    var stage: CompanionStage
    var tier: ProgressionTier
    var size: CGFloat = 220
    var extraGlow: Bool = false
    var equipped: [EquipmentSlot: EquipmentItem] = [:]
    var effectId: String? = nil
    var prestigeSkinId: String? = nil

    @State private var pulse = false

    var body: some View {
        let frameW = size
        let frameH = size * 1.18
        ZStack {
            CompanionAuraBlob(
                hex: auraHex,
                size: size,
                extraGlow: extraGlow,
                pulse: pulse
            )
            if tier.showsLegendAura {
                CompanionLegendRing(size: size, pulse: pulse)
            }
            CompanionCreatureLayer(
                species: species,
                stage: stage,
                size: size,
                prestigeSkinId: prestigeSkinId
            )
            CompanionGearOverlay(
                tier: tier,
                equipped: equipped,
                size: size
            )
            if let effectId {
                CompanionEffectLayer(effectId: effectId, size: size, pulse: pulse)
            }
        }
        .frame(width: frameW, height: frameH)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        .accessibilityLabel(accessibilityText)
    }

    private var auraHex: String {
        if prestigeSkinId == "skin.golden" { return "#fbbf24" }
        if prestigeSkinId == "skin.void" { return "#334155" }
        if prestigeSkinId == "skin.prism" { return "#c084fc" }
        return species.auraHex
    }

    private var accessibilityText: String {
        "\(species.displayName), \(stage.displayName)"
    }
}

struct CompanionStageIcon: View {
    var species: CompanionSpecies
    var stage: CompanionStage
    var size: CGFloat = 28

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: species.auraHex).opacity(0.22))
                .frame(width: size, height: size)
            Circle()
                .strokeBorder(Color(hex: species.auraHex).opacity(0.55), lineWidth: 1)
                .frame(width: size, height: size)
            stageGlyph
        }
        .overlay(alignment: .bottomTrailing) {
            Text("\(stage.rank + 1)")
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundColor(EmberColors.ink)
                .frame(width: 12, height: 12)
                .background(Circle().fill(Color(hex: species.auraHex)))
                .offset(x: 2, y: 2)
        }
        .accessibilityLabel("\(species.displayName) \(stage.shortLabel)")
    }

    @ViewBuilder
    private var stageGlyph: some View {
        if species == .robot {
            CompanionRobotImage(size: size * 0.72)
        } else {
            Image(systemName: species.iconName)
                .font(.system(size: size * 0.46, weight: .semibold))
                .foregroundColor(Color(hex: species.auraHex))
        }
    }
}

private struct CompanionAuraBlob: View {
    let hex: String
    let size: CGFloat
    let extraGlow: Bool
    let pulse: Bool

    var body: some View {
        let width: CGFloat = extraGlow ? size * 1.12 : size * 0.88
        let height: CGFloat = extraGlow ? size * 0.58 : size * 0.44
        let yOff: CGFloat = size * 0.26
        let startR: CGFloat = 10
        let endR: CGFloat = extraGlow ? size * 0.70 : size * 0.52
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        Color(hex: hex).opacity(extraGlow ? 0.80 : 0.50),
                        Color(hex: hex).opacity(extraGlow ? 0.30 : 0.14),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: startR,
                    endRadius: endR
                )
            )
            .frame(width: width, height: height)
            .offset(y: yOff)
            .blur(radius: extraGlow ? 26 : 16)
            .scaleEffect(pulse ? 1.08 : 0.92)
            .opacity(pulse ? 0.88 : 0.62)
    }
}

private struct CompanionLegendRing: View {
    let size: CGFloat
    let pulse: Bool

    var body: some View {
        let ring: CGFloat = size * 0.96
        Circle()
            .stroke(
                LinearGradient(
                    colors: [
                        EmberColors.gold.opacity(0.85),
                        EmberColors.ember.opacity(0.45),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 3
            )
            .frame(width: ring, height: ring)
            .blur(radius: 3)
            .opacity(pulse ? 0.90 : 0.55)
            .accessibilityHidden(true)
    }
}

private struct CompanionEffectLayer: View {
    let effectId: String
    let size: CGFloat
    let pulse: Bool

    var body: some View {
        switch effectId {
        case "fx.sparkles":
            CompanionSparkleDots(size: size, pulse: pulse, hex: "#ffe08a")
        case "fx.trail":
            CompanionSparkleDots(size: size, pulse: pulse, hex: "#ff7a3c")
        case "fx.leaves":
            CompanionSparkleDots(size: size, pulse: pulse, hex: "#4ade80")
        default:
            EmptyView()
        }
    }
}

private struct CompanionSparkleDots: View {
    let size: CGFloat
    let pulse: Bool
    let hex: String

    var body: some View {
        let leftX = -size * 0.28
        let leftY = -size * 0.20
        let rightX = size * 0.30
        let rightY = -size * 0.24
        ZStack {
            Circle()
                .fill(Color(hex: hex))
                .frame(width: 7, height: 7)
                .offset(x: leftX, y: leftY)
                .opacity(pulse ? 1 : 0.35)
            Circle()
                .fill(Color(hex: hex).opacity(0.85))
                .frame(width: 5, height: 5)
                .offset(x: rightX, y: rightY)
                .opacity(pulse ? 0.4 : 1)
        }
        .accessibilityHidden(true)
    }
}

/// Cute shared face so every species reads like the original Ember flame.
struct CompanionFace: View {
    var size: CGFloat
    var eyeY: CGFloat
    var mouthY: CGFloat
    var eyeSpread: CGFloat

    var body: some View {
        let eyeW: CGFloat = size * 0.072
        let eyeH: CGFloat = size * 0.078
        let pupil: CGFloat = size * 0.032
        let highlight: CGFloat = size * 0.018
        let mouthW: CGFloat = size * 0.16
        ZStack {
            CompanionEye(
                eyeW: eyeW,
                eyeH: eyeH,
                pupil: pupil,
                highlight: highlight
            )
            .offset(x: -eyeSpread, y: eyeY)
            CompanionEye(
                eyeW: eyeW,
                eyeH: eyeH,
                pupil: pupil,
                highlight: highlight
            )
            .offset(x: eyeSpread, y: eyeY)
            CompanionSmile(width: mouthW)
                .stroke(Color(hex: "#2a1208"), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
                .frame(width: mouthW, height: size * 0.06)
                .offset(y: mouthY)
        }
        .accessibilityHidden(true)
    }
}

private struct CompanionEye: View {
    let eyeW: CGFloat
    let eyeH: CGFloat
    let pupil: CGFloat
    let highlight: CGFloat

    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color(hex: "#fff8ee"))
                .frame(width: eyeW, height: eyeH)
            Circle()
                .fill(Color(hex: "#2a1208"))
                .frame(width: pupil, height: pupil)
                .offset(y: pupil * 0.18)
            Circle()
                .fill(Color.white)
                .frame(width: highlight, height: highlight)
                .offset(x: highlight * 0.6, y: -highlight * 0.7)
        }
    }
}

private struct CompanionSmile: Shape {
    var width: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY
        path.move(to: CGPoint(x: rect.minX, y: midY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: midY),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        return path
    }
}
