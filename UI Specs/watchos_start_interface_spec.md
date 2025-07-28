# watchOS Goal Tracker - Start Interface UX Specification

## Overview
The start interface provides the entry point for the Goal Tracker app on Apple Watch. It consists of three main screens: Start Page, Client Selection, and Settings. The design prioritizes quick access to begin tracking sessions while maintaining essential configuration options.

## Design Principles
- **Speed-First**: Minimize steps to start a tracking session
- **Large Touch Targets**: Optimize for small screen and finger interaction
- **Clear Hierarchy**: Prominent primary actions, subtle secondary options
- **Privacy-Conscious**: No sensitive medical information displayed
- **Apple Watch Native**: Follows watchOS design patterns and constraints

## Screen Specifications

### 1. Start Page (Main Screen)

#### Visual Layout
**Screen Dimensions:** 176px × 216px (Apple Watch 44mm)

**Header Section:**
- Position: Top of screen, 24px height
- Background: Semi-transparent overlay (rgba(255,255,255,0.03))
- Left: Current time display (10px font, gray #999)
- Right: Settings gear icon (16px × 16px, gray #999)
- Padding: 8px × 12px

**Main Content Area:**
- Centered vertically in remaining space
- Padding: 15px × 12px

**App Title:**
- Text: "Goal Tracker"
- Font: 11px, semibold, white
- Position: Top of content area
- Margin bottom: 15px

**Client Selection Section:**
- Label: "CURRENT CLIENT" (7px, uppercase, gray #666)
- Container: Rounded rectangle with blue accent
- Background: rgba(0,122,255,0.15)
- Border: 1px solid rgba(0,122,255,0.3)
- Padding: 6px × 10px
- Border radius: 12px
- Client name: 11px, semibold, blue #007AFF
- Subtitle: "Tap to change" (6px, gray #666)
- Chevron: Right arrow (›) positioned at right edge

**Start Button:**
- Size: 60px × 60px circular button
- Background: Green gradient (linear-gradient(135deg, #30D158, #228B22))
- Text: "START" (12px, bold, black #000)
- Shadow: 0 3px 15px rgba(48,209,88,0.3)
- Hover: Scale 1.05x with enhanced shadow
- Active: Scale 0.95x

#### Interaction Behavior
- **Tap Client Section**: Opens client selection overlay
- **Tap Settings Icon**: Opens settings overlay  
- **Tap Start Button**: Begins tracking session with selected client
- **Visual Feedback**: Buttons scale and glow on interaction

### 2. Client Selection Overlay

#### Visual Layout
**Overlay Style:**
- Full-screen overlay with dark background (rgba(0,0,0,0.95))
- Slide-up animation (0.3s ease-out)

**Header:**
- Height: ~36px with 12px padding
- Title: "Select Client" (11px, semibold, white)
- Subtitle: "Choose who you're working with" (7px, gray #666)
- Close button: × symbol (18px × 18px, top-right)

**Client List:**
- Scrollable area filling remaining space
- Padding: 8px

**Client Items:**
- Background: rgba(255,255,255,0.05)
- Border: 1px solid rgba(255,255,255,0.1)
- Border radius: 10px
- Padding: 8px × 10px
- Margin bottom: 5px
- Selected state: Blue background rgba(0,122,255,0.2) with blue border

**Client Information Display:**
- Name: 10px, semibold, white (e.g., "Sarah M.")
- Age: 6px, gray #999 (e.g., "Age 8")
- No medical diagnoses displayed

#### Data Structure
```javascript
clients = {
  id: {
    name: "First Last Initial",
    details: "Age X"
  }
}
```

#### Interaction Behavior
- **Tap Client Item**: Select client, update main screen, close overlay with 300ms delay
- **Tap Close Button**: Dismiss overlay without changes
- **Visual Feedback**: Items highlight on hover, selected item has blue accent
- **Selection Persistence**: Selected client highlighted with blue background

### 3. Settings Overlay

#### Visual Layout
**Overlay Style:**
- Full-screen overlay with dark background (rgba(0,0,0,0.95))
- Slide-up animation (0.3s ease-out)

**Header:**
- Height: ~36px with 12px padding
- Title: "Settings" (11px, semibold, white)
- Close button: × symbol (18px × 18px, top-right)

**Settings List:**
- Padding: 12px
- Non-scrollable (fits within screen)

**Setting Items:**
- Background: rgba(255,255,255,0.05)
- Border radius: 10px  
- Padding: 8px × 10px
- Margin bottom: 6px
- Two-column layout: label left, value right

**Setting Content:**
- Label: 9px, white (e.g., "Auto-timeout")
- Value: 8px, gray #666 (e.g., "3 seconds")

#### Default Settings Display
```
Auto-timeout        3 seconds
Haptic feedback     Enabled  
Data sync          WiFi only
App version        1.2.0
```

#### Interaction Behavior
- **Tap Close Button**: Dismiss overlay
- **Setting Items**: Display-only (no inline editing)
- **Future Enhancement**: Individual settings could navigate to detail screens

## Navigation Flow

### Primary Flow
1. **App Launch** → Start Page
2. **Start Page** → Tap Start → Main Goal Logging Interface
3. **Start Page** → Tap Client → Client Selection → Start Page
4. **Start Page** → Tap Settings → Settings Overlay → Start Page

### State Management
- **Current Client**: Persisted across app sessions
- **Settings**: Stored in app preferences
- **Navigation Stack**: Overlays dismiss to Start Page

## SwiftUI Implementation Guidelines

### Key View Structure
```swift
struct StartView: View {
    @State private var selectedClient: Client
    @State private var showingClientSelection = false
    @State private var showingSettings = false
    
    var body: some View {
        // Main start page content
    }
}

struct ClientSelectionView: View {
    @Binding var selectedClient: Client
    @Environment(\.dismiss) private var dismiss
    let clients: [Client]
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("autoTimeout") private var autoTimeout = 3
    @AppStorage("hapticEnabled") private var hapticEnabled = true
}
```

### Data Models
```swift
struct Client: Identifiable, Codable {
    let id = UUID()
    let name: String
    let age: Int
    
    var displayName: String { name }
    var displayDetails: String { "Age \(age)" }
}

struct AppSettings {
    var autoTimeout: Int = 3
    var hapticEnabled: Bool = true
    var syncOnWiFiOnly: Bool = true
    var appVersion: String = "1.2.0"
}
```

### Animation Specifications
```swift
// Overlay presentation
.transition(.move(edge: .bottom).combined(with: .opacity))
.animation(.easeOut(duration: 0.3), value: showingOverlay)

// Button interactions
.scaleEffect(isPressed ? 0.95 : 1.0)
.animation(.easeInOut(duration: 0.1), value: isPressed)

// Start button hover effect
.scaleEffect(isHovered ? 1.05 : 1.0)
.shadow(radius: isHovered ? 20 : 15)
```

### Accessibility Features
- **VoiceOver Labels**: All interactive elements have descriptive labels
- **Dynamic Type**: Text scales with user's preferred text size
- **High Contrast**: Enhanced borders and backgrounds in high contrast mode
- **Voice Control**: "Tap Start", "Show Settings", "Select Client" commands

### Performance Considerations
- **Lazy Loading**: Client list uses LazyVStack for large datasets
- **State Persistence**: Selected client saved to UserDefaults
- **Memory Management**: Overlays disposed when dismissed
- **Battery Optimization**: Minimal background processing

## Technical Requirements

### Minimum watchOS Version
- watchOS 9.0+ (for latest SwiftUI features)
- Backward compatibility considerations for older devices

### Dependencies
- SwiftUI framework
- Foundation (for UserDefaults, data persistence)
- WatchKit (for device-specific optimizations)

### Data Storage
- **Client List**: Bundled with app or synced from companion iOS app
- **Selected Client**: UserDefaults key "selectedClientID"
- **Settings**: @AppStorage property wrappers
- **Session Data**: Core Data or CloudKit (depending on sync requirements)

### Error Handling
- **No Clients Available**: Show placeholder with "Add clients in iPhone app" message
- **Settings Load Failure**: Use default values, show non-blocking error
- **Navigation Failures**: Graceful fallback to Start Page

## Usage Context
This interface serves as the entry point for therapy sessions, potentially used 10-50 times per day by healthcare professionals. Design priorities:

1. **Rapid Session Initiation**: Minimize taps to start tracking
2. **Client Safety**: Ensure correct client selected before starting
3. **Minimal Cognitive Load**: Clear visual hierarchy, familiar patterns
4. **Error Prevention**: Confirmation of client selection, persistent state
5. **Professional Appearance**: Clean, medical-appropriate aesthetic

The interface balances speed with accuracy, ensuring therapists can quickly begin data collection while maintaining proper client identification and configuration.