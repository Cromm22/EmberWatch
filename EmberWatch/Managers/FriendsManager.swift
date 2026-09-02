import Foundation
import SwiftUI
import CloudKit

/// Friend model for local display
struct Friend: Identifiable, Codable {
    let id: String // friendId (same as their friendCode)
    var name: String
    var avatarId: String
    var weeklyXP: Int
    var lastUpdated: Date
    
    var isCurrentUser: Bool = false
}

/// CloudKit-based friends system with invite codes
@MainActor
final class FriendsManager: ObservableObject {
    // MARK: - Published State
    
    @Published private(set) var myFriendCode: String = ""
    @Published private(set) var friends: [Friend] = []
    @Published private(set) var isCloudKitAvailable: Bool = false
    @Published private(set) var cloudKitError: String?
    @Published var addFriendSheet: Bool = false
    @Published var toast: String?
    
    // MARK: - Private State
    
    private let container: CKContainer
    private let publicDB: CKDatabase
    private var myRecordID: CKRecord.ID?
    
    private var friendIds: Set<String> {
        didSet {
            UserDefaults.standard.set(Array(friendIds), forKey: Keys.friendIds)
        }
    }
    
    private enum Keys {
        static let myFriendCode = "friendsManager.myFriendCode"
        static let friendIds = "friendsManager.friendIds"
    }
    
    private enum RecordType {
        static let profile = "UserProfile"
        static let friendship = "Friendship"
        static let challenge = "Challenge"
    }
    
    // MARK: - Init
    
    init() {
        self.container = CKContainer.default()
        self.publicDB = container.publicCloudDatabase
        
        // Initialize stored properties before any further self use
        let savedIds = UserDefaults.standard.stringArray(forKey: Keys.friendIds) ?? []
        self.friendIds = Set(savedIds)
        
        // Load saved friend code or generate new
        if let saved = UserDefaults.standard.string(forKey: Keys.myFriendCode), !saved.isEmpty {
            self.myFriendCode = saved
        } else {
            let code = Self.generateFriendCode()
            self.myFriendCode = code
            UserDefaults.standard.set(code, forKey: Keys.myFriendCode)
        }
        
        // Load cached friends from UserDefaults
        loadCachedFriends()
    }
    
    // MARK: - Setup
    
    /// Check CloudKit availability and publish profile
    func setupCloudKit() async {
        do {
            let status = try await container.accountStatus()
            
            await MainActor.run {
                switch status {
                case .available:
                    isCloudKitAvailable = true
                    cloudKitError = nil
                case .noAccount:
                    isCloudKitAvailable = false
                    cloudKitError = "Sign in to iCloud in Settings to add friends"
                case .restricted:
                    isCloudKitAvailable = false
                    cloudKitError = "iCloud access restricted"
                case .couldNotDetermine:
                    isCloudKitAvailable = false
                    cloudKitError = "Could not determine iCloud status"
                case .temporarilyUnavailable:
                    isCloudKitAvailable = false
                    cloudKitError = "iCloud temporarily unavailable"
                @unknown default:
                    isCloudKitAvailable = false
                    cloudKitError = "Unknown iCloud status"
                }
            }
            
            if status == .available {
                await publishMyProfile()
                await fetchFriends()
            }
        } catch {
            await MainActor.run {
                isCloudKitAvailable = false
                cloudKitError = "CloudKit error: \(error.localizedDescription)"
            }
        }
    }
    
    /// Update my profile when name/avatar/XP changes
    func updateMyProfile(name: String, avatarId: String, weeklyXP: Int) async {
        guard isCloudKitAvailable else { return }
        await publishMyProfile(name: name, avatarId: avatarId, weeklyXP: weeklyXP)
    }
    
    // MARK: - Add Friend
    
    /// Look up friend by code and add if found
    func addFriend(code: String) async throws {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        guard !trimmed.isEmpty else {
            throw FriendError.invalidCode
        }
        
        guard trimmed != myFriendCode else {
            throw FriendError.cannotAddSelf
        }
        
        guard !friendIds.contains(trimmed) else {
            throw FriendError.alreadyFriends
        }
        
        // Look up friend's profile in CloudKit
        let predicate = NSPredicate(format: "friendCode == %@", trimmed)
        let query = CKQuery(recordType: RecordType.profile, predicate: predicate)
        
        do {
            let (matchResults, _) = try await publicDB.records(matching: query, desiredKeys: ["friendCode", "displayName", "avatarId", "weeklyXP"])
            
            guard let (recordID, result) = matchResults.first else {
                throw FriendError.notFound
            }
            
            let record = try result.get()
            
            // Create friendship
            friendIds.insert(trimmed)
            
            // Cache friend locally
            let friend = Friend(
                id: trimmed,
                name: record["displayName"] as? String ?? "Unknown",
                avatarId: record["avatarId"] as? String ?? "classic",
                weeklyXP: record["weeklyXP"] as? Int ?? 0,
                lastUpdated: Date()
            )
            
            await MainActor.run {
                if !friends.contains(where: { $0.id == friend.id }) {
                    friends.append(friend)
                    saveCachedFriends()
                }
            }
            
            // Create bidirectional friendship record in CloudKit
            await createFriendship(friendRecordID: recordID)
            
            await MainActor.run {
                showToast("Added \(friend.name)!")
            }
        } catch {
            if (error as? CKError)?.code == .networkFailure || (error as? CKError)?.code == .networkUnavailable {
                throw FriendError.networkError
            }
            throw FriendError.notFound
        }
    }
    
    // MARK: - Refresh
    
    /// Fetch all friends' latest profiles
    func fetchFriends() async {
        guard isCloudKitAvailable, !friendIds.isEmpty else { return }
        
        let predicate = NSPredicate(format: "friendCode IN %@", Array(friendIds))
        let query = CKQuery(recordType: RecordType.profile, predicate: predicate)
        
        do {
            let (matchResults, _) = try await publicDB.records(matching: query, desiredKeys: ["friendCode", "displayName", "avatarId", "weeklyXP"])
            
            var updated: [Friend] = []
            for (_, result) in matchResults {
                guard let record = try? result.get() else { continue }
                guard let code = record["friendCode"] as? String else { continue }
                
                let friend = Friend(
                    id: code,
                    name: record["displayName"] as? String ?? "Unknown",
                    avatarId: record["avatarId"] as? String ?? "classic",
                    weeklyXP: record["weeklyXP"] as? Int ?? 0,
                    lastUpdated: Date()
                )
                updated.append(friend)
            }
            
            await MainActor.run {
                friends = updated
                saveCachedFriends()
            }
        } catch {
            print("FriendsManager: Failed to fetch friends: \(error)")
        }
    }
    
    // MARK: - Private CloudKit
    
    private func publishMyProfile(name: String? = nil, avatarId: String? = nil, weeklyXP: Int? = nil) async {
        // Get current values from UserDefaults if not provided
        let displayName = name ?? UserDefaults.standard.string(forKey: "emberName") ?? "Unknown"
        let avatar = avatarId ?? UserDefaults.standard.string(forKey: "selectedAvatarId") ?? "classic"
        let xp = weeklyXP ?? 0 // Could pull from LevelManager if needed
        
        // Try to find existing profile
        let predicate = NSPredicate(format: "friendCode == %@", myFriendCode)
        let query = CKQuery(recordType: RecordType.profile, predicate: predicate)
        
        do {
            let (matchResults, _) = try await publicDB.records(matching: query)
            
            let record: CKRecord
            if let (existingID, existingResult) = matchResults.first,
               let existingRecord = try? existingResult.get() {
                record = existingRecord
                myRecordID = existingID
            } else {
                // Create new profile
                record = CKRecord(recordType: RecordType.profile)
                record["friendCode"] = myFriendCode as CKRecordValue
            }
            
            record["displayName"] = displayName as CKRecordValue
            record["avatarId"] = avatar as CKRecordValue
            record["weeklyXP"] = xp as CKRecordValue
            record["updatedAt"] = Date() as CKRecordValue
            
            let savedRecord = try await publicDB.save(record)
            myRecordID = savedRecord.recordID
            
            print("FriendsManager: Published profile for \(myFriendCode)")
        } catch {
            print("FriendsManager: Failed to publish profile: \(error)")
        }
    }
    
    private func createFriendship(friendRecordID: CKRecord.ID) async {
        guard let myID = myRecordID else { return }
        
        let friendship = CKRecord(recordType: RecordType.friendship)
        friendship["user1"] = CKRecord.Reference(recordID: myID, action: .none)
        friendship["user2"] = CKRecord.Reference(recordID: friendRecordID, action: .none)
        friendship["createdAt"] = Date() as CKRecordValue
        
        do {
            _ = try await publicDB.save(friendship)
            print("FriendsManager: Created friendship")
        } catch {
            print("FriendsManager: Failed to create friendship: \(error)")
        }
    }
    
    // MARK: - Cache
    
    private func saveCachedFriends() {
        if let data = try? JSONEncoder().encode(friends) {
            UserDefaults.standard.set(data, forKey: "friendsManager.cachedFriends")
        }
    }
    
    private func loadCachedFriends() {
        guard let data = UserDefaults.standard.data(forKey: "friendsManager.cachedFriends"),
              let cached = try? JSONDecoder().decode([Friend].self, from: data) else {
            return
        }
        self.friends = cached
    }
    
    // MARK: - Helpers
    
    private static func generateFriendCode() -> String {
        // Generate 8-char readable code (no ambiguous chars: 0O, 1Il, etc)
        let chars = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"
        var code = ""
        for _ in 0..<8 {
            code.append(chars.randomElement()!)
        }
        return code
    }
    
    private func showToast(_ message: String) {
        toast = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            if self?.toast == message {
                self?.toast = nil
            }
        }
    }
}

// MARK: - Errors

enum FriendError: LocalizedError {
    case invalidCode
    case cannotAddSelf
    case alreadyFriends
    case notFound
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidCode:
            return "Please enter a friend code"
        case .cannotAddSelf:
            return "You can't add yourself"
        case .alreadyFriends:
            return "Already friends"
        case .notFound:
            return "Friend code not found"
        case .networkError:
            return "Network error. Try again."
        }
    }
}
