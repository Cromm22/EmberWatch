import SwiftUI

struct EmberTalkOverlay: View {
    @EnvironmentObject var emberTalkManager: EmberTalkManager
    @State private var iconScale: CGFloat = 0.5
    @State private var iconRotation: Double = -10
    @State private var glowOpacity: Double = 0
    @State private var glowPulse: CGFloat = 1.0
    @State private var particleOpacity: Double = 0
    @State private var particleScale: CGFloat = 0.5
    @State private var particleRotation: Double = 0
    @State private var innerGlowOpacity: Double = 0
    @State private var shimmerOffset: CGFloat = -200
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 20
    @State private var textScale: CGFloat = 0.9
    
    var body: some View {
        ZStack {
            if let phrase = emberTalkManager.currentPhrase {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        emberTalkManager.dismiss()
                    }
                
                VStack(spacing: 24) {
                    ZStack {
                        // Outer ring glow with pulse
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        categoryColor(phrase.category).opacity(0.5),
                                        categoryColor(phrase.category).opacity(0.2),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 100
                                )
                            )
                            .frame(width: 200, height: 200)
                            .opacity(glowOpacity)
                            .scaleEffect(glowPulse)
                        
                        // Inner concentrated glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        categoryColor(phrase.category).opacity(0.6),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 60
                                )
                            )
                            .frame(width: 120, height: 120)
                            .opacity(innerGlowOpacity)
                            .blur(radius: 8)
                        
                        // Large orbiting particles
                        ForEach(0..<12, id: \.self) { index in
                            let angle = Double(index) * .pi * 2 / 12
                            let radius: CGFloat = 95
                            let size: CGFloat = index % 3 == 0 ? 10 : (index % 2 == 0 ? 7 : 5)
                            
                            Circle()
                                .fill(categoryColor(phrase.category).opacity(0.8))
                                .frame(width: size, height: size)
                                .offset(
                                    x: cos(angle + particleRotation * .pi / 180) * radius,
                                    y: sin(angle + particleRotation * .pi / 180) * radius
                                )
                                .opacity(particleOpacity)
                                .scaleEffect(particleScale)
                                .blur(radius: 0.5)
                        }
                        
                        // Small inner sparkles
                        ForEach(0..<8, id: \.self) { index in
                            let angle = Double(index) * .pi * 2 / 8 + .pi / 8
                            let radius: CGFloat = 65
                            
                            Circle()
                                .fill(EmberColors.cream.opacity(0.9))
                                .frame(width: 4, height: 4)
                                .offset(
                                    x: cos(angle - particleRotation * .pi / 360) * radius,
                                    y: sin(angle - particleRotation * .pi / 360) * radius
                                )
                                .opacity(particleOpacity * 0.8)
                                .scaleEffect(particleScale * 1.2)
                        }
                        
                        // Icon container with shadow and glow
                        ZStack {
                            // Soft shadow layer
                            Circle()
                                .fill(EmberColors.cream)
                                .frame(width: 110, height: 110)
                                .opacity(0.3)
                                .blur(radius: 10)
                            
                            // Main icon background
                            Circle()
                                .fill(EmberColors.cream)
                                .frame(width: 100, height: 100)
                                .shadow(color: categoryColor(phrase.category).opacity(0.5), radius: 25, y: 5)
                                .shadow(color: .black.opacity(0.1), radius: 10, y: 3)
                            
                            // Shimmer overlay
                            if shouldShowShimmer(phrase.category) {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.clear,
                                                Color.white.opacity(0.3),
                                                Color.clear
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)
                                    .mask(Circle())
                                    .offset(x: shimmerOffset)
                            }
                            
                            // Category icon
                            Image(systemName: categoryIcon(phrase.category))
                                .font(.system(size: 48, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            categoryColor(phrase.category),
                                            categoryColor(phrase.category).opacity(0.8)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .rotationEffect(.degrees(iconRotation))
                                .shadow(color: categoryColor(phrase.category).opacity(0.3), radius: 2, y: 1)
                        }
                        .scaleEffect(iconScale)
                    }
                    .frame(height: 220)
                    
                    // Text container with premium styling
                    Text(phrase.text)
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(EmberColors.cream)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 18)
                        .background(
                            ZStack {
                                // Outer glow
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(categoryColor(phrase.category))
                                    .blur(radius: 12)
                                    .opacity(0.6)
                                    .padding(-4)
                                
                                // Main background
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(categoryColor(phrase.category))
                                    .shadow(color: categoryColor(phrase.category).opacity(0.6), radius: 20, y: 10)
                                    .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                            }
                        )
                        .opacity(textOpacity)
                        .offset(y: textOffset)
                        .scaleEffect(textScale)
                }
                .transition(.scale.combined(with: .opacity))
                .onAppear {
                    animateIn()
                }
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: emberTalkManager.currentPhrase != nil)
    }
    
    private func animateIn() {
        // Icon entrance - smooth spring with overshoot
        withAnimation(.spring(response: 0.7, dampingFraction: 0.65).delay(0.1)) {
            iconScale = 1.12
            iconRotation = 0
        }
        
        // Settle icon to final size
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                iconScale = 1.0
            }
        }
        
        // Outer glow with elegant fade and pulse
        withAnimation(.easeOut(duration: 1.0).delay(0.08)) {
            glowOpacity = 1.0
        }
        
        // Continuous gentle pulse
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(0.5)) {
            glowPulse = 1.15
        }
        
        // Inner concentrated glow - faster, brighter
        withAnimation(.easeOut(duration: 0.7).delay(0.15)) {
            innerGlowOpacity = 1.0
        }
        
        // Particles - staggered entrance with rotation
        withAnimation(.easeOut(duration: 0.9).delay(0.2)) {
            particleOpacity = 1.0
            particleScale = 1.0
        }
        
        // Slow continuous particle rotation
        withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false).delay(0.3)) {
            particleRotation = 360
        }
        
        // Shimmer sweep
        withAnimation(.easeInOut(duration: 1.2).delay(0.4)) {
            shimmerOffset = 200
        }
        
        // Text entrance - smooth scale and fade
        withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.2)) {
            textOpacity = 1.0
            textOffset = 0
            textScale = 1.0
        }
    }
    
    private func shouldShowShimmer(_ category: EmberTalkCategory) -> Bool {
        // Premium shimmer for water, food, and workout
        switch category {
        case .water, .food, .workout:
            return true
        case .greeting:
            return false
        }
    }
    
    private func categoryIcon(_ category: EmberTalkCategory) -> String {
        switch category {
        case .greeting:
            return "sun.max.fill"
        case .water:
            return "drop.fill"
        case .food:
            return "leaf.fill"
        case .workout:
            return "bolt.fill"
        }
    }
    
    private func categoryColor(_ category: EmberTalkCategory) -> Color {
        switch category {
        case .greeting:
            return EmberColors.ember
        case .water:
            return Color(red: 0.2, green: 0.7, blue: 0.85)  // Refined teal-cyan
        case .food:
            return Color(red: 0.3, green: 0.75, blue: 0.5)  // Premium emerald-green
        case .workout:
            return Color(red: 0.95, green: 0.65, blue: 0.2)  // Rich amber-gold
        }
    }
}
