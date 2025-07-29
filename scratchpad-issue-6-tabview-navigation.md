# Issue #6: Create Main TabView Navigation Structure

**GitHub Issue**: https://github.com/Fokcs/Sessions/issues/6

## Issue Summary
Implement the main navigation structure for the iPhone app with TabView containing Clients, Goals, and Sessions tabs.

## Requirements Analysis
From the GitHub issue:
- ✅ TabView displays three tabs: Clients, Goals, Sessions
- ✅ Navigation titles are properly set for each tab
- ✅ Toolbar buttons are implemented where needed
- ✅ Tab navigation works smoothly between views
- ✅ Follows SwiftUI navigation best practices

From Stage 2 prompt:
- TabView with Clients, Goals, Sessions tabs
- Proper navigation titles and toolbar buttons
- SwiftUI navigation best practices
- Pull-to-refresh functionality (future enhancement)

From UI Specs:
- Tab bar with House, Clients (two-person icon), Settings icons
- Modern iOS design following HIG
- Accessibility support (VoiceOver, Dynamic Type)
- Proper use of SF Symbols

## Current State
- ContentView.swift contains only placeholder "Hello, world!" content
- No existing navigation structure
- Models (Client, GoalTemplate, Session) are available in Models/
- Repository pattern implemented (SimpleCoreDataRepository, TherapyRepository)

## Implementation Plan

### Phase 1: Create Tab Views (High Priority)
1. **ClientsView.swift** - Placeholder view for client management
   - Navigation title: "Clients"
   - Toolbar: Add button for creating new clients
   - Placeholder content explaining future functionality

2. **GoalsView.swift** - Placeholder view for goal template management
   - Navigation title: "Goals"
   - Toolbar: Add button for creating new goal templates
   - Placeholder content explaining future functionality

3. **SessionsView.swift** - Placeholder view for session management
   - Navigation title: "Sessions"
   - Basic placeholder content (sessions will come in Stage 3)

### Phase 2: Implement TabView Structure (High Priority)
1. **Update ContentView.swift**
   - Replace placeholder content with TabView
   - Configure three tabs: Clients, Goals, Sessions
   - Use appropriate SF Symbols for tab icons
   - Set proper tab labels

2. **Navigation Structure**
   - Wrap each tab content in NavigationStack
   - Configure navigation titles
   - Add toolbar buttons where specified

### Phase 3: Polish & Best Practices (Medium Priority)
1. **Accessibility**
   - Add accessibility labels for all tab items
   - Ensure VoiceOver compatibility
   - Support Dynamic Type

2. **SwiftUI Best Practices**
   - Use @State for tab selection if needed
   - Proper view hierarchy
   - Clean separation of concerns

### Phase 4: Testing (High Priority)
1. **Build Verification**
   - Build iOS target successfully
   - No compilation errors

2. **Navigation Testing**
   - Tab switching works correctly
   - Navigation titles display properly
   - Toolbar buttons are functional
   - Tab state maintained during app lifecycle

3. **Unit Tests**
   - Test tab view structure
   - Test accessibility labels
   - Use swiftui-test-generator agent for comprehensive tests

## Implementation Details

### Tab Icons (from UI specs)
- **Clients**: `person.2.fill` or `person.2`
- **Goals**: `target` or `list.bullet.rectangle`  
- **Sessions**: `clock.fill` or `play.circle.fill`

### File Structure
```
Sessions/
├── ContentView.swift (updated)
├── Views/ (new directory)
│   ├── ClientsView.swift (new)
│   ├── GoalsView.swift (new)
│   └── SessionsView.swift (new)
```

### Code Architecture
- Each tab view will be a separate SwiftUI view
- ContentView will contain the TabView structure
- Navigation will be handled at the tab level
- Future integration points ready for Stage 2 functionality

## Success Criteria
- [x] Three tabs display correctly
- [x] Tab navigation works smoothly
- [x] Navigation titles are properly set  
- [x] Toolbar buttons are implemented
- [x] Follows SwiftUI best practices
- [x] Accessibility labels present
- [x] Builds successfully
- [x] No crashes during navigation

## Dependencies
- None (foundation from Stage 1 is sufficient)

## Risk Assessment
- **Low Risk**: Straightforward SwiftUI TabView implementation
- **No Breaking Changes**: Only replacing placeholder content
- **Future Compatibility**: Structure designed for Stage 2 enhancements

## Notes
- This creates the navigation foundation for Stage 2 client and goal management
- Session tab will remain basic until Stage 3 (Watch integration)
- Views are designed to be enhanced with actual functionality in future stages