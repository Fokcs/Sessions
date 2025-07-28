# Circular Cuing Level Picker - UX Design Specification

## Overview
A post-trial overlay that appears after each success/failure log to capture the cuing level provided during that trial. The interface uses a circular tap-based picker that auto-defaults to "Independent" after 3 seconds, optimized for rapid data collection during therapy sessions.

## Interaction Flow

### 1. Trigger Event
- Appears immediately after trial flash feedback ("+1 Success" or "+1 Failure")
- Overlays the entire screen with semi-transparent background
- Smooth fade-in animation (0.3s duration)

### 2. Visual Layout
**Full-screen overlay** with centered circular picker (140px × 140px)

**Center Element:**
- 70px circular display with subtle border
- Large countdown timer (24px, bold): "3" → "2" → "1" → "0"
- Updates every 1 second
- White text on semi-transparent background

**Four Option Buttons positioned around center:**
- **Top (12 o'clock)**: Independent - Blue gradient (#007AFF to #0056CC)
- **Right (3 o'clock)**: Min - Green gradient (#30D158 to #228B22)
- **Bottom (6 o'clock)**: Mod - Orange gradient (#FF9500 to #CC7700)
- **Left (9 o'clock)**: Max - Red gradient (#FF3B30 to #CC2A20)

Each button:
- 35px circular size
- White border (2px, semi-transparent)
- Abbreviated label: "IND", "MIN", "MOD", "MAX"
- 8px font, bold, uppercase

### 3. User Interactions

**Tap Selection:**
- Tap any button to immediately select that cuing level
- Button scales up (1.15x) with colored glow on selection
- Overlay dismisses instantly (no delay)
- Selection logged to trial data

**Auto-Default Behavior:**
- If no selection made within 3 seconds, automatically selects "Independent"
- Countdown timer shows remaining time visually
- Overlay dismisses automatically

**Visual Feedback:**
- Hover state: buttons scale to 1.1x
- Selected state: 1.15x scale + matching colored glow shadow
- No selection feedback in center (stays neutral until timeout)

## Design Principles

### Speed-Optimized
- **Single tap selection** - fastest possible input
- **Large touch targets** (35px minimum) for easy finger tapping
- **Immediate response** - no confirmation delays
- **Smart default** - "Independent" covers majority of trials

### Visual Clarity
- **Color coding** consistent with severity levels (blue=minimal → red=maximum)
- **High contrast** text and borders for readability
- **Minimal text** - abbreviated labels to reduce cognitive load
- **Clear timing** - large countdown prevents uncertainty

### Contextual Appropriateness
- **Circular layout** matches Apple Watch design language
- **Muscle memory positioning** - consistent button locations
- **One-handed operation** - all buttons reachable with thumb
- **Non-disruptive** - doesn't interrupt main workflow

## Data Structure

### Trial Data Enhancement
Each logged trial now includes:
```
trial: {
  success: boolean,
  cuingLevel: "independent" | "min" | "mod" | "max",
  timestamp: Date,
  goalType: string
}
```

### Default Behavior
- **Default Selection**: "independent" (covers ~70% of typical trials)
- **Timeout Duration**: 3 seconds (balances speed vs. accuracy)
- **Auto-dismiss**: Prevents interface blocking if user distracted

## SwiftUI Implementation Guidelines

### Key Components
```swift
// Main overlay view
struct CuingLevelPicker: View {
    @State private var timeRemaining = 3
    @State private var selectedLevel: CuingLevel? = nil
    let onSelection: (CuingLevel) -> Void
}

// Circular button positioning
struct CircularButtonLayout {
    // Use GeometryReader with trigonometric positioning
    // Independent: top (0°)
    // Min: right (90°) 
    // Mod: bottom (180°)
    // Max: left (270°)
}
```

### Animation Details
- **Fade-in**: `opacity` 0 → 1 over 0.3s with `easeOut`
- **Button scaling**: `scaleEffect` 1.0 → 1.1 (hover) → 1.15 (selected)
- **Glow effect**: `shadow` with matching button color, radius 15pt
- **Countdown**: `onReceive(timer)` updating every 1 second

### Touch Handling
```swift
.onTapGesture {
    selectedLevel = cuingLevel
    onSelection(cuingLevel)
    // Dismiss immediately - no delay
}
```

### Color Palette
```swift
enum CuingLevel: String, CaseIterable {
    case independent = "independent"
    case min = "min" 
    case mod = "mod"
    case max = "max"
    
    var gradient: LinearGradient {
        switch self {
        case .independent: 
            return LinearGradient([.blue, Color(hex: "0056CC")])
        case .min:
            return LinearGradient([.green, Color(hex: "228B22")])
        case .mod:
            return LinearGradient([.orange, Color(hex: "CC7700")])
        case .max:
            return LinearGradient([.red, Color(hex: "CC2A20")])
        }
    }
}
```

### Accessibility Considerations
- **VoiceOver labels**: "Independent cuing level", "Minimal cuing level", etc.
- **Haptic feedback**: Light impact on button press
- **Voice activation**: Consider "Hey Siri, Independent" for hands-free operation
- **High contrast mode**: Ensure border visibility increases

### Performance Optimization
- **Lazy rendering**: Only show when needed (after trial log)
- **Timer cleanup**: Cancel timer on manual selection
- **State management**: Reset countdown on each appearance
- **Memory efficiency**: Dispose overlay when dismissed

## Usage Context
This picker appears in high-frequency usage scenarios (potentially 50+ times per therapy session). The design prioritizes:

1. **Speed over precision** - Quick defaults for common cases
2. **Minimal cognitive load** - Simple visual hierarchy
3. **Consistent muscle memory** - Fixed button positions
4. **Error tolerance** - Easy to correct if wrong selection made

The circular layout leverages the natural affordances of the Apple Watch's round Digital Crown and circular interface patterns, making it feel native to the platform while optimizing for the specific needs of rapid clinical data collection.