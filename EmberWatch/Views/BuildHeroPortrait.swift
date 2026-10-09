import SwiftUI

/// Rounded build portrait. Crops with aspect-fill so the character stays framed.
struct BuildHeroPortrait: View {
    let imageName: String
    var width: CGFloat
    var height: CGFloat
    var cornerRadius: CGFloat = 16
    var alignment: Alignment = .bottom
    var accessibilityName: String

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFill()
            .frame(width: width, height: height, alignment: alignment)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .accessibilityLabel(accessibilityName)
    }
}

/// Main identity portrait: build hero art when present, otherwise companion or Ember flame.
struct PlayerPortraitView: View {
    var heroImageName: String?
    var heroAccessibilityName: String
    var size: CGFloat
    var heroHeight: CGFloat? = nil
    var heroCornerRadius: CGFloat = 16
    var heroAlignment: Alignment = .bottom
    var extraGlow: Bool = false
    var hasChosenCompanion: Bool
    var species: CompanionSpecies
    var stage: CompanionStage
    var tier: ProgressionTier
    var equipped: [EquipmentSlot: EquipmentItem] = [:]
    var effectId: String? = nil
    var prestigeSkinId: String? = nil
    var level: Int
    var style: AvatarStyle

    var body: some View {
        portraitBody
    }

    @ViewBuilder
    private var portraitBody: some View {
        if let heroImageName {
            BuildHeroPortrait(
                imageName: heroImageName,
                width: size,
                height: heroHeight ?? size * 1.55,
                cornerRadius: heroCornerRadius,
                alignment: heroAlignment,
                accessibilityName: heroAccessibilityName
            )
        } else if hasChosenCompanion {
            CompanionAvatarView(
                species: species,
                stage: stage,
                tier: tier,
                size: size,
                extraGlow: extraGlow,
                equipped: equipped,
                effectId: effectId,
                prestigeSkinId: prestigeSkinId
            )
        } else {
            EmberFlameAvatar(
                level: level,
                size: size,
                style: style,
                extraGlow: extraGlow
            )
        }
    }
}
