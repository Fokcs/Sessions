# watchOS Goal Tracker - Simple Session Summary UX Specification

## Overview
The simple session summary provides a clean, scannable overview of goal performance after a tracking session ends. It displays each targeted goal with its success rate and trial count in a standardized format, enabling therapists to quickly assess session outcomes and plan next steps.

## Design Principles
- **Clarity First**: Focus on essential performance metrics only
- **Scannable Format**: Consistent layout for rapid visual processing
- **Immediate Assessment**: Color-coded performance indicators for instant feedback
- **Minimal Cognitive Load**: Eliminate unnecessary complexity and visual noise
- **Workflow Continuity**: Direct path to next session or data sharing

## Screen Specification

### Visual Layout
**Screen Dimensions:** 176px × 216px (Apple Watch 44mm)

**Header Section:**
- Position: Top of screen, 24px height
- Background: Semi-transparent overlay (rgba(255,255,255,0.03))
- Left: Current time display (10px font, gray #999)
- Right: Close button (× symbol, 16px × 16px, gray #999)
- Padding: 8px × 12px

**Main Content Area:**
- Padding: 15px × 12px
- Slide-up animation on appearance (0.4s ease-out)
- Flex column layout with auto-spacing

### Content Sections

#### 1. Session Header
**Layout:**
- Centered text block
- 20px margin bottom

**Content:**
- Title: "Session Complete" (14px, semibold, white)
- Session info: "{Client Name} • {Duration}" (9px, gray #666)
- Example: "Sarah M. • 18:24 duration"

#### 2. Goals List
**Container:**
- Flexible height list
- 20px margin bottom
- Scrollable if content exceeds available space

**Goal Item Layout:**
- Background: rgba(255,255,255,0.05)
- Border: 1px solid rgba(255,255,255,0.1)
- Border radius: 12px
- Padding: 12px × 14px
- Margin bottom: 8px
- Flex layout: name left, stats right

**Goal Information Display:**
- **Left Side**: Goal name (11px, medium weight, white)
- **Right Side**: Performance stats with consistent spacing

**Performance Format:**
```
Goal Name - Percentage (Success/Total)
```

**Examples:**
- Water Goal - 70% (7/10)
- Exercise Goal - 90% (9/10)
- Reading Goal - 50% (10/20)
- Communication - 83% (5/6)

#### 3. Performance Indicators
**Color Coding System:**
- **Excellent (80%+)**: Green #30D158
- **Good (65-79%)**: Orange #FF9500
- **Needs Work (<65%)**: Red #FF3B30

**Typography:**
- Percentage: 11px, bold, color-coded
- Trial count: 9px, gray #666, parentheses format

#### 4. Action Buttons
**Layout:**
- Fixed at bottom of content area
- Horizontal flex with 8px gap
- Equal width buttons (1:1 ratio)

**Button Specifications:**
- Height: ~36px with 10px padding
- Border radius: 15px
- Text: 9px, uppercase, bold

**Share Button (Secondary):**
- Background: rgba(255,255,255,0.1)
- Border: 1px solid rgba(255,255,255,0.2)
- Text: "SHARE" (gray #999)

**New Session Button (Primary):**
- Background: Green gradient (linear-gradient(135deg, #30D158, #228B22))
- Border: 1px solid #30D158
- Text: "NEW SESSION" (black #000)

## Data Models

### Session Summary Structure
```swift
struct SimpleSessionSummary {
    let sessionId: UUID
    let clientName: String
    let duration: TimeInterval
    let goalResults: [GoalResult]
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct GoalResult {
    let goalName: String
    let successCount: Int
    let totalTrials: Int
    
    var successRate: Int {
        guard totalTrials > 0 else { return 0 }
        return Int((Double(successCount) / Double(totalTrials)) * 100)
    }
    
    var performanceLevel: PerformanceLevel {
        switch successRate {
        case 80...100: return .excellent
        case 65...79: return .good
        default: return .needsWork
        }
    }
    
    var displayFormat: String {
        return "\(successRate)% (\(successCount)/\(totalTrials))"
    }
}

enum PerformanceLevel {
    case excellent, good, needsWork
    
    var color: Color {
        switch self {
        case .excellent: return Color(hex: "30D158")
        case .good: return Color(hex: "FF9500")
        case .needsWork: return Color(hex: "FF3B30")
        }
    }
}
```

## SwiftUI Implementation Guidelines

### Main View Structure
```swift
struct SimpleSessionSummaryView: View {
    let sessionSummary: SimpleSessionSummary
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            HeaderView()
            
            ScrollView {
                VStack(spacing: 15) {
                    SessionHeaderView(summary: sessionSummary)
                    GoalsListView(goals: sessionSummary.goalResults)
                    ActionButtonsView(
                        onShare: shareSession,
                        onNewSession: startNewSession
                    )
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 15)
            }
        }
        .animation(.easeOut(duration: 0.4), value: sessionSummary)
    }
}
```

### Key Component Views
```swift
struct GoalResultRow: View {
    let goal: GoalResult
    
    var body: some View {
        HStack {
            Text(goal.goalName)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            HStack(spacing: 6) {
                Text("\(goal.successRate)%")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(goal.performanceLevel.color)
                
                Text("(\(goal.successCount)/\(goal.totalTrials))")
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

struct ActionButtonsView: View {
    let onShare: () -> Void
    let onNewSession: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Button(action: onShare) {
                Text("SHARE")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .cornerRadius(15)
            }
            
            Button(action: onNewSession) {
                Text("NEW SESSION")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "30D158"), Color(hex: "228B22")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(15)
            }
        }
    }
}
```

## Interaction Behaviors

### Navigation Actions
```swift
// Close summary
.onTapGesture { 
    dismiss()
    // Returns to start page
}

// New session
.onTapGesture { 
    navigationManager.startNewSession()
    // Navigates to goal selection interface
}

// Share results
.onTapGesture { 
    shareManager.shareSessionSummary(sessionSummary)
    // Opens share sheet or triggers data sync
}
```

### Visual Feedback
- **Button Press**: Scale effect (1.0 → 0.95 → 1.0) over 0.1s
- **Hover States**: Background opacity increase for interactive elements
- **Loading States**: Subtle opacity changes during share/navigation actions

## Accessibility Features

### VoiceOver Support
- **Goal Results**: "Water goal, 70 percent success rate, 7 successes out of 10 trials"
- **Performance Level**: "Excellent performance" / "Good performance" / "Needs improvement"
- **Action Buttons**: "Share session results button", "Start new session button"

### Dynamic Type Support
- All text scales proportionally with user's preferred text size
- Layout maintains hierarchy at larger text sizes
- Button touch targets remain accessible (minimum 44pt)

### High Contrast Mode
- Enhanced border visibility for goal items and buttons
- Increased opacity for background elements
- Stronger color differentiation for performance indicators

## Usage Context

### Typical User Workflow
1. **Session End**: Automatic transition from goal logging to summary
2. **Quick Scan**: 3-5 second review of goal performance (most common)
3. **Action Decision**: 
   - **New Session** (~75% of cases): Immediate return to goal tracking
   - **Share Results** (~20% of cases): Export for record keeping
   - **Close/Review** (~5% of cases): Return to start page

### Performance Requirements
- **Load Time**: <150ms from session end to summary display
- **Smooth Scrolling**: 60fps performance with goal list
- **Responsive Touch**: <100ms feedback for all interactive elements
- **Memory Efficiency**: Minimal data retention after navigation

### Error Handling
- **No Goals Logged**: Display "No goals completed" message with new session option
- **Incomplete Data**: Show available results with warning indicator
- **Share Failure**: Non-blocking error toast with retry option
- **Navigation Issues**: Graceful fallback to start page

## Integration Requirements

### Data Sources
- **Session Engine**: Aggregated trial results by goal
- **Goal Manager**: Goal names and configurations
- **Timer Service**: Session duration calculation
- **Client Profile**: Client name for header display

### Export Capabilities
- **Share Sheet**: Standard watchOS sharing interface
- **Data Sync**: Automatic backup to paired iPhone app
- **Report Format**: Structured summary for clinical documentation
- **Historical Tracking**: Data storage for progress analysis

This simplified summary interface prioritizes immediate comprehension over comprehensive analytics, enabling therapists to quickly assess session outcomes and maintain efficient workflow momentum in clinical environments.