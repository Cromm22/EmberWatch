# EmberWatch RPG Spec

Source of truth for the game-layer overhaul. Implement in **three separate PRs**. Do not start a later phase until the previous PR has merged.

| Phase | Scope | This repo |
| --- | --- | --- |
| **1** | XP economy, 1–100 level curve, titles, currencies (XP / Coins / Crystals), daily quest, remove XP boosters | **This PR** |
| **2** | Builds onboarding, stats (STR END VIT AGI REC), `LVL N - BUILD` UI | Later agent |
| **3** | Character progression visuals, equipment slots/rarities, companions/evolution, shop pricing polish | Later agent |

XP is a **status currency**. It is earned only from real-world healthy behavior. It is never spent, never purchasable, and never boosted.

---

## Builds (Phase 2)

Chosen at onboarding. **“Choose your build”** replaces **“What are your fitness goals?”**.

| Build | Goal | Nutrition / training | Primary stats | Recommended |
| --- | --- | --- | --- | --- |
| **Warrior** | Muscle + athleticism | Moderate surplus | STR, VIT | Strength + conditioning, protein adherence, recovery |
| **Assassin** | Lean / athletic | Get lean, maintain muscle, high steps/cardio, calorie deficit | AGI, END | Calorie adherence, movement, conditioning, strength |
| **Tank** | Gain strength | Higher protein, heavy lifting, progressive overload, strength milestones | STR, VIT | Protein, recovery |
| **Ranger** | Endurance | Cardio-forward | END, AGI | Cardio, steps, recovery, nutrition |
| **Mage** | General health | Mobility, sleep/recovery, moderate training | All stats develop relatively evenly | Replaces the old “Balanced” build |

Phase 1 does **not** add build picker UI. Persist nothing new for builds until Phase 2.

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

A few named tiers. Phase 1 shows the title on Home (XP bar / subtitle). Phase 2 prefixes with build: `LVL 37 - WARRIOR`.

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
| END | Running / cardio |
| VIT | Nutrition consistency |
| AGI | Mobility / yoga / stretching |
| REC | Sleep / rest / recovery |

Build **primary stats** gain a bonus multiplier. Display like:

`LVL 37 - WARRIOR` with `STR 42  END 28  VIT 35  AGI 23  REC 31`

Phase 1 does not persist or show stats.

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

---

## Equipment (Phase 3)

Six slots: **Head, Chest, Hands, Legs, Feet, Accessory**.

Rarities: **Common, Uncommon, Rare, Epic, Legendary, Mythic**.

**Cosmetic only** — no stat or XP bonuses (no pay-to-win).

---

## Companions (Phase 3)

Chosen early in onboarding. The companion **is** the Ember the user levels.

Options: Baby dragon, Robot, Wolf, Slime, Phoenix, Cyber cat.

Evolution with consistency / level:

| Level | Stage |
| --- | --- |
| 1 | Tiny baby |
| 25 | Juvenile |
| 50 | Adult |
| 75 | Elite |
| 100 | Majestic final evolution |

---

## Celebration toasts (Phase 1)

Use the existing **bottom toast** chrome (`CelebrationToast`).

- XP gains include the **action name** (e.g. `Logged breakfast — +10 XP`).
- Multiple awards in one evaluate pass may be combined into one toast.
- Level-up still uses `LevelUpCelebrationView`.
- Currency toasts say **Coins** or **Crystals**, never Sparks.

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

### Intentionally removed in Phase 1

- Board rank XP multiplier (`+10/20/30% XP`) and Home **XP Boost** card
- XP for Active Energy / burned calories
- XP for rapid weight loss
- Per-glass water XP
- Daily-open XP every morning (replaced by 3-day / 7-day streak bonuses)
- Friend-challenge **XP** (challenges still earn **Coins**)
- Any copy that says XP can be boosted or bought
- UI string **Sparks** (wallet balance is now **Crystals**)

### Out of scope until later phases

- Build picker / replacing onboarding fitness goals
- Stat numbers and `LVL N - BUILD` chrome
- Equipment slots, rarities, companion evolution, prestige auras
- Sex-specific calorie floors (generic 1200 until profile sex exists)
