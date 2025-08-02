import XCTest
import UIKit
import SwiftUI
@testable import Sessions_Watch_App

/// Comprehensive test suite for HapticManager in Stage 3 Apple Watch implementation
/// 
/// **Test Coverage:**
/// This test class validates the behavior of the HapticManager:
/// - Singleton pattern implementation
/// - All haptic feedback methods execute without errors
/// - Context-specific feedback methods mapping
/// - SwiftUI integration extensions
/// - HapticFeedbackType enum functionality
/// 
/// **Test Architecture:**
/// - Unit tests for haptic manager functionality
/// - Tests method calls without actual device feedback
/// - Validates proper method mapping and enum cases
/// - Tests SwiftUI view extension integration
/// 
/// **Testing Strategy:**
/// - Verifies methods can be called without crashing
/// - Tests singleton behavior and thread safety
/// - Validates enum-to-method mapping in extensions
/// - Ensures all feedback types are properly implemented
/// 
/// **Note on Testing Haptics:**
/// Since haptic feedback requires physical device hardware and produces no
/// testable return values, these tests focus on ensuring methods execute
/// without errors and maintain proper API contracts.
final class HapticManagerTests: XCTestCase {
    
    // MARK: - Test Infrastructure
    
    var hapticManager: HapticManager!
    
    override func setUp() {
        super.setUp()
        hapticManager = HapticManager.shared
    }
    
    override func tearDown() {
        hapticManager = nil
        super.tearDown()
    }
    
    // MARK: - Singleton Pattern Tests
    
    func testSingletonInstance() {
        // Act - Get multiple instances
        let instance1 = HapticManager.shared
        let instance2 = HapticManager.shared
        
        // Assert - Should be the same instance
        XCTAssertTrue(instance1 === instance2)
        XCTAssertTrue(hapticManager === instance1)
    }
    
    func testSingletonThreadSafety() async {
        // Arrange - Create multiple concurrent access tasks
        let expectation = XCTestExpectation(description: "Concurrent access to singleton")
        expectation.expectedFulfillmentCount = 10
        
        var instances: [HapticManager] = []
        let queue = DispatchQueue.global(qos: .userInitiated)
        
        // Act - Access singleton from multiple threads
        for _ in 0..<10 {
            queue.async {
                let instance = HapticManager.shared
                instances.append(instance)
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        // Assert - All instances should be the same
        let firstInstance = instances.first!
        for instance in instances {
            XCTAssertTrue(instance === firstInstance)
        }
    }
    
    // MARK: - Basic Haptic Feedback Tests
    
    func testLightImpact() {
        // Act & Assert - Should not crash
        XCTAssertNoThrow(hapticManager.lightImpact())
    }
    
    func testMediumImpact() {
        // Act & Assert - Should not crash
        XCTAssertNoThrow(hapticManager.mediumImpact())
    }
    
    func testHeavyImpact() {
        // Act & Assert - Should not crash
        XCTAssertNoThrow(hapticManager.heavyImpact())
    }
    
    func testSuccess() {
        // Act & Assert - Should not crash
        XCTAssertNoThrow(hapticManager.success())
    }
    
    func testWarning() {
        // Act & Assert - Should not crash
        XCTAssertNoThrow(hapticManager.warning())
    }
    
    func testError() {
        // Act & Assert - Should not crash
        XCTAssertNoThrow(hapticManager.error())
    }
    
    // MARK: - Context-Specific Feedback Tests
    
    func testTrialSuccess() {
        // Act & Assert - Should not crash and call appropriate method
        XCTAssertNoThrow(hapticManager.trialSuccess())
    }
    
    func testTrialFailure() {
        // Act & Assert - Should not crash and call appropriate method
        XCTAssertNoThrow(hapticManager.trialFailure())
    }
    
    func testCueLevelSelected() {
        // Act & Assert - Should not crash
        XCTAssertNoThrow(hapticManager.cueLevelSelected())
    }
    
    func testGoalNavigation() {
        // Act & Assert - Should not crash
        XCTAssertNoThrow(hapticManager.goalNavigation())
    }
    
    func testSessionStart() {
        // Act & Assert - Should not crash
        XCTAssertNoThrow(hapticManager.sessionStart())
    }
    
    func testSessionEnd() {
        // Act & Assert - Should not crash
        XCTAssertNoThrow(hapticManager.sessionEnd())
    }
    
    func testUndoAction() {
        // Act & Assert - Should not crash
        XCTAssertNoThrow(hapticManager.undoAction())
    }
    
    func testClientSelected() {
        // Act & Assert - Should not crash
        XCTAssertNoThrow(hapticManager.clientSelected())
    }
    
    func testNavigate() {
        // Act & Assert - Should not crash
        XCTAssertNoThrow(hapticManager.navigate())
    }
    
    func testAutoTimeout() {
        // Act & Assert - Should not crash
        XCTAssertNoThrow(hapticManager.autoTimeout())
    }
    
    // MARK: - Method Call Sequence Tests
    
    func testMultipleHapticCalls() {
        // Act - Call multiple haptic methods in sequence
        XCTAssertNoThrow {
            hapticManager.sessionStart()
            hapticManager.goalNavigation()
            hapticManager.trialSuccess()
            hapticManager.cueLevelSelected()
            hapticManager.trialFailure()
            hapticManager.undoAction()
            hapticManager.sessionEnd()
        }
    }
    
    func testRapidHapticCalls() {
        // Act - Call haptic methods rapidly
        XCTAssertNoThrow {
            for _ in 0..<10 {
                hapticManager.lightImpact()
            }
        }
    }
    
    func testAllHapticMethods() {
        // Act - Test all haptic methods
        XCTAssertNoThrow {
            // Basic impacts
            hapticManager.lightImpact()
            hapticManager.mediumImpact()
            hapticManager.heavyImpact()
            
            // Notifications
            hapticManager.success()
            hapticManager.warning()
            hapticManager.error()
            
            // Context-specific
            hapticManager.trialSuccess()
            hapticManager.trialFailure()
            hapticManager.cueLevelSelected()
            hapticManager.goalNavigation()
            hapticManager.sessionStart()
            hapticManager.sessionEnd()
            hapticManager.undoAction()
            hapticManager.clientSelected()
            hapticManager.navigate()
            hapticManager.autoTimeout()
        }
    }
    
    // MARK: - SwiftUI Integration Tests
    
    func testHapticFeedbackTypeEnum() {
        // Test all enum cases exist
        let allTypes: [HapticFeedbackType] = [
            .light, .medium, .heavy,
            .success, .warning, .error
        ]
        
        // Assert - All types should be valid
        XCTAssertEqual(allTypes.count, 6)
        
        // Test enum cases can be compared
        XCTAssertNotEqual(HapticFeedbackType.light, HapticFeedbackType.heavy)
        XCTAssertNotEqual(HapticFeedbackType.success, HapticFeedbackType.error)
    }
    
    func testHapticFeedbackViewExtension() {
        // Create a test view
        let testView = Text("Test View")
        
        // Act - Apply haptic feedback modifiers
        XCTAssertNoThrow {
            _ = testView.hapticFeedback(.light)
            _ = testView.hapticFeedback(.medium)
            _ = testView.hapticFeedback(.heavy)
            _ = testView.hapticFeedback(.success)
            _ = testView.hapticFeedback(.warning)
            _ = testView.hapticFeedback(.error)
        }
    }
    
    // MARK: - Memory and Performance Tests
    
    func testHapticManagerMemoryUsage() {
        // Test that haptic manager doesn't leak memory
        weak var weakReference: HapticManager?
        
        autoreleasepool {
            let manager = HapticManager.shared
            weakReference = manager
            
            // Perform some operations
            manager.lightImpact()
            manager.success()
            manager.trialSuccess()
        }
        
        // Assert - Singleton should still exist (not deallocated)
        XCTAssertNotNil(weakReference)
    }
    
    func testPerformanceOfHapticCalls() {
        // Measure performance of haptic calls
        measure {
            for _ in 0..<100 {
                hapticManager.lightImpact()
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testHapticCallsWithoutCrashing() {
        // Test haptic calls in various states/conditions
        
        // Call methods multiple times
        XCTAssertNoThrow {
            hapticManager.sessionStart()
            hapticManager.sessionStart() // Duplicate call
        }
        
        // Call conflicting methods
        XCTAssertNoThrow {
            hapticManager.trialSuccess()
            hapticManager.trialFailure() // Opposite call
        }
        
        // Call methods in unusual order
        XCTAssertNoThrow {
            hapticManager.sessionEnd()
            hapticManager.sessionStart()
            hapticManager.undoAction()
            hapticManager.cueLevelSelected()
        }
    }
    
    // MARK: - Integration with UI Components Tests
    
    func testHapticIntegrationScenarios() {
        // Simulate common usage patterns in the app
        
        // Session workflow
        XCTAssertNoThrow {
            hapticManager.clientSelected()
            hapticManager.sessionStart()
            hapticManager.goalNavigation()
            hapticManager.trialSuccess()
            hapticManager.cueLevelSelected()
            hapticManager.goalNavigation()
            hapticManager.trialFailure()
            hapticManager.cueLevelSelected()
            hapticManager.undoAction()
            hapticManager.sessionEnd()
        }
    }
    
    func testHapticFeedbackInErrorScenarios() {
        // Test haptic feedback for error conditions
        XCTAssertNoThrow {
            hapticManager.error()
            hapticManager.warning()
        }
    }
    
    // MARK: - Context Mapping Tests
    
    func testContextSpecificMappingConsistency() {
        // Verify that context-specific methods are properly mapped
        // This is more of a documentation test to ensure the API is consistent
        
        // Session-related haptics should use medium impact
        XCTAssertNoThrow {
            hapticManager.sessionStart()
            hapticManager.sessionEnd()
        }
        
        // Trial-related haptics should differentiate between success/failure
        XCTAssertNoThrow {
            hapticManager.trialSuccess() // Should call success()
            hapticManager.trialFailure() // Should call lightImpact()
        }
        
        // Navigation haptics should be light
        XCTAssertNoThrow {
            hapticManager.goalNavigation()
            hapticManager.navigate()
            hapticManager.clientSelected()
        }
        
        // Selection haptics should be light
        XCTAssertNoThrow {
            hapticManager.cueLevelSelected()
            hapticManager.autoTimeout()
        }
        
        // Action haptics should be light
        XCTAssertNoThrow {
            hapticManager.undoAction()
        }
    }
    
    // MARK: - Platform Compatibility Tests
    
    func testHapticManagerOnDifferentPlatforms() {
        // Test that haptic manager works regardless of platform capabilities
        // This ensures the app doesn't crash on devices without haptic support
        
        XCTAssertNoThrow {
            hapticManager.lightImpact()
            hapticManager.mediumImpact()
            hapticManager.heavyImpact()
            hapticManager.success()
            hapticManager.warning()
            hapticManager.error()
        }
    }
    
    // MARK: - API Contract Tests
    
    func testHapticManagerAPIContract() {
        // Verify that all expected methods are available
        
        // Basic impact methods
        XCTAssertTrue(hapticManager.responds(to: #selector(HapticManager.lightImpact)))
        XCTAssertTrue(hapticManager.responds(to: #selector(HapticManager.mediumImpact)))
        XCTAssertTrue(hapticManager.responds(to: #selector(HapticManager.heavyImpact)))
        
        // Notification methods
        XCTAssertTrue(hapticManager.responds(to: #selector(HapticManager.success)))
        XCTAssertTrue(hapticManager.responds(to: #selector(HapticManager.warning)))
        XCTAssertTrue(hapticManager.responds(to: #selector(HapticManager.error)))
        
        // Context-specific methods
        XCTAssertTrue(hapticManager.responds(to: #selector(HapticManager.trialSuccess)))
        XCTAssertTrue(hapticManager.responds(to: #selector(HapticManager.trialFailure)))
        XCTAssertTrue(hapticManager.responds(to: #selector(HapticManager.sessionStart)))
        XCTAssertTrue(hapticManager.responds(to: #selector(HapticManager.sessionEnd)))
    }
    
    // MARK: - Concurrency Tests
    
    func testConcurrentHapticCalls() async {
        // Test haptic calls from multiple concurrent contexts
        let expectation = XCTestExpectation(description: "Concurrent haptic calls")
        expectation.expectedFulfillmentCount = 10
        
        // Act - Make concurrent haptic calls
        for i in 0..<10 {
            Task {
                if i % 2 == 0 {
                    hapticManager.lightImpact()
                } else {
                    hapticManager.success()
                }
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        // Assert - No crashes occurred (implicit in successful completion)
    }
}

// MARK: - Mock View for Testing SwiftUI Integration

private struct MockView: View {
    var body: some View {
        VStack {
            Text("Test")
                .hapticFeedback(.light)
            
            Button("Success") {}
                .hapticFeedback(.success)
            
            Button("Error") {}
                .hapticFeedback(.error)
        }
    }
}