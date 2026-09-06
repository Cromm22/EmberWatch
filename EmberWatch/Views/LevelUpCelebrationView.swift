import SwiftUI
import AVFoundation

/// Full-screen level-up celebration overlay with ember icon, gradient animation, and particle effects.
struct LevelUpCelebrationView: View {
    let newLevel: Int
    let onDismiss: () -> Void
    
    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0
    @State private var emberRotation: Double = 0
    @State private var gradientPhase: Double = 0
    @State private var particlesVisible = false
    @State private var levelTextScale: CGFloat = 0.5
    @State private var levelTextOpacity: Double = 0
    
    private let particles = (0..<20).map { _ in
        ParticleData(
            angle: Double.random(in: 0...(2 * .pi)),
            distance: CGFloat.random(in: 80...150),
            size: CGFloat.random(in: 6...14),
            delay: Double.random(in: 0...0.3)
        )
    }
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .opacity(opacity)
            
            ZStack {
                // Particle splash effects
                ForEach(particles.indices, id: \.self) { index in
                    ParticleView(particle: particles[index], visible: particlesVisible)
                }
                
                // Ember icon outline with gradient animation
                ZStack {
                    EmberFlameOutlineShape(blaze: newLevel >= 5)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    EmberColors.ember,
                                    EmberColors.gold,
                                    Color(hex: "#ff0055"),
                                    EmberColors.emberAccent,
                                    EmberColors.ember
                                ]),
                                center: .center,
                                startAngle: .degrees(gradientPhase),
                                endAngle: .degrees(gradientPhase + 360)
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
                        )
                        .frame(width: 180, height: 216)
                        .shadow(color: EmberColors.ember.opacity(0.6), radius: 20, y: 0)
                        .shadow(color: EmberColors.gold.opacity(0.4), radius: 30, y: 0)
                    
                    // Level number centered inside ember
                    VStack(spacing: 4) {
                        Text("LEVEL")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(EmberColors.cream)
                            .tracking(2)
                        
                        Text("\(newLevel)")
                            .font(.system(size: 72, weight: .black, design: .rounded))
                            .foregroundColor(EmberColors.ember)
                            .shadow(color: Color.black.opacity(0.3), radius: 4, y: 2)
                            .shadow(color: EmberColors.ember.opacity(0.8), radius: 12, y: 0)
                    }
                    .scaleEffect(levelTextScale)
                    .opacity(levelTextOpacity)
                }
                .scaleEffect(scale)
                .rotationEffect(.degrees(emberRotation))
            }
            .opacity(opacity)
        }
        .onAppear {
            playLevelUpSound()
            animateEntrance()
        }
    }
    
    private func animateEntrance() {
        // Initial fade in and scale
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            opacity = 1.0
            scale = 1.0
        }
        
        // Ember icon gentle rotation
        withAnimation(.easeInOut(duration: 0.4).delay(0.2)) {
            emberRotation = 360
        }
        
        // Gradient rotation animation
        withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
            gradientPhase = 360
        }
        
        // Level text pop in
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.3)) {
            levelTextScale = 1.0
            levelTextOpacity = 1.0
        }
        
        // Particle burst
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 1.2)) {
                particlesVisible = true
            }
        }
        
        // Auto-dismiss after 2.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            dismiss()
        }
    }
    
    private func dismiss() {
        withAnimation(.easeInOut(duration: 0.4)) {
            opacity = 0
            scale = 1.1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            onDismiss()
        }
    }
    
    private func playLevelUpSound() {
        // Generate and play a simple celebratory tone
        let systemSoundID: SystemSoundID = 1057 // Fanfare sound
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
                    colors: [EmberColors.ember, EmberColors.gold, EmberColors.emberAccent].randomElement()!,
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
                        withAnimation(.easeOut(duration: 1.0)) {
                            offset = particle.distance
                            opacity = 0
                            scale = 1.2
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
