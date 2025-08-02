# Issue #9: Implement Error Handling Strategy

**GitHub Issue**: [https://github.com/aaronfuchs/Sessions/issues/9](https://github.com/aaronfuchs/Sessions/issues/9)

## Issue Requirements

Create a consistent error handling strategy across all views.

### Requirements
- Create consistent error presentation across all views
- Build reusable error alert components
- Handle repository async operation failures gracefully
- Provide user-friendly error messages for common scenarios

### Acceptance Criteria
- [ ] Reusable error alert components created
- [ ] Standard error handling patterns established
- [ ] User-friendly error messages for common failures
- [ ] Repository error handling integrated with UI
- [ ] Error recovery options provided where appropriate

### Test Criteria
- Error states display correctly across all views
- Users can recover from error states
- Error messages are clear and actionable

## Current State Analysis

### Existing Error Handling
- **ViewModels**: Have `@Published var errorMessage: String?` properties (from Issue #7)
- **Repository**: Uses `print()` statements for error logging (not production-ready)
- **Test Layer**: Has `MockRepositoryError` enum for testing
- **UI Layer**: No error presentation components exist

### Gaps Identified
1. **No Custom Error Types**: No app-specific error enum with user-friendly messages
2. **Poor Error Propagation**: Repository swallows errors with print statements
3. **Missing UI Components**: No reusable error alerts, banners, or recovery views
4. **No Component Structure**: Missing Views/Components directory
5. **Limited Recovery Options**: No retry mechanisms or error recovery patterns

## Implementation Plan

### Phase 1: Foundation (Error Types & Structure)
1. **Create TherapyAppError enum** - Custom error types with localized messages
2. **Create Views/Components directory** - Establish component architecture
3. **Create base error components** - ErrorAlert, ErrorBanner, ErrorRecoveryView

### Phase 2: Repository Enhancement
4. **Replace print statements** - Proper error propagation in SimpleCoreDataRepository
5. **Add error context** - Include operation context in errors for better user messages
6. **Implement retry patterns** - For transient failures like Core Data save conflicts

### Phase 3: ViewModel Integration
7. **Enhance error handling** - Upgrade ViewModels to use custom error types
8. **Add recovery actions** - Retry, dismiss, and navigation recovery options
9. **Improve error state management** - Better loading/error state coordination

### Phase 4: Target Duplication
10. **Duplicate to watchOS** - Copy all error handling components to watch target

### Phase 5: Testing & Validation
11. **Comprehensive error tests** - Using test-writer agent
12. **Integration testing** - Full test suite validation
13. **UI error state testing** - Error presentation and recovery testing

## Detailed Implementation Tasks

### Task 1: TherapyAppError Enum
**File**: `Sessions/Models/TherapyAppError.swift`
```swift
enum TherapyAppError: LocalizedError {
    case coreDataError(NSError)
    case networkUnavailable
    case validationError(String)
    case clientNotFound
    case goalTemplateNotFound
    case sessionInProgress
    case unknown(Error)
    
    var errorDescription: String? { /* user-friendly messages */ }
    var recoverySuggestion: String? { /* recovery actions */ }
}
```

### Task 2: Error UI Components
**Directory**: `Sessions/Views/Components/`
- `ErrorAlertModifier.swift` - Reusable alert modifier
- `ErrorBanner.swift` - Non-blocking error display
- `ErrorRecoveryView.swift` - Error states with recovery actions

### Task 3: Repository Error Enhancement
**File**: `Sessions/Repositories/SimpleCoreDataRepository.swift`
- Replace all `print()` statements with proper error throwing
- Add specific error context for different failure types
- Implement retry mechanisms for Core Data conflicts

### Task 4: ViewModel Updates
**Files**: All ViewModels in `Sessions/ViewModels/`
- Use TherapyAppError instead of generic Error
- Add error recovery methods (retry, clear, dismiss)
- Improve error state presentation logic

## Testing Strategy

### Error Scenarios to Test
1. **Core Data failures** - Database corruption, save conflicts, fetch errors
2. **Network scenarios** - Offline state, timeout errors
3. **Validation errors** - Invalid client data, missing required fields
4. **Business logic errors** - Duplicate sessions, invalid state transitions
5. **Recovery actions** - Retry success/failure, error dismissal, navigation recovery

### Test Coverage Areas
- Custom error type creation and localization
- Error component UI states and interactions
- Repository error propagation
- ViewModel error handling and recovery
- Integration between layers

## Acceptance Validation

### UI Error Presentation
- [ ] Errors display consistently across all views
- [ ] Error messages are user-friendly and actionable
- [ ] Error recovery options are available where appropriate
- [ ] Error states don't block critical app functionality

### Error Handling Integration
- [ ] Repository errors propagate properly to ViewModels
- [ ] ViewModels handle errors gracefully without crashes
- [ ] Error recovery actions work correctly
- [ ] Loading states coordinate properly with error states

### Code Quality
- [ ] Error types follow Swift best practices
- [ ] Error components are reusable and well-documented
- [ ] Error handling patterns are consistent across codebase
- [ ] All error scenarios have appropriate test coverage

## Dependencies & Constraints

### Dependencies
- **Issue #2 (ViewModels)**: ✅ Completed - ViewModels exist with basic error handling
- **Core Data Foundation**: ✅ Available - SimpleCoreDataRepository ready for enhancement

### Technical Constraints  
- **Target Duplication**: All changes must be copied to watchOS target
- **HIPAA Compliance**: Error messages must not expose sensitive patient data
- **SwiftUI Patterns**: Error components must follow existing SwiftUI architecture
- **Async/Await**: Error handling must work with repository async patterns

## Success Metrics

### User Experience
- Error states provide clear, actionable guidance
- Recovery options help users continue their workflow
- Error presentation doesn't disrupt therapy session flow

### Code Quality
- Zero print statements for error handling in production code
- All async operations have proper error propagation
- Error components are reusable across multiple views
- Comprehensive test coverage for error scenarios