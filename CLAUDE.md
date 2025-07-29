# Claude Context

## Project Overview
Sessions - iOS and watchOS therapy data logging app for speech and ABA therapists

## Project Structure
- `Sessions/` - iOS app target
  - `Models/` - Swift model structs (duplicated for target access)
  - `CoreData/` - Core Data stack and model
  - `Repositories/` - Repository pattern implementation
- `Sessions Watch App/` - watchOS app target (mirrors iOS structure)
- `SessionsTests/` - iOS tests
- `Sessions Watch AppTests/` - watchOS tests
- `UI Specs/` - Design specifications
- `therapy_app_requirements.md` - Requirements document
- `therapy_runbook_revised.md` - Development guide

**Note**: Shared files are duplicated in each target directory rather than using a Shared folder due to Xcode project configuration complexities.

## Stage 1 Implementation Status (COMPLETED)
✅ App groups and entitlements configured for HIPAA compliance  
✅ Core Data model with all entities (Client, GoalTemplate, Session, GoalLog)  
✅ CoreDataStack with app group sharing and NSFileProtectionComplete  
✅ Swift model structs with proper initializers and computed properties  
✅ Repository pattern with async/await SimpleCoreDataRepository  
✅ Comprehensive unit tests for foundation layer  
✅ SwiftUI test generator agent available for automated test creation  

### Stage 1 Issues & Lessons Learned
⚠️ **Core Data async/await Issues**: Initial CoreDataTherapyRepository had problems with `context.perform` return types. Solution: Use `SimpleCoreDataRepository` with proper async patterns.

⚠️ **Target Architecture**: Shared folder approach failed due to Xcode target configuration. Files are duplicated in each target directory instead.

⚠️ **Test Configuration**: Tests required files to be in main target directory to resolve import scope issues with `@testable import Sessions`.

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
- **Test Creation**: Use swiftui-test-generator agent for comprehensive test coverage of new components

## Development Best Practices

### Core Data Guidelines
- **Use SimpleCoreDataRepository**: Avoid complex `context.perform` return patterns
- **Background Contexts**: Always use `newBackgroundContext()` for write operations
- **View Context**: Use `viewContext` only for reads (UI binding)
- **Error Handling**: Use do-catch blocks in perform closures, don't throw from them
- **Thread Safety**: Never pass managed objects between contexts

### Testing Guidelines
- **SwiftUI Test Generator Agent**: Use the specialized `swiftui-test-generator` agent for creating comprehensive unit tests for SwiftUI components, ViewModels, and data layer components
- **Agent Delegation**: When test creation is needed, delegate to the test generator agent rather than writing tests manually
- **Test Coverage Areas**: Agent handles SwiftUI views, ViewModels, repository patterns, Core Data operations, and async/await testing
- **In-Memory Store**: Use `NSInMemoryStoreType` for unit tests
- **Test Isolation**: Create fresh Core Data stack for each test
- **Async Testing**: Use `async throws` test methods for repository testing
- **Mock Data**: Create test fixtures with realistic data

### Test Generation Workflow
- **When to Use Agent**: Delegate test creation for new SwiftUI components, ViewModels, repositories, or Core Data entities
- **Agent Capabilities**: Comprehensive test suites with proper iOS/watchOS testing patterns, async/await support, and Core Data testing
- **Integration**: Agent-generated tests follow existing project conventions and testing standards

### File Organization
- **Duplicate Shared Files**: Copy files to both iOS and watchOS target directories
- **Consistent Structure**: Mirror directory structure between targets
- **Target Inclusion**: Ensure all files are included in appropriate targets

### Known Issues to Avoid
- **Don't use Shared folder**: Xcode target configuration issues
- **Don't return from context.perform**: Use separate async/await pattern
- **Don't mix sync/async**: Choose one pattern and stick with it consistently