# Claude Context

## Project Overview
Sessions - iOS and watchOS therapy data logging app for speech and ABA therapists

## Project Structure
- `Sessions/` - iOS app target
- `Sessions Watch App/` - watchOS app target  
- `SessionsTests/` - iOS tests
- `Sessions Watch AppTests/` - watchOS tests
- `Shared/` - Shared infrastructure
  - `Models/` - Swift model structs (Client, Session, GoalTemplate, GoalLog, CueLevel)
  - `CoreData/` - Core Data stack and model (TherapyDataModel.xcdatamodeld)
  - `Repositories/` - Repository pattern implementation
- `UI Specs/` - Design specifications
- `therapy_app_requirements.md` - Requirements document
- `therapy_runbook_revised.md` - Development guide

## Stage 1 Implementation Status (COMPLETED)
✅ App groups and entitlements configured for HIPAA compliance  
✅ Core Data model with all entities (Client, GoalTemplate, Session, GoalLog)  
✅ CoreDataStack with app group sharing and NSFileProtectionComplete  
✅ Swift model structs with proper initializers and computed properties  
✅ Repository pattern with async/await CoreDataTherapyRepository  
✅ Comprehensive unit tests for foundation layer  

## Key Technologies
- SwiftUI for both platforms
- Core Data for local storage with persistent history tracking
- WatchConnectivity for device sync (ready for Stage 4)
- App Groups: `group.com.AAFU.Sessions`
- Bundle ID: `com.AAFU.Sessions`

## Build Commands
- Build: `xcodebuild -project Sessions.xcodeproj -scheme Sessions build`
- Test: `xcodebuild -project Sessions.xcodeproj -scheme Sessions test`
- Clean: `xcodebuild -project Sessions.xcodeproj clean`

## Code Guidelines
- Use SwiftUI declarative syntax
- Follow async/await patterns
- Repository pattern for data access
- MVVM architecture with ObservableObject
- Secure data handling (HIPAA considerations)
- All Core Data operations use background contexts for writes