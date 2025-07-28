# watchOS Goal Tracker - Post-Session Summary UX Specification

## Overview
The post-session summary provides immediate feedback and analytics after a goal tracking session ends. It displays key performance metrics, cuing level usage, and goal-specific breakdowns to help therapists quickly assess session effectiveness and plan next steps.

## Design Principles
- **Immediate Value**: Show most important metrics first
- **Scannable Layout**: Enable quick assessment of session success
- **Actionable Insights**: Highlight areas needing attention
- **Workflow Continuity**: Easy transition to next session or data sharing
- **Data Transparency**: Clear breakdown of all collected metrics

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
- Scrollable content with 12px padding
- Slide-up animation on appearance (0.4s ease-out)

### Content Sections

#### 1. Summary Header
**Layout:**
- Centered text block
- 15px margin bottom

**Content:**
- Title: "Session Complete" (12px, semibold, white)
- Session info: "{Client Name} • {Duration}" (8px, gray #666)
- Example: "Sarah M. • 18:24 duration"

#### 2. Primary Stats Grid
**Layout:**
- 2×2 CSS Grid with 8px gaps
- 15px margin bottom

**Stat Cards:**
- Background: rgba(255,255,255,0.05)
- Border: 1px solid rgba(255,255,255,0.1)
- Border radius: 10px
- Padding: 10px × 8px
- Center-aligned content

**Card Content:**
- Value: 16px, bold, color-coded
- Label: 7px, uppercase, gray #666

**Color Coding:**
- Success count: Green #30D158
- Failure count: Red #FF3B30  
- Total trials: Blue #007AFF
- Success rate: Orange #FF9500

#### 3. Cuing Level Summary
**Layout:**
- Single container with 8px padding
- Background: rgba(255,255,255,0.05)
- Border radius: 8px
- 12px margin bottom

**Header:**
- Title: "Cuing Levels Used" (8px, uppercase, gray #666)
- Center-aligned, 6px margin bottom

**Breakdown Display:**
- Horizontal flex layout with equal spacing
- Four columns for each cuing level

**Cuing Items:**
- Value: 10px, bold, color-coded
- Label: 6px, uppercase, gray #666
- Center-aligned

**Cuing Level Colors:**
- Independent: Blue #007AFF
- Min: Green #30D158  
- Mod: Orange #FF9500
- Max: Red #FF3B30

#### 4. Goal Performance Breakdown
**Layout:**
- Title: "Goal Performance" (9px, uppercase, center-aligned)
- 8px margin bottom

**Goal Items:**
- Background: rgba(255,255,255,0.05)
- Border radius: 8px
- Padding: 6px × 8px
- 4px margin bottom
- Flex layout: name left, stats right

**Goal Information:**
- Name: 9px, medium weight, white
- Percentage badge: 8px, bold, colored background
- Count: 7px, gray #666 (format: "success/total")

**Performance Indicators:**
- **Excellent (85%+)**: Green background rgba(48,209,88,0.2), green text #30D158
- **Good (70-84%)**: Orange background rgba(255,149,0,0.2), orange text #FF9500  
- **Needs Work (<70%)**: Red background rgba(255,59,48,0.2), red text #FF3B30

#### 5. Action Buttons
**Layout:**
- Fixed at bottom of content area
- Horizontal flex with 8px gap
- Margin top: auto (pushes to bottom)

**Button Specifications:**
- Height: ~32px with 8px padding
- Border radius: 12px
- Equal flex width (1:1 ratio)

**Share Button (Secondary):**
- Background: rgba(255,255,255,0.1)
- Border: 1px solid rgba(255,255,255,0.2)
- Text: "SHARE" (8px, uppercase, gray #999)

**New Session Button (Primary):**
- Background: Green gradient (linear-gradient(135deg, #30D158, #228B22))
- Border: 1px solid #30D158
- Text: "NEW SESSION" (8px, uppercase, black #000)

## Interaction Behaviors

### Navigation Actions
```swift
// Close summary
.onTapGesture { dismiss() }
// Returns to start page

// New session
.onTapGesture { startNewSession() }
// Navigates to goal selection interface

// Share results  
.onTapGesture { shareSession() }
// Opens share sheet or triggers data sync
```

### Visual Feedback
- **Button Press**: Scale effect (1.0 → 0.95 → 1.0)
- **Hover States**: Background color intensification
- **Loading States**: Subtle opacity changes during actions

### Data Display Logic
```swift
// Success rate calculation
let successRate = Int((Double(successTrials) / Double(totalTrials)) * 100)

// Performance categorization
func getPerformanceLevel(_ percentage: Int) -> PerformanceLevel {
    switch percentage {
    case 85...100: return .excellent
    case 70...84: return .good  
    default: return .needsWork
    }
}

// Duration formatting
func formatDuration(_ seconds: Int) -> String {
    let minutes = seconds / 60
    let remainingSeconds = seconds % 60
    return String(format: "%d:%02d", minutes, remainingSeconds)
}
```

## Data Models

### Session Summary Structure
```swift
struct SessionSummary {
    let sessionId: UUID
    let clientId: UUID
    let clientName: String
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    
    let totalTrials: Int
    let successTrials: Int
    let failureTrials: Int
    
    let cuingLevelBreakdown: CuingLevelStats
    let goalBreakdown: [GoalPerformance]
    
    var successRate: Int {
        return Int((Double(successTrials) / Double(totalTrials)) * 100)
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct CuingLevelStats {
    let independent: Int
    let minimal: Int
    let moderate: Int
    let maximum: Int
}

struct GoalPerformance {
    let goalName: String
    let successCount: Int
    let totalCount: Int
    
    var successRate: Int {
        return Int((Double(successCount) / Double(totalCount)) * 100)
    }
    
    var performanceLevel: PerformanceLevel {
        switch successRate {
        case 85...100: return .excellent
        case 70...84: return .good
        default: return .needsWork
        }
    }
}

enum PerformanceLevel {
    case excellent, good, needsWork
    
    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .orange
        case .needsWork: return .red
        }
    }
}
```

## SwiftUI Implementation Guidelines

### Main View Structure
```swift
struct SessionSummaryView: View {
    let sessionSummary: SessionSummary
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 15) {
                SummaryHeaderView(summary: sessionSummary)
                StatsGridView(summary: sessionSummary)
                CuingLevelView(stats: sessionSummary.cuingLevelBreakdown)
                GoalBreakdownView(goals: sessionSummary.goalBreakdown)
                ActionButtonsView(onNewSession: startNewSession, 
                                onShare: shareSession)
            }
            .padding(12)
        }
        .animation(.easeOut(duration: 0.4), value: sessionSummary)
    }
}
```

### Key Component Views
```swift
struct StatsGridView: View {
    let summary: SessionSummary
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), 
                  spacing: 8) {
            StatCard(value: summary.successTrials, 
                    label: "Success", 
                    color: .green)
            StatCard(value: summary.failureTrials, 
                    label: "Failed", 
                    color: .red)
            StatCard(value: summary.totalTrials, 
                    label: "Total", 
                    color: .blue)
            StatCard(value: summary.successRate, 
                    label: "Success Rate", 
                    color: .orange, 
                    suffix: "%")
        }
    }
}

struct GoalPerformanceRow: View {
    let goal: GoalPerformance
    
    var body: some View {
        HStack {
            Text(goal.goalName)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            HStack(spacing: 8) {
                Text("\(goal.successRate)%")
                    .font(.system(size: 8, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(goal.performanceLevel.color.opacity(0.2))
                    .foregroundColor(goal.performanceLevel.color)
                    .cornerRadius(6)
                
                Text("\(goal.successCount)/\(goal.totalCount)")
                    .font(.system(size: 7))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}
```

## Accessibility Features

### VoiceOver Support
- **Statistical Summary**: "Session complete. 23 successes, 7 failures, 30 total trials, 77 percent success rate"
- **Goal Performance**: "Water goal, 85 percent success rate, excellent performance"
- **Action Buttons**: "Start new session button", "Share session results button"

### Dynamic Type Support
- All text scales proportionally with user's preferred text size
- Maintains layout hierarchy at larger sizes
- Button touch targets remain accessible

### High Contrast Mode
- Enhanced border visibility for all cards and buttons
- Increased opacity for background elements
- Stronger color differentiation for performance indicators

## Usage Context & Performance

### Typical Usage Patterns
- **Quick Review**: 10-15 second scan of main metrics
- **Detailed Analysis**: 30-45 second review of goal breakdown
- **Workflow Continuation**: Immediate transition to new session (~80% of cases)
- **Data Export**: Periodic sharing for record-keeping (~20% of cases)

### Performance Requirements
- **Load Time**: <200ms from session end to summary display
- **Smooth Scrolling**: 60fps scroll performance with minimal content
- **Responsive Interactions**: <100ms button feedback
- **Memory Usage**: Minimal retention - dispose after navigation

### Error Handling
- **No Data Available**: Show placeholder with "No trials recorded" message
- **Incomplete Session**: Display partial data with warning indicator
- **Share Failure**: Non-blocking error with retry option
- **Navigation Issues**: Graceful fallback to start page

## Integration Points

### Data Sources
- **Session Engine**: Real-time trial data aggregation
- **Goal Manager**: Individual goal configurations and targets
- **Client Profile**: Name and identification for header display
- **Settings**: Preferred metrics display and sharing options

### Export Capabilities
- **Share Sheet**: Standard iOS/watchOS sharing interface
- **Cloud Sync**: Automatic backup to paired iPhone app
- **Report Generation**: Formatted summary for clinical records
- **Trend Analysis**: Historical data for progress tracking

This summary interface serves as the crucial feedback loop for therapists, providing immediate insight into session effectiveness and enabling data-driven adjustments to therapy approaches.