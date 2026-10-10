import SwiftUI

/// Try-before-you-buy sheet. Renders a mini Home hero from a value snapshot
/// so opening / dismissing never writes the user's saved loadout.
struct ShopItemPreviewSheet: View {
    let subject: ShopPreviewSubject
    let look: HomeHeroLook
    let isOwned: Bool
    let isEquipped: Bool
    let coins: Int
    let crystals: Int
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ShopPreviewGrabber()
            ScrollView {
                VStack(spacing: 18) {
                    ShopPreviewHeroCard(look: look)
                    if let details = ShopPreviewDetails.resolve(subject) {
                        ShopPreviewMetaBlock(details: details)
                        ShopPreviewActionRow(
                            details: details,
                            isOwned: isOwned,
                            isEquipped: isEquipped,
                            canAfford: canAfford(details),
                            onConfirm: onConfirm,
                            onCancel: onCancel
                        )
                    } else {
                        Button("Cancel", action: onCancel)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(GalleryPalette.subtitle)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
        }
        .background(GalleryPalette.sky.ignoresSafeArea())
        .accessibilityLabel(accessibilityTitle)
    }

    private func canAfford(_ details: ShopPreviewDetails) -> Bool {
        if details.price <= 0 { return true }
        switch details.currency {
        case .coins:
            return coins >= details.price
        case .crystals:
            return crystals >= details.price
        }
    }

    private var accessibilityTitle: String {
        if let details = ShopPreviewDetails.resolve(subject) {
            return "Preview \(details.name)"
        }
        return "Item preview"
    }
}

private struct ShopPreviewGrabber: View {
    var body: some View {
        Capsule()
            .fill(Color.black.opacity(0.12))
            .frame(width: 36, height: 5)
            .padding(.top, 10)
            .padding(.bottom, 6)
            .accessibilityHidden(true)
    }
}

/// Mini Home hero: same `PlayerPortraitView` + Home XP bar + card fill.
private struct ShopPreviewHeroCard: View {
    let look: HomeHeroLook

    var body: some View {
        VStack(spacing: 10) {
            ShopPreviewPortrait(look: look)
            ShopPreviewIdentityRow(look: look)
            HomeXPProgressBar(
                level: look.level,
                progressFraction: look.progressFraction
            )
            .padding(.horizontal, 12)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .background(ShopPreviewCardFill(look: look))
        .overlay(ShopPreviewCardStroke(themeId: look.themeId))
    }
}

private struct ShopPreviewCardFill: View {
    let look: HomeHeroLook

    var body: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(ShopLookTokens.cardFill(
                backgroundId: look.backgroundId,
                themeId: look.themeId
            ))
    }
}

private struct ShopPreviewCardStroke: View {
    let themeId: String

    var body: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .strokeBorder(
                ShopLookTokens.themeAccent(for: themeId).opacity(0.42),
                lineWidth: 1.5
            )
    }
}

private struct ShopPreviewPortrait: View {
    let look: HomeHeroLook

    var body: some View {
        PlayerPortraitView(
            heroImageName: look.heroImageName,
            heroAccessibilityName: look.heroAccessibilityName,
            size: portraitSize,
            extraGlow: look.extraGlow,
            hasChosenCompanion: look.hasChosenCompanion,
            species: look.species,
            stage: look.stage,
            tier: look.tier,
            equipped: look.equipped,
            effectId: look.effectId,
            prestigeSkinId: look.prestigeSkinId,
            level: look.level,
            style: look.style
        )
        .frame(maxWidth: .infinity)
    }

    private var portraitSize: CGFloat {
        if look.heroImageName != nil { return 64 }
        return 118
    }
}

private struct ShopPreviewIdentityRow: View {
    let look: HomeHeroLook

    var body: some View {
        HStack(spacing: 8) {
            if let icon = ShopLookTokens.emoteIconName(for: look.emoteId) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(ShopLookTokens.themeAccent(for: look.themeId))
                    .accessibilityLabel("Emote")
            }
            Text(look.displayName)
                .font(.headline.weight(.bold))
                .foregroundColor(identityColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, 12)
    }

    private var identityColor: Color {
        ShopLookTokens.identityColor(
            nameplateId: look.nameplateId,
            backgroundId: look.backgroundId,
            themeId: look.themeId
        )
    }
}

private struct ShopPreviewMetaBlock: View {
    let details: ShopPreviewDetails

    var body: some View {
        VStack(spacing: 6) {
            Text(details.name)
                .font(.title3.weight(.bold))
                .foregroundColor(GalleryPalette.title)
                .multilineTextAlignment(.center)
            Text(details.rarity.displayName)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(details.rarity.color)
            Text(details.detail)
                .font(.caption)
                .foregroundColor(GalleryPalette.subtitle)
                .multilineTextAlignment(.center)
            ShopPreviewPriceLine(details: details)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ShopPreviewPriceLine: View {
    let details: ShopPreviewDetails

    var body: some View {
        if details.price <= 0 {
            Text("Free")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(GalleryPalette.subtitle)
        } else {
            Text("\(details.price) \(details.currency.displayName)")
                .font(.subheadline.weight(.bold))
                .foregroundColor(GalleryPalette.price)
                .monospacedDigit()
        }
    }
}

private struct ShopPreviewActionRow: View {
    let details: ShopPreviewDetails
    let isOwned: Bool
    let isEquipped: Bool
    let canAfford: Bool
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            ShopPreviewPrimaryButton(
                title: primaryTitle,
                isEnabled: primaryEnabled,
                action: onConfirm
            )
            Button("Cancel", action: onCancel)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(GalleryPalette.subtitle)
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
                .accessibilityLabel("Cancel")
        }
    }

    private var primaryEnabled: Bool {
        if isOwned { return !isEquipped }
        return canAfford
    }

    private var primaryTitle: String {
        if isOwned {
            return isEquipped ? "Equipped" : "Equip"
        }
        if !canAfford {
            return "Not enough \(details.currency.displayName)"
        }
        if details.price <= 0 {
            return "Claim"
        }
        return "Buy for \(details.price) \(details.currency.displayName)"
    }
}

private struct ShopPreviewPrimaryButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(ShopPreviewPrimaryFill(isEnabled: isEnabled))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(title)
    }
}

private struct ShopPreviewPrimaryFill: View {
    let isEnabled: Bool

    var body: some View {
        Capsule()
            .fill(isEnabled ? EmberColors.ember : EmberColors.muted)
    }
}
