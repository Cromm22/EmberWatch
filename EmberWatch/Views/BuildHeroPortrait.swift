import SwiftUI
import UIKit

/// Rounded build portrait. Uses aspect-fit in a frame that matches the
/// image's ratio so the full figure and companion stay in view.
struct BuildHeroPortrait: View {
    let imageName: String
    var width: CGFloat
    var cornerRadius: CGFloat = 16
    var accessibilityName: String

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: width, height: portraitHeight)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .accessibilityLabel(accessibilityName)
    }

    private var portraitHeight: CGFloat {
        width / max(imageAspectRatio, 0.01)
    }

    private var imageAspectRatio: CGFloat {
        let fallback: CGFloat = 0.41
        guard let image = UIImage(named: imageName) else { return fallback }
        let size = image.size
        guard size.height > 0 else { return fallback }
        return size.width / size.height
    }
}

/// Main identity portrait: build hero art when present, otherwise companion or Ember flame.
struct PlayerPortraitView: View {
    var heroImageName: String?
    var heroAccessibilityName: String
    var size: CGFloat
    var heroCornerRadius: CGFloat = 16
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
                cornerRadius: heroCornerRadius,
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
