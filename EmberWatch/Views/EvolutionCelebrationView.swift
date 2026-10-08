import SwiftUI

/// Bottom toast when a companion crosses an evolution stage.
struct EvolutionCelebrationView: View {
    let species: CompanionSpecies
    let stage: CompanionStage
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.88
    @State private var opacity: Double = 0
    @State private var isDismissing = false

    var body: some View {
        CelebrationToastAnchor(sitsOutsideTabView: true) {
            CelebrationToastCard(
                accent: EmberColors.gold,
                secondaryAccent: EmberColors.ember
            ) {
                HStack(spacing: 12) {
                    CompanionAvatarView(
                        species: species,
                        stage: stage,
                        tier: ProgressionTier.current(forLevel: stage.unlockLevel),
                        size: 52
                    )
                    .frame(width: 56, height: 62)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("EVOLUTION")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(EmberColors.ink.opacity(0.85))
                            .tracking(1.2)
                        Text(stage.displayName)
                            .font(.headline.weight(.bold))
                            .foregroundColor(EmberColors.ink)
                        Text(species.displayName)
                            .font(.caption)
                            .foregroundColor(EmberColors.ink.opacity(0.8))
                    }

                    Spacer(minLength: 0)
                }
            }
            .scaleEffect(scale)
            .opacity(opacity)
            .accessibilityLabel("\(species.displayName) evolved to \(stage.displayName)")
            .onTapGesture {
                dismiss()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.80)) {
                opacity = 1
                scale = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                dismiss()
            }
        }
    }

    private func dismiss() {
        guard !isDismissing else { return }
        isDismissing = true
        withAnimation(.easeInOut(duration: 0.24)) {
            opacity = 0
            scale = 0.96
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            onDismiss()
        }
    }
}
