# EmberWatch RPG Spec

Source of truth for the game-layer overhaul. Implement in **three separate PRs**. Do not start a later phase until the previous PR has merged.

| Phase | Scope | This repo |
| --- | --- | --- |
| **1** | XP economy, 1–100 level curve, titles, currencies (XP / Coins / Crystals), daily quest, remove XP boosters | **Merged** (PR #81) |
| **2** | Builds onboarding, stats (STR END VIT AGI REC), `LVL N — BUILD` UI | **Merged** (PR #82) |
| **3** | Character progression visuals, equipment slots/rarities, companions/evolution, shop pricing polish | **This PR** |

XP is a **status currency**. It is earned only from real-world healthy behavior. It is never spent, never purchasable, and never boosted.

---

## Frozen tracking surfaces (all phases)

Nutrition tracking, exercise / workout logging, and food search stay **exactly as they are** (UI, flows, data, behavior) across Phases 1–3.

That includes Food Diary, food search, barcode, serving/amount pickers, voice food/workout entry, Quick Add, workout edit, and HealthKit sync (`fetchTodayWorkouts`, Active Energy, Exercise minutes, observers). **Do not** restyle, reflow, rename, or change models for those screens.

RPG code may only **observe** a successful log:

- Read-only listeners on already-published state (e.g. Home / `ContentView` watching today’s food entries or workout IDs).
- A single call **after** a successful log returns (same pattern as the old `awardWorkout(id:)` hook), without changing what was saved.

Do **not** inject extra environment objects, `onAppear` fetches, or new `onChange` handlers into Food Diary, food search, serving pickers, or the Workout tab beyond replacing that post-log XP call. Do **not** change SwiftData / `FoodEntry` / `WorkoutData` / `FoodDataManager` / `HealthKitManager` for the game layer.

Builds, stats, and companion/equipment work (Phases 2–3) must not violate this. If a later phase needs a new signal, add an observer at the call site of an existing successful log — never by editing those tracking UIs.

---

## Builds (Phase 2)

Chosen at onboarding. **“Choose your build”** is a card-style picker (icon, goal line, primary-stat chips, recommended behaviors).

| Build | Goal | Nutrition / training | Primary stats | Recommended |
| --- | --- | --- | --- | --- |
| **Warrior** | Muscle + athleticism | Moderate surplus | STR, VIT | Strength + conditioning, protein adherence, recovery |
| **Assassin** | Lean / athletic | Get lean, maintain muscle, high steps/cardio, calorie deficit | AGI, END | Calorie adherence, movement, conditioning, strength |
| **Tank** | Gain strength | Higher protein, heavy lifting, progressive overload, strength milestones | STR, VIT | Protein, recovery |
| **Ranger** | Endurance | Cardio-forward | END, AGI | Cardio, steps, recovery, nutrition |
| **Mage** | General health | Mobility, sleep/recovery, moderate training | All stats develop relatively evenly | Replaces the old “Balanced” build |

- **New users** pick a build during onboarding (required to continue).
- **Existing users** with no build see a **non-blocking sheet** on the next launch (can dismiss with Later; it returns next launch until completed).
- Users can **change build later** from Profile and Goals. Changing build does **not** reset XP, level, or earned stats.
- Selection is persisted in UserDefaults (`characterManager.build`).
- CloudKit `UserProfile.build` is **optional**. Core profile save still writes name / avatar / XP / level first; `build` is a second save that is ignored if the schema does not have the field.

---

## Levels 1–100

- Player is **Level 1 immediately** (0 lifetime XP).
- Cap at **100**. Extra XP past the L100 threshold is overflow only; it does not create L101.
- Early levels are fast; later levels need much more consistency.
- **L100 must feel prestigious.** Title at 100 is **IRON LEGEND**.

### Calibration

Assume a typical active user earns **~350 XP/day**:

| Level | Approx. day | Lifetime XP to *reach* this level |
| --- | --- | --- |
| 10 | day 4 | 1,400 |
| 20 | day 14 | 4,900 |
| 40 | day 60 | 21,000 |
| 60 | day 150 | 52,500 |
| 80 | day 270 | 94,500 |
| 100 | day 400 (~13 months of consistency) | 140,000 |

The per-level table in `XPRules` is generated from these checkpoints, is **strictly increasing**, and is asserted monotonic at load.

### Level titles

A few named tiers. Phase 1 showed the title on Home (XP bar / subtitle). Phase 2 prefixes with build: `LVL 37 — WARRIOR`. The named title lives on the Character sheet.

| Levels | Title |
| --- | --- |
| 1–9 | Ember Spark |
| 10–19 | Kindling |
| 20–29 | Emberling |
| 30–39 | Flamebearer |
| 40–49 | Blaze Adept |
| 50–59 | Inferno Knight |
| 60–69 | Ash Champion |
| 70–79 | Ember Lord |
| 80–89 | Phoenix Guard |
| 90–99 | Mythic Flame |
| **100** | **IRON LEGEND** |

### Existing-user migration (Phase 1)

- **Keep total lifetime XP.** Do not reset to 0.
- Recompute displayed level from the new curve.
- Do not crash if XP is huge; clamp level at 100.
- CloudKit friends/leaderboard already publish `totalXP` + `level`. Keep publishing those fields with the new derived level. No CloudKit schema change.

---

## XP economy

### What awards XP (idempotent per local calendar day per action)

| Action | XP | Notes |
| --- | --- | --- |
| Log breakfast | +10 | At least one Breakfast entry that day |
| Log lunch | +10 | At least one Lunch entry |
| Log dinner | +10 | At least one Dinner entry |
| Complete nutrition logging for the day | +25 | Breakfast + lunch + dinner all present |
| Hit protein target range | +40 | Protein within range of the user’s protein goal |
| Stay within calorie target range | +40 | Calories within range **and** safety rules pass |
| Complete planned workout | +100 | Max **1–2** awards per day (see exercise cap) |
| Hit movement goal | +40 | Workout-minutes goal if enabled; else ~30 Exercise minutes |
| Recovery goal | +25 | Water goal met (sleep/recovery hook; Phase 2 can add sleep) |
| Daily quest | +50 | One rotating quest per day |
| 3-day streak | +50 | Once per streak run when count reaches 3 |
| 7-day streak | +100 | Once per streak run when count reaches 7 |

Typical active user: **250–400 XP/day**.

### Ranges (adherence, not extremes)

- **Calories:** within **-10% … +5%** of the calorie goal (i.e. 90%–105%).
- **Protein:** within **90%–120%** of the protein goal.
- Calorie-range XP also requires all three meals logged (no “skip dinner and still get calorie XP”).

### Safety — no XP for

- Eating dramatically under calories: **&lt; 75% of target**, **or** below a safe floor (**~1200 generic**; **1200 F / 1500 M** when sex is known — Phase 2+).
- Rapid weight loss / weigh-in “pounds lost” bonuses (removed in Phase 1).
- Extreme workouts: duration **&gt; 180 minutes** or **&gt; 1500 kcal** on a single session.
- Skipping meals (no meal XP, no complete-nutrition XP, no calorie-range XP).
- Burning Active Energy as a raw XP faucet (removed in Phase 1 — it enabled power-leveling).
- Per-glass water XP (replaced by a once-per-day recovery goal).

### Daily exercise cap

- Workout XP at most **twice per day** (+100 each).
- Exercise-derived XP cap **~200/day**.
- No power-leveling with 15 Quick Adds. Extra workouts do not grant XP.

### Ledger

Persist a **per-day XP ledger** (UserDefaults JSON keyed by `yyyy-MM-dd`):

- Action id → XP currently counted for that action.
- Awarded workout IDs for the day (max 2).

Re-logging or editing the same meal must **not** double-award. If the day’s food/water/workout data changes, **recompute** that day’s food/recovery/movement/quest rows and claw back or grant the delta (total XP never goes below 0).

XP is **never multiplied**. Rank on the Board does not boost XP. There are no XP boosters, XP bonus cards, or paid XP packs.

---

## Stats (Phase 2)

| Stat | Fed by |
| --- | --- |
| STR | Strength workouts |
| END | Running / cardio / movement goal (steps proxy — step count is not a HealthKit read) |
| VIT | Nutrition consistency (all meals logged + calorie and protein in range) |
| AGI | Mobility / yoga / stretching |
| REC | Recovery goal (water), rest days, recovery-type workouts. HealthKit sleep is **not** already read, so Phase 2 does not add a sleep permission |

- Same **safety** as XP: no stat gains from extreme deficits, extreme workouts, or skipped meals (VIT requires all three meals and a non-extreme intake).
- **Daily cap** per stat after the build multiplier (`StatRules.dailyCap` ≈ 0.70). Growth is slow so a typical L37 lands around **20–45** per stat.
- Build **primary stats** get **1.5×**. **Mage** grows all stats at **1.0×** (evenly).
- Existing users are **backfilled** once: level-based baseline, raised by recent food-history VIT when `FoodDataManager.entries(from:to:)` has data. New L1 users start at the floor (5).
- Changing build does not rewind earned stats; the multiplier applies going forward.
- Display: Home compact panel (`STR` / value / small bar; primaries highlighted). Tap opens the Character sheet (stats, build, recommended behaviors, level title, XP to next level).

`LVL 37 — WARRIOR` with `STR 42  END 28  VIT 35  AGI 23  REC 31`

---

## Three currencies

### 1. XP (status)

- Earned from the table above.
- Never spent, never purchased, no boosters.

### 2. Coins (gameplay economy)

Earned by playing; users can earn plenty:

- Daily quest completion
- 3-day and 7-day streak milestones
- Each level-up: **+50 Coins × level tier** (tier = `ceil(level / 10)`, so L1–10 → 50, L11–20 → 100, …)
- Friend challenges and board #1 (gameplay, not XP)
- Achievements / squad quests when those exist

Spent on **standard** cosmetics: avatar styles, later standard equipment, profile backgrounds, basic companions, emotes, themes, character effects.

### 3. Crystals (premium)

Formerly **Sparks**. Phase 1 **renames Sparks → Crystals in all UI**. Stored Sparks balance migrates **1:1** (same UserDefaults key).

- **Purchased** (StoreKit consumables, product IDs follow `com.ember.watch.crystals.*`):

  | Pack | Crystals | Price |
  | --- | --- | --- |
  | Crystal Cache | 500 | $4.99 |
  | Crystal Vault | 1,100 | $9.99 |
  | Crystal Crown | 2,400 | $19.99 |

- Occasionally awarded for **major level milestones** (L20 / L40 / L60 / L80 / L100).
- Cosmetics only. **Never** buy health progress, levels, workouts, or XP boosters.

### Home badge row (Phase 1)

`Daily Streak | Crystals | Coins`

- Coins card: gold coin icon, grouped value (e.g. `1,250`), label `Coins`, pastel yellow fill (same card chrome as the Home stat row).
- Remove the **XP Boost / XP Bonus** third card and every XP multiplier.

### Shop (Phase 1)

- Standard avatar styles: **Coins**.
- Premium cosmetics (glow, nameplates, later prestige skins): **Crystals**.
- Buying never credits currency unless StoreKit verifies the transaction.

---

## Daily quest (Phase 1)

One rotating healthy quest per local calendar day. Examples:

- Hit your protein range
- Log all 3 meals
- Hit movement goal
- Stay in calorie range
- Hit your recovery goal

Reward: **+50 XP** and **Coins** (see `XPRules`). Idempotent. Shown on Home. Completion uses the same ledger as other daily XP.

---

## Character progression visuals (Phase 3)

| Level | Look |
| --- | --- |
| 1 | Basic clothes / basic armor / no effects |
| 20 | Better equipment |
| 40 | Epic gear |
| 60 | Animated items |
| 80 | Prestige armor |
| 100 | Unique aura / title / effect (**IRON LEGEND**) |

Drawn as gear overlays / aura on the companion. The named title (including **IRON LEGEND**) stays on the Character sheet.

---

## Equipment (Phase 3)

Six slots: **Head, Chest, Hands, Legs, Feet, Accessory**.

Rarities: **Common, Uncommon, Rare, Epic, Legendary, Mythic** (gray, green, blue, purple, orange, red/pink).

**Cosmetic only** — no stat, XP, or health bonuses (no pay-to-win).

Catalog: ~7–8 items per slot. Some grant free at L1 / L20 / L40 / L60 / L80 / L100; others are buyable with Coins or Crystals. Equipment screen is opened from the Character sheet and Ember Shop.

---

## Companions (Phase 3)

Chosen early in onboarding **after build**. The companion **is** the Ember the user levels and is shown on Home in place of the old flame avatar.

Options: Baby Dragon, Robot, Wolf, Slime, Phoenix, Cyber Cat.

- **New users** pick a species during onboarding (required to continue).
- **Existing users** with no species see a **non-blocking sheet** (Later dismisses it; returns next launch). Current flame style maps to the closest species; they can still choose another.
- Rename from the Character sheet (uses the existing Ember name).
- Evolution celebration toast when crossing a stage threshold. Existing users already past a stage are seeded quietly so they are not spammed.

Evolution with consistency / level:

| Level | Stage |
| --- | --- |
| 1 | Tiny baby |
| 25 | Juvenile |
| 50 | Adult |
| 75 | Elite |
| 100 | Majestic final evolution |

Each species/stage is SwiftUI vector art (shapes, gradients, SF Symbols) in the existing Ember glow / cute-face style. Later stages are larger and add horns, wings, antennae, and elite/final auras.

CloudKit `UserProfile.companion` is **optional** (species raw value). Stage is derived from the already-published level. Written as a second save after core fields + `build`, ignored if the schema does not have the field. Board shows a species + stage icon when present.

---

## Celebration toasts (Phase 1)

Use the existing **bottom toast** chrome (`CelebrationToast`).

- XP gains include the **action name** (e.g. `Logged breakfast — +10 XP`).
- Multiple awards in one evaluate pass may be combined into one toast.
- Level-up still uses `LevelUpCelebrationView`.
- Currency toasts say **Coins** or **Crystals**, never Sparks.

---

## Phase 2 implementation map

| Piece | Where |
| --- | --- |
| Build catalog (goal, icons, primary stats, recommended) | `EmberWatch/Managers/RPGBuild.swift` |
| Stat rules, workout family, daily evaluate, daily caps | `EmberWatch/Managers/StatEngine.swift` |
| Persist build + stats + daily ledger + one-time backfill | `EmberWatch/Managers/CharacterManager.swift` |
| Card picker (onboarding, sheet, Goals, Profile) | `EmberWatch/Views/BuildPickerView.swift` |
| Home `LVL N — BUILD` + compact bars + Character sheet | `EmberWatch/Views/CharacterSheetView.swift`, `HomeView.swift` |
| Existing-user non-blocking sheet | `ContentView` (`BuildChoiceSheet`, once per launch until chosen) |
| Change build later | `GoalsView`, `ProfileSettingsView` |
| Optional CloudKit `build` + Board subtitle | `FriendsManager`, `BoardView` |
| Food / workout / search screens | **Unchanged** — stats observe Home / `ContentView` the same way XP does |

Phase 2 does **not** edit Food Diary, food search, serving pickers, the Workout tab, `FoodEntry`, `WorkoutData`, `FoodDataManager`, or `HealthKitManager`.

---

## Phase 1 implementation map

| Piece | Where |
| --- | --- |
| Curve, titles, XP amounts, safety, quest rotation, coin/crystal constants | `EmberWatch/Managers/XPRules.swift` |
| Ledger + idempotent evaluate / revoke | `EmberWatch/Managers/XPEngine.swift` |
| Persistence, streak, toasts, CloudKit-facing level | `EmberWatch/Managers/LevelManager.swift` |
| Crystals + Coins wallet, IAP packs, shop prices | `EmberWatch/Managers/SparksManager.swift` (class name kept; UI says Crystals) |
| StoreKit | `EmberWatch/Managers/SparksShopStore.swift` |
| Home badges, daily quest card | `EmberWatch/Views/HomeStatBadges.swift`, `HomeView.swift` |
| Workout XP hook (post-log only) | `LevelManager.observeWorkouts` after existing Quick Add / HealthKit list updates |
| Food XP hook | Home / `ContentView` observers on already-published `FoodDataManager` totals — **Food Diary is unmodified** |

### Intentionally removed in Phase 1

- Board rank XP multiplier (`+10/20/30% XP`) and Home **XP Boost** card
- XP for Active Energy / burned calories
- XP for rapid weight loss
- Per-glass water XP
- Daily-open XP every morning (replaced by 3-day / 7-day streak bonuses)
- Friend-challenge **XP** (challenges still earn **Coins**)
- Any copy that says XP can be boosted or bought
- UI string **Sparks** (wallet balance is now **Crystals**)

## Phase 3 implementation map

| Piece | Where |
| --- | --- |
| Species, stages, progression tiers | `EmberWatch/Managers/CompanionSpecies.swift` |
| Equipment slots, rarities, catalog | `EmberWatch/Managers/EquipmentCatalog.swift` |
| Shop backgrounds / emotes / themes / effects / premium | `EmberWatch/Managers/ShopCatalog.swift` |
| Persist species, loadout, ownership, evolution | `EmberWatch/Managers/CompanionManager.swift` |
| Vector companion + gear overlays | `CompanionAvatarView`, `CompanionCreatureArt`, `CompanionGearOverlay` |
| Onboarding + existing-user picker | `CompanionPickerView`, `OnboardingView`, `ContentView` |
| Equipment inventory | `EquipmentView` (Character sheet + Ember Shop) |
| Restructured Avatar Gallery | `AvatarPickerView` (now Ember Shop) + Crystal packs in `SparksShopView` |
| Evolution toast | `EvolutionCelebrationView` |
| Optional CloudKit `companion` + Board icon | `FriendsManager`, `BoardView` |
| Food / workout / search screens | **Unchanged** |

Phase 3 does **not** edit Food Diary, food search, serving pickers, the Workout tab, `FoodEntry`, `WorkoutData`, `FoodDataManager`, or `HealthKitManager`.

### Out of scope

- Sex-specific calorie floors (generic 1200 until profile sex exists)
- HealthKit sleep permission (not already read; REC uses water + rest days)
