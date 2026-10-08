import SwiftUI

/// Level-tier look plus equipped slot icons. Cosmetic only.
struct CompanionGearOverlay: View {
    let tier: ProgressionTier
    let equipped: [EquipmentSlot: EquipmentItem]
    let size: CGFloat

    @State private var shimmer = false

    var body: some View {
        ZStack {
            if tier != .basic {
                CompanionTierShoulders(tier: tier, size: size)
            }
            if tier.showsPrestigePlates {
                CompanionPrestigePlates(size: size)
            }
            if tier.showsShimmer {
                CompanionShimmerBand(size: size, active: shimmer)
            }
            if tier.showsLegendAura {
                CompanionLegendTitleMark(size: size)
            }
            ForEach(EquipmentSlot.allCases) { slot in
                if let item = equipped[slot] {
                    CompanionEquippedGlyph(item: item, size: size)
                }
            }
        }
        .onAppear {
            guard tier.showsShimmer else { return }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                shimmer = true
            }
        }
        .accessibilityHidden(true)
    }
}

private struct CompanionTierShoulders: View {
    let tier: ProgressionTier
    let size: CGFloat

    var body: some View {
        let hex = shoulderHex
        let w = size * 0.16
        let h = size * 0.08
        let y = size * 0.08
        ZStack {
            Capsule()
                .fill(Color(hex: hex).opacity(0.85))
                .frame(width: w, height: h)
                .offset(x: -size * 0.22, y: y)
            Capsule()
                .fill(Color(hex: hex).opacity(0.85))
                .frame(width: w, height: h)
                .offset(x: size * 0.22, y: y)
        }
    }

    private var shoulderHex: String {
        switch tier {
        case .basic: return "#9CA3AF"
        case .better: return "#64748B"
        case .epic: return "#A855F7"
        case .animated: return "#38BDF8"
        case .prestige: return "#F59E0B"
        case .legend: return "#F43F5E"
        }
    }
}

private struct CompanionPrestigePlates: View {
    let size: CGFloat

    var body: some View {
        let plateW = size * 0.18
        let plateH = size * 0.10
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(EmberColors.gold.opacity(0.55))
                .frame(width: plateW, height: plateH)
                .offset(x: -size * 0.20, y: size * 0.18)
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(EmberColors.gold.opacity(0.55))
                .frame(width: plateW, height: plateH)
                .offset(x: size * 0.20, y: size * 0.18)
        }
    }
}

private struct CompanionShimmerBand: View {
    let size: CGFloat
    let active: Bool

    var body: some View {
        let bandW = size * 0.55
        let bandH = size * 0.10
        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.0),
                        Color.white.opacity(0.55),
                        Color.white.opacity(0.0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: bandW, height: bandH)
            .offset(y: size * 0.02)
            .opacity(active ? 0.85 : 0.25)
    }
}

private struct CompanionLegendTitleMark: View {
    let size: CGFloat

    var body: some View {
        Image(systemName: "seal.fill")
            .font(.system(size: size * 0.12, weight: .bold))
            .foregroundColor(EmberColors.gold)
            .offset(x: size * 0.28, y: size * 0.28)
    }
}

private struct CompanionEquippedGlyph: View {
    let item: EquipmentItem
    let size: CGFloat

    var body: some View {
        let glyph = size * 0.12
        Image(systemName: safeIcon)
            .font(.system(size: glyph, weight: .bold))
            .foregroundColor(item.rarity.color)
            .offset(x: offsetX, y: offsetY)
            .shadow(color: item.rarity.color.opacity(0.35), radius: 3, y: 1)
    }

    private var safeIcon: String {
        item.iconName
    }

    private var offsetX: CGFloat {
        switch item.slot {
        case .head: return 0
        case .chest: return 0
        case .hands: return -size * 0.32
        case .legs: return size * 0.26
        case .feet: return 0
        case .accessory: return size * 0.30
        }
    }

    private var offsetY: CGFloat {
        switch item.slot {
        case .head: return -size * 0.36
        case .chest: return size * 0.02
        case .hands: return size * 0.10
        case .legs: return size * 0.22
        case .feet: return size * 0.34
        case .accessory: return -size * 0.18
        }
    }
}
