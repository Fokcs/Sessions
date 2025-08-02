# Issue #26: Stage 3 Apple Watch Workflow Implementation

**GitHub Issue**: https://github.com/Fokcs/Sessions/issues/26

## Overview
Implement complete Apple Watch session management workflow including:
- Watch start interface with client selection
- Goal logging with swipe gestures and Digital Crown navigation  
- Circular cue level picker with auto-timeout
- Session summary with performance metrics
- Optimized for 44mm Apple Watch constraints

## Analysis of Prior Art

### Existing Foundation (Stages 1-2 Complete)
✅ Core Data stack with app group sharing
✅ Swift model structs (Client, GoalTemplate, Session, GoalLog, CueLevel)
✅ Repository pattern with SimpleCoreDataRepository
✅ ViewModels duplicated in both iOS and watchOS targets
✅ Error handling with TherapyAppError
✅ Sample data generation

### Watch App Structure
Current `Sessions Watch App/` directory contains:
- Models/ - All data models already implemented
- ViewModels/ - Core ViewModels ready for session management
- Views/ - Client/Goal management views (for setup)
- CoreData/ - Stack ready for session data
- Repositories/ - Data access layer complete

### UI Specifications Available
- `watchos_start_interface_spec.md` - Start interface design
- `watchos_design_spec.md` - Goal logging interface
- `circular_picker_ux_spec.md` - Cue level picker design  
- `session_summary_ux_spec.md` - Session summary layout

## Implementation Plan

### Phase 1: Session Management Foundation
1. **SessionViewModel** - Manage active session state
   - Track current client, goals, session timer
   - Handle trial logging with undo functionality
   - Calculate real-time statistics
   - Manage navigation between goals

2. **SessionData Models** - Runtime session data
   - ActiveSession - Current session state
   - TrialLog - Individual trial with timestamp/cue level
   - SessionStats - Real-time statistics calculation

### Phase 2: Core Watch Views
3. **StartView** - Entry point interface
   - Header with time and settings gear
   - Client selection with blue accent styling
   - Large green circular START button
   - Client selection overlay with slide-up animation

4. **GoalLoggingView** - Main session interface  
   - Swipe up/down gesture recognition for success/failure
   - Digital Crown navigation between goals
   - Session timer and undo functionality
   - Real-time success percentage display
   - Navigation dots for multiple goals

5. **CueLevelPickerView** - Post-trial overlay
   - Circular layout with 4 positioned buttons
   - 3-second countdown with auto-default to "Independent"
   - Button scaling and glow effects
   - Immediate dismissal on selection

6. **SessionSummaryView** - End session summary
   - 2x2 stats grid (success, failure, total, rate)
   - Cue level breakdown statistics
   - Goal performance with excellence indicators
   - Action buttons for share/new session

### Phase 3: Interaction & Optimization
7. **Gesture Recognition**
   - SwiftUI DragGesture with 25px threshold
   - Debouncing to prevent double-taps
   - Visual feedback during recognition
   - Haptic feedback integration

8. **Digital Crown Integration**
   - WKCrownSequencer for smooth goal navigation
   - Maintain session state during goal switches
   - Update navigation dots appropriately

9. **Performance Optimization**
   - Efficient Core Data operations
   - 60fps animations
   - Memory management for extended sessions
   - Battery-conscious implementation

### Phase 4: Integration & Testing
10. **Navigation Flow**
    - StartView → GoalLoggingView → CueLevelPickerView → GoalLoggingView (loop)
    - End session → SessionSummaryView → StartView
    - Settings overlay functionality

11. **Comprehensive Testing**
    - Unit tests for SessionViewModel
    - Integration tests for gesture recognition
    - Performance tests for memory usage
    - UI tests for navigation flow

## Key Technical Decisions

### Data Strategy
- **In-Memory Session Data**: Store active session in SessionViewModel
- **No WatchConnectivity**: Use mock/sample data as specified
- **Local Persistence**: Save completed sessions to Core Data

### Gesture Thresholds
- **Swipe Distance**: 25px minimum movement
- **Timing**: 100ms maximum recognition delay
- **Feedback**: Light haptic on successful recognition

### Auto-Timeout Logic
- **Duration**: 3 seconds for cue level picker
- **Default**: "Independent" (most common case)
- **Visual**: Large countdown timer in center

### Performance Targets
- **Animation**: 60fps for all transitions
- **Response**: <100ms for button feedback
- **Memory**: Efficient cleanup of views
- **Battery**: Minimal background processing

## File Structure Plan

```
Sessions Watch App/Views/
├── Session/
│   ├── StartView.swift
│   ├── GoalLoggingView.swift 
│   ├── CueLevelPickerView.swift
│   └── SessionSummaryView.swift
└── Components/
    ├── SessionTimer.swift
    ├── NavigationDots.swift
    └── CircularButton.swift

Sessions Watch App/ViewModels/
├── SessionViewModel.swift
└── SessionStatsCalculator.swift

Sessions Watch App/Models/
├── ActiveSession.swift
├── TrialLog.swift  
└── SessionStats.swift (if needed beyond computed properties)
```

## Success Criteria
- ✅ Watch app launches and displays start interface
- ✅ Client selection works with sample data
- ✅ Goal logging gestures respond within 100ms
- ✅ Cue level picker appears and auto-defaults correctly
- ✅ Session summary calculates statistics accurately
- ✅ Digital Crown scrolling between goals works smoothly
- ✅ All animations maintain 60fps
- ✅ Memory usage remains efficient during extended sessions
- ✅ Haptic feedback provides appropriate user feedback

## Validation Steps
1. Manual testing on Apple Watch simulator
2. Gesture recognition accuracy testing
3. Performance profiling during extended sessions
4. Memory leak detection
5. Animation frame rate verification
6. Haptic feedback confirmation

## Risks & Mitigations
- **Performance Risk**: Multiple animated views → Use lazy loading and efficient state management
- **Gesture Conflicts**: Swipe vs scroll → Implement proper gesture priority
- **Memory Issues**: Extended sessions → Implement cleanup and efficient data structures
- **Navigation Complexity**: Multiple overlays → Clear state management patterns

## Implementation Sequence
1. Session foundation (models, ViewModels)
2. StartView with basic navigation
3. GoalLoggingView with gesture recognition
4. CueLevelPickerView with circular layout
5. SessionSummaryView with statistics
6. Navigation flow integration
7. Performance optimization
8. Comprehensive testing

This plan builds on the solid foundation from Stages 1-2 and leverages the detailed UI specifications to create a complete, intuitive Apple Watch experience for therapy sessions.