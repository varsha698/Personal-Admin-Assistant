# LifeAdmin

Personal life-admin assistant for iOS 26+. Local-first, on-device AI via Foundation Models, sync via CloudKit. No backend.

## Requirements

- iPhone 15 Pro or newer (Apple Intelligence capable)
- iOS 26+ on the phone, iOS 26 SDK in Xcode 16+
- Mac with iCloud signed in

## Setup

### Option A — XcodeGen (repeatable)

```bash
brew install xcodegen
cd LifeAdmin
xcodegen generate
open LifeAdmin.xcodeproj
```

Then in Xcode:
1. Select the `LifeAdmin` target → Signing & Capabilities → set your Team.
2. Change `Bundle Identifier` from `com.example.lifeadmin` to something unique (`com.<you>.lifeadmin`).
3. Add capability `iCloud` → check `CloudKit` → create container `iCloud.com.<you>.lifeadmin`.
4. Update `Persistence/ModelContainer+Setup.swift` with the same container id.
5. Add capability `Background Modes` → check `Background fetch` and `Background processing`.

### Option B — manual

1. Xcode → New Project → App → iOS → SwiftUI, name `LifeAdmin`, Storage: SwiftData, "Host in CloudKit" ticked.
2. Delete Xcode's generated `Item.swift` and `ContentView.swift`.
3. Drag every folder under `LifeAdmin/` (App, Models, Features, Services, Persistence, Resources) into the project navigator, "Create groups", target = LifeAdmin.
4. Same signing / iCloud / Background Modes steps as above.

## Build & run on your phone

Plug the iPhone in → select it as the run destination → ⌘R. First run will prompt for Calendar, Reminders, and Notifications permissions.

- Free personal signing: works but the app expires every 7 days. Re-run from Xcode to refresh.
- Apple Developer Program ($99/yr): install once, runs indefinitely.

## What's in Phase 1

- Task model + list + capture sheet (text input)
- EventKit two-way sync (Reminders + Calendar)
- Local notifications for task reminders
- Today screen showing agenda + tasks due today
- CloudKit sync between your devices

Phase 2 (not yet built): Mail ingestion + Foundation Models commitment extraction.
Phase 3 (not yet built): Bills / subscriptions / routines.
# Personal-Admin-Assistant
