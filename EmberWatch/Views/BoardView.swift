import SwiftUI

struct BoardView: View {
    @EnvironmentObject var calorieGoalManager: CalorieGoalManager
    
    var body: some View {
        NavigationView {
            ZStack {
                EmberColors.dusk
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        weeklyBoardCard
                    }
                    .padding()
                }
            }
            .navigationTitle("Board")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(EmberColors.dusk, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
    
    private var weeklyBoardCard: some View {
        VStack(spacing: 0) {
            Text("This Week")
                .font(.headline)
                .foregroundColor(EmberColors.cream)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            
            ForEach(Array(mockLeaderboard.enumerated()), id: \.offset) { index, entry in
                LeaderboardRow(
                    rank: index + 1,
                    name: entry.name,
                    level: entry.level,
                    xp: entry.xp,
                    isCurrentUser: entry.isCurrentUser
                )
                
                if index < mockLeaderboard.count - 1 {
                    Divider()
                        .background(EmberColors.cream.opacity(0.1))
                        .padding(.horizontal)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(EmberColors.lightPlum)
        )
    }
    
    private var mockLeaderboard: [(name: String, level: Int, xp: Int, isCurrentUser: Bool)] {
        [
            ("Jules Park", calorieGoalManager.currentLevel, calorieGoalManager.currentXP, true),
            ("Alex Chen", 8, 450, false),
            ("Sam Rivera", 7, 320, false),
            ("Taylor Kim", 6, 580, false),
            ("Jordan Lee", 5, 290, false)
        ]
    }
}

struct LeaderboardRow: View {
    let rank: Int
    let name: String
    let level: Int
    let xp: Int
    let isCurrentUser: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Text("\(rank)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(rankColor)
                .frame(width: 36)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(name)
                        .font(.headline)
                        .foregroundColor(EmberColors.cream)
                    
                    if isCurrentUser {
                        Text("(You)")
                            .font(.caption)
                            .foregroundColor(EmberColors.ember)
                    }
                }
                
                HStack(spacing: 12) {
                    Label("Level \(level)", systemImage: "flame.fill")
                        .font(.subheadline)
                        .foregroundColor(EmberColors.cream.opacity(0.7))
                    
                    Label("\(xp) XP", systemImage: "star.fill")
                        .font(.subheadline)
                        .foregroundColor(EmberColors.cream.opacity(0.7))
                }
            }
            
            Spacer()
            
            if rank <= 3 {
                Image(systemName: medalIcon)
                    .font(.title2)
                    .foregroundColor(rankColor)
            }
        }
        .padding()
        .background(
            isCurrentUser ? EmberColors.dusk.opacity(0.5) : Color.clear
        )
    }
    
    private var rankColor: Color {
        switch rank {
        case 1:
            return EmberColors.gold
        case 2:
            return Color(hex: "#C0C0C0")
        case 3:
            return Color(hex: "#CD7F32")
        default:
            return EmberColors.cream.opacity(0.7)
        }
    }
    
    private var medalIcon: String {
        switch rank {
        case 1:
            return "medal.fill"
        case 2:
            return "medal.fill"
        case 3:
            return "medal.fill"
        default:
            return ""
        }
    }
}
