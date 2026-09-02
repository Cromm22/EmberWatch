import SwiftUI
import UIKit

struct ShareView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var foodDataManager: FoodDataManager
    @EnvironmentObject var calorieGoalManager: CalorieGoalManager
    @EnvironmentObject var avatarManager: AvatarManager
    
    @State private var shareImage: UIImage?
    
    var body: some View {
        NavigationView {
            ZStack {
                EmberColors.dusk
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        shareCardPreview
                        
                        shareButton
                    }
                    .padding()
                }
            }
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(EmberColors.dusk, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
    
    private var shareCardPreview: some View {
        ShareCard(
            level: calorieGoalManager.currentLevel,
            xp: calorieGoalManager.currentXP,
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
        .padding()
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
