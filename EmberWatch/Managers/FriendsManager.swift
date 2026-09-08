import Foundation
import SwiftUI
import CloudKit

// SecTask entitlement APIs exist on iOS (linked via Security.framework) but are
// omitted from the public SDK headers. Declare the subset we need so we can
// detect a stripped CloudKit entitlement before CKContainer.default() traps.
private typealias EmberSecTask = OpaquePointer
@_silgen_name("SecTaskCreateFromSelf")
private func EmberSecTaskCreateFromSelf(_ allocator: CFAllocator?) -> EmberSecTask?
@_silgen_name("SecTaskCopyValueForEntitlement")
private func EmberSecTaskCopyValueForEntitlement(
    _ task: EmberSecTask?,
    _ entitlement: CFString,
    _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?
) -> CFTypeRef?

/// Friend model for local display
struct Friend: Identifiable, Codable {
    let id: String // friendId (same as their friendCode)
    var name: String
    var avatarId: String
    var weeklyXP: Int
    var totalXP: Int
    var level: Int
    var lastUpdated: Date
    
    var isCurrentUser: Bool = false
}

/// CloudKit-based friends system with invite codes.
/// Safe without CloudKit entitlements: never calls CKContainer APIs unless
/// the process is signed with iCloud CloudKit services.
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
    
    /// Nil when the binary lacks CloudKit entitlement (device Personal Team builds).
    private let container: CKContainer?
    private let publicDB: CKDatabase?
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
        // CKContainer init can trap when CloudKit entitlement is missing or when
        // the specified container doesn't exist. Gate creation on the signed
        // entitlement so Personal Team / HealthKit-only device builds still launch.
        let entitled = Self.hasCloudKitEntitlement()
        
        // Initialize stored properties first
        let savedIds = UserDefaults.standard.stringArray(forKey: Keys.friendIds) ?? []
        self.friendIds = Set(savedIds)
        
        if entitled {
            // Use explicit container identifier matching EmberWatch.entitlements.
            // CKContainer.default() fails when custom container is specified.
            // Container creation is synchronous but may fail if not provisioned.
            let ck = CKContainer(identifier: "iCloud.com.ember.watch")
            self.container = ck
            self.publicDB = ck.publicCloudDatabase
        } else {
            self.container = nil
            self.publicDB = nil
        }
        
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
        
        if !entitled {
            isCloudKitAvailable = false
            cloudKitError = "iCloud unavailable on this build"
        }
    }
    
    /// True when the running binary includes CloudKit in icloud-services.
    /// Must be checked before any CKContainer call — missing entitlement traps.
    private static func hasCloudKitEntitlement() -> Bool {
        guard let task = EmberSecTaskCreateFromSelf(nil) else { return false }
        var error: Unmanaged<CFError>?
        guard let value = EmberSecTaskCopyValueForEntitlement(
            task,
            "com.apple.developer.icloud-services" as CFString,
            &error
        ) else {
            return false
        }
        let any = value as AnyObject
        if let services = any as? [String] {
            return services.contains("CloudKit")
        }
        if let service = any as? String {
            return service == "CloudKit"
        }
        return false
    }
    
    // MARK: - Setup
    
    /// Check CloudKit availability and publish profile
    func setupCloudKit() async {
        guard let container else {
            isCloudKitAvailable = false
            if cloudKitError == nil {
                cloudKitError = "iCloud unavailable on this build"
            }
            return
        }
        
        do {
            let status = try await container.accountStatus()
            
            switch status {
            case .available:
                isCloudKitAvailable = true
                cloudKitError = nil
                
                // TODO: When profile settings UI exists, call updateMyContactInfo here
                // to publish user's email/phone for Contacts-based friend discovery.
                // For now, Contacts matching stays no-op until email/phone are set via
                // a future profile settings screen.
                // Example: await updateMyContactInfo(email: userEmail, phone: userPhone)
                
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
            
            if status == .available {
                await publishMyProfile()
                await fetchFriends()
            }
        } catch {
            isCloudKitAvailable = false
            cloudKitError = "CloudKit error: \(error.localizedDescription)"
        }
    }
    
    /// Update my profile when name/avatar/XP/level changes
    func updateMyProfile(name: String, avatarId: String, totalXP: Int, level: Int) async {
        guard isCloudKitAvailable, publicDB != nil else { return }
        await publishMyProfile(name: name, avatarId: avatarId, totalXP: totalXP, level: level)
    }
    
    /// Update my email/phone for contact lookup (enables Contacts-based friend discovery).
    ///
    /// Call this when the user sets their email/phone in profile settings (future feature).
    /// Without email/phone on UserProfile, Contacts-based Add Friend will show "not found"
    /// for all contacts. Invite code flow works independently without these fields.
    ///
    /// - Parameters:
    ///   - email: User's email address (will be lowercased and indexed)
    ///   - phone: User's phone number (digits-only, will be normalized and indexed)
    func updateMyContactInfo(email: String?, phone: String?) async {
        guard isCloudKitAvailable, let publicDB else { return }
        
        // Find existing profile
        let predicate = NSPredicate(format: "friendCode == %@", myFriendCode)
        let query = CKQuery(recordType: RecordType.profile, predicate: predicate)
        
        do {
            let (matchResults, _) = try await publicDB.records(matching: query)
            
            if let (_, existingResult) = matchResults.first,
               let record = try? existingResult.get() {
                if let email = email, !email.isEmpty {
                    record["email"] = email.lowercased() as CKRecordValue
                }
                if let phone = phone, !phone.isEmpty {
                    // Normalize phone: remove non-digits
                    let normalized = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                    record["phone"] = normalized as CKRecordValue
                }
                _ = try await publicDB.save(record)
            }
        } catch {
            print("FriendsManager: Failed to update contact info: \(error)")
        }
    }
    
    // MARK: - Add Friend
    
    /// Look up friend by email or phone and add if found
    func addFriend(email: String? = nil, phone: String? = nil) async throws -> Friend {
        guard isCloudKitAvailable, let publicDB else {
            throw FriendError.icloudUnavailable
        }
        
        var predicate: NSPredicate?
        
        if let email = email, !email.isEmpty {
            let normalized = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            predicate = NSPredicate(format: "email == %@", normalized)
        } else if let phone = phone, !phone.isEmpty {
            let normalized = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            predicate = NSPredicate(format: "phone == %@", normalized)
        } else {
            throw FriendError.invalidCode
        }
        
        guard let predicate else {
            throw FriendError.invalidCode
        }
        
        let query = CKQuery(recordType: RecordType.profile, predicate: predicate)
        
        do {
            let (matchResults, _) = try await publicDB.records(matching: query, desiredKeys: ["friendCode", "displayName", "avatarId", "totalXP", "level", "weeklyXP"])
            
            guard let (recordID, result) = matchResults.first else {
                throw FriendError.notFound
            }
            
            let record = try result.get()
            guard let friendCode = record["friendCode"] as? String else {
                throw FriendError.notFound
            }
            
            guard friendCode != myFriendCode else {
                throw FriendError.cannotAddSelf
            }
            
            guard !friendIds.contains(friendCode) else {
                throw FriendError.alreadyFriends
            }
            
            // Add friendship
            friendIds.insert(friendCode)
            
            // Cache friend locally
            let friend = Friend(
                id: friendCode,
                name: record["displayName"] as? String ?? "Unknown",
                avatarId: record["avatarId"] as? String ?? "classic",
                weeklyXP: record["weeklyXP"] as? Int ?? 0,
                totalXP: record["totalXP"] as? Int ?? 0,
                level: record["level"] as? Int ?? 1,
                lastUpdated: Date()
            )
            
            if !friends.contains(where: { $0.id == friend.id }) {
                friends.append(friend)
                saveCachedFriends()
            }
            
            // Create bidirectional friendship record in CloudKit
            await createFriendship(friendRecordID: recordID)
            
            return friend
        } catch let error as FriendError {
            throw error
        } catch {
            if (error as? CKError)?.code == .networkFailure || (error as? CKError)?.code == .networkUnavailable {
                throw FriendError.networkError
            }
            throw FriendError.notFound
        }
    }
    
    /// Look up friend by code and add if found
    func addFriend(code: String) async throws {
        guard isCloudKitAvailable, let publicDB else {
            throw FriendError.icloudUnavailable
        }
        
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
            let (matchResults, _) = try await publicDB.records(matching: query, desiredKeys: ["friendCode", "displayName", "avatarId", "totalXP", "level", "weeklyXP"])
            
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
                totalXP: record["totalXP"] as? Int ?? 0,
                level: record["level"] as? Int ?? 1,
                lastUpdated: Date()
            )
            
            if !friends.contains(where: { $0.id == friend.id }) {
                friends.append(friend)
                saveCachedFriends()
            }
            
            // Create bidirectional friendship record in CloudKit
            await createFriendship(friendRecordID: recordID)
            
            showToast("Added \(friend.name)!")
        } catch let error as FriendError {
            throw error
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
        guard isCloudKitAvailable, let publicDB, !friendIds.isEmpty else { return }
        
        let predicate = NSPredicate(format: "friendCode IN %@", Array(friendIds))
        let query = CKQuery(recordType: RecordType.profile, predicate: predicate)
        
        do {
            let (matchResults, _) = try await publicDB.records(matching: query, desiredKeys: ["friendCode", "displayName", "avatarId", "totalXP", "level", "weeklyXP"])
            
            var updated: [Friend] = []
            for (_, result) in matchResults {
                guard let record = try? result.get() else { continue }
                guard let code = record["friendCode"] as? String else { continue }
                
                let friend = Friend(
                    id: code,
                    name: record["displayName"] as? String ?? "Unknown",
                    avatarId: record["avatarId"] as? String ?? "classic",
                    weeklyXP: record["weeklyXP"] as? Int ?? 0,
                    totalXP: record["totalXP"] as? Int ?? 0,
                    level: record["level"] as? Int ?? 1,
                    lastUpdated: Date()
                )
                updated.append(friend)
            }
            
            friends = updated
            saveCachedFriends()
        } catch {
            print("FriendsManager: Failed to fetch friends: \(error)")
        }
    }
    
    // MARK: - Private CloudKit
    
    private func publishMyProfile(name: String? = nil, avatarId: String? = nil, totalXP: Int? = nil, level: Int? = nil) async {
        guard let publicDB else { return }
        
        // Get current values from UserDefaults if not provided
        let displayName = name ?? UserDefaults.standard.string(forKey: "emberName") ?? "Unknown"
        let avatar = avatarId ?? UserDefaults.standard.string(forKey: "selectedAvatarId") ?? "classic"
        let xp = totalXP ?? 0
        let lvl = level ?? 1
        
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
            record["totalXP"] = xp as CKRecordValue
            record["level"] = lvl as CKRecordValue
            record["weeklyXP"] = 0 as CKRecordValue  // Keep for backward compat, but unused
            record["updatedAt"] = Date() as CKRecordValue
            
            let savedRecord = try await publicDB.save(record)
            myRecordID = savedRecord.recordID
            
            print("FriendsManager: Published profile for \(myFriendCode) - Lv\(lvl), \(xp) XP")
        } catch {
            print("FriendsManager: Failed to publish profile: \(error)")
        }
    }
    
    private func createFriendship(friendRecordID: CKRecord.ID) async {
        guard let publicDB, let myID = myRecordID else { return }
        
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
    
    // MARK: - Challenges
    
    /// Send a challenge to a friend (creates CloudKit Challenge record)
    func sendChallenge(to friendId: String) async -> Bool {
        guard isCloudKitAvailable, let publicDB, let myID = myRecordID else {
            return false
        }
        
        // Find friend's record
        let predicate = NSPredicate(format: "friendCode == %@", friendId)
        let query = CKQuery(recordType: RecordType.profile, predicate: predicate)
        
        do {
            let (matchResults, _) = try await publicDB.records(matching: query)
            guard let (friendRecordID, _) = matchResults.first else {
                print("FriendsManager: Friend record not found for challenge")
                return false
            }
            
            // Create challenge record
            let challenge = CKRecord(recordType: RecordType.challenge)
            challenge["challenger"] = CKRecord.Reference(recordID: myID, action: .none)
            challenge["challenged"] = CKRecord.Reference(recordID: friendRecordID, action: .none)
            challenge["challengerCode"] = myFriendCode as CKRecordValue
            challenge["challengedCode"] = friendId as CKRecordValue
            challenge["createdAt"] = Date() as CKRecordValue
            challenge["status"] = "pending" as CKRecordValue
            
            _ = try await publicDB.save(challenge)
            print("FriendsManager: Challenge sent to \(friendId)")
            return true
        } catch {
            print("FriendsManager: Failed to send challenge: \(error)")
            return false
        }
    }
    
    /// Fetch pending challenges sent to me
    func fetchReceivedChallenges() async -> [(challengeId: CKRecord.ID, fromCode: String, fromName: String, date: Date)] {
        guard isCloudKitAvailable, let publicDB, let myID = myRecordID else {
            return []
        }
        
        let challengedRef = CKRecord.Reference(recordID: myID, action: .none)
        let predicate = NSPredicate(format: "challenged == %@ AND status == %@", challengedRef, "pending")
        let query = CKQuery(recordType: RecordType.challenge, predicate: predicate)
        
        do {
            let (matchResults, _) = try await publicDB.records(matching: query)
            var challenges: [(CKRecord.ID, String, String, Date)] = []
            
            for (recordID, result) in matchResults {
                guard let record = try? result.get() else { continue }
                guard let fromCode = record["challengerCode"] as? String else { continue }
                let date = record["createdAt"] as? Date ?? Date()
                
                // Look up challenger's name
                let namePredicate = NSPredicate(format: "friendCode == %@", fromCode)
                let nameQuery = CKQuery(recordType: RecordType.profile, predicate: namePredicate)
                let (nameResults, _) = try await publicDB.records(matching: nameQuery, desiredKeys: ["displayName"])
                
                let name = (try? nameResults.first?.1.get()["displayName"] as? String) ?? "Unknown"
                challenges.append((recordID, fromCode, name, date))
            }
            
            return challenges
        } catch {
            print("FriendsManager: Failed to fetch challenges: \(error)")
            return []
        }
    }
    
    /// Accept a challenge (marks it completed)
    func acceptChallenge(_ challengeId: CKRecord.ID) async -> Bool {
        guard isCloudKitAvailable, let publicDB else {
            return false
        }
        
        do {
            let record = try await publicDB.record(for: challengeId)
            record["status"] = "completed" as CKRecordValue
            record["completedAt"] = Date() as CKRecordValue
            _ = try await publicDB.save(record)
            print("FriendsManager: Challenge accepted")
            return true
        } catch {
            print("FriendsManager: Failed to accept challenge: \(error)")
            return false
        }
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
    case icloudUnavailable
    
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
        case .icloudUnavailable:
            return "iCloud unavailable"
        }
    }
}
