import SwiftUI

/// Speech bubble that appears near the Ember avatar with auto-dismiss animation.
struct EmberSpeechBubble: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundColor(EmberColors.ink)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    // Main bubble
                    Capsule()
                        .fill(EmberColors.cream)
                        .shadow(color: EmberColors.ember.opacity(0.25), radius: 8, y: 2)
                    
                    // Subtle ember glow
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    EmberColors.ember.opacity(0.15),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
            )
            .transition(.scale(scale: 0.8).combined(with: .opacity))
    }
}

#Preview {
    ZStack {
        EmberColors.dusk.ignoresSafeArea()
        EmberSpeechBubble(text: "Let's get after it")
    }
}
