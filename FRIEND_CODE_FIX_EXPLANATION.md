# Friend Code Fix - Root Cause Analysis

## Issue
Friend invite codes fail with "Friend code not found" even when the profile exists.

## What PR #43 Did (Insufficient)
PR #43 added `sortDescriptors` to CloudKit queries:
```swift
query.sortDescriptors = [NSSortDescriptor(key: "friendCode", ascending: true)]
```

**Why this didn't fix it:** `sortDescriptors` only affects sorting, not querying. CloudKit has two separate schema requirements:
- **SORTABLE** - allows sorting results (what sortDescriptors uses)
- **QUERYABLE** - allows filtering/searching (what NSPredicate uses)

## Real Root Cause
1. **CloudKit queries require QUERYABLE indexes** - The original code queried by `friendCode` field, but this field was likely not marked as QUERYABLE in CloudKit schema configuration. Without this index, queries would:
   - Return empty results, OR
   - Throw CloudKit errors (which were masked)

2. **Error masking hid the real problem** - All CloudKit errors were caught and converted to `FriendError.notFound`:
   ```swift
   catch {
       throw FriendError.notFound  // Hides real CKError
   }
   ```

3. **Wrong approach** - Querying by field requires CloudKit Dashboard schema configuration that may not exist or may fail to sync.

## The Durable Fix

### Use recordName = friendCode
Instead of storing `friendCode` as a field and querying it, use the friend code as the **record ID**:

```swift
// Old approach (query-based - unreliable)
let predicate = NSPredicate(format: "friendCode == %@", code)
let query = CKQuery(recordType: "UserProfile", predicate: predicate)
let results = try await publicDB.records(matching: query)

// New approach (ID-based - reliable)
let recordID = CKRecord.ID(recordName: code)
let record = try await publicDB.record(for: recordID)
```

### Benefits
1. **More efficient** - Direct fetch is faster than querying
2. **More reliable** - Record IDs are always fetchable, no schema configuration needed
3. **No CloudKit Dashboard setup** - Works immediately, no QUERYABLE indexes required
4. **Deterministic** - One code = one record, no duplicate handling needed

### Enhanced Error Handling
Added proper CloudKit error surfacing:
```swift
catch let ckError as CKError {
    print("CloudKit error: code=\(ckError.code.rawValue), \(ckError.localizedDescription)")
    switch ckError.code {
    case .unknownItem:
        throw FriendError.notFound  // Profile doesn't exist
    case .networkFailure, .networkUnavailable:
        throw FriendError.networkError
    case .notAuthenticated, .permissionFailure:
        throw FriendError.icloudUnavailable
    default:
        print("Unexpected CKError: \(ckError)")
        throw FriendError.notFound
    }
}
```

## Changes Made

### 1. `publishMyProfile()` 
- Uses `CKRecord.ID(recordName: myFriendCode)` when creating/updating profile
- Direct fetch via `publicDB.record(for: recordID)` instead of query
- Enhanced error logging

### 2. `addFriend(code:)`
- Fetches by record ID instead of querying
- Proper CloudKit error handling and logging
- Clear diagnostics when profile doesn't exist

### 3. `updateMyContactInfo(email:phone:)`
- Direct record fetch by ID for consistency
- Enhanced error logging

### 4. `addFriend(email:phone:)`
- Improved error handling (still uses queries - email/phone need to be QUERYABLE)
- Added notes that email/phone fields require CloudKit schema configuration
- Better error diagnostics

### 5. `fetchFriends()`
- Batch fetch by record IDs instead of query
- More efficient and reliable

## Testing
When a user with a valid friend code (e.g., Sara's `BNB5SYT7`) shares it:
1. Sara's profile is created with `recordName = "BNB5SYT7"`
2. Chris enters the code
3. App does `publicDB.record(for: CKRecord.ID(recordName: "BNB5SYT7"))`
4. Profile is found immediately, no query or index required

## What to Check if Still Failing
1. **Profile publication** - Check Xcode console logs: "Published profile for [CODE]"
2. **CloudKit environment** - Verify Development vs Production environment
3. **iCloud account** - User must be signed into iCloud
4. **Container identifier** - Must match `iCloud.com.ember.watch`
5. **Error logs** - New error handling will show real CloudKit errors

## Migration Note
Existing profiles created with the old code may have random `recordID.recordName` values. Those profiles won't be findable by the new code. Users who published profiles with the old code should:
1. Delete their old profile from CloudKit (or let it expire)
2. Launch the app with the new code
3. New profile will be created with `recordName = friendCode`
4. Friend codes will work correctly

Alternatively, a migration script could update existing profiles' record names, but simpler to let old profiles expire and recreate.
