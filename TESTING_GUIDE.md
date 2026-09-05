# EmberWatch Food Search Testing Guide

## Quick Start Testing

### 1. Basic Brand Search (Core Fix)

**Test the "mcdonalds" issue from the screenshot:**
```
1. Open EmberWatch
2. Tap "Add Food" → Search Foods
3. Type "mcdonalds"
4. ✅ EXPECTED: McDonald's items dominate (Big Mac, McNuggets, etc.)
5. ❌ NOT EXPECTED: Apple Juice, Minute Maid, random drinks
```

**Test other chains:**
- Search "chipotle" → Should show Chipotle Burrito Bowl, etc.
- Search "starbucks" → Should show Starbucks drinks/food
- Search "subway" → Should show Subway sandwiches

### 2. Search History

**Test history appears:**
```
1. Search "mcdonalds"
2. Tap X to clear field
3. ✅ EXPECTED: History shows "mcdonalds" with timestamp
4. Search "chipotle"
5. Clear field again
6. ✅ EXPECTED: Both searches visible, "chipotle" at top
```

**Test history tap:**
```
1. Tap a history item
2. ✅ EXPECTED: Query re-runs immediately
```

**Test clear history:**
```
1. Tap "Clear" button in history
2. ✅ EXPECTED: All history disappears
```

### 3. Nutritionix (Optional - Requires API Keys)

**To enable Nutritionix:**
1. Get free API keys from https://www.nutritionix.com/business/api
2. Edit `EmberWatch/Info.plist`:
   ```xml
   <key>NUTRITIONIX_APP_ID</key>
   <string>YOUR_APP_ID_HERE</string>
   <key>NUTRITIONIX_API_KEY</key>
   <string>YOUR_API_KEY_HERE</string>
   ```
3. Rebuild and run

**Test with Nutritionix:**
- Search "chipotle bowl" → More detailed restaurant items
- Search "kraft mac and cheese" → Branded packaged foods

**Test without Nutritionix (default):**
- Leave keys empty in Info.plist
- ✅ EXPECTED: Search still works, uses curated + OFF + USDA

### 4. Regression Testing

**Barcode scan still works:**
```
1. Tap "Add Food" → Scan button
2. Scan any food barcode
3. ✅ EXPECTED: Product loads, serving sheet appears
```

**Serving picker still works:**
```
1. Search for any food
2. Tap a result
3. ✅ EXPECTED: FoodServingSheet opens
4. Adjust serving size
5. ✅ EXPECTED: Nutrition scales correctly
6. Tap "Add to Diary"
7. ✅ EXPECTED: Food appears in diary
```

**Speed & cancellation:**
```
1. Type "mc" quickly
2. Immediately type "chi"
3. ✅ EXPECTED: No hang, only "chi" results appear
```

## Expected Results Summary

### ✅ Search "mcdonalds"
- **Top results:** Big Mac, Quarter Pounder, McNuggets, Fries, McChicken
- **Source:** Curated seed (instant)
- **No Apple Juice or unrelated items**

### ✅ Search "chipotle"
- **Top results:** Burrito Bowl, Steak Burrito, Chicken Burrito, Tacos
- **Source:** Curated seed + Nutritionix (if enabled)

### ✅ Search "starbucks"
- **Top results:** Pike Place, Latte, Breakfast Sandwich
- **Source:** Curated seed + Nutritionix (if enabled)

### ✅ Search "banana" (generic food)
- **Results:** Various banana products from OFF/USDA
- **Behavior:** No brand filtering, normal text search

### ✅ Search history
- **Appears when:** Search field is empty
- **Shows:** Last 20 searches (48 hours)
- **Actions:** Tap to re-run, Clear to remove all

## Known Limitations

1. **Curated seed is limited:** Only 6 major chains (McDonald's, Chipotle, Starbucks, Wendy's, Taco Bell, Subway) with ~5 items each. Other chains fall back to Nutritionix/OFF.

2. **Nutritionix requires keys:** Without API keys, search relies on curated seed + improved OFF ranking. Still much better than before, but fewer restaurant options.

3. **OFF data quality varies:** Some products may have incomplete brand data. The ranking logic handles this gracefully but can't fix missing data.

4. **Search history is local:** Stored in UserDefaults, not synced across devices.

## Troubleshooting

**Issue:** Search feels slow
- **Check:** Network connection
- **Fix:** The code already caps results and cancels stale requests. Slow search is likely network latency.

**Issue:** "mcdonalds" still shows unrelated items
- **Check:** Are curated items appearing first? (They should)
- **Check:** Is Nutritionix enabled? (Optional but helps)
- **Possible cause:** OFF data quality improved but not perfect

**Issue:** Search history not appearing
- **Check:** Have you performed at least one search?
- **Check:** Is search field empty? (History only shows when empty)
- **Check:** Are searches older than 48 hours? (Auto-cleaned)

**Issue:** App won't build
- **Check:** Did you add non-empty Nutritionix keys? If so, ensure they're valid strings (not required to be real API keys for compilation)
- **Check:** Xcode version (requires Swift 5.5+ for async/await)

## Manual Test Checklist

Copy this checklist for testing:

- [ ] Search "mcdonalds" → McDonald's items appear, no Apple Juice
- [ ] Search "chipotle" → Chipotle items appear
- [ ] Search "starbucks" → Starbucks items appear
- [ ] Search history appears when field is empty
- [ ] Tapping history item re-runs search
- [ ] "Clear" button removes all history
- [ ] Barcode scan still works
- [ ] Serving picker still works
- [ ] Food logs to diary successfully
- [ ] Rapid typing doesn't hang UI
- [ ] Nutritionix fallback works (leave keys empty, search still succeeds)
- [ ] No crashes or errors

## Performance Metrics

**Expected behavior:**
- Search typing debounce: 300ms
- Network timeout: 12s request, 18s total
- Max results: 20 items
- Curated results: Instant (no network)
- History load: <10ms (UserDefaults)

## Success Criteria Met

✅ **Accuracy:** "mcdonalds" search no longer returns unrelated Apple Juice  
✅ **Speed:** Cancellation, off-main work, result caps  
✅ **Coverage:** Nutritionix wired + curated seed + improved OFF ranking  
✅ **History:** 2-day search history with persistence  

## Next Steps After Testing

If all tests pass:
1. Mark PR as ready for review (remove draft status)
2. Request code review
3. Merge to main when approved

If issues found:
1. Document failing test cases
2. Create follow-up issue or fix in this PR
3. Re-test after fixes
