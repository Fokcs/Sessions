import XCTest
import Foundation
import Combine
@testable import Sessions_Watch_App

/// Comprehensive test suite for SessionViewModel in Stage 3 Apple Watch implementation
/// 
/// **Test Coverage:**
/// This test class validates the behavior of the SessionViewModel:
/// - Session lifecycle management (start, end, active state)
/// - Goal navigation and state management
/// - Trial logging with different cue levels
/// - Undo functionality for trial removal
/// - Real-time statistics and computed properties
/// - Error handling and repository interactions
/// - Timer management and session duration
/// - Session summary generation
/// - Sample data loading for development
/// 
/// **Test Architecture:**
/// - Uses MockTherapyRepository for isolated testing
/// - Tests async operations with proper MainActor annotations
/// - Validates @Published property updates and state changes
/// - Uses Combine for testing property changes over time
/// 
/// **Testing Strategy:**
/// - Arrange-Act-Assert pattern for each test
/// - Mock repository provides controlled data scenarios
/// - Tests both happy path and error conditions
/// - Validates timer behavior and UI state management
@MainActor
final class SessionViewModelTests: XCTestCase {
    
    // MARK: - Test Infrastructure
    
    var mockRepository: MockTherapyRepository!
    var sessionViewModel: SessionViewModel!
    var cancellables: Set<AnyCancellable>!
    var testClients: [Client]!
    var testGoalTemplates: [GoalTemplate]!
    
    override func setUp() async throws {
        try await super.setUp()
        mockRepository = MockTherapyRepository()
        cancellables = Set<AnyCancellable>()
        
        // Create test data
        testClients = createTestClients()
        testGoalTemplates = createTestGoalTemplates()
        
        // Configure mock repository
        mockRepository.mockClients = testClients
        mockRepository.mockGoalTemplates = testGoalTemplates
        
        // Create view model (this will trigger loadSampleData)
        sessionViewModel = SessionViewModel(repository: mockRepository)
        
        // Wait a moment for sample data loading to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
    }
    
    override func tearDown() async throws {
        cancellables?.removeAll()
        cancellables = nil
        sessionViewModel = nil
        mockRepository = nil
        testClients = nil
        testGoalTemplates = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testSessionViewModelInitialization() async {
        // Assert - Initial state
        XCTAssertNil(sessionViewModel.activeSession)
        XCTAssertFalse(sessionViewModel.isSessionActive)
        XCTAssertFalse(sessionViewModel.showingCueLevelPicker)
        XCTAssertFalse(sessionViewModel.lastTrialWasSuccess)
        XCTAssertFalse(sessionViewModel.undoButtonEnabled)
        XCTAssertNotNil(sessionViewModel.currentTime)
        
        // Assert - Sample data should be loaded
        XCTAssertNotNil(sessionViewModel.selectedClient)
        XCTAssertFalse(sessionViewModel.availableGoals.isEmpty)
        XCTAssertEqual(sessionViewModel.availableGoals.count, 3) // Limited to 4 but we have 3
    }
    
    func testTimeTimerUpdatesCurrentTime() async {
        // Arrange
        let initialTime = sessionViewModel.currentTime
        
        // Act - Wait for timer to update
        try? await Task.sleep(nanoseconds: 1_100_000_000) // 1.1 seconds
        
        // Assert - Time should have updated
        XCTAssertGreaterThan(sessionViewModel.currentTime, initialTime)
    }
    
    // MARK: - Session Management Tests
    
    func testStartSession() async {
        // Arrange
        let client = testClients[0]
        let goals = Array(testGoalTemplates.prefix(2))
        
        // Act
        sessionViewModel.startSession(with: client, goals: goals)
        
        // Assert
        XCTAssertNotNil(sessionViewModel.activeSession)
        XCTAssertTrue(sessionViewModel.isSessionActive)
        XCTAssertEqual(sessionViewModel.selectedClient?.id, client.id)
        XCTAssertEqual(sessionViewModel.availableGoals.count, 2)
        XCTAssertFalse(sessionViewModel.undoButtonEnabled)
        
        // Check active session properties
        let activeSession = sessionViewModel.activeSession!
        XCTAssertEqual(activeSession.clientId, client.id)
        XCTAssertEqual(activeSession.clientName, client.displayName)
        XCTAssertEqual(activeSession.goalTemplates.count, 2)
        XCTAssertEqual(activeSession.currentGoalIndex, 0)
        XCTAssertTrue(activeSession.trials.isEmpty)
    }
    
    func testStartSessionWithEmptyGoals() async {
        // Arrange
        let client = testClients[0]
        let emptyGoals: [GoalTemplate] = []
        
        // Act
        sessionViewModel.startSession(with: client, goals: emptyGoals)
        
        // Assert - Session should not start with empty goals
        XCTAssertNil(sessionViewModel.activeSession)
        XCTAssertFalse(sessionViewModel.isSessionActive)
    }
    
    func testEndSession() async {
        // Arrange - Start a session first
        let client = testClients[0]
        let goals = Array(testGoalTemplates.prefix(2))
        sessionViewModel.startSession(with: client, goals: goals)
        
        // Add a trial to make the session meaningful
        sessionViewModel.addTrialWithCueLevel(.independent)
        
        XCTAssertTrue(sessionViewModel.isSessionActive)
        XCTAssertEqual(mockRepository.mockSessions.count, 0)
        
        // Act
        sessionViewModel.endSession()
        
        // Wait for async operation to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        // Assert
        XCTAssertNil(sessionViewModel.activeSession)
        XCTAssertFalse(sessionViewModel.isSessionActive)
        XCTAssertFalse(sessionViewModel.undoButtonEnabled)
        
        // Verify session was saved to repository
        XCTAssertEqual(mockRepository.mockSessions.count, 1)
        let savedSession = mockRepository.mockSessions[0]
        XCTAssertEqual(savedSession.clientId, client.id)
        XCTAssertEqual(savedSession.createdOn, "Watch")
    }
    
    func testEndSessionWithRepositoryError() async {
        // Arrange - Start a session
        let client = testClients[0]
        let goals = Array(testGoalTemplates.prefix(2))
        sessionViewModel.startSession(with: client, goals: goals)
        
        // Configure repository to throw error
        mockRepository.shouldThrowError = true
        
        // Act
        sessionViewModel.endSession()
        
        // Wait for async operation to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        // Assert - Session should still end locally even if save fails
        XCTAssertNil(sessionViewModel.activeSession)
        XCTAssertFalse(sessionViewModel.isSessionActive)
        XCTAssertEqual(mockRepository.mockSessions.count, 0) // Save failed
    }
    
    // MARK: - Goal Navigation Tests
    
    func testMoveToNextGoal() async {
        // Arrange - Start session with multiple goals
        let client = testClients[0]
        let goals = testGoalTemplates
        sessionViewModel.startSession(with: client, goals: goals)
        
        XCTAssertEqual(sessionViewModel.currentGoalIndex, 0)
        
        // Act
        sessionViewModel.moveToNextGoal()
        
        // Assert
        XCTAssertEqual(sessionViewModel.currentGoalIndex, 1)
        XCTAssertEqual(sessionViewModel.currentGoal?.id, goals[1].id)
        
        // Act - Move to next goal again
        sessionViewModel.moveToNextGoal()
        
        // Assert
        XCTAssertEqual(sessionViewModel.currentGoalIndex, 2)
        XCTAssertEqual(sessionViewModel.currentGoal?.id, goals[2].id)
    }
    
    func testMoveToPreviousGoal() async {
        // Arrange - Start session and move to second goal
        let client = testClients[0]
        let goals = testGoalTemplates
        sessionViewModel.startSession(with: client, goals: goals)
        sessionViewModel.setCurrentGoal(at: 2)
        
        XCTAssertEqual(sessionViewModel.currentGoalIndex, 2)
        
        // Act
        sessionViewModel.moveToPreviousGoal()
        
        // Assert
        XCTAssertEqual(sessionViewModel.currentGoalIndex, 1)
        XCTAssertEqual(sessionViewModel.currentGoal?.id, goals[1].id)
        
        // Act - Move to previous goal again
        sessionViewModel.moveToPreviousGoal()
        
        // Assert
        XCTAssertEqual(sessionViewModel.currentGoalIndex, 0)
        XCTAssertEqual(sessionViewModel.currentGoal?.id, goals[0].id)
    }
    
    func testSetCurrentGoal() async {
        // Arrange - Start session
        let client = testClients[0]
        let goals = testGoalTemplates
        sessionViewModel.startSession(with: client, goals: goals)
        
        // Act
        sessionViewModel.setCurrentGoal(at: 2)
        
        // Assert
        XCTAssertEqual(sessionViewModel.currentGoalIndex, 2)
        XCTAssertEqual(sessionViewModel.currentGoal?.id, goals[2].id)
        
        // Act - Set to different goal
        sessionViewModel.setCurrentGoal(at: 0)
        
        // Assert
        XCTAssertEqual(sessionViewModel.currentGoalIndex, 0)
        XCTAssertEqual(sessionViewModel.currentGoal?.id, goals[0].id)
    }
    
    func testGoalNavigationWithoutActiveSession() async {
        // Arrange - No active session
        XCTAssertNil(sessionViewModel.activeSession)
        
        // Act - Try to navigate goals
        sessionViewModel.moveToNextGoal()
        sessionViewModel.moveToPreviousGoal()
        sessionViewModel.setCurrentGoal(at: 1)
        
        // Assert - Nothing should change
        XCTAssertNil(sessionViewModel.activeSession)
        XCTAssertEqual(sessionViewModel.currentGoalIndex, 0) // Default value
    }
    
    // MARK: - Trial Logging Tests
    
    func testLogSuccess() async {
        // Arrange - Start session
        let client = testClients[0]
        let goals = Array(testGoalTemplates.prefix(2))
        sessionViewModel.startSession(with: client, goals: goals)
        
        // Act
        sessionViewModel.logSuccess()
        
        // Assert
        XCTAssertTrue(sessionViewModel.lastTrialWasSuccess)
        XCTAssertTrue(sessionViewModel.showingCueLevelPicker)
    }
    
    func testLogFailure() async {
        // Arrange - Start session
        let client = testClients[0]
        let goals = Array(testGoalTemplates.prefix(2))
        sessionViewModel.startSession(with: client, goals: goals)
        
        // Act
        sessionViewModel.logFailure()
        
        // Assert
        XCTAssertFalse(sessionViewModel.lastTrialWasSuccess)
        XCTAssertTrue(sessionViewModel.showingCueLevelPicker)
    }
    
    func testAddTrialWithCueLevel() async {
        // Arrange - Start session and initiate trial logging
        let client = testClients[0]
        let goals = Array(testGoalTemplates.prefix(2))
        sessionViewModel.startSession(with: client, goals: goals)
        sessionViewModel.logSuccess()
        
        XCTAssertTrue(sessionViewModel.showingCueLevelPicker)
        XCTAssertFalse(sessionViewModel.undoButtonEnabled)
        
        // Act
        sessionViewModel.addTrialWithCueLevel(.minimal)
        
        // Assert
        XCTAssertFalse(sessionViewModel.showingCueLevelPicker)
        XCTAssertTrue(sessionViewModel.undoButtonEnabled)
        
        // Check trial was added to active session
        let activeSession = sessionViewModel.activeSession!
        XCTAssertEqual(activeSession.trials.count, 1)
        let trial = activeSession.trials[0]
        XCTAssertTrue(trial.wasSuccessful)
        XCTAssertEqual(trial.cueLevel, .minimal)
        XCTAssertEqual(trial.goalTemplateId, goals[0].id)
    }
    
    func testUndoLastTrial() async {
        // Arrange - Start session and add trials
        let client = testClients[0]
        let goals = Array(testGoalTemplates.prefix(2))
        sessionViewModel.startSession(with: client, goals: goals)
        
        // Add first trial
        sessionViewModel.logSuccess()
        sessionViewModel.addTrialWithCueLevel(.independent)
        
        // Add second trial
        sessionViewModel.logFailure()
        sessionViewModel.addTrialWithCueLevel(.moderate)
        
        XCTAssertEqual(sessionViewModel.activeSession!.trials.count, 2)
        XCTAssertTrue(sessionViewModel.undoButtonEnabled)
        
        // Act - Undo last trial
        sessionViewModel.undoLastTrial()
        
        // Assert
        XCTAssertEqual(sessionViewModel.activeSession!.trials.count, 1)
        XCTAssertTrue(sessionViewModel.undoButtonEnabled) // Still enabled because 1 trial remains
        
        // Verify remaining trial
        let remainingTrial = sessionViewModel.activeSession!.trials[0]
        XCTAssertTrue(remainingTrial.wasSuccessful)
        XCTAssertEqual(remainingTrial.cueLevel, .independent)
        
        // Act - Undo last remaining trial
        sessionViewModel.undoLastTrial()
        
        // Assert
        XCTAssertEqual(sessionViewModel.activeSession!.trials.count, 0)
        XCTAssertFalse(sessionViewModel.undoButtonEnabled) // No more trials
    }
    
    func testUndoLastTrialWithoutTrials() async {
        // Arrange - Start session with no trials
        let client = testClients[0]
        let goals = Array(testGoalTemplates.prefix(2))
        sessionViewModel.startSession(with: client, goals: goals)
        
        XCTAssertEqual(sessionViewModel.activeSession!.trials.count, 0)
        XCTAssertFalse(sessionViewModel.undoButtonEnabled)
        
        // Act - Try to undo with no trials
        sessionViewModel.undoLastTrial()
        
        // Assert - Nothing should change
        XCTAssertEqual(sessionViewModel.activeSession!.trials.count, 0)
        XCTAssertFalse(sessionViewModel.undoButtonEnabled)
    }
    
    func testTrialLoggingWithoutActiveSession() async {
        // Arrange - No active session
        XCTAssertNil(sessionViewModel.activeSession)
        
        // Act - Try to log trials
        sessionViewModel.logSuccess()
        sessionViewModel.addTrialWithCueLevel(.independent)
        sessionViewModel.undoLastTrial()
        
        // Assert - Should not crash and state should remain unchanged
        XCTAssertNil(sessionViewModel.activeSession)
        XCTAssertFalse(sessionViewModel.showingCueLevelPicker)
        XCTAssertFalse(sessionViewModel.undoButtonEnabled)
    }
    
    // MARK: - Computed Properties Tests
    
    func testCurrentGoalProperty() async {
        // Test with no active session
        XCTAssertNil(sessionViewModel.currentGoal)
        
        // Start session
        let client = testClients[0]
        let goals = testGoalTemplates
        sessionViewModel.startSession(with: client, goals: goals)
        
        // Test with active session
        XCTAssertNotNil(sessionViewModel.currentGoal)
        XCTAssertEqual(sessionViewModel.currentGoal?.id, goals[0].id)
        
        // Test after navigation
        sessionViewModel.moveToNextGoal()
        XCTAssertEqual(sessionViewModel.currentGoal?.id, goals[1].id)
    }
    
    func testSessionDurationProperty() async {
        // Test with no active session
        XCTAssertEqual(sessionViewModel.sessionDuration, "00:00")
        
        // Start session
        let client = testClients[0]
        let goals = Array(testGoalTemplates.prefix(2))
        sessionViewModel.startSession(with: client, goals: goals)
        
        // Test with active session
        let duration = sessionViewModel.sessionDuration
        XCTAssertTrue(duration.hasPrefix("00:0"))
        XCTAssertTrue(duration.contains(":"))
    }
    
    func testCurrentGoalIndexProperty() async {
        // Test with no active session
        XCTAssertEqual(sessionViewModel.currentGoalIndex, 0)
        
        // Start session
        let client = testClients[0]
        let goals = testGoalTemplates
        sessionViewModel.startSession(with: client, goals: goals)
        
        // Test with active session
        XCTAssertEqual(sessionViewModel.currentGoalIndex, 0)
        
        // Test after navigation
        sessionViewModel.moveToNextGoal()
        XCTAssertEqual(sessionViewModel.currentGoalIndex, 1)
    }
    
    func testTotalGoalsProperty() async {
        // Test with no active session
        XCTAssertEqual(sessionViewModel.totalGoals, 0)
        
        // Start session
        let client = testClients[0]
        let goals = testGoalTemplates
        sessionViewModel.startSession(with: client, goals: goals)
        
        // Test with active session
        XCTAssertEqual(sessionViewModel.totalGoals, 3)
    }
    
    func testSuccessRateProperty() async {
        // Test with no active session
        XCTAssertEqual(sessionViewModel.successRate, "0% (0/0)")
        
        // Start session and add trials
        let client = testClients[0]
        let goals = Array(testGoalTemplates.prefix(2))
        sessionViewModel.startSession(with: client, goals: goals)
        
        // Add successful trial
        sessionViewModel.logSuccess()
        sessionViewModel.addTrialWithCueLevel(.independent)
        
        // Add failed trial
        sessionViewModel.logFailure()
        sessionViewModel.addTrialWithCueLevel(.minimal)
        
        // Test success rate (1 success out of 2 trials = 50%)
        XCTAssertEqual(sessionViewModel.successRate, "50% (1/2)")
    }
    
    func testSuccessRateColorProperty() async {
        // Start session
        let client = testClients[0]
        let goals = Array(testGoalTemplates.prefix(2))
        sessionViewModel.startSession(with: client, goals: goals)
        
        // Test with no trials (gray)
        XCTAssertEqual(sessionViewModel.successRateColor, .gray)
        
        // Add trials for good performance (70%+)
        for _ in 0..<7 {
            sessionViewModel.logSuccess()
            sessionViewModel.addTrialWithCueLevel(.independent)
        }
        for _ in 0..<3 {
            sessionViewModel.logFailure()
            sessionViewModel.addTrialWithCueLevel(.minimal)
        }
        
        // Test green color for good performance
        XCTAssertEqual(sessionViewModel.successRateColor, .green)
    }
    
    func testNavigationDotsProperty() async {
        // Test with no active session
        XCTAssertTrue(sessionViewModel.navigationDots.isEmpty)
        
        // Start session with 3 goals
        let client = testClients[0]
        let goals = testGoalTemplates
        sessionViewModel.startSession(with: client, goals: goals)
        
        // Test initial navigation dots (first is active)
        let initialDots = sessionViewModel.navigationDots
        XCTAssertEqual(initialDots.count, 3)
        XCTAssertTrue(initialDots[0])  // First goal is active
        XCTAssertFalse(initialDots[1])
        XCTAssertFalse(initialDots[2])
        
        // Move to next goal and test
        sessionViewModel.moveToNextGoal()
        let updatedDots = sessionViewModel.navigationDots
        XCTAssertFalse(updatedDots[0])
        XCTAssertTrue(updatedDots[1])  // Second goal is now active
        XCTAssertFalse(updatedDots[2])
    }
    
    // MARK: - Session Summary Tests
    
    func testGetSessionSummary() async {
        // Test with no active session
        XCTAssertNil(sessionViewModel.getSessionSummary())
        
        // Start session
        let client = testClients[0]
        let goals = testGoalTemplates
        sessionViewModel.startSession(with: client, goals: goals)
        
        // Add trials for different goals
        sessionViewModel.logSuccess()
        sessionViewModel.addTrialWithCueLevel(.independent)
        
        sessionViewModel.moveToNextGoal()
        sessionViewModel.logFailure()
        sessionViewModel.addTrialWithCueLevel(.moderate)
        
        sessionViewModel.logSuccess()
        sessionViewModel.addTrialWithCueLevel(.minimal)
        
        // Act
        let summary = sessionViewModel.getSessionSummary()
        
        // Assert
        XCTAssertNotNil(summary)
        XCTAssertEqual(summary!.clientId, client.id)
        XCTAssertEqual(summary!.clientName, client.displayName)
        XCTAssertEqual(summary!.totalTrials, 3)
        XCTAssertEqual(summary!.successTrials, 2)
        XCTAssertEqual(summary!.failureTrials, 1)
        XCTAssertEqual(summary!.successRate, 66) // 2/3 = 66%
        
        // Check cue level breakdown
        XCTAssertEqual(summary!.cuingLevelBreakdown.independent, 1)
        XCTAssertEqual(summary!.cuingLevelBreakdown.minimal, 1)
        XCTAssertEqual(summary!.cuingLevelBreakdown.moderate, 1)
        XCTAssertEqual(summary!.cuingLevelBreakdown.maximal, 0)
        
        // Check goal breakdown
        XCTAssertEqual(summary!.goalBreakdown.count, 3) // Should have performance for all goals
        
        let goal1Performance = summary!.goalBreakdown.first { $0.goalName == goals[0].description }
        XCTAssertNotNil(goal1Performance)
        XCTAssertEqual(goal1Performance!.totalCount, 1)
        XCTAssertEqual(goal1Performance!.successCount, 1)
        
        let goal2Performance = summary!.goalBreakdown.first { $0.goalName == goals[1].description }
        XCTAssertNotNil(goal2Performance)
        XCTAssertEqual(goal2Performance!.totalCount, 2)
        XCTAssertEqual(goal2Performance!.successCount, 1)
    }
    
    // MARK: - Sample Data Loading Tests
    
    func testSampleDataLoading() async {
        // Sample data should be loaded during initialization
        XCTAssertNotNil(sessionViewModel.selectedClient)
        XCTAssertFalse(sessionViewModel.availableGoals.isEmpty)
        XCTAssertEqual(sessionViewModel.selectedClient?.id, testClients[0].id)
        XCTAssertEqual(sessionViewModel.availableGoals.count, 3) // Limited to first 4, we have 3
    }
    
    func testSampleDataLoadingWithRepositoryError() async {
        // Arrange - Create new view model with error-prone repository
        let errorRepository = MockTherapyRepository()
        errorRepository.shouldThrowError = true
        
        // Act - Create view model (triggers loadSampleData)
        let errorViewModel = SessionViewModel(repository: errorRepository)
        
        // Wait for async loading to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        // Assert - Should handle errors gracefully
        XCTAssertNil(errorViewModel.selectedClient)
        XCTAssertTrue(errorViewModel.availableGoals.isEmpty)
    }
    
    // MARK: - Published Properties Change Tests
    
    func testPublishedPropertiesUpdatesOnSessionStart() async {
        // Arrange - Track property changes
        var sessionActiveStates: [Bool] = []
        var undoEnabledStates: [Bool] = []
        
        sessionViewModel.$isSessionActive
            .sink { sessionActiveStates.append($0) }
            .store(in: &cancellables)
        
        sessionViewModel.$undoButtonEnabled
            .sink { undoEnabledStates.append($0) }
            .store(in: &cancellables)
        
        // Act
        let client = testClients[0]
        let goals = Array(testGoalTemplates.prefix(2))
        sessionViewModel.startSession(with: client, goals: goals)
        
        // Wait for property updates
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 second
        
        // Assert
        XCTAssertTrue(sessionActiveStates.contains(true))
        XCTAssertTrue(undoEnabledStates.contains(false))
    }
    
    func testPublishedPropertiesUpdatesOnTrialLogging() async {
        // Arrange - Start session
        let client = testClients[0]
        let goals = Array(testGoalTemplates.prefix(2))
        sessionViewModel.startSession(with: client, goals: goals)
        
        // Track property changes
        var cueLevelPickerStates: [Bool] = []
        var undoEnabledStates: [Bool] = []
        
        sessionViewModel.$showingCueLevelPicker
            .sink { cueLevelPickerStates.append($0) }
            .store(in: &cancellables)
        
        sessionViewModel.$undoButtonEnabled
            .sink { undoEnabledStates.append($0) }
            .store(in: &cancellables)
        
        // Act - Log trial
        sessionViewModel.logSuccess()
        sessionViewModel.addTrialWithCueLevel(.independent)
        
        // Wait for property updates
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 second
        
        // Assert
        XCTAssertTrue(cueLevelPickerStates.contains(true))   // Should show picker
        XCTAssertTrue(cueLevelPickerStates.contains(false))  // Should hide picker after adding
        XCTAssertTrue(undoEnabledStates.contains(true))      // Should enable undo
    }
    
    // MARK: - Edge Cases and Error Handling Tests
    
    func testSessionTimerInvalidationOnDeinit() async {
        // This test ensures proper cleanup of timers
        // The timer should be invalidated when the view model is deallocated
        
        // Create a view model in a limited scope
        do {
            let repository = MockTherapyRepository()
            let viewModel = SessionViewModel(repository: repository)
            let client = testClients[0]
            let goals = Array(testGoalTemplates.prefix(2))
            viewModel.startSession(with: client, goals: goals)
            
            // Timer should be active
            XCTAssertNotNil(viewModel.sessionTimer)
        }
        
        // View model should be deallocated here, invalidating timers
        // This test mainly ensures no crashes occur during deinitialization
    }
    
    func testMultipleSessionStarts() async {
        // Arrange - Start first session
        let client1 = testClients[0]
        let goals1 = Array(testGoalTemplates.prefix(1))
        sessionViewModel.startSession(with: client1, goals: goals1)
        
        let firstSessionId = sessionViewModel.activeSession!.id
        
        // Act - Start second session (should replace first)
        let client2 = testClients[1]
        let goals2 = Array(testGoalTemplates.suffix(2))
        sessionViewModel.startSession(with: client2, goals: goals2)
        
        // Assert - Second session should replace first
        XCTAssertNotEqual(sessionViewModel.activeSession!.id, firstSessionId)
        XCTAssertEqual(sessionViewModel.activeSession!.clientId, client2.id)
        XCTAssertEqual(sessionViewModel.activeSession!.goalTemplates.count, 2)
    }
    
    // MARK: - Test Helper Methods
    
    private func createTestClients() -> [Client] {
        return [
            Client(
                id: UUID(),
                name: "John Doe",
                dateOfBirth: Calendar.current.date(byAdding: .year, value: -25, to: Date()),
                notes: "Test client 1",
                createdDate: Date(),
                lastModified: Date()
            ),
            Client(
                id: UUID(),
                name: "Jane Smith",
                dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: Date()),
                notes: "Test client 2",
                createdDate: Date(),
                lastModified: Date()
            ),
            Client(
                id: UUID(),
                name: "Bob Wilson",
                dateOfBirth: nil,
                notes: nil,
                createdDate: Date(),
                lastModified: Date()
            )
        ]
    }
    
    private func createTestGoalTemplates() -> [GoalTemplate] {
        let clientId = UUID()
        return [
            GoalTemplate(
                id: UUID(),
                title: "Improve Pronunciation",
                description: "Focus on consonant sounds",
                category: "Speech",
                defaultCueLevel: .minimal,
                clientId: clientId,
                isActive: true,
                createdDate: Date()
            ),
            GoalTemplate(
                id: UUID(),
                title: "Reduce Disruptive Behavior",
                description: "Behavioral intervention strategies",
                category: "Behavior",
                defaultCueLevel: .moderate,
                clientId: clientId,
                isActive: true,
                createdDate: Date()
            ),
            GoalTemplate(
                id: UUID(),
                title: "Increase Eye Contact",
                description: "Social interaction skills",
                category: "Social",
                defaultCueLevel: .maximal,
                clientId: clientId,
                isActive: true,
                createdDate: Date()
            )
        ]
    }
}

// MARK: - Mock Repository Implementation for watchOS

/// Mock implementation of TherapyRepository for isolated ViewModel testing on watchOS
class MockTherapyRepository: TherapyRepository {
    
    // MARK: - Mock Data Storage
    var mockClients: [Client] = []
    var mockGoalTemplates: [GoalTemplate] = []
    var mockSessions: [Session] = []
    var mockGoalLogs: [GoalLog] = []
    
    // MARK: - Error Control
    var shouldThrowError = false
    var shouldThrowErrorOnGoalTemplates = false
    var therapyErrorToThrow: TherapyAppError?
    
    // MARK: - Operation Tracking
    var createdClients: [Client] = []
    var updatedClients: [Client] = []
    var deletedClientIds: [UUID] = []
    var createdGoalTemplates: [GoalTemplate] = []
    var updatedGoalTemplates: [GoalTemplate] = []
    var deletedGoalTemplateIds: [UUID] = []
    
    // MARK: - Client Operations
    
    func createClient(_ client: Client) async throws {
        if shouldThrowError {
            throw MockRepositoryError.operationFailed("Mock create client error")
        }
        createdClients.append(client)
        mockClients.append(client)
    }
    
    func fetchClients() async throws -> [Client] {
        if let therapyError = therapyErrorToThrow {
            throw therapyError
        }
        if shouldThrowError {
            throw MockRepositoryError.operationFailed("Failed to load clients")
        }
        return mockClients
    }
    
    func updateClient(_ client: Client) async throws {
        if shouldThrowError {
            throw MockRepositoryError.operationFailed("Mock update client error")
        }
        updatedClients.append(client)
        if let index = mockClients.firstIndex(where: { $0.id == client.id }) {
            mockClients[index] = client
        }
    }
    
    func deleteClient(_ clientId: UUID) async throws {
        if let therapyError = therapyErrorToThrow {
            throw therapyError
        }
        if shouldThrowError {
            throw MockRepositoryError.operationFailed("Failed to delete client")
        }
        deletedClientIds.append(clientId)
        mockClients.removeAll { $0.id == clientId }
    }
    
    func fetchClient(_ clientId: UUID) async throws -> Client? {
        if shouldThrowError {
            throw MockRepositoryError.operationFailed("Mock fetch client error")
        }
        return mockClients.first { $0.id == clientId }
    }
    
    // MARK: - Goal Template Operations
    
    func createGoalTemplate(_ goalTemplate: GoalTemplate) async throws {
        if shouldThrowError {
            throw MockRepositoryError.operationFailed("Mock create goal template error")
        }
        createdGoalTemplates.append(goalTemplate)
        mockGoalTemplates.append(goalTemplate)
    }
    
    func fetchGoalTemplates(for clientId: UUID) async throws -> [GoalTemplate] {
        if let therapyError = therapyErrorToThrow {
            throw therapyError
        }
        if shouldThrowErrorOnGoalTemplates || shouldThrowError {
            throw MockRepositoryError.operationFailed("Failed to load goal templates")
        }
        return mockGoalTemplates.filter { $0.clientId == clientId }
    }
    
    func fetchAllGoalTemplates() async throws -> [GoalTemplate] {
        if shouldThrowError {
            throw MockRepositoryError.operationFailed("Failed to load all goal templates")
        }
        return mockGoalTemplates
    }
    
    func updateGoalTemplate(_ goalTemplate: GoalTemplate) async throws {
        if shouldThrowError {
            throw MockRepositoryError.operationFailed("Mock update goal template error")
        }
        updatedGoalTemplates.append(goalTemplate)
        if let index = mockGoalTemplates.firstIndex(where: { $0.id == goalTemplate.id }) {
            mockGoalTemplates[index] = goalTemplate
        }
    }
    
    func deleteGoalTemplate(_ goalTemplateId: UUID) async throws {
        if let therapyError = therapyErrorToThrow {
            throw therapyError
        }
        if shouldThrowError {
            throw MockRepositoryError.operationFailed("Failed to delete goal template")
        }
        deletedGoalTemplateIds.append(goalTemplateId)
        mockGoalTemplates.removeAll { $0.id == goalTemplateId }
    }
    
    func fetchGoalTemplate(_ goalTemplateId: UUID) async throws -> GoalTemplate? {
        if shouldThrowError {
            throw MockRepositoryError.operationFailed("Mock fetch goal template error")
        }
        return mockGoalTemplates.first { $0.id == goalTemplateId }
    }
    
    // MARK: - Session Operations
    
    func startSession(for clientId: UUID, location: String?, createdOn: String) async throws -> Session {
        if shouldThrowError {
            throw MockRepositoryError.operationFailed("Mock start session error")
        }
        return Session(
            id: UUID(),
            clientId: clientId,
            location: location,
            createdOn: createdOn
        )
    }
    
    func endSession(_ sessionId: UUID) async throws {
        if shouldThrowError {
            throw MockRepositoryError.operationFailed("Mock end session error")
        }
    }
    
    func fetchSessions(for clientId: UUID) async throws -> [Session] {
        if shouldThrowError {
            throw MockRepositoryError.operationFailed("Mock fetch sessions error")
        }
        return mockSessions.filter { $0.clientId == clientId }
    }
    
    func fetchActiveSession() async throws -> Session? {
        if shouldThrowError {
            throw MockRepositoryError.operationFailed("Mock fetch active session error")
        }
        return mockSessions.first { $0.endTime == nil }
    }
    
    func fetchSession(_ sessionId: UUID) async throws -> Session? {
        if shouldThrowError {
            throw MockRepositoryError.operationFailed("Mock fetch session error")
        }
        return mockSessions.first { $0.id == sessionId }
    }
    
    // MARK: - Goal Log Operations
    
    func logGoal(_ goalLog: GoalLog) async throws {
        if shouldThrowError {
            throw MockRepositoryError.operationFailed("Mock log goal error")
        }
        mockGoalLogs.append(goalLog)
    }
    
    func fetchGoalLogs(for sessionId: UUID) async throws -> [GoalLog] {
        if shouldThrowError {
            throw MockRepositoryError.operationFailed("Mock fetch goal logs error")
        }
        return mockGoalLogs.filter { $0.sessionId == sessionId }
    }
    
    func deleteGoalLog(_ goalLogId: UUID) async throws {
        if shouldThrowError {
            throw MockRepositoryError.operationFailed("Mock delete goal log error")
        }
        mockGoalLogs.removeAll { $0.id == goalLogId }
    }
    
    // MARK: - Additional Methods for SessionViewModel Support
    
    func getAllClients() async throws -> [Client] {
        if shouldThrowError {
            throw MockRepositoryError.operationFailed("Failed to load all clients")
        }
        return mockClients
    }
    
    func getAllGoalTemplates() async throws -> [GoalTemplate] {
        if shouldThrowError {
            throw MockRepositoryError.operationFailed("Failed to load all goal templates")
        }
        return mockGoalTemplates
    }
    
    func createSession(_ session: Session) async throws {
        if shouldThrowError {
            throw MockRepositoryError.operationFailed("Failed to create session")
        }
        mockSessions.append(session)
    }
}

// MARK: - Mock Error Types

enum MockRepositoryError: Error, LocalizedError {
    case operationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .operationFailed(let message):
            return message
        }
    }
}