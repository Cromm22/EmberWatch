# CloudKit Friends & Challenges Setup Guide

## Overview

EmberWatch now uses CloudKit to sync friend invites and challenges between devices. This was previously disabled on Personal Team builds due to entitlement restrictions.

## What Changed

### Team Configuration
- **Old Team:** `RQWCD638WP` (Apple Personal Team - chrusht@gmail.com)
- **New Team:** `4UNUWW2348` (Paid Apple Developer Team)
- **Bundle ID:** `com.ember.watch`
- **CloudKit Container:** `iCloud.com.ember.watch`

### CloudKit Features Now Enabled
1. **Friend Codes** - 8-character invite codes that sync to CloudKit
2. **Friends List** - Real-time friend discovery and weekly XP leaderboard
3. **Profile Sync** - Name, avatar, and XP automatically sync when changed
4. **Challenges** - Infrastructure ready for friend challenges (future enhancement)

## First Build Setup

### In Xcode (Before First Device Build)

1. **Open the project:**
   ```bash
   open EmberWatch.xcodeproj
   ```

2. **Verify Signing:**
   - Select `EmberWatch` project in navigator
   - Go to **Signing & Capabilities** tab
   - Confirm **Team:** shows `Apple Development: chrusht@gmail.com (4UNUWW2348)`
   - Confirm **Bundle Identifier:** `com.ember.watch`

3. **Verify CloudKit Entitlements:**
   - Still in **Signing & Capabilities**
   - Confirm these capabilities exist:
     - ✅ **HealthKit**
     - ✅ **iCloud** → CloudKit
   - Under iCloud, verify:
     - Services: **CloudKit** (checked)
     - Containers: `iCloud.com.ember.watch`

4. **First Archive (if needed):**
   - If this is the first build with this team, Xcode may prompt to create the CloudKit container
   - Select your device and build (Cmd+R) or archive
   - Xcode Automatic Signing will handle provisioning profiles

### In Apple Developer Portal (Optional Verification)

If CloudKit doesn't work after first build, verify container exists:

1. Go to [developer.apple.com/account](https://developer.apple.com/account)
2. Sign in as `chrusht@gmail.com`
3. Navigate to **Identifiers** → **App IDs**
4. Find `com.ember.watch`
5. Verify **iCloud** capability is enabled with container `iCloud.com.ember.watch`
6. Navigate to **CloudKit Console** → **Containers**
7. Verify `iCloud.com.ember.watch` exists and is linked to the app

> **Note:** With Automatic Signing, the container is typically created automatically on first archive. Manual creation is rarely needed.

## Testing CloudKit on Devices

### Prerequisites
- Two physical iOS devices (e.g., Chris's iPhone and Sara's iPhone)
- Both devices signed into iCloud (Settings → [Your Name])
- Both devices have good internet connection
- EmberWatch installed on both devices from the **same build** (same team + entitlements)

### Test Procedure

#### On Device 1 (Chris's Phone):
1. Launch EmberWatch
2. Complete onboarding if first launch (set name and avatar)
3. Go to **Board** tab (trophy icon)
4. Check for CloudKit status at top of screen:
   - ✅ **Should NOT show:** "iCloud unavailable" error banner
   - ✅ **Should show:** Your 8-character friend code (e.g., `A3B7K9M2`)
5. Tap **Copy Code** to copy your friend code
6. Send the code to Device 2 (Messages, etc.)

#### On Device 2 (Sara's Phone):
1. Launch EmberWatch
2. Complete onboarding (set different name and avatar from Device 1)
3. Go to **Board** tab
4. Verify no "iCloud unavailable" error
5. Tap **Add Friend** button (+ icon)
6. Paste Chris's friend code from step 6 above
7. Tap **Add Friend**
8. ✅ **Should see:** "Added [Chris's name]!" toast
9. ✅ **Should see:** Chris's profile appear in friends list with avatar and XP

#### Back on Device 1:
1. On Board tab, tap the refresh icon (or pull to refresh)
2. ✅ **Should see:** Sara's profile appear in friends list

#### Verify Sync:
1. On **either device**, go to Home tab
2. Complete an action that earns XP (log water, add food, etc.)
3. Return to Board tab on **both devices**
4. Pull to refresh on the other device
5. ✅ **Should see:** XP count updated for that user

### Troubleshooting

#### Error: "iCloud unavailable on this build"
**Cause:** Binary was signed without CloudKit entitlement
- Rebuild from Xcode with correct team selected
- Verify `EmberWatch.entitlements` is not being overridden
- Check that no `EmberWatch-device.entitlements` file exists (old Personal Team workaround)

#### Error: "Sign in to iCloud in Settings to add friends"
**Cause:** Device not signed into iCloud
- Go to Settings → [Your Name]
- Sign in with Apple ID
- Enable iCloud Drive if prompted

#### Error: "Friend code not found"
**Possible causes:**
1. The friend hasn't opened the app yet (profile not published to CloudKit)
   - **Fix:** Have them launch the app and wait 5 seconds for publish
2. Network issue preventing CloudKit sync
   - **Fix:** Check internet connection, retry after a few seconds
3. Typo in friend code
   - **Fix:** Double-check code (case-insensitive, 8 characters)

#### Friends list is empty after adding
- Pull to refresh on Board tab
- Restart the app
- Check console logs in Xcode for CloudKit errors:
  ```
  FriendsManager: Published profile for [code]
  FriendsManager: Created friendship
  FriendsManager: Failed to fetch friends: [error]
  ```

## How It Works

### Runtime Entitlement Detection
`FriendsManager` checks for CloudKit entitlement **at runtime** using iOS Security framework APIs:
```swift
private static func hasCloudKitEntitlement() -> Bool {
    // Queries signed entitlements via SecTask APIs
    // Returns true only if icloud-services contains "CloudKit"
}
```

This approach:
- ✅ Prevents crashes on Personal Team builds that strip CloudKit
- ✅ Automatically enables CloudKit when signed with paid team
- ✅ Shows appropriate UI messages when CloudKit unavailable

### CloudKit Schema
EmberWatch uses CloudKit Public Database with these record types:

1. **UserProfile**
   - `friendCode` (String, indexed) - 8-char invite code
   - `displayName` (String) - User's Ember name
   - `avatarId` (String) - Selected avatar ID
   - `weeklyXP` (Int) - Current weekly XP total
   - `updatedAt` (Date) - Last profile update

2. **Friendship** (prepared for future use)
   - `user1` (Reference) - First user's UserProfile
   - `user2` (Reference) - Second user's UserProfile
   - `createdAt` (Date) - When friendship was created

3. **Challenge** (schema ready, not yet implemented)
   - Placeholder for future challenge features

### Privacy & Data
- All friend data uses **Public Database** (no private data stored)
- Only synced fields: display name, avatar ID, weekly XP
- No HealthKit data is sent to CloudKit
- Friend codes are randomly generated 8-character strings

## Next Steps After Verification

Once CloudKit is confirmed working on devices:

1. **Optional:** Remove old Personal Team references from docs
2. **Optional:** Add challenge feature implementation (schema is ready)
3. **Test:** Archive and distribute via TestFlight to verify provisioning profile includes CloudKit
4. **Document:** Add GIFs or screenshots of friend invite flow to README

## Support

If issues persist after following this guide:
1. Check Xcode console logs for CloudKit-specific errors
2. Verify Apple Developer account status and entitlements
3. Test with a fresh app install (delete app, reinstall from Xcode)
4. Check CloudKit Dashboard for container status and record counts
