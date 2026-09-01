# EmberWatch - Full Native iOS Fitness Tracker

A native iOS app built with SwiftUI that provides real-time HealthKit integration, food tracking, and calorie management with a leveling flame avatar.

## Features

### Real-time HealthKit Integration
- **Live Workout Tracking**: Uses HKObserverQuery and background delivery for instant updates when Watch workouts complete
- **Auto-refresh**: No manual "Send to Ember" Safari hop required - calories update automatically
- **Today's Activity**: View total calories burned and all workouts from today
- **Authorization Flow**: Real-time authorization status (authorized/denied/not determined) with permission request

### Food Diary
- **Meal Logging**: Log meals with calories and macros (protein/carbs/fat)
- **Meal Types**: Breakfast, Lunch, Dinner, Snack
- **SwiftData Persistence**: All food entries saved locally with SwiftData
- **Quick Stats**: View daily totals for calories and macros

### Calorie Management
- **Remaining Calories**: Real-time calculation (goal + exercise - food)
- **Customizable Goals**: Set your daily calorie target
- **Live Updates**: Remaining calories update as HealthKit and food logs change

### Ember Avatar & Leveling
- **Animated Flame**: Beautiful gradient flame avatar on home screen
- **XP System**: Earn experience and level up (stubs ready for gamification)
- **Progress Bar**: Visual XP progress to next level

### Four-Tab Interface
1. **Home**: Ember avatar, level/XP, remaining calories, and daily summary
2. **Food**: Log meals, view macros, track consumption
3. **Workouts**: Detailed workout list with calories and duration
4. **Health**: HealthKit authorization management

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Apple device with HealthKit capability
- Apple Watch (optional, for workout tracking)

## Project Structure

```
EmberWatch/
├── EmberWatch.xcodeproj/
│   └── project.pbxproj
└── EmberWatch/
    ├── EmberWatch.entitlements     # HealthKit entitlement
    ├── Info.plist                  # Usage descriptions
    ├── EmberWatchApp.swift         # App entry point with SwiftData setup
    ├── ContentView.swift           # Four-tab container
    ├── Views/
    │   ├── HomeView.swift          # Ember avatar + calorie summary
    │   ├── FoodDiaryView.swift     # Food logging interface
    │   ├── WorkoutsView.swift      # Detailed workouts list
    │   └── HealthConnectView.swift # Authorization management
    ├── Models/
    │   ├── WorkoutModel.swift      # Workout data model
    │   └── FoodEntry.swift         # SwiftData food model
    ├── Managers/
    │   ├── HealthKitManager.swift  # HealthKit API + observers
    │   ├── FoodDataManager.swift   # SwiftData food operations
    │   └── CalorieGoalManager.swift # Goal + XP management
    └── Assets.xcassets/
```

## Building & Running

1. **Open Project**
   ```bash
   open EmberWatch.xcodeproj
   ```

2. **Set Development Team**
   - Select the EmberWatch project in Xcode
   - Go to Signing & Capabilities
   - Set your development team (currently configured for Personal Team RQWCD638WP)
   - Bundle ID: `com.ember.watch`

3. **Run on Device**
   - Select your iPhone from the device menu
   - Press Cmd+R to build and run
   - Note: HealthKit data is not available in Simulator

4. **First Launch**
   - App will request HealthKit permissions
   - Grant access to Workouts and Active Energy
   - Complete a workout on your Apple Watch
   - Watch the app automatically update when workout syncs!

## HealthKit Permissions

The app requests read access for:
- Workout samples (`HKWorkoutType`)
- Active Energy Burned (`HKQuantityTypeIdentifier.activeEnergyBurned`)

Real-time updates use:
- `HKObserverQuery` for change notifications
- Background delivery with `.immediate` frequency
- Anchored queries for efficient data fetching

## Testing the Real-time Feature

1. **Launch the app** and grant HealthKit permissions
2. **Start a workout** on your Apple Watch (e.g., Outdoor Walk)
3. **Complete the workout** and let it sync to Health
4. **Switch to the app** - calories should update automatically without any manual action
5. **Add a meal** in the Food tab and watch remaining calories update instantly

## Data Persistence

- **Food Entries**: SwiftData model stored locally on device
- **Calorie Goal**: UserDefaults (survives app restarts)
- **XP & Level**: UserDefaults (ready for cloud sync later)
- **Workouts**: Read-only from HealthKit (not stored locally)

## Known Limitations

- No backend accounts yet (local-only)
- No barcode scanning for food (manual entry only)
- No WatchOS companion target (iPhone reads Watch via HealthKit)
- XP system is stubbed (no actual earning logic yet)

## Ember Color Scheme

- **Dark Plum**: `Color(red: 0.3, green: 0.2, blue: 0.35)` - Main background
- **Cream**: `Color(red: 0.98, green: 0.95, blue: 0.9)` - Primary text
- **Flame**: `Color(red: 1.0, green: 0.45, blue: 0.2)` - Accent/CTA
- **Light Plum**: `Color(red: 0.4, green: 0.3, blue: 0.45)` - Cards

## Next Steps

- [ ] Add barcode scanning for food items
- [ ] Implement XP earning logic (e.g., 10 XP per workout)
- [ ] Add workout type filtering
- [ ] Export/import food diary
- [ ] Add water tracking
- [ ] Integrate with Ember web backend for multiplayer
- [ ] WatchOS companion app

## Live Web Demo

The web version is still available at: https://ember-teal-six.vercel.app

However, this native iOS app provides the full real-time experience without needing to open Safari!
