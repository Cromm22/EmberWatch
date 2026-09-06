# Setup Instructions for EmberWatch

## Important: Add New Files to Xcode Project

The new Swift files have been created but need to be added to the Xcode project before building.

### Steps:

1. **Open the project in Xcode:**
   ```bash
   open EmberWatch.xcodeproj
   ```

2. **Add the new files to the project:**
   
   In Xcode's Project Navigator (left sidebar):
   
   **Add to Views group:**
   - Right-click the `Views` folder
   - Choose "Add Files to 'EmberWatch'..."
   - Navigate to and select:
     - `BarcodeScannerView.swift`
     - `BoardView.swift`
     - `ServingSizePickerView.swift`
     - `ShareView.swift`
   - Make sure "Copy items if needed" is UNCHECKED (files are already in the right place)
   - Click "Add"

   **Add to Managers group:**
   - Right-click the `Managers` folder
   - Choose "Add Files to 'EmberWatch'..."
   - Select: `WaterManager.swift`
   - Make sure "Copy items if needed" is UNCHECKED
   - Click "Add"

   **Create Services group and add file:**
   - Right-click the `EmberWatch` group (top level, next to Models/Views/Managers)
   - Choose "New Group"
   - Name it `Services`
   - Right-click the new `Services` group
   - Choose "Add Files to 'EmberWatch'..."
   - Navigate to `EmberWatch/Services/` and select: `FoodLookupService.swift`
   - Make sure "Copy items if needed" is UNCHECKED
   - Click "Add"

3. **Verify all files are added:**
   - Check that all 6 new files appear in the Project Navigator
   - They should be in their respective groups (Views, Managers, Services)
   - Build the project (Cmd+B) to ensure everything compiles

4. **Set your Development Team:**
   - Select the EmberWatch project in the navigator
   - Go to "Signing & Capabilities" tab
   - Verify team is set to `Apple Development: chrusht@gmail.com (4UNUWW2348)`
   - Bundle ID is `com.ember.watch`
   - CloudKit entitlements should be enabled automatically

5. **Run on a physical device:**
   - Select your iPhone from the device dropdown
   - Press Cmd+R to build and run
   - Grant camera and HealthKit permissions when prompted

## Why This Step Is Needed

Git tracks file contents but Xcode projects store their structure in `project.pbxproj`, which is a complex format. Rather than risk corrupting the project file with manual edits, it's safer to add files through Xcode's UI.

## Alternative: Command Line (Advanced)

If you have `xcodeproj` Ruby gem installed:

```bash
gem install xcodeproj
ruby -e "
require 'xcodeproj'
project = Xcodeproj::Project.open('EmberWatch.xcodeproj')
target = project.targets.first
# Add files programmatically...
project.save
"
```

However, the UI method above is recommended for reliability.

## Files Added in This PR

- ✅ `EmberWatch/Services/FoodLookupService.swift`
- ✅ `EmberWatch/Views/BarcodeScannerView.swift`
- ✅ `EmberWatch/Views/ServingSizePickerView.swift`
- ✅ `EmberWatch/Views/BoardView.swift`
- ✅ `EmberWatch/Views/ShareView.swift`
- ✅ `EmberWatch/Managers/WaterManager.swift`

All files are already in the correct directories on disk - they just need to be linked into the Xcode project structure.
