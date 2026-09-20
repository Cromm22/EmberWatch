import SwiftUI
import AVFoundation

/// Compact bottom toast for level-up celebrations. Keeps the ember icon, level copy, and fanfare.
struct LevelUpCelebrationView: View {
    let newLevel: Int
    let onDismiss: () -> Void
    
    @State private var scale: CGFloat = 0.85
    @State private var opacity: Double = 0
    @State private var emberRotation: Double = 0
    @State private var gradientPhase: Double = 0
    @State private var particlesVisible = false
    @State private var levelTextScale: CGFloat = 0.7
    @State private var levelTextOpacity: Double = 0
    @State private var isDismissing = false
    
    private let particles = (0..<8).map { index in
        ParticleData(
            angle: Double(index) * .pi * 2 / 8 + Double.random(in: -0.2...0.2),
            distance: CGFloat.random(in: 18...28),
            size: CGFloat.random(in: 4...7),
            delay: Double.random(in: 0...0.15)
        )
    }
    
    var body: some View {
        CelebrationToastAnchor(sitsOutsideTabView: true) {
            CelebrationToastCard(
                accent: EmberColors.ember,
                secondaryAccent: EmberColors.gold
            ) {
                HStack(spacing: 12) {
                    ZStack {
                        ForEach(particles.indices, id: \.self) { index in
                            ParticleView(particle: particles[index], visible: particlesVisible)
                        }
                        
                        EmberFlameOutlineShape(blaze: newLevel >= 5)
                            .stroke(
                                AngularGradient(
                                    gradient: Gradient(colors: [
                                        EmberColors.ink,
                                        EmberColors.gold,
                                        EmberColors.ink,
                                        EmberColors.emberAccent,
                                        EmberColors.ink
                                    ]),
                                    center: .center,
                                    startAngle: .degrees(gradientPhase),
                                    endAngle: .degrees(gradientPhase + 360)
                                ),
                                style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                            )
                            .frame(width: 32, height: 38)
                            .shadow(color: EmberColors.gold.opacity(0.5), radius: 6, y: 0)
                            .rotationEffect(.degrees(emberRotation))
                    }
                    .frame(width: 44, height: 44)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("LEVEL")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(EmberColors.ink.opacity(0.85))
                            .tracking(1.4)
                        
                        Text("\(newLevel)")
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundColor(EmberColors.ink)
                            .shadow(color: Color.black.opacity(0.2), radius: 2, y: 1)
                    }
                    .scaleEffect(levelTextScale)
                    .opacity(levelTextOpacity)
                    
                    Spacer(minLength: 0)
                }
            }
            .scaleEffect(scale)
            .opacity(opacity)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Level \(newLevel)")
            .onTapGesture {
                dismiss()
            }
        }
        .onAppear {
            playLevelUpSound()
            animateEntrance()
        }
    }
    
    private func animateEntrance() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) {
            opacity = 1.0
            scale = 1.0
        }
        
        withAnimation(.easeInOut(duration: 0.35).delay(0.12)) {
            emberRotation = 360
        }
        
        withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
            gradientPhase = 360
        }
        
        withAnimation(.spring(response: 0.45, dampingFraction: 0.65).delay(0.15)) {
            levelTextScale = 1.0
            levelTextOpacity = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeOut(duration: 0.8)) {
                particlesVisible = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            dismiss()
        }
    }
    
    private func dismiss() {
        guard !isDismissing else { return }
        isDismissing = true
        withAnimation(.easeInOut(duration: 0.28)) {
            opacity = 0
            scale = 0.96
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            onDismiss()
        }
    }
    
    private func playLevelUpSound() {
        let systemSoundID: SystemSoundID = 1057
        AudioServicesPlaySystemSound(systemSoundID)
    }
}

/// Particle data for splash effects
private struct ParticleData {
    let angle: Double
    let distance: CGFloat
    let size: CGFloat
    let delay: Double
}

/// Individual particle view for splash effect
private struct ParticleView: View {
    let particle: ParticleData
    let visible: Bool
    
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 0.3
    
    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [[EmberColors.ink, EmberColors.gold, EmberColors.emberAccent].randomElement()!],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: particle.size, height: particle.size)
            .scaleEffect(scale)
            .opacity(opacity)
            .offset(
                x: cos(particle.angle) * offset,
                y: sin(particle.angle) * offset
            )
            .onChange(of: visible) { _, newValue in
                if newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + particle.delay) {
                        withAnimation(.easeOut(duration: 0.7)) {
                            offset = particle.distance
                            opacity = 0
                            scale = 1.15
                        }
                    }
                }
            }
    }
}

#Preview {
    ZStack {
        EmberColors.dusk.ignoresSafeArea()
        LevelUpCelebrationView(newLevel: 15) {}
    }
}
