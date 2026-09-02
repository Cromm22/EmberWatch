# EmberWatch - Full Native iOS Fitness Tracker

A native iOS app built with SwiftUI that provides real-time HealthKit integration, barcode food scanning, water tracking, and calorie management with a leveling flame avatar. Designed to match the web demo at https://ember-teal-six.vercel.app with full feature parity.

## Features

### Five-Tab Navigation
1. **Home**: Ember flame avatar, level/XP, calories remaining, water tracking, and daily summary
2. **Food**: Barcode scanning, recents, meal logging with macros
3. **Workout**: HealthKit live workouts + quick-add options
4. **Board**: Weekly leaderboard with XP tracking
5. **Share**: Generate and share progress cards

### Real-time HealthKit Integration
- **Live Workout Tracking**: Uses HKObserverQuery and background delivery for instant updates when Watch workouts complete
- **Auto-refresh**: No manual sync required - calories update automatically
- **Today's Activity**: View total calories burned and all workouts from today
- **Authorization Flow**: Real-time authorization status with permission request

### Barcode Food Scanner
- **Open Food Facts First**: Scans barcodes and looks up nutritional data from Open Food Facts API
- **USDA Fallback**: Falls back to USDA database if not found in Open Food Facts
- **Serving Size Picker**: Confirm serving with multiplier chips (0.5×, 1×, 1.5×, 2×, 3×)
- **Smart Validation**: Rejects all-zero macros as database misses
- **Camera Permission**: Automatically requests camera access for barcode scanning

### Food Diary
- **Meal Logging**: Log meals with calories and macros (protein/carbs/fat)
- **Meal Types**: Breakfast, Lunch, Dinner, Snack
- **Recents**: Quick re-log of previously added meals (deduplicated by name+serving)
- **SwiftData Persistence**: All food entries saved locally with SwiftData
- **Quick Stats**: View daily totals for calories and macros

### Water Tracking
- **125 fl oz Default Goal**: Daily hydration goal defaults to 125 fl oz (cups still log 8 oz servings)
- **Dual Units**: Shows both fl oz and mL; goal stored in fl oz as source of truth
- **Ember Tumbler Icons**: Custom glass icons with ember/cream colors (cup count derived from goal ÷ 8)
- **Independent Tracking**: Water does NOT affect calorie calculations

### Workout Features
- **Real-time HealthKit Sync**: Automatic workout detection from Apple Watch
- **Quick-Add Workouts**: Six preset workout types in web-matching order:
  - Outdoor walk
  - Indoor walk
  - Functional strength training
  - Pool swim
  - High Intensity Interval training
  - Outdoor cycle
- **Manual Entry**: Log custom workouts by hand
- **Calories Burned**: All workouts contribute to daily calorie budget

### Calorie Management
- **Remaining Calories**: Real-time calculation (goal + exercise − food)
- **Eat-back Method**: Exercise adds to your budget
- **Customizable Goals**: Set your daily calorie target
- **Live Updates**: Remaining calories update as HealthKit and food logs change

### Ember Avatar & Leveling
- **Animated Flame**: Beautiful gradient flame avatar matching web design
- **XP System**: Earn experience and level up
- **Progress Bar**: Visual XP progress to next level
- **Board Competition**: See where you rank weekly

### Share Feature
- **Progress Cards**: Generate shareable images with avatar + stats
- **iOS Share Sheet**: Native UIActivityViewController integration
- **Today's Summary**: Includes goal, burned, eaten, and remaining calories

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Apple device with HealthKit capability
- Camera (for barcode scanning)
- Apple Watch (optional, for workout tracking)

## Permissions

The app requests:
- **Camera**: To scan food barcodes
- **HealthKit Read**: Workout samples and Active Energy Burned
- **HealthKit Write**: Health data updates (configured but not currently used)

## Project Structure

```
EmberWatch/
├── EmberWatch.xcodeproj/
│   └── project.pbxproj
└── EmberWatch/
    ├── Info.plist                  # Camera + HealthKit permissions
    ├── EmberWatchApp.swift         # App entry with SwiftData + managers
    ├── ContentView.swift           # Five-tab container
    ├── Views/
    │   ├── HomeView.swift          # Avatar, calories, water, summary
    │   ├── FoodDiaryView.swift     # Barcode scan, recents, meals
    │   ├── WorkoutsView.swift      # HealthKit + quick-adds
    │   ├── BoardView.swift         # Weekly leaderboard
    │   ├── ShareView.swift         # Progress card sharing
    │   ├── EmberFlameAvatar.swift  # Animated flame companion
    │   ├── BarcodeScannerView.swift # VisionKit/AVFoundation scanner
    │   └── ServingSizePickerView.swift # Multiplier picker
    ├── Models/
    │   ├── WorkoutModel.swift      # Workout data model
    │   └── FoodEntry.swift         # SwiftData food model
    ├── Managers/
    │   ├── HealthKitManager.swift  # HealthKit API + observers
    │   ├── FoodDataManager.swift   # SwiftData food + recents
    │   ├── CalorieGoalManager.swift # Goal + XP management
    │   └── WaterManager.swift      # Water tracking (125 fl oz default)
    ├── Services/
    │   └── FoodLookupService.swift # Open Food Facts + USDA APIs
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
   - Set your Personal Team
   - Bundle ID: `com.ember.watch`

3. **Run on Device**
   - Select your iPhone from the device menu
   - Press Cmd+R to build and run
   - Note: Camera and HealthKit require a physical device (not Simulator)

4. **Grant Permissions**
   - Camera: Required for barcode scanning
   - HealthKit: Grant access to Workouts and Active Energy
   - Complete a workout on Apple Watch to see real-time sync

## Using the App

### Scanning Food Barcodes
1. Go to Food tab
2. Tap "Scan barcode" button
3. Point camera at product barcode
4. App looks up Open Food Facts → USDA
5. If found, confirm serving size (use multiplier chips)
6. Item added to diary and recents

### Tracking Water
1. Home tab shows cup tracker sized to the fl oz goal (default 125)
2. Tap cups to log 8 fl oz servings
3. See fl oz and mL totals
4. Water does NOT affect calorie remaining

### Quick-Add Workouts
1. Go to Workout tab
2. Tap "Log Workout" button
3. Select from 6 preset workout types
4. Or use + to add custom workout
5. Calories burned add to remaining budget

### Viewing Progress
1. Board tab shows weekly leaderboard
2. Share tab generates progress card
3. Tap share button to open iOS share sheet
4. Share via Messages, social media, etc.

## Color Scheme

The app matches the web demo color palette:
- **Dusk**: `#100814` - Main background
- **Cream**: `#fff1dc` - Primary text
- **Ember**: `#ff7a3c` - Primary accent/CTA
- **Ember Accent**: `#f97316` - Secondary accent
- **Gold**: `#ffd27a` - Medals/highlights
- **Light Plum**: `#1a0d22` - Cards/surfaces
- **Plum**: `#3a1848` - Secondary surfaces

## Data Persistence

- **Food Entries**: SwiftData model stored locally
- **Recents**: Last 7 days, deduplicated by name+serving (max 5)
- **Water**: UserDefaults per-day tracking
- **Calorie Goal**: UserDefaults (survives restarts)
- **XP & Level**: UserDefaults (ready for cloud sync)
- **Workouts**: Read-only from HealthKit (not stored locally)

## API Integration

### Open Food Facts
- **Endpoint**: `https://world.openfoodfacts.org/api/v2/product/{barcode}.json`
- **First Priority**: Checked before USDA
- **Returns**: Product name, serving size, macros per 100g

### USDA FoodData Central
- **Endpoint**: `https://api.nal.usda.gov/fdc/v1/foods/search`
- **Fallback**: Used if Open Food Facts returns no valid data
- **API Key**: Currently using DEMO_KEY (replace for production)

## Known Limitations

- No backend accounts (local-only data)
- USDA uses DEMO_KEY (rate limited)
- XP earning is stubbed (no automatic gain from workouts yet)
- Board leaderboard uses mock data
- Quick-add workouts don't save to HealthKit yet

## Next Steps

- [ ] Backend integration for accounts and cloud sync
- [ ] Automatic XP earning from completing workouts
- [ ] Save quick-add workouts to HealthKit
- [ ] Real leaderboard with multiplayer
- [ ] Production USDA API key
- [ ] Additional food databases (e.g., Nutritionix)
- [ ] Meal photo recognition
- [ ] WatchOS companion app

## Live Web Demo

Compare native experience with the web version: https://ember-teal-six.vercel.app

The native iOS app provides full feature parity plus real-time HealthKit integration!
