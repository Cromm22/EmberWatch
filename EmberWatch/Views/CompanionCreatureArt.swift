import SwiftUI

/// Routes a species to a dedicated creature view. Each creature is a handful
/// of shapes so the type checker stays happy.
struct CompanionCreatureLayer: View {
    let species: CompanionSpecies
    let stage: CompanionStage
    let size: CGFloat
    let prestigeSkinId: String?

    var body: some View {
        let scaled = size * stage.bodyScale
        Group {
            switch species {
            case .babyDragon:
                DragonCreature(size: scaled, stage: stage, palette: palette)
            case .robot:
                CompanionRobotImage(size: scaled)
            case .wolf:
                WolfCreature(size: scaled, stage: stage, palette: palette)
            case .slime:
                SlimeCreature(size: scaled, stage: stage, palette: palette)
            case .phoenix:
                PhoenixCreature(size: scaled, stage: stage, palette: palette)
            case .cyberCat:
                CyberCatCreature(size: scaled, stage: stage, palette: palette)
            }
        }
    }

    private var palette: CompanionPalette {
        CompanionPalette.make(species: species, prestigeSkinId: prestigeSkinId)
    }
}

struct CompanionPalette: Sendable {
    let body: String
    let belly: String
    let accent: String
    let aura: String

    static func make(species: CompanionSpecies, prestigeSkinId: String?) -> CompanionPalette {
        switch prestigeSkinId {
        case "skin.golden":
            return CompanionPalette(body: "#fbbf24", belly: "#fde68a", accent: "#b45309", aura: "#f59e0b")
        case "skin.void":
            return CompanionPalette(body: "#475569", belly: "#cbd5e1", accent: "#0f172a", aura: "#334155")
        case "skin.prism":
            return CompanionPalette(body: "#c084fc", belly: "#f5d0fe", accent: "#22d3ee", aura: "#a855f7")
        default:
            return CompanionPalette(
                body: species.bodyHex,
                belly: species.bellyHex,
                accent: species.accentHex,
                aura: species.auraHex
            )
        }
    }
}

// MARK: - Dragon

private struct DragonCreature: View {
    let size: CGFloat
    let stage: CompanionStage
    let palette: CompanionPalette

    var body: some View {
        ZStack {
            if stage >= .adult {
                DragonWing(size: size, hex: palette.accent, isLeft: true)
                DragonWing(size: size, hex: palette.accent, isLeft: false)
            }
            if stage >= .juvenile {
                DragonHorn(size: size, hex: palette.accent, isLeft: true)
                DragonHorn(size: size, hex: palette.accent, isLeft: false)
            }
            CompanionBodyBlob(size: size, bodyHex: palette.body, bellyHex: palette.belly)
            CompanionFace(
                size: size,
                eyeY: -size * 0.04,
                mouthY: size * 0.10,
                eyeSpread: size * 0.10
            )
            if stage >= .elite {
                Image(systemName: "flame.fill")
                    .font(.system(size: size * 0.16, weight: .bold))
                    .foregroundColor(Color(hex: palette.accent))
                    .offset(y: -size * 0.42)
            }
        }
    }
}

private struct DragonWing: View {
    let size: CGFloat
    let hex: String
    let isLeft: Bool

    var body: some View {
        let w = size * 0.34
        let h = size * 0.28
        let xOff = isLeft ? -size * 0.30 : size * 0.30
        Ellipse()
            .fill(Color(hex: hex).opacity(0.85))
            .frame(width: w, height: h)
            .rotationEffect(.degrees(isLeft ? -28 : 28))
            .offset(x: xOff, y: -size * 0.02)
    }
}

private struct DragonHorn: View {
    let size: CGFloat
    let hex: String
    let isLeft: Bool

    var body: some View {
        let w = size * 0.08
        let h = size * 0.18
        let xOff = isLeft ? -size * 0.16 : size * 0.16
        Capsule()
            .fill(Color(hex: hex))
            .frame(width: w, height: h)
            .rotationEffect(.degrees(isLeft ? -22 : 22))
            .offset(x: xOff, y: -size * 0.30)
    }
}

// MARK: - Robot

struct CompanionRobotImage: View {
    var size: CGFloat

    var body: some View {
        Image("CompanionRobot")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

// MARK: - Wolf

private struct WolfCreature: View {
    let size: CGFloat
    let stage: CompanionStage
    let palette: CompanionPalette

    var body: some View {
        ZStack {
            if stage >= .adult {
                WolfTail(size: size, hex: palette.accent)
            }
            WolfEar(size: size, hex: palette.accent, isLeft: true)
            WolfEar(size: size, hex: palette.accent, isLeft: false)
            CompanionBodyBlob(size: size, bodyHex: palette.body, bellyHex: palette.belly)
            CompanionFace(
                size: size,
                eyeY: -size * 0.02,
                mouthY: size * 0.12,
                eyeSpread: size * 0.10
            )
            if stage >= .juvenile {
                Capsule()
                    .fill(Color(hex: palette.accent))
                    .frame(width: size * 0.08, height: size * 0.06)
                    .offset(y: size * 0.08)
            }
            if stage >= .elite {
                Image(systemName: "moon.fill")
                    .font(.system(size: size * 0.14, weight: .bold))
                    .foregroundColor(Color(hex: palette.aura))
                    .offset(y: -size * 0.44)
            }
        }
    }
}

private struct WolfEar: View {
    let size: CGFloat
    let hex: String
    let isLeft: Bool

    var body: some View {
        let xOff = isLeft ? -size * 0.16 : size * 0.16
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(Color(hex: hex))
            .frame(width: size * 0.14, height: size * 0.20)
            .rotationEffect(.degrees(isLeft ? -18 : 18))
            .offset(x: xOff, y: -size * 0.30)
    }
}

private struct WolfTail: View {
    let size: CGFloat
    let hex: String

    var body: some View {
        Capsule()
            .fill(Color(hex: hex).opacity(0.85))
            .frame(width: size * 0.16, height: size * 0.36)
            .rotationEffect(.degrees(38))
            .offset(x: size * 0.30, y: size * 0.16)
    }
}

// MARK: - Slime

private struct SlimeCreature: View {
    let size: CGFloat
    let stage: CompanionStage
    let palette: CompanionPalette

    var body: some View {
        ZStack {
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: palette.belly),
                            Color(hex: palette.body),
                            Color(hex: palette.accent).opacity(0.85)
                        ],
                        center: .top,
                        startRadius: 4,
                        endRadius: size * 0.42
                    )
                )
                .frame(width: size * 0.64, height: size * 0.52)
                .offset(y: size * 0.04)
            CompanionFace(
                size: size,
                eyeY: -size * 0.02,
                mouthY: size * 0.12,
                eyeSpread: size * 0.11
            )
            if stage >= .juvenile {
                Circle()
                    .fill(Color.white.opacity(0.55))
                    .frame(width: size * 0.12, height: size * 0.12)
                    .offset(x: -size * 0.14, y: -size * 0.10)
            }
            if stage >= .adult {
                Image(systemName: "leaf.fill")
                    .font(.system(size: size * 0.14, weight: .bold))
                    .foregroundColor(Color(hex: palette.accent))
                    .offset(x: size * 0.16, y: -size * 0.22)
            }
            if stage >= .elite {
                Image(systemName: "crown.fill")
                    .font(.system(size: size * 0.14, weight: .bold))
                    .foregroundColor(EmberColors.gold)
                    .offset(y: -size * 0.30)
            }
        }
    }
}

// MARK: - Phoenix

private struct PhoenixCreature: View {
    let size: CGFloat
    let stage: CompanionStage
    let palette: CompanionPalette

    var body: some View {
        ZStack {
            if stage >= .juvenile {
                PhoenixWing(size: size, hex: palette.accent, isLeft: true)
                PhoenixWing(size: size, hex: palette.accent, isLeft: false)
            }
            CompanionBodyBlob(size: size, bodyHex: palette.body, bellyHex: palette.belly)
            CompanionFace(
                size: size,
                eyeY: -size * 0.04,
                mouthY: size * 0.10,
                eyeSpread: size * 0.10
            )
            if stage >= .adult {
                Image(systemName: "flame.fill")
                    .font(.system(size: size * 0.18, weight: .bold))
                    .foregroundColor(Color(hex: palette.accent))
                    .offset(y: -size * 0.38)
            }
            if stage >= .elite {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: size * 0.16, weight: .bold))
                    .foregroundColor(EmberColors.gold)
                    .offset(y: -size * 0.52)
            }
        }
    }
}

private struct PhoenixWing: View {
    let size: CGFloat
    let hex: String
    let isLeft: Bool

    var body: some View {
        let w = size * 0.40
        let h = size * 0.22
        let xOff = isLeft ? -size * 0.28 : size * 0.28
        Capsule()
            .fill(
                LinearGradient(
                    colors: [Color(hex: hex), Color(hex: "#ff7a3c")],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: w, height: h)
            .rotationEffect(.degrees(isLeft ? -40 : 40))
            .offset(x: xOff, y: -size * 0.06)
    }
}

// MARK: - Cyber Cat

private struct CyberCatCreature: View {
    let size: CGFloat
    let stage: CompanionStage
    let palette: CompanionPalette

    var body: some View {
        ZStack {
            CyberEar(size: size, hex: palette.accent, isLeft: true)
            CyberEar(size: size, hex: palette.accent, isLeft: false)
            CompanionBodyBlob(size: size, bodyHex: palette.body, bellyHex: palette.belly)
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color(hex: palette.accent).opacity(0.55))
                .frame(width: size * 0.36, height: size * 0.06)
                .offset(y: -size * 0.05)
            CompanionFace(
                size: size,
                eyeY: -size * 0.03,
                mouthY: size * 0.11,
                eyeSpread: size * 0.10
            )
            if stage >= .juvenile {
                Capsule()
                    .fill(Color(hex: palette.accent))
                    .frame(width: size * 0.18, height: size * 0.04)
                    .offset(y: size * 0.18)
            }
            if stage >= .adult {
                Image(systemName: "bolt.fill")
                    .font(.system(size: size * 0.12, weight: .bold))
                    .foregroundColor(Color(hex: palette.accent))
                    .offset(x: size * 0.22, y: -size * 0.22)
            }
            if stage >= .elite {
                Image(systemName: "cpu.fill")
                    .font(.system(size: size * 0.12, weight: .bold))
                    .foregroundColor(Color(hex: palette.aura))
                    .offset(y: -size * 0.42)
            }
        }
    }
}

private struct CyberEar: View {
    let size: CGFloat
    let hex: String
    let isLeft: Bool

    var body: some View {
        let xOff = isLeft ? -size * 0.16 : size * 0.16
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(Color(hex: hex))
            .frame(width: size * 0.12, height: size * 0.18)
            .rotationEffect(.degrees(isLeft ? -16 : 16))
            .offset(x: xOff, y: -size * 0.30)
    }
}

// MARK: - Shared body

private struct CompanionBodyBlob: View {
    let size: CGFloat
    let bodyHex: String
    let bellyHex: String

    var body: some View {
        let outerW = size * 0.60
        let outerH = size * 0.66
        let innerW = size * 0.36
        let innerH = size * 0.34
        ZStack {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: bellyHex),
                            Color(hex: bodyHex)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: outerW, height: outerH)
                .shadow(color: Color(hex: bodyHex).opacity(0.35), radius: 12, y: 6)
            Ellipse()
                .fill(Color(hex: bellyHex).opacity(0.85))
                .frame(width: innerW, height: innerH)
                .offset(y: size * 0.08)
        }
    }
}
