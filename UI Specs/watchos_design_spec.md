# watchOS Goal Logging Interface - Design Specification

## Overview
A minimal, gesture-driven interface for logging goal trials on Apple Watch. Users can quickly log success/failure attempts for various goals using intuitive swipe gestures, with real-time session tracking and percentage feedback.

## Core Interaction Model
- **Primary Action**: Swipe up for success, swipe down for failure
- **Secondary Navigation**: Digital Crown scrolling to switch between goals
- **Tertiary Actions**: Undo last trial, view session timer

## Visual Layout & Components

### Header (Top Bar)
- **Layout**: Three-column header with equal spacing
- **Left**: Session timer (MM:SS format, green styling)
- **Center**: Current time display (HH:MM format, gray text)
- **Right**: Undo button (circular, orange, icon-only: ↶)
- **Styling**: Subtle background with rounded bottom corners

### Swipe Prompts
- **Success Prompt** (Top): Green gradient background, "↑ SUCCESS ↑" text
- **Failure Prompt** (Bottom): Red gradient background, "↓ FAILURE ↓" text
- **Behavior**: Animate when user is actively swiping in that direction
- **Position**: Fixed at top and bottom edges, spanning most of screen width

### Main Content Area
Positioned between the swipe prompts with adequate clearance:

#### Client Information
- **Client Name**: Blue pill-shaped badge directly above goal name
- **Styling**: Light blue background, white text, compact padding

#### Goal Display
- **Goal Name**: Large, bold white text (primary focus)
- **Session Percentage**: Color-coded percentage with trial count format "X% (success/total)"
  - Green: 70%+ success rate
  - Orange: 40-69% success rate  
  - Red: <40% success rate
  - Gray: No trials yet (0/0)

#### Navigation Dots
- **Position**: Bottom center, small circular indicators
- **Active State**: Green dot, slightly larger
- **Inactive State**: Gray translucent dots
- **Count**: 4 dots representing different goals

## Interaction Behaviors

### Swipe Gestures
```
Swipe Up (Success):
1. Visual feedback: Goal area moves up slightly, success prompt highlights
2. Haptic feedback: Light impact
3. Data update: Increment success counter, recalculate percentage
4. Flash feedback: "+1 Success" overlay appears briefly
5. Color update: Percentage text color updates based on new rate

Swipe Down (Failure):
1. Visual feedback: Goal area moves down slightly, failure prompt highlights  
2. Haptic feedback: Light impact
3. Data update: Increment failure counter, recalculate percentage
4. Flash feedback: "+1 Failure" overlay appears briefly
5. Color update: Percentage text color updates based on new rate
```

### Digital Crown Navigation
```
Crown Rotation:
- Scroll Up: Previous goal (with smooth transition)
- Scroll Down: Next goal (with smooth transition)
- Updates: Goal name and navigation dots
- Maintains: Session data is goal-independent
```

### Undo Functionality
```
Undo Button Tap:
1. Remove last trial from history stack
2. Decrement appropriate counter (success or failure)
3. Recalculate percentage and update display
4. Show "Undone" feedback flash
5. Disable button if no trials remain
```

## Data Model

### Session State
- `sessionTrials.success`: Number of successful trials
- `sessionTrials.failure`: Number of failed trials  
- `sessionTrials.total`: Total trials (success + failure)
- `trialHistory[]`: Array of trial objects for undo functionality
- `sessionStartTime`: Timestamp for session timer

### Goal Configuration
```javascript
goals = ['water', 'exercise', 'meditation', 'reading']
goalData = {
  goalName: {
    title: "Display Name"
  }
}
```

## Visual Design System

### Colors
- **Success Green**: #30D158 (Apple's system green)
- **Failure Red**: #FF3B30 (Apple's system red)  
- **Warning Orange**: #FF9500 (Apple's system orange)
- **Primary Blue**: #007AFF (Apple's system blue)
- **Background**: Pure black (#000000)
- **Text Primary**: White (#FFFFFF)
- **Text Secondary**: Gray (#999999)

### Typography
- **Goal Name**: 16px, semibold, white
- **Client Name**: 10px, semibold, blue
- **Session Percentage**: 12px, medium weight, color-coded
- **Session Timer**: 10px, semibold, green
- **Current Time**: 10px, medium, gray

### Spacing & Layout
- **Screen Padding**: 15px horizontal, variable vertical
- **Component Spacing**: 8-20px between major elements
- **Button Size**: 16-18px circular for header buttons
- **Touch Targets**: Minimum 44pt for accessibility

## Animation & Feedback

### Gesture Feedback
- **Swipe Recognition Threshold**: 25px movement
- **Visual Response**: Immediate transform and color changes during drag
- **Completion Animation**: Scale pulse (1.0 → 1.1 → 1.0) over 300ms
- **Flash Overlay**: 800ms fade-in/fade-out with trial feedback

### State Transitions
- **Goal Switching**: Smooth text transitions with navigation dot updates
- **Percentage Updates**: Color transitions over 300ms
- **Button States**: Opacity changes for disabled/enabled states

## Accessibility Considerations
- **VoiceOver**: All interactive elements have appropriate labels
- **Haptic Feedback**: Consistent light impacts for successful interactions
- **Color Contrast**: Sufficient contrast ratios for all text elements
- **Touch Targets**: All buttons meet minimum 44pt size requirement

## Implementation Notes for Xcode/SwiftUI

### Key SwiftUI Components
- `GeometryReader` for responsive layout
- `DragGesture` for swipe detection
- `@State` variables for session tracking
- `withAnimation` for smooth transitions
- `HapticManager` for tactile feedback

### Watch-Specific Considerations
- Use `WKInterfaceController` for Digital Crown input
- Implement `WKCrownSequencer` for smooth scrolling
- Handle app lifecycle for session persistence
- Optimize for Series 4+ screen sizes (40mm/44mm)

### Performance Optimizations
- Minimize state updates during drag gestures
- Cache calculated percentages
- Use lazy loading for goal data
- Implement efficient undo stack management

This interface prioritizes speed and simplicity, enabling users to quickly log multiple trials without complex navigation or excessive UI elements.