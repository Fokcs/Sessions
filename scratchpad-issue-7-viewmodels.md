# Issue #7: Create ViewModels for MVVM Architecture

**GitHub Issue**: https://github.com/Fokcs/Sessions/issues/7

## Issue Summary
Implement ViewModels for proper MVVM architecture across the app, focusing on client and goal template management functionality.

## Requirements Analysis
From the GitHub issue:
- Implement ClientListViewModel, ClientDetailViewModel, ClientEditViewModel
- Implement GoalTemplateListViewModel, GoalTemplateEditViewModel
- Use @StateObject and @ObservedObject patterns with repository injection
- Handle loading states, error states, and async operations
- ViewModels are duplicated in both iOS and watchOS target directories

## Current State Analysis
- **Repository Layer**: SimpleCoreDataRepository is fully implemented with async/await patterns
- **Models**: Client, GoalTemplate, Session, GoalLog models are complete with proper initializers
- **Views**: Placeholder views exist but need ViewModel integration
- **Architecture**: Foundation ready for MVVM implementation

## Implementation Plan

### Phase 1: Client ViewModels (High Priority)

#### 1.1 ClientListViewModel
**File**: `Sessions/ViewModels/ClientListViewModel.swift` (+ watchOS duplicate)
**Responsibilities**:
- Manage list of clients from repository
- Handle loading states during fetch operations
- Provide search/filter functionality
- Handle client creation navigation
- Manage error states for fetch failures

**Key Properties**:
- `@Published var clients: [Client] = []`
- `@Published var isLoading: Bool = false`
- `@Published var errorMessage: String?`
- `@Published var searchText: String = ""`

**Key Methods**:
- `func loadClients() async`
- `func refreshClients() async`
- `var filteredClients: [Client]` (computed property)

#### 1.2 ClientDetailViewModel
**File**: `Sessions/ViewModels/ClientDetailViewModel.swift` (+ watchOS duplicate)
**Responsibilities**:
- Display individual client details
- Load client-specific goal templates
- Handle navigation to edit mode
- Manage client deletion with confirmation

**Key Properties**:
- `@Published var client: Client?`
- `@Published var goalTemplates: [GoalTemplate] = []`
- `@Published var isLoading: Bool = false`
- `@Published var errorMessage: String?`

**Key Methods**:
- `func loadClient(_ clientId: UUID) async`
- `func loadGoalTemplates() async`
- `func deleteClient() async`

#### 1.3 ClientEditViewModel
**File**: `Sessions/ViewModels/ClientEditViewModel.swift` (+ watchOS duplicate)
**Responsibilities**:
- Handle client creation and editing
- Form validation and error handling
- Save changes to repository
- Manage form state and user inputs

**Key Properties**:
- `@Published var name: String = ""`
- `@Published var dateOfBirth: Date?`
- `@Published var notes: String = ""`
- `@Published var isLoading: Bool = false`
- `@Published var errorMessage: String?`
- `var isValid: Bool` (computed property)

**Key Methods**:
- `func save() async -> Bool`
- `func loadClient(_ client: Client)` (for editing)
- `func validateForm() -> Bool`

### Phase 2: Goal Template ViewModels (High Priority)

#### 2.1 GoalTemplateListViewModel
**File**: `Sessions/ViewModels/GoalTemplateListViewModel.swift` (+ watchOS duplicate)
**Responsibilities**:
- Manage goal templates for a specific client
- Handle loading states during fetch operations
- Provide filtering by category
- Handle goal template creation navigation

**Key Properties**:
- `@Published var goalTemplates: [GoalTemplate] = []`
- `@Published var isLoading: Bool = false`
- `@Published var errorMessage: String?`
- `let clientId: UUID`

**Key Methods**:
- `func loadGoalTemplates() async`
- `func refreshGoalTemplates() async`
- `func deleteGoalTemplate(_ templateId: UUID) async`

#### 2.2 GoalTemplateEditViewModel
**File**: `Sessions/ViewModels/GoalTemplateEditViewModel.swift` (+ watchOS duplicate)
**Responsibilities**:
- Handle goal template creation and editing
- Form validation for required fields
- Save changes to repository
- Manage cue level selection

**Key Properties**:
- `@Published var title: String = ""`
- `@Published var description: String = ""`
- `@Published var category: String = ""`
- `@Published var defaultCueLevel: CueLevel = .independent`
- `@Published var isLoading: Bool = false`
- `@Published var errorMessage: String?`
- `let clientId: UUID`

### Phase 3: Implementation Details

#### 3.1 Common ViewModel Patterns
- All ViewModels extend `ObservableObject`
- Repository injection through initializer
- Consistent error handling patterns
- Loading state management
- Async/await for repository operations

#### 3.2 Error Handling Strategy
- Use `@Published var errorMessage: String?` for displaying errors
- Clear errors when operations succeed
- Provide user-friendly error messages
- Log detailed errors for debugging

#### 3.3 Repository Integration
- Inject `SimpleCoreDataRepository` through initializer
- Use dependency injection pattern for testability
- Handle repository errors gracefully
- Maintain separation of concerns

### Phase 4: File Structure
```
Sessions/
├── ViewModels/ (new directory)
│   ├── ClientListViewModel.swift
│   ├── ClientDetailViewModel.swift
│   ├── ClientEditViewModel.swift
│   ├── GoalTemplateListViewModel.swift
│   └── GoalTemplateEditViewModel.swift
Sessions Watch App/
├── ViewModels/ (new directory - duplicated files)
│   ├── ClientListViewModel.swift
│   ├── ClientDetailViewModel.swift
│   ├── ClientEditViewModel.swift
│   ├── GoalTemplateListViewModel.swift
│   └── GoalTemplateEditViewModel.swift
```

### Phase 5: Testing Strategy
- Use test-writer agent to create comprehensive unit tests
- Test async operations with proper error handling
- Mock repository for isolated ViewModel testing
- Test computed properties and validation logic
- Verify proper state management and published properties

## Implementation Steps

1. **Create ViewModels directory structure** in both iOS and watchOS targets
2. **Implement ClientListViewModel** with repository integration
3. **Implement ClientDetailViewModel** with client loading
4. **Implement ClientEditViewModel** with form validation
5. **Implement GoalTemplateListViewModel** with client-specific loading
6. **Implement GoalTemplateEditViewModel** with category management
7. **Update Views** to use ViewModels with @StateObject/@ObservedObject
8. **Create comprehensive tests** using test-writer agent
9. **Verify integration** with repository layer

## Success Criteria
- [ ] All ViewModels properly inject SimpleCoreDataRepository
- [ ] ViewModels use async/await patterns for repository operations
- [ ] Loading states are managed in ViewModels
- [ ] Error states are handled gracefully
- [ ] ViewModels are duplicated in both iOS and watchOS target directories
- [ ] Views integrate with ViewModels using proper SwiftUI patterns
- [ ] Comprehensive unit tests cover ViewModel functionality
- [ ] No regressions in existing functionality

## Dependencies
- SimpleCoreDataRepository (completed)
- Swift model structs (completed)
- Core Data stack (completed)

## Risk Assessment
- **Medium Risk**: Complex state management across multiple ViewModels
- **Mitigation**: Use consistent patterns and comprehensive testing
- **Future Compatibility**: Design for Stage 3 session management integration

## Notes
- This establishes the MVVM foundation for Stage 2 client and goal management
- ViewModels prepare for future session integration in Stage 3
- Follows CLAUDE.md guidelines for async/await patterns and repository usage