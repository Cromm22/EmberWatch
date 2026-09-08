# Board Challenge Button Fix - Summary

## Issue
The Challenge button on Board friend rows was getting stuck showing "Sent" (grayed out, disabled) instead of "Challenge" after being tapped once, even when there was no real pending CloudKit challenge.

## Root Cause
- The `canChallenge` flag was based on a local `challengeAwards` dictionary that tracked whether you'd challenged a friend today
- This was intended to prevent XP spam (once per friend per day)
- However, it also changed the UI to show "Sent" and disabled the button for the rest of the day
- Since PR #45's CloudKit challenge sync was never fully implemented (no `sendChallenge`, `fetchReceivedChallenges`, or `acceptChallenge` methods exist), there was no real "pending" state to track

## Solution
**Always show "Challenge" button** (active, tappable) regardless of whether the user has challenged that friend today.

The once-per-day XP limit is still enforced in `LevelManager.awardChallenge()`:
- First tap of day → awards XP/Sparks
- Subsequent taps today → returns 0 XP (silent no-op)

## Code Changes
### BoardView.swift

1. **Removed `canChallenge` parameter** from `LeaderboardRow` struct
2. **Removed conditional logic** from button label and styling
3. **Always show "Challenge"** text
4. **Always enable button** (removed `.disabled()` modifier)
5. **Always use active styling** (ember color, not grayed dusk)

## Testing
### Before Fix
- User taps Challenge → button changes to "Sent" (gray, disabled)
- Button stays "Sent" for rest of day
- User cannot tap again until next day
- **Bug:** Shows "Sent" even when there's no real pending challenge

### After Fix
- User taps Challenge → button stays "Challenge" (ember color, enabled)
- User can tap multiple times
- First tap awards XP/Sparks
- Subsequent taps today award 0 XP silently
- **Fixed:** Always shows "Challenge" as requested

## Future Work
When real CloudKit challenge sync is implemented, the button can be updated to show:
- **"Challenge"** (default) - no pending challenge
- **"Pending"** (temporary) - active CloudKit Challenge record with `status: "pending"`
- Return to **"Challenge"** when challenge is accepted/declined/expired

For now, with no CloudKit challenge system, "Challenge" is always correct.

## Commit
SHA: c8a7a40
Branch: cursor/fix-board-challenge-stuck-sent-42e2
PR: #46
