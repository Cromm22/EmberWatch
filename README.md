# EmberWatch - Apple Watch Companion
 
A native iOS app built with SwiftUI that connects to HealthKit to sync Apple Watch workout data.

## Features

- **HealthKit Integration**: Real authorization flow for reading workout data and active energy burned
- **Today's Activity**: View total calories burned and all workouts from today
- **Workout Details**: Each workout shows duration, calories burned, and start time
- **Health Connect Screen**: Real-time authorization status (authorized/denied/not determined) with permission request button
- **Ember Color Scheme**: Dark plum, cream, orange flame theme

## Supported Workout Types

The app maps HealthKit workout types to friendly names:
- Outdoor Walk / Indoor Walk
- Outdoor Cycle
- Pool Swim
- Functional Strength Training
- High Intensity Interval Training
- And other HealthKit workout types with their default names

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Apple device with HealthKit capability (not available in Simulator for real data)

## Project Structure

```
EmberWatch/
├── EmberWatch.xcodeproj/
│   └── project.pbxproj
└── EmberWatch/
    ├── EmberWatch.entitlements     # HealthKit entitlement
    ├── Info.plist                  # Usage descriptions
    ├── EmberWatchApp.swift         # App entry point
    ├── ContentView.swift           # Tab view container
    ├── Views/
    │   ├── HomeView.swift          # Today's workouts and calories
    │   └── HealthConnectView.swift # Authorization management
    ├── Models/
    │   └── WorkoutModel.swift      # Workout data model
    ├── Managers/
    │   └── HealthKitManager.swift  # HealthKit API integration
    └── Assets.xcassets/
```

## Building

1. Open `EmberWatch.xcodeproj` in Xcode
2. Select your development team in project settings
3. Build and run on a physical iOS device (HealthKit data not available in Simulator)

## HealthKit Permissions

The app requests read access for:
- Workout samples (`HKWorkoutType`)
- Active Energy Burned (`HKQuantityTypeIdentifier.activeEnergyBurned`)

Users must grant permission through the Health Connect screen for the app to display workout data.
