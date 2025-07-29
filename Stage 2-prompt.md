## Stage 2: iPhone Data Management

### Prompt 2.1: iPhone Client and Goal Management

```
Using the working foundation from Stage 1, implement Stage 2 (iPhone Data Management) of the Therapy Data Logger app. 

SCOPE FOR THIS STAGE:
- Build complete iPhone client management interface (
- Implement goal template creation and management
- Create navigation structure for iPhone app
- Add data validation and error handling in UI
- Implement basic search and filtering
- Create sample data for testing


SPECIFIC REQUIREMENTS:

1. CLIENT MANAGEMENT:
   - ClientListView: Browse clients with search functionality
   - ClientDetailView: View client profile with session count and goal templates
   - ClientEditView: Create/edit client with form validation
   - Client deletion with confirmation and cascade handling

2. GOAL TEMPLATE MANAGEMENT:
   - GoalTemplateListView: Browse templates by category
   - GoalTemplateEditView: Create/edit with category selection
   - Template activation/deactivation (soft delete)
   - Default cue level selection with visual indicators

3. NAVIGATION STRUCTURE:
   - TabView with Clients, Goals, Sessions tabs
   - Proper navigation titles and toolbar buttons
   - SwiftUI navigation best practices
   - Pull-to-refresh functionality

4. DATA FEATURES:
   - Form validation with user feedback
   - Search and filter capabilities
   - Sample data creation for testing
   - Error states and empty states
   - Loading indicators for async operations

5. UI REQUIREMENTS:
   - Modern iOS design following Human Interface Guidelines
   - Accessibility support (VoiceOver, Dynamic Type)
   - Proper use of SF Symbols
   - Color coding for cue levels matching CueLevel enum
   - Responsive layout for different screen sizes

VALIDATION CRITERIA:
- All iPhone screens navigate properly
- CRUD operations work for clients and goal templates
- Search and filtering function correctly
- Forms validate input appropriately
- Sample data populates correctly
- No crashes or memory leaks
- Repository integration works seamlessly
- Accessibility labels present

DO NOT IMPLEMENT:
- Session management UI (that's Stage 3 with Watch integration)
- Analytics or reporting features
- WatchConnectivity code
- Data export functionality
- Apple Watch UI

Create a complete, polished iPhone experience for client and goal management that therapists can use to set up their practice before conducting sessions with the Apple Watch.