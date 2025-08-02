import XCTest
import Foundation
@testable import Sessions_Watch_App

/// Comprehensive test suite for ActiveSession model in Stage 3 Apple Watch implementation
/// 
/// **Test Coverage:**
/// This test class validates the behavior of the ActiveSession model:
/// - Session initialization and state management
/// - Goal navigation (next, previous, set index)
/// - Trial logging with success/failure and cue levels
/// - Undo functionality for trial removal
/// - Real-time statistics calculation
/// - Session duration tracking
/// - Goal-specific statistics
/// - Cue level breakdown statistics
/// - Session conversion to Core Data model
/// 
/// **Test Architecture:**
/// - Pure unit tests for model logic without dependencies
/// - Tests both happy path and edge case scenarios
/// - Validates all computed properties and statistics
/// - Tests mutation methods and state transitions
/// 
/// **Testing Strategy:**
/// - Arrange-Act-Assert pattern for each test
/// - Test data setup with realistic goal templates
/// - Comprehensive edge case coverage
/// - Performance and accuracy validation for statistics
final class ActiveSessionTests: XCTestCase {
    
    // MARK: - Test Infrastructure
    
    var testClientId: UUID!
    var testGoalTemplates: [GoalTemplate]!
    var activeSession: ActiveSession!
    
    override func setUp() {
        super.setUp()
        testClientId = UUID()
        testGoalTemplates = createTestGoalTemplates()
        activeSession = ActiveSession(
            clientId: testClientId,
            clientName: "Test Client",
            goalTemplates: testGoalTemplates
        )
    }
    
    override func tearDown() {
        activeSession = nil
        testGoalTemplates = nil
        testClientId = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testActiveSessionInitialization() {
        // Arrange & Act
        let session = ActiveSession(
            clientId: testClientId,
            clientName: "John Doe",
            goalTemplates: testGoalTemplates
        )
        
        // Assert
        XCTAssertNotNil(session.id)
        XCTAssertEqual(session.clientId, testClientId)
        XCTAssertEqual(session.clientName, "John Doe")
        XCTAssertEqual(session.goalTemplates.count, 3)
        XCTAssertEqual(session.currentGoalIndex, 0)
        XCTAssertTrue(session.trials.isEmpty)
        XCTAssertNotNil(session.startTime)
        XCTAssertLessThanOrEqual(abs(session.startTime.timeIntervalSinceNow), 1.0)
    }
    
    func testActiveSessionInitializationWithEmptyGoals() {
        // Arrange & Act
        let session = ActiveSession(
            clientId: testClientId,
            clientName: "Test Client",
            goalTemplates: []
        )
        
        // Assert
        XCTAssertEqual(session.goalTemplates.count, 0)
        XCTAssertEqual(session.currentGoalIndex, 0)
        XCTAssertNil(session.currentGoal)
    }
    
    // MARK: - Goal Management Tests
    
    func testCurrentGoal() {
        // Arrange & Act - Initial goal
        let currentGoal = activeSession.currentGoal
        
        // Assert
        XCTAssertNotNil(currentGoal)
        XCTAssertEqual(currentGoal?.id, testGoalTemplates[0].id)
        XCTAssertEqual(currentGoal?.title, "Improve Pronunciation")
    }
    
    func testCurrentGoalWhenIndexOutOfBounds() {
        // Arrange
        var session = ActiveSession(
            clientId: testClientId,
            clientName: "Test Client",
            goalTemplates: []
        )
        
        // Act
        let currentGoal = session.currentGoal
        
        // Assert
        XCTAssertNil(currentGoal)
    }
    
    func testMoveToNextGoal() {
        // Arrange
        XCTAssertEqual(activeSession.currentGoalIndex, 0)
        
        // Act - Move to next goal
        activeSession.moveToNextGoal()
        
        // Assert
        XCTAssertEqual(activeSession.currentGoalIndex, 1)
        XCTAssertEqual(activeSession.currentGoal?.title, "Reduce Disruptive Behavior")
        
        // Act - Move to next goal again
        activeSession.moveToNextGoal()
        
        // Assert
        XCTAssertEqual(activeSession.currentGoalIndex, 2)
        XCTAssertEqual(activeSession.currentGoal?.title, "Increase Eye Contact")
    }
    
    func testMoveToNextGoalAtLastIndex() {
        // Arrange - Move to last goal
        activeSession.setGoalIndex(2) // Last index
        XCTAssertEqual(activeSession.currentGoalIndex, 2)
        
        // Act - Try to move beyond last goal
        activeSession.moveToNextGoal()
        
        // Assert - Should stay at last index
        XCTAssertEqual(activeSession.currentGoalIndex, 2)
        XCTAssertEqual(activeSession.currentGoal?.title, "Increase Eye Contact")
    }
    
    func testMoveToPreviousGoal() {
        // Arrange - Start at second goal
        activeSession.setGoalIndex(2)
        XCTAssertEqual(activeSession.currentGoalIndex, 2)
        
        // Act - Move to previous goal
        activeSession.moveToPreviousGoal()
        
        // Assert
        XCTAssertEqual(activeSession.currentGoalIndex, 1)
        XCTAssertEqual(activeSession.currentGoal?.title, "Reduce Disruptive Behavior")
        
        // Act - Move to previous goal again
        activeSession.moveToPreviousGoal()
        
        // Assert
        XCTAssertEqual(activeSession.currentGoalIndex, 0)
        XCTAssertEqual(activeSession.currentGoal?.title, "Improve Pronunciation")
    }
    
    func testMoveToPreviousGoalAtFirstIndex() {
        // Arrange - Already at first goal
        XCTAssertEqual(activeSession.currentGoalIndex, 0)
        
        // Act - Try to move before first goal
        activeSession.moveToPreviousGoal()
        
        // Assert - Should stay at first index
        XCTAssertEqual(activeSession.currentGoalIndex, 0)
        XCTAssertEqual(activeSession.currentGoal?.title, "Improve Pronunciation")
    }
    
    func testSetGoalIndex() {
        // Act - Set to valid index
        activeSession.setGoalIndex(1)
        
        // Assert
        XCTAssertEqual(activeSession.currentGoalIndex, 1)
        XCTAssertEqual(activeSession.currentGoal?.title, "Reduce Disruptive Behavior")
        
        // Act - Set to another valid index
        activeSession.setGoalIndex(2)
        
        // Assert
        XCTAssertEqual(activeSession.currentGoalIndex, 2)
        XCTAssertEqual(activeSession.currentGoal?.title, "Increase Eye Contact")
    }
    
    func testSetGoalIndexWithInvalidValues() {
        // Arrange
        let originalIndex = activeSession.currentGoalIndex
        
        // Act & Assert - Negative index
        activeSession.setGoalIndex(-1)
        XCTAssertEqual(activeSession.currentGoalIndex, originalIndex)
        
        // Act & Assert - Index too high
        activeSession.setGoalIndex(10)
        XCTAssertEqual(activeSession.currentGoalIndex, originalIndex)
        
        // Act & Assert - Index equal to count
        activeSession.setGoalIndex(testGoalTemplates.count)
        XCTAssertEqual(activeSession.currentGoalIndex, originalIndex)
    }
    
    // MARK: - Trial Management Tests
    
    func testAddTrial() {
        // Arrange
        XCTAssertTrue(activeSession.trials.isEmpty)
        
        // Act - Add successful trial
        activeSession.addTrial(wasSuccessful: true, cueLevel: .independent)
        
        // Assert
        XCTAssertEqual(activeSession.trials.count, 1)
        let trial = activeSession.trials[0]
        XCTAssertEqual(trial.goalTemplateId, testGoalTemplates[0].id)
        XCTAssertEqual(trial.goalDescription, testGoalTemplates[0].description)
        XCTAssertTrue(trial.wasSuccessful)
        XCTAssertEqual(trial.cueLevel, .independent)
        XCTAssertNotNil(trial.timestamp)
        XCTAssertLessThanOrEqual(abs(trial.timestamp.timeIntervalSinceNow), 1.0)
    }
    
    func testAddTrialWithDifferentGoals() {
        // Act - Add trial for first goal
        activeSession.addTrial(wasSuccessful: true, cueLevel: .minimal)
        
        // Move to second goal and add trial
        activeSession.moveToNextGoal()
        activeSession.addTrial(wasSuccessful: false, cueLevel: .moderate)
        
        // Assert
        XCTAssertEqual(activeSession.trials.count, 2)
        
        let firstTrial = activeSession.trials[0]
        XCTAssertEqual(firstTrial.goalTemplateId, testGoalTemplates[0].id)
        XCTAssertTrue(firstTrial.wasSuccessful)
        XCTAssertEqual(firstTrial.cueLevel, .minimal)
        
        let secondTrial = activeSession.trials[1]
        XCTAssertEqual(secondTrial.goalTemplateId, testGoalTemplates[1].id)
        XCTAssertFalse(secondTrial.wasSuccessful)
        XCTAssertEqual(secondTrial.cueLevel, .moderate)
    }
    
    func testAddTrialWithNoCurrentGoal() {
        // Arrange - Session with no goals
        var emptySession = ActiveSession(
            clientId: testClientId,
            clientName: "Test Client",
            goalTemplates: []
        )
        
        // Act - Try to add trial with no current goal
        emptySession.addTrial(wasSuccessful: true, cueLevel: .independent)
        
        // Assert - No trial should be added
        XCTAssertTrue(emptySession.trials.isEmpty)
    }
    
    func testRemoveLastTrial() {
        // Arrange - Add some trials
        activeSession.addTrial(wasSuccessful: true, cueLevel: .independent)
        activeSession.addTrial(wasSuccessful: false, cueLevel: .minimal)
        XCTAssertEqual(activeSession.trials.count, 2)
        
        // Act - Remove last trial
        let removedTrial = activeSession.removeLastTrial()
        
        // Assert
        XCTAssertNotNil(removedTrial)
        XCTAssertFalse(removedTrial!.wasSuccessful)
        XCTAssertEqual(removedTrial!.cueLevel, .minimal)
        XCTAssertEqual(activeSession.trials.count, 1)
        
        // Verify remaining trial
        let remainingTrial = activeSession.trials[0]
        XCTAssertTrue(remainingTrial.wasSuccessful)
        XCTAssertEqual(remainingTrial.cueLevel, .independent)
    }
    
    func testRemoveLastTrialFromEmptyList() {
        // Arrange - Empty trials
        XCTAssertTrue(activeSession.trials.isEmpty)
        
        // Act - Try to remove from empty list
        let removedTrial = activeSession.removeLastTrial()
        
        // Assert
        XCTAssertNil(removedTrial)
        XCTAssertTrue(activeSession.trials.isEmpty)
    }
    
    // MARK: - Session Statistics Tests
    
    func testSessionDuration() {
        // Act - Get duration immediately after creation
        let duration = activeSession.sessionDuration
        
        // Assert - Should be very small but positive
        XCTAssertGreaterThanOrEqual(duration, 0)
        XCTAssertLessThan(duration, 1.0) // Less than 1 second
    }
    
    func testFormattedDuration() {
        // Act - Test initial formatted duration
        let formatted = activeSession.formattedDuration
        
        // Assert - Should be in MM:SS format starting with 00:00
        XCTAssertTrue(formatted.hasPrefix("00:00") || formatted.hasPrefix("00:01"))
        XCTAssertTrue(formatted.contains(":"))
        XCTAssertEqual(formatted.count, 5) // MM:SS format
    }
    
    func testTotalTrials() {
        // Arrange - Initially no trials
        XCTAssertEqual(activeSession.totalTrials, 0)
        
        // Act - Add trials
        activeSession.addTrial(wasSuccessful: true, cueLevel: .independent)
        activeSession.addTrial(wasSuccessful: false, cueLevel: .minimal)
        activeSession.addTrial(wasSuccessful: true, cueLevel: .moderate)
        
        // Assert
        XCTAssertEqual(activeSession.totalTrials, 3)
    }
    
    func testSuccessCount() {
        // Arrange - Add mixed trials
        activeSession.addTrial(wasSuccessful: true, cueLevel: .independent)
        activeSession.addTrial(wasSuccessful: false, cueLevel: .minimal)
        activeSession.addTrial(wasSuccessful: true, cueLevel: .moderate)
        activeSession.addTrial(wasSuccessful: true, cueLevel: .maximal)
        
        // Act & Assert
        XCTAssertEqual(activeSession.successCount, 3)
        XCTAssertEqual(activeSession.failureCount, 1)
    }
    
    func testFailureCount() {
        // Arrange - Add mixed trials
        activeSession.addTrial(wasSuccessful: false, cueLevel: .independent)
        activeSession.addTrial(wasSuccessful: false, cueLevel: .minimal)
        activeSession.addTrial(wasSuccessful: true, cueLevel: .moderate)
        
        // Act & Assert
        XCTAssertEqual(activeSession.failureCount, 2)
        XCTAssertEqual(activeSession.successCount, 1)
    }
    
    func testSuccessRate() {
        // Test with no trials
        XCTAssertEqual(activeSession.successRate, 0.0)
        
        // Add 3 successful, 2 failed trials
        activeSession.addTrial(wasSuccessful: true, cueLevel: .independent)
        activeSession.addTrial(wasSuccessful: true, cueLevel: .minimal)
        activeSession.addTrial(wasSuccessful: false, cueLevel: .moderate)
        activeSession.addTrial(wasSuccessful: true, cueLevel: .maximal)
        activeSession.addTrial(wasSuccessful: false, cueLevel: .independent)
        
        // Act & Assert - 3/5 = 0.6
        XCTAssertEqual(activeSession.successRate, 0.6, accuracy: 0.001)
    }
    
    func testSuccessPercentage() {
        // Add trials with 75% success rate
        activeSession.addTrial(wasSuccessful: true, cueLevel: .independent)
        activeSession.addTrial(wasSuccessful: true, cueLevel: .minimal)
        activeSession.addTrial(wasSuccessful: true, cueLevel: .moderate)
        activeSession.addTrial(wasSuccessful: false, cueLevel: .maximal)
        
        // Act & Assert
        XCTAssertEqual(activeSession.successPercentage, 75)
    }
    
    func testFormattedSuccessRate() {
        // Test with no trials
        XCTAssertEqual(activeSession.formattedSuccessRate, "0% (0/0)")
        
        // Add trials
        activeSession.addTrial(wasSuccessful: true, cueLevel: .independent)
        activeSession.addTrial(wasSuccessful: false, cueLevel: .minimal)
        activeSession.addTrial(wasSuccessful: true, cueLevel: .moderate)
        
        // Act & Assert - 2/3 = 66%
        XCTAssertEqual(activeSession.formattedSuccessRate, "66% (2/3)")
    }
    
    // MARK: - Goal-Specific Statistics Tests
    
    func testStatsForGoal() {
        // Arrange - Add trials for different goals
        let goal1Id = testGoalTemplates[0].id
        let goal2Id = testGoalTemplates[1].id
        
        // Add trials for goal 1
        activeSession.addTrial(wasSuccessful: true, cueLevel: .independent)
        activeSession.addTrial(wasSuccessful: true, cueLevel: .minimal)
        activeSession.addTrial(wasSuccessful: false, cueLevel: .moderate)
        
        // Move to goal 2 and add trials
        activeSession.moveToNextGoal()
        activeSession.addTrial(wasSuccessful: false, cueLevel: .maximal)
        activeSession.addTrial(wasSuccessful: true, cueLevel: .independent)
        
        // Act - Get stats for goal 1
        let goal1Stats = activeSession.statsForGoal(goal1Id)
        
        // Assert - Goal 1 should have 2 successes out of 3 trials
        XCTAssertEqual(goal1Stats.goalTemplateId, goal1Id)
        XCTAssertEqual(goal1Stats.successCount, 2)
        XCTAssertEqual(goal1Stats.totalCount, 3)
        XCTAssertEqual(goal1Stats.successRate, 2.0/3.0, accuracy: 0.001)
        XCTAssertEqual(goal1Stats.successPercentage, 66)
        
        // Act - Get stats for goal 2
        let goal2Stats = activeSession.statsForGoal(goal2Id)
        
        // Assert - Goal 2 should have 1 success out of 2 trials
        XCTAssertEqual(goal2Stats.successCount, 1)
        XCTAssertEqual(goal2Stats.totalCount, 2)
        XCTAssertEqual(goal2Stats.successRate, 0.5, accuracy: 0.001)
    }
    
    func testStatsForGoalWithNoTrials() {
        // Arrange
        let goalId = testGoalTemplates[0].id
        
        // Act - Get stats for goal with no trials
        let stats = activeSession.statsForGoal(goalId)
        
        // Assert
        XCTAssertEqual(stats.goalTemplateId, goalId)
        XCTAssertEqual(stats.successCount, 0)
        XCTAssertEqual(stats.totalCount, 0)
        XCTAssertEqual(stats.successRate, 0.0)
        XCTAssertEqual(stats.successPercentage, 0)
    }
    
    func testAllGoalStats() {
        // Arrange - Add trials for multiple goals
        activeSession.addTrial(wasSuccessful: true, cueLevel: .independent)
        activeSession.addTrial(wasSuccessful: false, cueLevel: .minimal)
        
        activeSession.moveToNextGoal()
        activeSession.addTrial(wasSuccessful: true, cueLevel: .moderate)
        
        // Act
        let allStats = activeSession.allGoalStats
        
        // Assert
        XCTAssertEqual(allStats.count, 3) // Should have stats for all 3 goals
        
        // Check stats for goal with trials
        let goal1Stats = allStats.first { $0.goalTemplateId == testGoalTemplates[0].id }!
        XCTAssertEqual(goal1Stats.totalCount, 2)
        XCTAssertEqual(goal1Stats.successCount, 1)
        
        let goal2Stats = allStats.first { $0.goalTemplateId == testGoalTemplates[1].id }!
        XCTAssertEqual(goal2Stats.totalCount, 1)
        XCTAssertEqual(goal2Stats.successCount, 1)
        
        // Check stats for goal with no trials
        let goal3Stats = allStats.first { $0.goalTemplateId == testGoalTemplates[2].id }!
        XCTAssertEqual(goal3Stats.totalCount, 0)
        XCTAssertEqual(goal3Stats.successCount, 0)
    }
    
    // MARK: - Cue Level Statistics Tests
    
    func testCueLevelBreakdown() {
        // Arrange - Add trials with different cue levels
        activeSession.addTrial(wasSuccessful: true, cueLevel: .independent)
        activeSession.addTrial(wasSuccessful: false, cueLevel: .independent)
        activeSession.addTrial(wasSuccessful: true, cueLevel: .minimal)
        activeSession.addTrial(wasSuccessful: true, cueLevel: .moderate)
        activeSession.addTrial(wasSuccessful: false, cueLevel: .moderate)
        activeSession.addTrial(wasSuccessful: true, cueLevel: .maximal)
        
        // Act
        let breakdown = activeSession.cueLevelBreakdown
        
        // Assert
        XCTAssertEqual(breakdown.independent, 2)
        XCTAssertEqual(breakdown.minimal, 1)
        XCTAssertEqual(breakdown.moderate, 2)
        XCTAssertEqual(breakdown.maximal, 1)
        XCTAssertEqual(breakdown.total, 6)
    }
    
    func testCueLevelBreakdownWithNoTrials() {
        // Act
        let breakdown = activeSession.cueLevelBreakdown
        
        // Assert
        XCTAssertEqual(breakdown.independent, 0)
        XCTAssertEqual(breakdown.minimal, 0)
        XCTAssertEqual(breakdown.moderate, 0)
        XCTAssertEqual(breakdown.maximal, 0)
        XCTAssertEqual(breakdown.total, 0)
    }
    
    // MARK: - Session Conversion Tests
    
    func testToSession() {
        // Arrange - Add some trials
        activeSession.addTrial(wasSuccessful: true, cueLevel: .independent)
        activeSession.addTrial(wasSuccessful: false, cueLevel: .minimal)
        
        // Act
        let session = activeSession.toSession()
        
        // Assert - Basic session properties
        XCTAssertEqual(session.clientId, testClientId)
        XCTAssertEqual(session.createdOn, "Watch")
        XCTAssertNil(session.location)
        
        // Assert - Goal logs
        XCTAssertEqual(session.goalLogs.count, 2)
        
        let firstLog = session.goalLogs[0]
        XCTAssertEqual(firstLog.goalTemplateId, testGoalTemplates[0].id)
        XCTAssertEqual(firstLog.goalDescription, testGoalTemplates[0].description)
        XCTAssertTrue(firstLog.wasSuccessful)
        XCTAssertEqual(firstLog.cueLevel, .independent)
        XCTAssertEqual(firstLog.sessionId, session.id)
        
        let secondLog = session.goalLogs[1]
        XCTAssertEqual(secondLog.goalTemplateId, testGoalTemplates[0].id)
        XCTAssertFalse(secondLog.wasSuccessful)
        XCTAssertEqual(secondLog.cueLevel, .minimal)
        XCTAssertEqual(secondLog.sessionId, session.id)
    }
    
    func testToSessionWithNoTrials() {
        // Act
        let session = activeSession.toSession()
        
        // Assert
        XCTAssertEqual(session.clientId, testClientId)
        XCTAssertTrue(session.goalLogs.isEmpty)
        XCTAssertEqual(session.createdOn, "Watch")
    }
    
    // MARK: - Performance Level Tests
    
    func testPerformanceLevel() {
        // Test excellent performance (85-100%)
        var stats = GoalStats(
            goalTemplateId: UUID(),
            successCount: 9,
            totalCount: 10,
            successRate: 0.9
        )
        XCTAssertEqual(stats.performanceLevel, .excellent)
        XCTAssertEqual(stats.successPercentage, 90)
        
        // Test good performance (70-84%)
        stats = GoalStats(
            goalTemplateId: UUID(),
            successCount: 8,
            totalCount: 10,
            successRate: 0.8
        )
        XCTAssertEqual(stats.performanceLevel, .good)
        
        // Test needs work performance (< 70%)
        stats = GoalStats(
            goalTemplateId: UUID(),
            successCount: 6,
            totalCount: 10,
            successRate: 0.6
        )
        XCTAssertEqual(stats.performanceLevel, .needsWork)
    }
    
    // MARK: - Edge Case Tests
    
    func testTrialEntryIdentifiable() {
        // Arrange
        activeSession.addTrial(wasSuccessful: true, cueLevel: .independent)
        activeSession.addTrial(wasSuccessful: false, cueLevel: .minimal)
        
        // Act
        let trial1 = activeSession.trials[0]
        let trial2 = activeSession.trials[1]
        
        // Assert - Each trial should have unique ID
        XCTAssertNotEqual(trial1.id, trial2.id)
        XCTAssertNotNil(trial1.id)
        XCTAssertNotNil(trial2.id)
    }
    
    func testGoalStatsIdentifiable() {
        // Arrange
        let goalId = UUID()
        let stats = GoalStats(
            goalTemplateId: goalId,
            successCount: 5,
            totalCount: 10,
            successRate: 0.5
        )
        
        // Act & Assert
        XCTAssertEqual(stats.id, goalId)
    }
    
    func testCueLevelStatsTotal() {
        // Arrange
        let stats = CueLevelStats(
            independent: 5,
            minimal: 3,
            moderate: 2,
            maximal: 1
        )
        
        // Act & Assert
        XCTAssertEqual(stats.total, 11)
    }
    
    // MARK: - Test Helper Methods
    
    private func createTestGoalTemplates() -> [GoalTemplate] {
        return [
            GoalTemplate(
                id: UUID(),
                title: "Improve Pronunciation",
                description: "Focus on consonant sounds",
                category: "Speech",
                defaultCueLevel: .minimal,
                clientId: testClientId,
                isActive: true,
                createdDate: Date()
            ),
            GoalTemplate(
                id: UUID(),
                title: "Reduce Disruptive Behavior",
                description: "Behavioral intervention strategies",
                category: "Behavior",
                defaultCueLevel: .moderate,
                clientId: testClientId,
                isActive: true,
                createdDate: Date()
            ),
            GoalTemplate(
                id: UUID(),
                title: "Increase Eye Contact",
                description: "Social interaction skills",
                category: "Social",
                defaultCueLevel: .maximal,
                clientId: testClientId,
                isActive: true,
                createdDate: Date()
            )
        ]
    }
}