# UX Polish Testing Checklist

## Feature 1: Ember Grows with Level

### Visual Progression Test
- [ ] Level 1: Ember appears small (170pt) - baby-sized
- [ ] Level 5: Ember is noticeably larger
- [ ] Level 10: Clear size increase from level 1
- [ ] Level 25: Mid-sized Ember
- [ ] Level 50: Significantly larger
- [ ] Level 100: Maximum size (270pt), no overflow

### Animation Test
- [ ] Level up triggers smooth spring animation
- [ ] Ember size transition feels natural (0.6s spring)
- [ ] No jarring jumps or clipping during animation
- [ ] Layout adjusts correctly to new size

### Layout Test
- [ ] Avatar card accommodates all sizes without overflow
- [ ] Edit button stays positioned correctly
- [ ] Level label and badges remain properly aligned
- [ ] XP progress bar displays correctly below avatar
- [ ] No layout issues at level 1, 50, or 100

## Feature 2: Water Celebration Every Other Glass

### Celebration Cadence Test
- [ ] Glass 1: Logs quietly, no center celebration
- [ ] Glass 2: Shows full Ember talk celebration 🎉
- [ ] Glass 3: Logs quietly
- [ ] Glass 4: Shows celebration
- [ ] Glass 5: Logs quietly
- [ ] Glass 6: Shows celebration
- [ ] Glass 7: Logs quietly
- [ ] Glass 8: Shows celebration

### XP & Progress Test
- [ ] Every glass awards 5 XP (both odd and even)
- [ ] XP animation appears on all glasses
- [ ] Water progress updates correctly for all glasses
- [ ] oz/mL totals update on every glass
- [ ] Goal completion works correctly

### Edge Cases
- [ ] Removing glasses (tapping filled glass) works correctly
- [ ] Starting new day resets counter properly
- [ ] Water goal changes don't affect celebration logic
- [ ] Multiple rapid taps handled correctly

## Regression Testing

### Level-Up System
- [ ] Level-up splash screen still appears
- [ ] Level-up banner still shows
- [ ] Sparks award correctly on level-up
- [ ] Level progress bar updates correctly
- [ ] Multiple level-ups handled correctly

### Other Ember Talk Triggers
- [ ] Food logging still triggers talk
- [ ] Workout logging still triggers talk
- [ ] Greeting appears on first daily open
- [ ] Talk phrases vary correctly

### Visual Consistency
- [ ] Ember colors and styling unchanged
- [ ] Talk overlay animation unchanged
- [ ] All ember accessories display correctly (glow, circlet, horns)
- [ ] Blaze mode (level 5+) still works
- [ ] Avatar picker shows correct sizes
- [ ] Share view displays correctly

## Performance
- [ ] No lag when logging water rapidly
- [ ] Level-up animation smooth on device
- [ ] No memory issues with size calculations
- [ ] Scrolling performance unaffected

## Accessibility
- [ ] Ember size changes don't affect VoiceOver
- [ ] Water glass tap targets remain accessible
- [ ] Celebration dismissal works with assistive tech

## Notes
- Ember growth: Linear interpolation from 170pt (L1) to 270pt (L100)
- Water celebration: Even glasses only (2, 4, 6...) show center talk
- Both features maintain existing game mechanics (XP, progression, etc.)
