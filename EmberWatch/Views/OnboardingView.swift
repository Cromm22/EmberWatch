import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var avatarManager: AvatarManager
    @EnvironmentObject var levelManager: LevelManager
    
    @State private var step = 0
    @State private var nameDraft = ""
    
    private let totalSteps = 5 // avatar, name, xp1, xp2, xp3
    
    var body: some View {
        ZStack {
            EmberColors.dusk.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress
                HStack(spacing: 8) {
                    ForEach(0..<totalSteps, id: \.self) { i in
                        Capsule()
                            .fill(i <= step ? EmberColors.ember : EmberColors.cream.opacity(0.2))
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                TabView(selection: $step) {
                    avatarStep.tag(0)
                    nameStep.tag(1)
                    xpStep(
                        title: "Earn XP every day",
                        bodyText: "Log water servings, burn calories, finish workouts, and challenge friends — each action fuels your Ember.",
                        icon: "flame.fill"
                    ).tag(2)
                    xpStep(
                        title: "Level 1 → 100",
                        bodyText: "XP fills your bar. As you level up, your Ember grows in power. Level 100 is a real grind — keep the fire going.",
                        icon: "chart.line.uptrend.xyaxis"
                    ).tag(3)
                    xpStep(
                        title: "Board multipliers",
                        bodyText: "Climb the weekly Board. Top ranks boost all XP: 3rd +10%, 2nd +20%, 1st +30%.",
                        icon: "trophy.fill"
                    ).tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.25), value: step)
                
                primaryButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
                    .padding(.top, 8)
            }
        }
        .onAppear {
            nameDraft = avatarManager.emberName
        }
    }
    
    private var canContinue: Bool {
        switch step {
        case 0:
            return !avatarManager.selectedAvatarId.isEmpty
        case 1:
            return !nameDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        default:
            return true
        }
    }
    
    private var primaryButton: some View {
        Button {
            advance()
        } label: {
            Text(step == totalSteps - 1 ? "Get started" : "Continue")
                .font(.headline)
                .foregroundColor(canContinue ? EmberColors.ink : EmberColors.cream.opacity(0.4))
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(canContinue ? EmberColors.ember : EmberColors.lightPlum)
                )
        }
        .disabled(!canContinue)
    }
    
    private func advance() {
        if step == 1 {
            avatarManager.emberName = nameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if step >= totalSteps - 1 {
            avatarManager.completeOnboarding()
            return
        }
        withAnimation { step += 1 }
    }
    
    private var avatarStep: some View {
        VStack(spacing: 16) {
            Text("Pick your Ember")
                .font(.title.bold())
                .foregroundColor(EmberColors.cream)
            
            Text("Choose one of 20 flames — you can change it later.")
                .font(.subheadline)
                .foregroundColor(EmberColors.cream.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            EmberFlameAvatar(
                level: max(1, levelManager.level),
                size: 140,
                style: avatarManager.selectedStyle
            )
            .frame(height: 160)
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 12)], spacing: 12) {
                    ForEach(AvatarStyle.presets) { style in
                        Button {
                            avatarManager.selectAvatar(style.id)
                        } label: {
                            VStack(spacing: 6) {
                                EmberFlameAvatar(level: 3, size: 56, style: style)
                                    .frame(width: 64, height: 72)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(
                                                avatarManager.selectedAvatarId == style.id
                                                ? EmberColors.ember
                                                : Color.clear,
                                                lineWidth: 2
                                            )
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(EmberColors.lightPlum)
                                            )
                                    )
                                Text(style.name)
                                    .font(.caption2)
                                    .foregroundColor(EmberColors.cream.opacity(0.7))
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
        .padding(.top, 8)
    }
    
    private var nameStep: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 12)
            
            EmberFlameAvatar(
                level: max(1, levelManager.level),
                size: 160,
                style: avatarManager.selectedStyle
            )
            
            Text("Name your Ember")
                .font(.title.bold())
                .foregroundColor(EmberColors.cream)
            
            TextField("e.g. Blaze", text: $nameDraft)
                .font(.title2.weight(.semibold))
                .foregroundColor(EmberColors.cream)
                .multilineTextAlignment(.center)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(EmberColors.lightPlum)
                )
                .padding(.horizontal, 24)
            
            Spacer()
        }
    }
    
    private func xpStep(title: String, bodyText: String, icon: String) -> some View {
        VStack(spacing: 28) {
            Spacer(minLength: 40)
            
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundColor(EmberColors.ember)
                .shadow(color: EmberColors.ember.opacity(0.4), radius: 16)
            
            Text(title)
                .font(.title.bold())
                .foregroundColor(EmberColors.cream)
                .multilineTextAlignment(.center)
            
            Text(bodyText)
                .font(.body)
                .foregroundColor(EmberColors.cream.opacity(0.75))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            
            Spacer()
        }
    }
}
