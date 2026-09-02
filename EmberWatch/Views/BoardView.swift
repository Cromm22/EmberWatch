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
    
    /// Soft teal that sits against dusk/plum without reading as medal bronze.
    private static let teal = Color(hex: "#5EC8C0")
    
    var body: some View {
        HStack(spacing: 12) {
            RankMark(rank: rank)
            
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
            
            Spacer(minLength: 4)
            
            if !isCurrentUser {
                Button(action: { onChallenge?() }) {
                    HStack(spacing: 3) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 8, weight: .bold))
                        Text(canChallenge ? "Challenge" : "Sent")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(canChallenge ? EmberColors.ink : EmberColors.cream.opacity(0.45))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(canChallenge ? EmberColors.ember : EmberColors.dusk)
                    )
                }
                .buttonStyle(.plain)
                .disabled(!canChallenge)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            isCurrentUser ? EmberColors.dusk.opacity(0.5) : Color.clear
        )
    }
}

/// Ember-branded rank marks (no medals).
struct RankMark: View {
    let rank: Int
    
    private static let teal = Color(hex: "#5EC8C0")
    
    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundFill)
                .frame(width: 32, height: 32)
            
            Circle()
                .strokeBorder(accent.opacity(rank <= 3 ? 0.55 : 0.25), lineWidth: 1)
                .frame(width: 32, height: 32)
            
            Group {
                switch rank {
                case 1:
                    Image(systemName: "flame.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(accent)
                case 2:
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(accent)
                case 3:
                    Image(systemName: "drop.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(accent)
                default:
                    Text("\(rank)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(EmberColors.cream.opacity(0.75))
                }
            }
        }
        .frame(width: 36, height: 36)
        .accessibilityLabel("Rank \(rank)")
    }
    
    private var accent: Color {
        switch rank {
        case 1: return EmberColors.ember
        case 2: return EmberColors.gold
        case 3: return Self.teal
        default: return EmberColors.cream.opacity(0.7)
        }
    }
    
    private var backgroundFill: Color {
        switch rank {
        case 1: return EmberColors.ember.opacity(0.22)
        case 2: return EmberColors.gold.opacity(0.16)
        case 3: return Self.teal.opacity(0.16)
        default: return EmberColors.dusk.opacity(0.55)
        }
    }
}
