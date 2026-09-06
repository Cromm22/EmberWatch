import SwiftUI

struct EmberTalkOverlay: View {
    @EnvironmentObject var emberTalkManager: EmberTalkManager
    @State private var iconScale: CGFloat = 0.5
    @State private var iconRotation: Double = -10
    @State private var glowOpacity: Double = 0
    @State private var particleOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 20
    
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
                        ForEach(0..<8, id: \.self) { index in
                            Circle()
                                .fill(EmberColors.ember.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .offset(
                                    x: cos(Double(index) * .pi / 4) * 80,
                                    y: sin(Double(index) * .pi / 4) * 80
                                )
                                .opacity(particleOpacity)
                                .scaleEffect(particleOpacity)
                        }
                        
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        categoryColor(phrase.category).opacity(0.4),
                                        categoryColor(phrase.category).opacity(0.1),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)
                            .opacity(glowOpacity)
                            .scaleEffect(glowOpacity * 1.2)
                        
                        ZStack {
                            Circle()
                                .fill(EmberColors.cream)
                                .frame(width: 100, height: 100)
                                .shadow(color: categoryColor(phrase.category).opacity(0.4), radius: 20)
                            
                            Image(systemName: categoryIcon(phrase.category))
                                .font(.system(size: 45, weight: .semibold))
                                .foregroundColor(categoryColor(phrase.category))
                                .rotationEffect(.degrees(iconRotation))
                        }
                        .scaleEffect(iconScale)
                    }
                    .frame(height: 200)
                    
                    Text(phrase.text)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(EmberColors.cream)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(categoryColor(phrase.category))
                                .shadow(color: categoryColor(phrase.category).opacity(0.5), radius: 16, y: 8)
                        )
                        .opacity(textOpacity)
                        .offset(y: textOffset)
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
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1)) {
            iconScale = 1.15
            iconRotation = 0
        }
        
        withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
            glowOpacity = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
            particleOpacity = 1.0
        }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.15)) {
            textOpacity = 1.0
            textOffset = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                iconScale = 1.0
            }
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
            return Color.cyan
        case .food:
            return Color.green
        case .workout:
            return EmberColors.gold
        }
    }
}
