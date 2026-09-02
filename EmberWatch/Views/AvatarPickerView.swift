import SwiftUI

struct AvatarPickerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var avatarManager: AvatarManager
    @EnvironmentObject var calorieGoalManager: CalorieGoalManager
    
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#100814")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Choose your Ember companion")
                            .font(.headline)
                            .foregroundColor(EmberColors.cream.opacity(0.9))
                            .padding(.top, 8)
                        
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(AvatarStyle.presets) { style in
                                AvatarThumbnail(
                                    style: style,
                                    isSelected: avatarManager.selectedAvatarId == style.id,
                                    level: calorieGoalManager.currentLevel
                                ) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        avatarManager.selectAvatar(style.id)
                                    }
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                        dismiss()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Avatar Gallery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color(hex: "#100814"), for: .navigationBar)
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
}

struct AvatarThumbnail: View {
    let style: AvatarStyle
    let isSelected: Bool
    let level: Int
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
                    
                    if isSelected {
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
        .environmentObject(CalorieGoalManager())
}
