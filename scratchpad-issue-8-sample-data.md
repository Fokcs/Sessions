# Issue #8: Create Sample Data Generation System

**GitHub Issue**: https://github.com/Fokcs/Sessions/issues/8

## Issue Summary
Build a comprehensive sample data generation system for testing and development that creates realistic therapy scenarios and client profiles.

## Requirements Analysis
From the GitHub issue:
- Create SampleDataManager in both iOS and watchOS Models folders
- Generate realistic therapy scenarios and client profiles
- Add method to reset/clear sample data for testing
- Include diverse client demographics and goal templates
- Sample data integrates with SimpleCoreDataRepository

## Current State Analysis
- **Repository Layer**: SimpleCoreDataRepository is fully implemented with CRUD operations
- **Models**: Client, GoalTemplate, Session, GoalLog models are complete
- **Core Data**: Stack is configured with proper entity relationships
- **ViewModels**: Available for testing sample data integration

## Implementation Plan

### Phase 1: SampleDataManager Design (High Priority)

#### 1.1 Core Architecture
**File**: `Sessions/Models/SampleDataManager.swift` (+ watchOS duplicate)
**Responsibilities**:
- Generate realistic client profiles with diverse demographics
- Create goal templates across therapy categories
- Provide data reset/clearing functionality
- Integrate with SimpleCoreDataRepository

**Key Properties**:
- Reference to repository for data persistence
- Predefined sample data templates
- Configuration for data generation

#### 1.2 Sample Client Data Strategy
**Demographics Diversity**:
- Age ranges: Pediatric (3-12), Adolescent (13-17), Adult (18-65), Senior (65+)
- Gender diversity with realistic name distribution
- Various therapy backgrounds and conditions
- Different date ranges for creation dates

**Client Profiles**:
- Speech therapy clients (articulation, language, fluency)
- ABA therapy clients (autism spectrum, behavioral)
- Occupational therapy clients (fine motor, sensory)
- Mixed therapy needs

#### 1.3 Goal Template Categories
**Speech Therapy Goals**:
- Articulation (sound production)
- Language Development (vocabulary, grammar)
- Fluency (stuttering intervention)
- Voice Therapy (vocal quality)

**ABA Therapy Goals**:
- Social Skills (eye contact, turn-taking)
- Communication (requesting, labeling)
- Academic Skills (counting, reading)
- Daily Living Skills (self-care)

**Occupational Therapy Goals**:
- Fine Motor Skills (writing, manipulation)
- Gross Motor Skills (balance, coordination)
- Sensory Processing (sensory integration)
- Visual Perceptual Skills (visual motor)

### Phase 2: Implementation Details

#### 2.1 SampleDataManager Structure
```swift
class SampleDataManager {
    private let repository: TherapyRepository
    
    // Sample data generation
    func generateSampleData() async throws
    func clearSampleData() async throws
    
    // Individual data generators
    private func generateSampleClients() -> [Client]
    private func generateGoalTemplates(for clientId: UUID) -> [GoalTemplate]
    
    // Helper methods
    private func randomName() -> String
    private func randomAge() -> Date?
    private func randomCategory() -> String
}
```

#### 2.2 Data Generation Strategy
- **Realistic Names**: Use common first and last names from diverse backgrounds
- **Age Distribution**: Spread across therapy-appropriate age ranges
- **Goal Templates**: 3-8 templates per client across relevant categories
- **Creation Dates**: Distributed over realistic time periods
- **Notes**: Include sample therapy notes and observations

#### 2.3 Repository Integration
- Use existing SimpleCoreDataRepository methods
- Leverage async/await patterns for non-blocking generation
- Handle errors gracefully during bulk data creation
- Respect Core Data relationship constraints

### Phase 3: Sample Data Content

#### 3.1 Client Profiles (15-20 clients)
**Pediatric Speech Clients**:
- Emma Johnson (5 years) - Articulation disorders
- Liam Rodriguez (7 years) - Language delay
- Sophia Chen (4 years) - Fluency issues

**ABA Clients**:
- Aiden Williams (6 years) - Autism spectrum, communication goals
- Maya Patel (8 years) - Social skills development
- Noah Thompson (5 years) - Behavioral intervention

**Adult Clients**:
- David Miller (45 years) - Post-stroke speech therapy
- Sarah Davis (32 years) - Voice therapy professional
- Michael Brown (28 years) - Stuttering intervention

#### 3.2 Goal Template Examples
**Articulation Goals**:
- "Produce /r/ sound in initial position"
- "Improve /th/ sound production"
- "Reduce fronting of /k/ sounds"

**Language Goals**:
- "Increase MLU to 4 words"
- "Follow 2-step directions"
- "Use present progressive verbs"

**Social Skills Goals**:
- "Maintain eye contact for 3 seconds"
- "Initiate greetings with peers"
- "Take turns in conversation"

### Phase 4: Implementation Steps

1. **Create SampleDataManager class** with repository integration
2. **Implement client generation** with diverse demographics
3. **Add goal template generation** across therapy categories
4. **Create data clearing functionality** for testing
5. **Add error handling** and validation
6. **Duplicate implementation** in watchOS target
7. **Create comprehensive tests** for data generation
8. **Verify integration** with existing ViewModels

### Phase 5: Testing Strategy

#### 5.1 Unit Testing
- Test sample data generation without errors
- Verify data diversity and realism
- Test clear/reset functionality
- Validate Core Data constraint compliance
- Test repository integration

#### 5.2 Integration Testing
- Test with ViewModels to ensure compatibility
- Verify UI displays sample data correctly
- Test data persistence and retrieval
- Check performance with bulk data operations

### Phase 6: File Structure
```
Sessions/
├── Models/
│   ├── Client.swift (existing)
│   ├── GoalTemplate.swift (existing)
│   ├── SampleDataManager.swift (new)
│   └── ...
Sessions Watch App/
├── Models/
│   ├── Client.swift (existing)
│   ├── GoalTemplate.swift (existing)
│   ├── SampleDataManager.swift (new)
│   └── ...
SessionsTests/
├── SampleDataManagerTests.swift (new)
```

### Phase 7: Integration Points

#### 7.1 Development Usage
- Initialize sample data during development
- Clear data between testing scenarios
- Provide consistent test environment

#### 7.2 ViewModels Integration
- Use sample data for ViewModel testing
- Verify UI components handle diverse data
- Test search and filtering with sample data

#### 7.3 UI Testing
- Populate sample data for UI testing
- Verify accessibility with diverse content
- Test edge cases with generated data

## Success Criteria
- [ ] SampleDataManager class created in both target directories
- [ ] Generates realistic client data with diverse demographics
- [ ] Creates goal templates across different therapy categories
- [ ] Includes method to populate sample data
- [ ] Includes method to clear/reset sample data
- [ ] Sample data integrates with SimpleCoreDataRepository
- [ ] Comprehensive unit tests cover all functionality
- [ ] No errors during sample data generation
- [ ] Reset functionality clears all sample data correctly
- [ ] Generated data follows Core Data model constraints

## Dependencies
- SimpleCoreDataRepository (completed)
- Swift model structs (completed)
- Core Data stack (completed)

## Risk Assessment
- **Low Risk**: Straightforward data generation using existing models
- **Performance**: Bulk data creation might be slow - use background contexts
- **Data Quality**: Ensure realistic and diverse sample data
- **Future Compatibility**: Design for easy maintenance and updates

## Notes
- Sample data will be valuable for Stage 2 UI development and testing
- Provides realistic scenarios for therapist workflow validation
- Enables comprehensive testing without manual data entry
- Foundation for future demo and training materials