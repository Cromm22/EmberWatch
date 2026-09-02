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
    @EnvironmentObject var sparksManager: SparksManager
    @EnvironmentObject var friendsManager: FriendsManager
    @EnvironmentObject var avatarManager: AvatarManager
    
    @State private var showAddFriend = false
    @State private var addFriendCode = ""
    @State private var addFriendError: String?
    @State private var isAddingFriend = false
    
    private var allEntries: [BoardEntry] {
        var entries: [BoardEntry] = []
        
        // Current user
        let userName = avatarManager.emberName.isEmpty ? "You" : avatarManager.emberName
        entries.append(BoardEntry(id: "you", name: userName, level: levelManager.level, xp: levelManager.totalXP, isCurrentUser: true))
        
        // Real friends
        for friend in friendsManager.friends {
            entries.append(BoardEntry(id: friend.id, name: friend.name, level: 1, xp: friend.weeklyXP, isCurrentUser: false))
        }
        
        return entries
    }
    
    private var rankedBoard: [BoardEntry] {
        allEntries.sorted { lhs, rhs in
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
                        if let error = friendsManager.cloudKitError {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.icloud.fill")
                                    .foregroundColor(EmberColors.ember)
                                Text(error)
                                    .font(.subheadline)
                                    .foregroundColor(EmberColors.cream)
                                Spacer()
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(EmberColors.lightPlum)
                            )
                        }
                        
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
                        
                        myFriendCodeCard
                        
                        weeklyBoardCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }
                .refreshable {
                    await friendsManager.fetchFriends()
                }
            }
            .navigationTitle("Board")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(EmberColors.dusk, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                syncBoardRankAndSparks()
            }
            .onChange(of: levelManager.level) { _, _ in
                syncBoardRankAndSparks()
            }
            .onChange(of: levelManager.totalXP) { _, _ in
                syncBoardRankAndSparks()
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private func syncBoardRankAndSparks() {
        levelManager.updateBoardRank(userRank)
        _ = sparksManager.earnBoardFirstIfEligible(rank: userRank)
    }
    
    private var myFriendCodeCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("My Friend Code")
                        .font(.caption)
                        .foregroundColor(EmberColors.cream.opacity(0.7))
                    
                    Text(friendsManager.myFriendCode)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(EmberColors.ember)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button {
                        UIPasteboard.general.string = friendsManager.myFriendCode
                        friendsManager.toast = "Code copied!"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            friendsManager.toast = nil
                        }
                    } label: {
                        Image(systemName: "doc.on.doc.fill")
                            .font(.title3)
                            .foregroundColor(EmberColors.ember)
                            .padding(10)
                            .background(Circle().fill(EmberColors.dusk))
                    }
                    
                    Button {
                        shareCode()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                            .foregroundColor(EmberColors.ember)
                            .padding(10)
                            .background(Circle().fill(EmberColors.dusk))
                    }
                }
            }
            
            Button {
                showAddFriend = true
            } label: {
                HStack {
                    Image(systemName: "person.badge.plus")
                    Text("Add Friend")
                        .font(.headline)
                }
                .foregroundColor(EmberColors.cream)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(EmberColors.ember)
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(EmberColors.lightPlum)
        )
        .sheet(isPresented: $showAddFriend) {
            addFriendSheet
        }
        .overlay(alignment: .top) {
            if let toast = friendsManager.toast {
                Text(toast)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(EmberColors.ink)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(EmberColors.gold))
                    .offset(y: -40)
                    .transition(.opacity)
            }
        }
    }
    
    private var addFriendSheet: some View {
        NavigationView {
            ZStack {
                EmberColors.dusk.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Enter your friend's code to add them")
                        .font(.subheadline)
                        .foregroundColor(EmberColors.cream.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.top)
                    
                    TextField("Friend Code", text: $addFriendCode)
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(EmberColors.cream)
                        .textInputAutocapitalization(.characters)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(EmberColors.lightPlum)
                        )
                        .disabled(isAddingFriend)
                    
                    if let error = addFriendError {
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                    
                    Button {
                        addFriend()
                    } label: {
                        if isAddingFriend {
                            ProgressView()
                                .tint(EmberColors.cream)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text("Add Friend")
                                .font(.headline)
                                .foregroundColor(EmberColors.cream)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(EmberColors.ember)
                    )
                    .disabled(addFriendCode.isEmpty || isAddingFriend)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showAddFriend = false
                        addFriendCode = ""
                        addFriendError = nil
                    }
                    .foregroundColor(EmberColors.ember)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(EmberColors.dusk, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
    
    private func addFriend() {
        addFriendError = nil
        isAddingFriend = true
        
        Task {
            do {
                try await friendsManager.addFriend(code: addFriendCode)
                await MainActor.run {
                    isAddingFriend = false
                    showAddFriend = false
                    addFriendCode = ""
                }
            } catch {
                await MainActor.run {
                    isAddingFriend = false
                    addFriendError = error.localizedDescription
                }
            }
        }
    }
    
    private func shareCode() {
        let message = "Add me on Ember! My friend code is \(friendsManager.myFriendCode)"
        let activityVC = UIActivityViewController(
            activityItems: [message],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
    
    private var weeklyBoardCard: some View {
        VStack(spacing: 0) {
            Text("This Week")
                .font(.headline)
                .foregroundColor(EmberColors.cream)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            
            if friendsManager.friends.isEmpty && friendsManager.isCloudKitAvailable {
                VStack(spacing: 16) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 40))
                        .foregroundColor(EmberColors.cream.opacity(0.3))
                    
                    Text("No friends yet")
                        .font(.headline)
                        .foregroundColor(EmberColors.cream)
                    
                    Text("Share your code or add a friend to start competing")
                        .font(.subheadline)
                        .foregroundColor(EmberColors.cream.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .padding(.horizontal)
            } else {
                ForEach(Array(rankedBoard.enumerated()), id: \.element.id) { index, entry in
                    LeaderboardRow(
                        rank: index + 1,
                        name: entry.name,
                        level: entry.level,
                        xp: entry.xp,
                        isCurrentUser: entry.isCurrentUser,
                        canChallenge: !entry.isCurrentUser && levelManager.canChallenge(friendId: entry.id),
                        onChallenge: {
                            let xp = levelManager.awardChallenge(friendId: entry.id)
                            if xp > 0 {
                                _ = sparksManager.earnChallenge(friendId: entry.id)
                            }
                        }
                    )
                    
                    if index < rankedBoard.count - 1 {
                        Divider()
                            .background(EmberColors.cream.opacity(0.1))
                            .padding(.horizontal)
                    }
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
