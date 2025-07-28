# Therapy Data Logger - Product Requirements Document

## Project Overview

Build a native Apple Watch + iPhone app system for speech and ABA therapists to collect real-time client performance data during therapy sessions. The Apple Watch serves as the primary data collection interface during sessions, while the iPhone provides comprehensive client management, goal setup, and session analytics.

## Core Value Proposition

**Problem**: Therapists currently use paper forms or tablets that disrupt natural therapy flow, leading to incomplete data collection and reduced session effectiveness.

**Solution**: Discreet Apple Watch interface enabling rapid trial logging with intuitive swipe gestures, synchronized with comprehensive iPhone companion app for session management and analysis.

## Technical Architecture

### Platform Stack
- **Single Xcode Project** with iOS + watchOS targets
- **SwiftUI** for both platforms with platform-optimized UI
- **Core Data** with iPhone as primary store, Watch as cache
- **WatchConnectivity** for real-time device-to-device sync
- **App Groups** for shared data container
- **NSFileProtection.complete** for HIPAA-ready encryption

### Project Structure
```
TherapyDataLogger/
├── Shared/
│   ├── Models/              # Swift structs (Client, Session, GoalLog, GoalTemplate)
│   ├── CoreData/           # Core Data stack and entities
│   ├── Repositories/       # Repository protocols and implementations
│   ├── WatchConnectivity/  # Device sync logic
│   └── ViewModels/         # Shared business logic
├── iOS App/                # iPhone companion app
│   ├── Views/
│   │   ├── ClientViews/    # Client management screens
│   │   ├── GoalViews/      # Goal template creation
│   │   └── HistoryViews/   # Session review and analytics
│   ├── ViewModels/         # iOS-specific view models
│   └── Extensions/         # iOS platform extensions
├── watchOS App/            # Apple Watch app
│   ├── Views/
│   │   ├── SessionViews/   # Session management
│   │   └── LoggingViews/   # Quick goal logging
│   ├── ViewModels/         # Watch-specific view models
│   └── Extensions/         # Watch platform extensions
└── Tests/                  # Unit and integration tests
```

## Core Data Model

### ClientEntity
- `id`: UUID (required)
- `name`: String (required)
- `dateOfBirth`: Date (optional)
- `notes`: String (optional)
- `createdDate`: Date (required)
- `lastModified`: Date (required)
- Relationships: `sessions` → SessionEntity, `goalTemplates` → GoalTemplateEntity

### GoalTemplateEntity
- `id`: UUID (required)
- `title`: String (required)
- `description`: String (optional)
- `category`: String (required) # "Communication", "Social", "Articulation"
- `defaultCueLevel`: String (required)
- `clientId`: UUID (required)
- `isActive`: Boolean (required)
- `createdDate`: Date (required)
- Relationship: `client` → ClientEntity

### SessionEntity
- `id`: UUID (required)
- `date`: Date (required)
- `startTime`: Date (required)
- `endTime`: Date (optional)
- `clientId`: UUID (required)
- `notes`: String (optional)
- `location`: String (optional)
- `createdOn`: String (required) # "iPhone" or "Watch"
- `lastModified`: Date (required)
- Relationships: `client` → ClientEntity, `goalLogs` → GoalLogEntity

### GoalLogEntity
- `id`: UUID (required)
- `goalTemplateId`: UUID (optional)
- `goalDescription`: String (required)
- `cueLevel`: String (required) # "Independent", "Minimal", "Moderate", "Maximal"
- `wasSuccessful`: Boolean (required)
- `sessionId`: UUID (required)
- `timestamp`: Date (required)
- `notes`: String (optional)
- Relationship: `session` → SessionEntity

## Apple Watch App Requirements

### 1. Start Interface (Primary Entry Point)

**Start Page Layout:**
- Header: Current time (left), Settings gear (right)
- App title: "Goal Tracker"
- Client selection section with blue accent, shows selected client name
- Large green circular "START" button (60px)

**Client Selection Overlay:**
- Full-screen dark overlay with slide-up animation
- Scrollable client list with privacy-conscious display (first name + last initial)
- Age display only (no medical information)
- Tap to select, automatic overlay dismissal

**Settings Overlay:**
- Display-only settings view
- Auto-timeout: 3 seconds
- Haptic feedback: Enabled
- Data sync: WiFi only
- App version display

### 2. Goal Logging Interface (Primary Data Collection)

**Core Interaction Model:**
- **Primary Action**: Swipe up for success, swipe down for failure
- **Secondary Navigation**: Digital Crown scrolling to switch between goals
- **Tertiary Actions**: Undo last trial, view session timer

**Visual Layout:**
- Header with session timer (MM:SS, green), current time (center), undo button (orange, circular)
- Swipe prompts: "↑ SUCCESS ↑" (top, green), "↓ FAILURE ↓" (bottom, red)
- Client name in blue pill badge above goal name
- Goal name in large, bold white text
- Session percentage with color coding (green 70%+, orange 40-69%, red <40%)
- Navigation dots at bottom (4 dots for different goals)

**Gesture Implementation:**
- Swipe recognition threshold: 25px movement
- Haptic feedback: Light impact on successful swipe
- Flash feedback: "+1 Success" or "+1 Failure" overlay (800ms)
- Real-time percentage calculation and color updates

### 3. Circular Cuing Level Picker (Post-Trial Data Capture)

**Trigger:** Appears immediately after each trial flash feedback

**Visual Design:**
- Full-screen overlay with semi-transparent background
- Centered circular picker (140px × 140px)
- Center countdown timer: "3" → "2" → "1" → "0" (24px, bold)
- Four positioned buttons around center:
  - Top: Independent (blue gradient)
  - Right: Min (green gradient)
  - Bottom: Mod (orange gradient)
  - Left: Max (red gradient)

**Interaction Behavior:**
- Single tap selection with immediate dismissal
- Auto-default to "Independent" after 3 seconds
- Button scaling (1.15x) with colored glow on selection
- No confirmation required

### 4. Post-Session Summary

**Content Sections:**
- Summary header: "Session Complete", client name, duration
- Primary stats grid (2×2): Success count, failure count, total trials, success rate
- Cuing level breakdown with color-coded usage stats
- Goal performance breakdown with excellence indicators
- Action buttons: "SHARE" (secondary), "NEW SESSION" (primary, green)

**Performance Indicators:**
- Excellent (85%+): Green background
- Good (70-84%): Orange background
- Needs Work (<70%): Red background

## iPhone App Requirements

### 1. Client Management
- `ClientListView`: Browse and search clients with profile photos
- `ClientDetailView`: Full client profile with session history overview
- `ClientEditView`: Create/edit comprehensive client information
- `ClientGoalsView`: Manage goal templates specific to each client

### 2. Goal Template Management
- `GoalTemplateListView`: Browse templates organized by therapy category
- `GoalTemplateEditView`: Create/edit detailed goal templates
- `GoalCategoryView`: Organize goals by therapy type (Communication, Social, etc.)

### 3. Session History & Analytics
- `SessionHistoryView`: Browse past sessions with filtering and search
- `SessionDetailView`: Detailed session review with trial-by-trial breakdown
- `SessionAnalyticsView`: Progress charts and success rate trends over time
- `DataExportView`: Export session data as CSV or PDF reports

## Data Sync Strategy

### Sync Scenarios
1. **Session Start**: iPhone sends client data and goal templates to Watch
2. **Active Logging**: Watch immediately syncs each goal log back to iPhone
3. **Session End**: Complete session data consolidated on iPhone
4. **Client Changes**: iPhone updates Watch cache when client/goals modified
5. **Conflict Resolution**: iPhone data takes precedence with user notification

### Sync Implementation
- **Real-time sync** during active sessions using WatchConnectivity messages
- **Background sync** for client/template updates using application context
- **Offline mode** with local caching and background sync when connectivity restored
- **Data integrity** with UUID-based conflict resolution

## Key Features by Development Phase

### Phase 1: Core MVP
- [ ] Client management on iPhone
- [ ] Basic goal template creation
- [ ] WatchConnectivity setup and sync
- [ ] Watch session start/client selection
- [ ] Goal logging with swipe gestures
- [ ] Cuing level picker implementation
- [ ] Session summary display
- [ ] Basic session history on iPhone

### Phase 2: Enhanced UX
- [ ] Advanced session analytics
- [ ] Goal template import/export
- [ ] Voice-to-text notes
- [ ] Watch complications
- [ ] Improved data visualizations

### Phase 3: Professional Features
- [ ] Multi-therapist support
- [ ] Progress reports and documentation
- [ ] Practice management integration
- [ ] Advanced analytics and trends

## Security & Privacy Requirements

### Data Protection
- All data encrypted at rest using NSFileProtection.complete
- No cloud sync in MVP (local device-to-device only)
- Secure WatchConnectivity transfer
- App Groups for shared data access between targets

### HIPAA Considerations
- Local-only data storage
- User authentication options
- Audit trail of data access
- Secure data export capabilities

## Performance Requirements

### Apple Watch Optimization
- Session start within 2 seconds of "START" button tap
- Gesture recognition within 100ms
- Smooth 60fps animations during interactions
- Efficient battery usage during extended sessions
- Minimal Core Data operations (use in-memory caching)

### iPhone Optimization
- Full client database load within 1 second
- Responsive session analytics with large datasets
- Efficient sync handling without UI blocking
- Quick data export for large session histories

## Testing Requirements

### Unit Tests
- Repository implementations with mock data
- WatchConnectivity message handling
- Data sync conflict resolution
- Business logic in ViewModels

### Integration Tests
- End-to-end data flow iPhone → Watch → iPhone
- Core Data stack initialization on both platforms
- Sync performance under various network conditions

### UI Tests
- Critical user flows on both platforms
- Complete session workflow from client selection to summary
- Goal template management and usage

## Deployment Configuration

### App Store Requirements
- Single app bundle with both iPhone and Watch targets
- Screenshots for both devices
- Privacy policy covering local data storage
- Medical device compliance review if applicable

### Development Setup
- App Groups entitlement: `group.com.yourcompany.therapydatalogger`
- File protection: NSFileProtectionComplete
- WatchConnectivity capabilities
- Background app refresh for sync

## Success Metrics

### Primary KPIs
- Session completion rate (target: >95%)
- Average trials logged per session (target: 30+)
- Time from app launch to first trial logged (target: <10 seconds)
- Data sync success rate (target: >99%)

### User Experience Goals
- Therapists can complete full session workflow without looking at iPhone
- Zero data loss during typical therapy sessions
- Intuitive interface requiring minimal training
- Professional appearance suitable for clinical environments

## Technical Constraints

### Apple Watch Limitations
- Limited screen real estate (176px × 216px for 44mm)
- Battery optimization crucial for extended sessions
- Memory constraints require efficient caching strategies
- WatchConnectivity has message size limits

### iPhone App Considerations
- Must work seamlessly with Watch during active sessions
- Handle large datasets efficiently for session history
- Export capabilities for clinical record keeping
- Maintain sync reliability in various network conditions

This specification provides comprehensive requirements for building a professional-grade therapy data collection system optimized for the unique constraints and opportunities of the Apple Watch + iPhone ecosystem.