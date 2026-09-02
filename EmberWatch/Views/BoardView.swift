import SwiftUI

struct BoardEntry: Identifiable {
    let id: String
    let name: String
    let level: Int
    let xp: Int
    let isCurrentUser: Bool
}

struct BoardView: View {
    @EnvironmentObject var levelManager: LevelManager
    
    private var mockFriends: [BoardEntry] {
        [
            BoardEntry(id: "you", name: "Jules Park", level: levelManager.level, xp: levelManager.totalXP, isCurrentUser: true),
            BoardEntry(id: "alex", name: "Alex Chen", level: 8, xp: 450, isCurrentUser: false),
            BoardEntry(id: "sam", name: "Sam Rivera", level: 7, xp: 320, isCurrentUser: false),
            BoardEntry(id: "taylor", name: "Taylor Kim", level: 6, xp: 580, isCurrentUser: false),
            BoardEntry(id: "jordan", name: "Jordan Lee", level: 5, xp: 290, isCurrentUser: false)
        ]
    }
    
    private var rankedBoard: [BoardEntry] {
        mockFriends.sorted { lhs, rhs in
            if lhs.level != rhs.level { return lhs.level > rhs.level }
            return lhs.xp > rhs.xp
        }
    }
    
    private var userRank: Int {
        (rankedBoard.firstIndex(where: \.isCurrentUser) ?? 0) + 1
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                EmberColors.dusk
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        if let boost = levelManager.boardMultiplierLabel {
                            HStack(spacing: 8) {
                                Image(systemName: "bolt.fill")
                                    .foregroundColor(EmberColors.gold)
                                Text("Board rank #\(userRank) · \(boost) on all XP gains")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(EmberColors.cream)
                                Spacer()
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(EmberColors.lightPlum)
                            )
                        }
                        
                        weeklyBoardCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle("Board")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(EmberColors.dusk, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                levelManager.updateBoardRank(userRank)
            }
            .onChange(of: levelManager.level) { _, _ in
                levelManager.updateBoardRank(userRank)
            }
            .onChange(of: levelManager.totalXP) { _, _ in
                levelManager.updateBoardRank(userRank)
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private var weeklyBoardCard: some View {
        VStack(spacing: 0) {
            Text("This Week")
                .font(.headline)
                .foregroundColor(EmberColors.cream)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            
            ForEach(Array(rankedBoard.enumerated()), id: \.element.id) { index, entry in
                LeaderboardRow(
                    rank: index + 1,
                    name: entry.name,
                    level: entry.level,
                    xp: entry.xp,
                    isCurrentUser: entry.isCurrentUser,
                    canChallenge: !entry.isCurrentUser && levelManager.canChallenge(friendId: entry.id),
                    onChallenge: {
                        _ = levelManager.awardChallenge(friendId: entry.id)
                    }
                )
                
                if index < rankedBoard.count - 1 {
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
}

struct LeaderboardRow: View {
    let rank: Int
    let name: String
    let level: Int
    let xp: Int
    let isCurrentUser: Bool
    var canChallenge: Bool = false
    var onChallenge: (() -> Void)? = nil
    
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
            
            if !isCurrentUser {
                Button(action: { onChallenge?() }) {
                    Text(canChallenge ? "Challenge" : "Sent")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(canChallenge ? EmberColors.ink : EmberColors.cream.opacity(0.5))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(canChallenge ? EmberColors.ember : EmberColors.dusk)
                        )
                }
                .disabled(!canChallenge)
            } else if rank <= 3 {
                Image(systemName: medalIcon)
                    .font(.title2)
                    .foregroundColor(rankColor)
            }
            
            if isCurrentUser == false && rank <= 3 {
                Image(systemName: medalIcon)
                    .font(.title3)
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
        "medal.fill"
    }
}
