# Issue #10: Implement ClientListView with Search

**GitHub Issue**: https://github.com/Fokcs/Sessions/issues/10

## Issue Summary
Create the main client browsing interface with search functionality as part of Stage 2 - iPhone Data Management.

## Requirements Analysis
From the GitHub issue:
- Create client browsing interface with search functionality  
- Implement empty states and loading indicators
- Add accessibility labels for VoiceOver
- Include pull-to-refresh functionality
- Navigation to ClientDetailView works

## Current State Analysis

### ✅ Completed Dependencies
- **Issue #7 (ViewModels)**: ClientListViewModel fully implemented with search, loading states, error handling
- **Issue #9 (Error Handling)**: TherapyAppError system and ErrorAlertModifier components available
- **Foundation Layer**: SimpleCoreDataRepository, Client model, SampleDataManager all available

### 📱 Current ClientsView State
**File**: `Sessions/Views/ClientsView.swift`
- Currently a placeholder view with "Stage 2" message
- Basic navigation structure exists with toolbar button
- Needs complete replacement with functional ClientListView

### 🧱 Available Building Blocks
1. **ClientListViewModel** (`Sessions/ViewModels/ClientListViewModel.swift`):
   - `@Published var clients: [Client]` - Main data source
   - `@Published var searchText: String` - Search functionality
   - `@Published var isLoading: Bool` - Loading states
   - `@Published var error: TherapyAppError?` - Error handling
   - `var filteredClients: [Client]` - Computed search results
   - `func loadClients() async`, `func refreshClients() async` - Data operations
   - `func retryLastOperation() async`, `func clearError()` - Error recovery

2. **Error Handling** (`Sessions/Views/Components/ErrorAlertModifier.swift`):
   - `.errorAlert(error:onDismiss:onRetry:)` - Consistent error presentation
   - Built-in retry functionality for retryable errors
   - Accessibility support included

3. **Client Model** (`Sessions/Models/Client.swift`):
   - `displayName: String` - UI-friendly name display
   - `displayDetails: String` - Age information
   - `privacyName: String` - HIPAA-compliant display option

4. **Sample Data** (`Sessions/Models/SampleDataManager.swift`):
   - Available for development and testing

## Implementation Plan

### Phase 1: Core ClientListView Implementation
Replace the placeholder ClientsView with a fully functional ClientListView that integrates with ClientListViewModel.

#### Task 1.1: Basic List Structure
**File**: `Sessions/Views/ClientsView.swift`
- Replace placeholder content with List view
- Integrate ClientListViewModel with @StateObject
- Display clients using NavigationLink rows
- Implement basic client row design

#### Task 1.2: Search Functionality  
- Add SearchBar using .searchable modifier
- Bind to viewModel.searchText
- Use viewModel.filteredClients for display
- Include search clear functionality

#### Task 1.3: Loading States
- Show ProgressView when viewModel.isLoading
- Implement skeleton loading states
- Handle initial load vs refresh states

#### Task 1.4: Empty States
- Display custom empty state when no clients exist
- Include helpful messaging and actions
- Handle empty search results separately

### Phase 2: Enhanced Features

#### Task 2.1: Pull-to-Refresh
- Implement refreshable modifier
- Call viewModel.refreshClients() on pull
- Provide user feedback during refresh

#### Task 2.2: Error Handling Integration
- Use .errorAlert modifier for error display
- Implement retry functionality for failed operations
- Handle network/Core Data errors gracefully

#### Task 2.3: Navigation Integration
- NavigationLink to ClientDetailView (placeholder for now)
- Proper navigation title and toolbar
- Add client creation button functionality (future enhancement)

### Phase 3: Accessibility & Polish

#### Task 3.1: VoiceOver Support
- Add comprehensive accessibility labels
- Provide hints for interactive elements
- Test with VoiceOver enabled

#### Task 3.2: Visual Polish
- Consistent spacing and typography
- Proper loading indicators
- Error state styling

### Phase 4: Target Duplication
- Copy updated ClientsView to `Sessions Watch App/Views/`
- Ensure watchOS compatibility
- Test watchOS implementation

## Detailed Implementation Design

### ClientListView Structure
```swift
struct ClientsView: View {
    @StateObject private var viewModel = ClientListViewModel()
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.clients.isEmpty {
                    LoadingView()
                } else if viewModel.filteredClients.isEmpty {
                    EmptyStateView(isSearchActive: !viewModel.searchText.isEmpty)
                } else {
                    ClientList(clients: viewModel.filteredClients)
                }
            }
            .navigationTitle("Clients")
            .searchable(text: $viewModel.searchText, prompt: "Search clients")
            .refreshable {
                await viewModel.refreshClients()
            }
            .errorAlert(error: viewModel.error) {
                viewModel.clearError()
            } onRetry: {
                Task { await viewModel.retryLastOperation() }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        // Future: Navigation to ClientEditView
                    }
                    .accessibilityLabel("Add new client")
                }
            }
        }
        .task {
            await viewModel.loadClients()
        }
    }
}
```

### Component Breakdown

#### 1. ClientList Component
- Displays List of clients
- NavigationLink rows to ClientDetailView
- Row content: name, age, accessibility labels

#### 2. LoadingView Component  
- ProgressView with descriptive text
- Used during initial data load

#### 3. EmptyStateView Component
- Different messages for no clients vs no search results
- Helpful actions (create client, clear search)
- Proper accessibility support

### Accessibility Requirements

#### VoiceOver Labels
- **Client Rows**: "Client: [Name], [Age details]"
- **Search Field**: "Search clients by name"
- **Add Button**: "Add new client"
- **Loading**: "Loading clients"
- **Empty State**: "No clients found" or "No search results"

#### Accessibility Actions
- Swipe actions for client management (future)
- Voice control support
- Dynamic type support

## Testing Strategy

### UI Testing Areas
1. **Search Functionality**: Filter results, clear search, empty results
2. **Loading States**: Initial load, refresh, error recovery
3. **Empty States**: No clients, no search results
4. **Error Handling**: Network errors, Core Data errors, retry operations
5. **Accessibility**: VoiceOver navigation, labels, hints
6. **Pull-to-Refresh**: User interaction, data updates

### Test Implementation
- Use test-writer agent for comprehensive test suite
- Cover both iOS and watchOS implementations
- Include integration tests with ClientListViewModel
- Mock repository for isolated testing

## Success Criteria

### Functional Requirements
- [ ] ClientListView displays all clients from repository
- [ ] Search functionality filters clients by name  
- [ ] Empty state shown when no clients exist
- [ ] Loading indicators during async operations
- [ ] Pull-to-refresh updates client list
- [ ] Error handling with retry options
- [ ] Navigation structure maintained

### Accessibility Requirements  
- [ ] VoiceOver labels for all interactive elements
- [ ] Proper accessibility hints and traits
- [ ] Dynamic type support
- [ ] High contrast compatibility

### Architecture Requirements
- [ ] Follows MVVM pattern with ClientListViewModel
- [ ] Uses established error handling patterns
- [ ] Maintains separation of concerns
- [ ] Code duplicated to watchOS target

## Implementation Order

1. **Setup**: Create new branch, mark todo as in_progress
2. **Core Implementation**: Replace ClientsView with functional ClientListView
3. **Feature Integration**: Search, loading, empty states, pull-to-refresh
4. **Error & Accessibility**: Error handling, VoiceOver support
5. **Target Duplication**: Copy to watchOS target
6. **Testing**: Comprehensive test suite with test-writer agent
7. **Integration**: Full test suite, build verification
8. **Review**: PR creation and pr-review-agent feedback

## Risk Assessment

### Low Risk
- **ViewModel Integration**: ClientListViewModel is fully implemented and tested
- **Error Handling**: Established patterns with TherapyAppError system
- **Foundation**: Core Data and repository layer stable

### Medium Risk
- **UI Complexity**: Managing multiple states (loading, empty, error, content)
- **Accessibility**: Comprehensive VoiceOver support requires careful testing

### Mitigation Strategies
- Start with basic implementation and iterate
- Use existing error handling patterns consistently
- Leverage test-writer agent for comprehensive test coverage
- Test with VoiceOver enabled throughout development

## Future Considerations

### Stage 2 Integration
- ClientDetailView navigation (dependent on Issue #11)
- Client creation/editing (dependent on Issue #12)
- Client deletion confirmation dialogs

### Stage 3 Preparation
- Session history integration
- Client activity summaries
- Therapy progress indicators

## Dependencies & Blockers

### ✅ Resolved Dependencies  
- Issue #7 (ViewModels): ClientListViewModel complete
- Issue #9 (Error Handling): TherapyAppError system complete
- Foundation layer: Repository, models, Core Data ready

### 🚧 Parallel Work
- Issue #11 (ClientDetailView): Can start after this issue
- Issue #12 (Client Creation): Depends on this foundation

### 📋 No Current Blockers
All dependencies are resolved, ready for implementation.