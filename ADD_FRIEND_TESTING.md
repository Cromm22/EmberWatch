# Add Friend Testing Guide

## Overview
This PR redesigns the Add Friend feature to support two paths:
1. **From Contacts** - Pick a contact from the system contacts and check if they're on Ember
2. **Invite Code** - Keep the existing 8-character invite code flow

## Prerequisites
- Two iOS devices or simulators with EmberWatch installed
- iCloud account signed in on both devices
- Contacts permission granted when testing the Contacts path

## Testing Checklist

### Path Selection Screen
- [ ] Open BoardView and tap "Add Friend"
- [ ] Verify the Add Friend sheet shows two options:
  - "From Contacts" with person icon
  - "Invite Code" with number icon
- [ ] Verify both options are disabled if iCloud is unavailable
- [ ] Verify CloudKit error banner shows if iCloud is unavailable

### Path 1: From Contacts

#### Happy Path - Contact Found
1. [ ] Tap "From Contacts"
2. [ ] Verify description explains that only the selected contact is looked up
3. [ ] Tap "Choose from Contacts"
4. [ ] Grant Contacts permission when prompted (first time)
5. [ ] Select a contact that has EmberWatch account with matching email/phone
6. [ ] Verify friend is added successfully
7. [ ] Verify success toast shows "Added [Friend Name]!"
8. [ ] Verify sheet dismisses automatically
9. [ ] Verify friend appears in the Board list

#### Contact Not Found
1. [ ] Tap "From Contacts"
2. [ ] Choose a contact that is NOT on EmberWatch
3. [ ] Verify friendly error message: "[Contact Name] isn't on Ember yet. Try sharing your invite code with them!"
4. [ ] Verify user can try again or go back

#### Permission Denied
1. [ ] Deny Contacts permission when prompted (or disable in Settings)
2. [ ] Tap "Choose from Contacts"
3. [ ] Verify permission denied banner appears
4. [ ] Tap "Open Settings"
5. [ ] Verify Settings app opens to EmberWatch settings

#### Edge Cases - Contacts
- [ ] Test with contact that has only email (no phone)
- [ ] Test with contact that has only phone (no email)
- [ ] Test with contact that has multiple emails/phones (should use first)
- [ ] Test adding the same friend twice (should show "Already friends" error)

### Path 2: Invite Code

#### Happy Path - Valid Code
1. [ ] Tap "Invite Code"
2. [ ] Enter a valid 8-character friend code
3. [ ] Verify code is auto-uppercased and trimmed (from PR #36)
4. [ ] Tap "Add Friend"
5. [ ] Verify loading indicator appears
6. [ ] Verify friend is added successfully
7. [ ] Verify success toast shows "Added [Friend Name]!"
8. [ ] Verify sheet dismisses automatically
9. [ ] Verify friend appears in the Board list

#### Invalid Code
- [ ] Test with empty code (button should be disabled)
- [ ] Test with non-existent code (should show "Friend code not found")
- [ ] Test with your own friend code (should show "You can't add yourself")
- [ ] Test with code of already added friend (should show "Already friends")

#### Paste Support (from PR #36)
1. [ ] Copy a friend code to clipboard
2. [ ] Paste into the text field
3. [ ] Verify pasted code is trimmed and uppercased
4. [ ] Verify "Add Friend" button enables immediately after paste

### Navigation & UX

#### Back Navigation
- [ ] From Contacts path, tap "Back" button
- [ ] Verify returns to path selection screen
- [ ] From Invite Code path, tap "Back" button
- [ ] Verify returns to path selection screen

#### Cancel
- [ ] Tap "Cancel" from any screen
- [ ] Verify sheet dismisses completely
- [ ] Re-open Add Friend sheet
- [ ] Verify it starts fresh at path selection

#### Error Handling
- [ ] Test with airplane mode enabled (network error)
- [ ] Test with iCloud signed out (iCloud unavailable)
- [ ] Verify all errors show user-friendly messages
- [ ] Verify errors don't crash the app

### Integration with Existing Features

#### Friend Code Display
- [ ] Verify "My Friend Code" card still shows correctly
- [ ] Verify copy button still works
- [ ] Verify share button still works

#### Board Updates
- [ ] Add a friend using either path
- [ ] Verify friend appears in "This Week" board
- [ ] Pull to refresh the board
- [ ] Verify friend's data updates

#### CloudKit Schema
- [ ] Verify existing friends still show up
- [ ] Verify existing UserProfile records still work
- [ ] Verify friendship records are still created correctly

## Contact Lookup Implementation Notes

The Contacts path works by:
1. User selects a contact via CNContactPickerViewController
2. App attempts lookup by email first (if available)
3. If email lookup fails, tries phone number (if available)
4. Both email and phone are normalized before CloudKit query
5. Email is lowercased, phone has non-digits removed
6. If found, friend is added using existing FriendsManager flow
7. If not found, shows helpful message suggesting invite code

## CloudKit Schema Requirements

For the Contacts path to work, UserProfile records need to include:
- `email` field (String, indexed) - optional
- `phone` field (String, indexed) - optional

These fields should be added to the CloudKit schema in the dashboard.

## Known Limitations

1. Contacts lookup requires users to have email/phone set in their EmberWatch profile
2. Users need to call `FriendsManager.updateMyContactInfo()` to populate their email/phone in CloudKit
3. The app doesn't automatically sync contact info yet (future enhancement)

## Testing Both Devices

### Device A Setup
1. [ ] Sign in with iCloud
2. [ ] Note your friend code (e.g., "ABC12345")
3. [ ] Optionally add email/phone to profile

### Device B Setup
1. [ ] Sign in with different iCloud account
2. [ ] Add Device A's user to contacts (if testing Contacts path)
3. [ ] Try adding Device A as friend using both paths

### Verify Bidirectional
- [ ] On Device A, verify Device B appears as friend
- [ ] On Device B, verify Device A appears as friend
- [ ] Verify both can see each other's weekly XP
- [ ] Verify board ranking updates correctly
