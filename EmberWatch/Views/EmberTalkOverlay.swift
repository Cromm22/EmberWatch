import SwiftUI

struct EmberTalkOverlay: View {
    @EnvironmentObject var emberTalkManager: EmberTalkManager
    @State private var iconScale: CGFloat = 0.7
    @State private var glowOpacity: Double = 0
    @State private var textOpacity: Double = 0
    
    var body: some View {
        Group {
            if let phrase = emberTalkManager.currentPhrase {
                CelebrationToastAnchor(sitsOutsideTabView: true) {
                    CelebrationToastCard(accent: categoryColor(phrase.category)) {
                        HStack(alignment: .center, spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(categoryColor(phrase.category).opacity(0.45))
                                    .frame(width: 44, height: 44)
                                    .blur(radius: 8)
                                    .opacity(glowOpacity)
                                
                                Circle()
                                    .fill(EmberColors.ink.opacity(0.18))
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: categoryIcon(phrase.category))
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(EmberColors.ink)
                                    .shadow(color: categoryColor(phrase.category).opacity(0.35), radius: 2, y: 1)
                            }
                            .scaleEffect(iconScale)
                            
                            Text(phrase.text)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(EmberColors.ink)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .opacity(textOpacity)
                            
                            Spacer(minLength: 0)
                        }
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .accessibilityElement(children: .combine)
                .accessibilityLabel(phrase.text)
                .onTapGesture {
                    emberTalkManager.dismiss()
                }
                .onAppear {
                    animateIn()
                }
                .onChange(of: phrase.text) { _, _ in
                    animateIn()
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.82), value: emberTalkManager.currentPhrase != nil)
    }
    
    private func animateIn() {
        iconScale = 0.7
        glowOpacity = 0
        textOpacity = 0
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            iconScale = 1.0
            glowOpacity = 1.0
            textOpacity = 1.0
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
            return Color(red: 0.2, green: 0.7, blue: 0.85)
        case .food:
            return Color(red: 0.3, green: 0.75, blue: 0.5)
        case .workout:
            return Color(red: 0.95, green: 0.65, blue: 0.2)
        }
    }
}
