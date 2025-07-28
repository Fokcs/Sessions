# iOS Goal Tracker - Home Page Design Specification

## Overview
The iOS companion app home page serves as the primary entry point for healthcare professionals to manage clients and initiate goal tracking sessions. The design follows Apple's Human Interface Guidelines with a focus on dark mode aesthetics, large touch targets, and clear visual hierarchy suitable for clinical environments.

## Visual Design System

### Color Palette
```swift
// Primary Colors
Background: Color(.systemBackground) // #000000 in dark mode
CardBackground: Color(.secondarySystemBackground) // #1C1C1E in dark mode
PrimaryText: Color(.label) // #FFFFFF in dark mode
SecondaryText: Color(.secondaryLabel) // #8E8E93

// Accent Colors
SystemBlue: Color(.systemBlue) // #007AFF
SystemGreen: Color(.systemGreen) // #32D74B  
SystemRed: Color(.systemRed) // #FF6B6B
SystemGray: Color(.systemGray) // #8E8E93
```

### Typography
```swift
// Headers
LargeTitle: .largeTitle (34pt, weight: .bold)
Headline: .headline (17pt, weight: .semibold)
Body: .body (17pt, weight: .regular)
Subheadline: .subheadline (15pt, weight: .regular)
Caption: .caption (12pt, weight: .medium)
TabLabel: .caption2 (11pt, weight: .medium)
```

### Spacing System
```swift
// 8-point grid system
ExtraSmall: 4pt
Small: 8pt
Medium: 16pt  
Large: 20pt
ExtraLarge: 24pt
```

## Layout Structure

### Screen Dimensions
- Target: iPhone 14/15 (375pt × 812pt)
- Safe area considerations for status bar and home indicator
- Optimized for one-handed use

### Header Section
**Height**: 100pt
**Components**:
- Large title "AppName" (34pt, bold, leading edge +20pt)
- Profile avatar (40pt diameter, trailing edge -20pt, top +20pt)

### Main Content Area
**Layout**: Vertical scroll view with padding
**Horizontal margins**: 20pt
**Vertical spacing**: 20pt between sections

## Component Specifications

### Primary Action Cards

#### New Client Card (Full Width)
```swift
Dimensions: 335pt × 120pt
Corner radius: 12pt
Background: Linear gradient (systemGreen variants)
Shadow: 4pt blur, 15% opacity
Content spacing: 25pt leading margin

Icon Container:
- Size: 50pt diameter
- Background: 20% white overlay
- Corner radius: 25pt
- Plus icon: 3pt stroke weight

Typography:
- Title: 22pt, bold, white
- Subtitle: 16pt, medium, 90% white opacity
- Leading margin from icon: 25pt
```

#### View Clients Card
```swift
Dimensions: 160pt × 120pt  
Position: Leading edge of row
Background: Linear gradient (systemBlue variants)
Content: Centered layout

Icon Container:
- Size: 40pt × 40pt
- Corner radius: 12pt
- Background: 20% white overlay
- Two-person icon composition

Typography:
- Title: 18pt, bold, white
- Subtitle: 14pt, medium, 90% white opacity
```

#### Start Session Card  
```swift
Dimensions: 160pt × 120pt
Position: Trailing edge of row  
Background: Linear gradient (systemRed variants)
Spacing from View Clients: 15pt

Icon Container:
- Apple Watch representation
- 16pt × 20pt main body
- 6pt corner radius
- 2pt white stroke
- Side button details

Typography:
- Title: 18pt, bold, white
- Subtitle: 14pt, medium, 90% white opacity
```

### Secondary Information Cards

#### Last Session Card
```swift
Dimensions: 335pt × 80pt
Background: secondarySystemBackground
Layout: Horizontal, center-aligned

Icon Container:
- Size: 40pt diameter circle
- Background: tertiarySystemBackground
- Clock icon with hands showing time

Content:
- Title: 17pt, semibold, primary text
- Details: 15pt, regular, secondary text
- Chevron: 2pt stroke, systemGray4

Spacing:
- Icon leading margin: 20pt
- Text leading margin from icon: 20pt
- Chevron trailing margin: 20pt
```

#### Goal Bank Card
```swift
Dimensions: 335pt × 80pt
Position: 20pt below Last Session
Layout: Identical to Last Session card

Icon Container:
- Target/bullseye design
- Concentric circles: 12pt, 6pt, 2pt radii
- 2pt stroke weight
```

## Tab Navigation

### Tab Bar
```swift
Height: 83pt (includes safe area)
Background: Material(.thinMaterial) with dark mode tint
Border: 0.5pt systemGray4 top border

Tab Item Spacing: Distributed evenly across 375pt width
Active state: systemBlue tint
Inactive state: systemGray tint

Icon size: 24pt × 24pt
Label spacing from icon: 4pt
```

### Tab Items
1. **Home** (Active)
   - House icon with filled state
   - systemBlue color
   
2. **Clients**
   - Two-person icon outline
   - systemGray color
   
3. **Settings**  
   - 8-tooth gear icon
   - 6pt inner circle, 2pt fill
   - systemGray color

## SwiftUI Implementation Guidelines

### View Structure
```swift
NavigationView {
    ScrollView {
        VStack(spacing: 20) {
            PrimaryActionsSection()
            SecondaryInfoSection()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    .background(Color(.systemBackground))
    .navigationTitle("AppName")
    .navigationBarTitleDisplayMode(.large)
    .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
            ProfileButton()
        }
    }
}
.tabItem {
    TabBarView()
}
```

### Animation Specifications
```swift
// Card press animations
.scaleEffect(isPressed ? 0.95 : 1.0)
.animation(.easeInOut(duration: 0.1), value: isPressed)

// Navigation transitions
.transition(.opacity.combined(with: .slide))

// Tab switching
.animation(.easeInOut(duration: 0.2), value: selectedTab)
```

### Accessibility Implementation
```swift
// VoiceOver labels
.accessibilityLabel("Add new client")
.accessibilityHint("Creates a new client profile")

// Dynamic Type support
.font(.title2)
.minimumScaleFactor(0.8)

// Touch targets
.frame(minWidth: 44, minHeight: 44)
```

## Interactive States

### Touch Feedback
- **Press**: 95% scale with 0.1s ease-in-out
- **Release**: Return to 100% scale
- **Haptic**: Light impact on successful taps

### Loading States
- Skeleton views for async content
- Progress indicators for long operations
- Graceful error states with retry options

## Data Integration Points

### Required Models
```swift
struct Client {
    let id: UUID
    let name: String
    let age: Int
    let lastSessionDate: Date?
}

struct SessionSummary {
    let client: Client
    let date: Date
    let successRate: Double
    let duration: TimeInterval
}

struct AppState {
    var clients: [Client]
    var lastSession: SessionSummary?
    var availableGoals: Int
}
```

### State Management
- Use @StateObject for view models
- @ObservableObject for data persistence
- Combine for async operations

## Performance Considerations
- Lazy loading for client lists
- Image caching for profile avatars
- Efficient list updates with @State
- Memory management for large datasets

This specification provides the complete foundation for implementing the iOS Goal Tracker home page in SwiftUI while maintaining Apple's design standards and healthcare app requirements.