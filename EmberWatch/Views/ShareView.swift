import SwiftUI
import UIKit

struct ShareView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var foodDataManager: FoodDataManager
    @EnvironmentObject var calorieGoalManager: CalorieGoalManager
    @EnvironmentObject var avatarManager: AvatarManager
    @EnvironmentObject var levelManager: LevelManager
    @EnvironmentObject var friendsManager: FriendsManager
    @EnvironmentObject var sparksManager: SparksManager
    
    @State private var challengeToast: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                EmberColors.dusk
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        shareCardPreview
                        
                        shareButton
                        
                        challengeSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }
                
                if let challengeToast {
                    VStack {
                        Spacer()
                        Text(challengeToast)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(EmberColors.ink)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(EmberColors.gold))
                            .padding(.bottom, 24)
                    }
                    .transition(.opacity)
                }
            }
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(EmberColors.dusk, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .navigationViewStyle(.stack)
    }
    
    private var shareCardPreview: some View {
        ShareCard(
            level: levelManager.level,
            xp: levelManager.totalXP,
            goal: Int(calorieGoalManager.dailyCalorieGoal),
            burned: Int(healthKitManager.totalCaloriesBurned),
            eaten: Int(foodDataManager.totalCaloriesConsumed),
            remaining: Int(calorieGoalManager.calculateRemainingCalories(
                burned: healthKitManager.totalCaloriesBurned,
                consumed: foodDataManager.totalCaloriesConsumed
            )),
            avatarStyle: avatarManager.selectedStyle
        )
    }
    
    private var shareButton: some View {
        Button(action: shareCard) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                    .font(.headline)
                
                Text("Share Your Progress")
                    .font(.headline)
            }
            .foregroundColor(EmberColors.cream)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(EmberColors.ember)
            )
        }
    }
    
    private var challengeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Challenge a Friend")
                .font(.headline)
                .foregroundColor(EmberColors.cream)
            
            Text("+\(LevelManager.challengeXP) XP · once per friend / day\(levelManager.boardMultiplierLabel.map { " · \($0)" } ?? "")")
                .font(.caption)
                .foregroundColor(EmberColors.cream.opacity(0.6))
            
            if friendsManager.friends.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 32))
                        .foregroundColor(EmberColors.cream.opacity(0.3))
                    
                    Text("Add friends on the Board tab to challenge them")
                        .font(.subheadline)
                        .foregroundColor(EmberColors.cream.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .padding(.horizontal)
                .background(RoundedRectangle(cornerRadius: 14).fill(EmberColors.lightPlum))
            } else {
                ForEach(friendsManager.friends) { friend in
                    let can = levelManager.canChallenge(friendId: friend.id)
                    Button {
                        let gained = levelManager.awardChallenge(friendId: friend.id)
                        if gained > 0 {
                            _ = sparksManager.earnChallenge(friendId: friend.id)
                        }
                        withAnimation {
                            challengeToast = gained > 0
                                ? "Challenged \(friend.name)! +\(gained) XP"
                                : "Already challenged \(friend.name) today"
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation { challengeToast = nil }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "flag.fill")
                                .foregroundColor(EmberColors.ember)
                            Text(friend.name)
                                .foregroundColor(EmberColors.cream)
                            Spacer()
                            Text(can ? "Challenge" : "Sent")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(can ? EmberColors.ink : EmberColors.cream.opacity(0.5))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(can ? EmberColors.ember : EmberColors.dusk))
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 14).fill(EmberColors.lightPlum))
                    }
                    .disabled(!can)
                }
            }
        }
    }
    
    private func shareCard() {
        let renderer = ImageRenderer(content: shareCardPreview.frame(width: 375))
        renderer.scale = 3.0
        
        if let image = renderer.uiImage {
            let activityVC = UIActivityViewController(
                activityItems: [image, "Check out my Ember progress! 🔥"],
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(activityVC, animated: true)
            }
        }
    }
}

struct ShareCard: View {
    let level: Int
    let xp: Int
    let goal: Int
    let burned: Int
    let eaten: Int
    let remaining: Int
    var avatarStyle: AvatarStyle = AvatarStyle.presets[0]
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                EmberFlameAvatar(level: level, size: 160, style: avatarStyle)
                
                Text("Level \(level)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(EmberColors.cream)
                
                Text("\(xp) XP")
                    .font(.headline)
                    .foregroundColor(EmberColors.ember)
            }
            
            Divider()
                .background(EmberColors.cream.opacity(0.2))
            
            VStack(spacing: 16) {
                Text("Today's Stats")
                    .font(.headline)
                    .foregroundColor(EmberColors.cream.opacity(0.9))
                
                HStack(spacing: 20) {
                    ShareStatItem(icon: "target", label: "Goal", value: "\(goal)")
                    ShareStatItem(icon: "flame.fill", label: "Burned", value: "+\(burned)")
                    ShareStatItem(icon: "fork.knife", label: "Eaten", value: "-\(eaten)")
                }
                
                VStack(spacing: 8) {
                    Text("Remaining")
                        .font(.caption)
                        .foregroundColor(EmberColors.cream.opacity(0.7))
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(remaining)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(remaining >= 0 ? EmberColors.ember : .orange)
                        
                        Text("cal")
                            .font(.subheadline)
                            .foregroundColor(EmberColors.cream.opacity(0.7))
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(EmberColors.dusk)
                )
            }
            
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(EmberColors.ember)
                
                Text("Ember")
                    .font(.headline)
                    .foregroundColor(EmberColors.cream)
            }
            .padding(.top, 8)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(EmberColors.lightPlum)
        )
    }
}

struct ShareStatItem: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(EmberColors.ember)
            
            Text(value)
                .font(.headline)
                .foregroundColor(EmberColors.cream)
            
            Text(label)
                .font(.caption)
                .foregroundColor(EmberColors.cream.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}
