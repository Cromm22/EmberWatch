import SwiftUI

struct AvatarPickerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var avatarManager: AvatarManager
    @EnvironmentObject var levelManager: LevelManager
    @EnvironmentObject var sparksManager: SparksManager
    
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                EmberColors.dusk
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Balance chip
                        HStack(spacing: 6) {
                            Image(systemName: "sparkle")
                                .foregroundColor(EmberColors.ember)
                            Text("\(sparksManager.balance) Sparks")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(EmberColors.cream)
                            Spacer()
                            Text("Cosmetics only")
                                .font(.caption2)
                                .foregroundColor(EmberColors.cream.opacity(0.45))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(EmberColors.lightPlum)
                        )
                        .padding(.horizontal)
                        .padding(.top, 4)
                        
                        Text("Choose your Ember companion")
                            .font(.headline)
                            .foregroundColor(EmberColors.cream.opacity(0.9))
                        
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(AvatarStyle.presets) { style in
                                let unlocked = sparksManager.isAvatarUnlocked(style.id)
                                AvatarThumbnail(
                                    style: style,
                                    isSelected: avatarManager.selectedAvatarId == style.id,
                                    level: levelManager.level,
                                    isLocked: !unlocked,
                                    price: SparksManager.avatarUnlockPrice
                                ) {
                                    if unlocked {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            avatarManager.selectAvatar(style.id)
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                            dismiss()
                                        }
                                    } else {
                                        if sparksManager.unlockAvatar(style.id) {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                avatarManager.selectAvatar(style.id)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        cosmeticsSection
                            .padding(.horizontal)
                            .padding(.bottom, 24)
                    }
                }
                
                if let toast = sparksManager.toast {
                    VStack {
                        Text(toast)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(EmberColors.ink)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [EmberColors.ember, EmberColors.emberAccent],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .padding(.top, 12)
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(30)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: sparksManager.toast)
            .navigationTitle("Avatar Gallery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(EmberColors.dusk, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(EmberColors.cream)
                }
            }
        }
    }
    
    private var cosmeticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cosmetic unlocks")
                .font(.headline)
                .foregroundColor(EmberColors.cream)
            
            Text("Status flair only — never gates tracking.")
                .font(.caption)
                .foregroundColor(EmberColors.cream.opacity(0.55))
            
            ForEach(SparksManager.cosmetics) { item in
                let unlocked = sparksManager.isCosmeticUnlocked(item.id)
                HStack(spacing: 12) {
                    Image(systemName: item.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(EmberColors.ember)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(EmberColors.dusk))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(EmberColors.cream)
                        Text(item.detail)
                            .font(.caption)
                            .foregroundColor(EmberColors.cream.opacity(0.55))
                    }
                    
                    Spacer()
                    
                    if unlocked {
                        if item.id == "glow" {
                            Button(sparksManager.glowEnabled ? "On" : "Off") {
                                sparksManager.toggleGlow()
                            }
                            .font(.caption.weight(.bold))
                            .foregroundColor(EmberColors.ink)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(sparksManager.glowEnabled ? EmberColors.ember : EmberColors.muted))
                        } else if item.id.hasPrefix("nameplate_") {
                            let active = sparksManager.activeNameplateId == item.id
                            Button(active ? "Active" : "Use") {
                                sparksManager.selectNameplate(active ? nil : item.id)
                            }
                            .font(.caption.weight(.bold))
                            .foregroundColor(EmberColors.ink)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(active ? EmberColors.gold : EmberColors.ember))
                        } else {
                            Text("Owned")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(EmberColors.cream.opacity(0.55))
                        }
                    } else {
                        Button {
                            _ = sparksManager.unlockCosmetic(item.id)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkle")
                                    .font(.system(size: 9, weight: .bold))
                                Text("\(item.price)")
                                    .font(.caption.weight(.bold))
                            }
                            .foregroundColor(EmberColors.ink)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(EmberColors.ember))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(EmberColors.lightPlum)
                )
            }
        }
    }
}

struct AvatarThumbnail: View {
    let style: AvatarStyle
    let isSelected: Bool
    let level: Int
    var isLocked: Bool = false
    var price: Int = 100
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(EmberColors.lightPlum)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    isSelected ?
                                        LinearGradient(
                                            colors: [
                                                Color(hex: style.auraColor),
                                                Color(hex: style.outerColors[1])
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ) :
                                        LinearGradient(
                                            colors: [Color.clear],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                    lineWidth: isSelected ? 3 : 0
                                )
                        )
                        .shadow(
                            color: isSelected ? Color(hex: style.auraColor).opacity(0.5) : .clear,
                            radius: isSelected ? 12 : 0
                        )
                    
                    EmberFlameAvatar(level: level, size: 68, style: style)
                        .scaleEffect(isPressed ? 0.92 : 1.0)
                        .opacity(isLocked ? 0.45 : 1.0)
                    
                    if isLocked {
                        VStack {
                            Spacer()
                            HStack(spacing: 3) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 9, weight: .bold))
                                Image(systemName: "sparkle")
                                    .font(.system(size: 8, weight: .bold))
                                Text("\(price)")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundColor(EmberColors.ink)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(EmberColors.ember))
                            .padding(.bottom, 6)
                        }
                    }
                    
                    if isSelected && !isLocked {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(EmberColors.ember)
                                    .background(
                                        Circle()
                                            .fill(EmberColors.dusk)
                                            .frame(width: 22, height: 22)
                                    )
                                    .padding(6)
                            }
                            Spacer()
                        }
                    }
                }
                .frame(height: 90)
                
                Text(style.name)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? EmberColors.cream : EmberColors.cream.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 32)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

#Preview {
    AvatarPickerView()
        .environmentObject(AvatarManager())
        .environmentObject(LevelManager())
        .environmentObject(SparksManager())
}
