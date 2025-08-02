import XCTest
import SwiftUI
import CoreData
import Combine
@testable import Sessions

/// Comprehensive test suite for error handling implementation in Sessions app
/// 
/// **Test Coverage:**
/// This test class validates the complete error handling system:
/// - TherapyAppError enum and its properties
/// - Error UI components (alerts, banners, recovery views)
/// - Repository error propagation and validation
/// - ViewModel error integration and retry functionality
/// - Error classification and user-friendly messaging
/// 
/// **Test Architecture:**
/// - Uses MockTherapyRepository with TherapyAppError support
/// - Tests SwiftUI error components with proper async patterns
/// - Validates accessibility features for error states
/// - Tests error recovery and retry mechanisms
/// - Ensures backward compatibility with legacy error handling
/// 
/// **Testing Strategy:**
/// - Arrange-Act-Assert pattern for comprehensive error scenarios
/// - Mock dependencies to isolate error conditions
/// - Tests both happy path error recovery and failure cases
/// - Validates HIPAA-compliant error messaging (no PHI exposure)
final class ErrorHandlingTests: XCTestCase {
    
    // MARK: - Test Infrastructure
    
    var mockRepository: MockTherapyRepository!
    var cancellables: Set<AnyCancellable>!
    
    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        mockRepository = MockTherapyRepository()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() async throws {
        cancellables = nil
        mockRepository = nil
        try await super.tearDown()
    }
    
    // MARK: - TherapyAppError Tests
    
    /// Tests all error cases have proper localized descriptions
    func testTherapyAppErrorLocalizedDescriptions() {
        // Core Data Errors
        let saveError = TherapyAppError.saveFailure(NSError(domain: "Test", code: 0, userInfo: [:]))
        XCTAssertEqual(saveError.errorDescription, "Unable to save your changes. Please try again.")
        
        let fetchError = TherapyAppError.fetchFailure(NSError(domain: "Test", code: 0, userInfo: [:]))
        XCTAssertEqual(fetchError.errorDescription, "Unable to load data. Please check your connection and try again.")
        
        let contextSyncError = TherapyAppError.contextSyncFailure(NSError(domain: "Test", code: 0, userInfo: [:]))
        XCTAssertEqual(contextSyncError.errorDescription, "Data synchronization failed. Your changes may not be saved.")
        
        let persistentStoreError = TherapyAppError.persistentStoreError(NSError(domain: "Test", code: 0, userInfo: [:]))
        XCTAssertEqual(persistentStoreError.errorDescription, "Database is temporarily unavailable. Please restart the app.")
        
        // Validation Errors
        let validationError = TherapyAppError.validationError(field: "Name", reason: "cannot be empty")
        XCTAssertEqual(validationError.errorDescription, "Name: cannot be empty")
        
        let clientNameError = TherapyAppError.clientNameRequired
        XCTAssertEqual(clientNameError.errorDescription, "Client name is required. Please enter a name for this client.")
        
        let goalTitleError = TherapyAppError.goalTitleRequired
        XCTAssertEqual(goalTitleError.errorDescription, "Goal title is required. Please enter a title for this goal template.")
        
        let invalidCueError = TherapyAppError.invalidCueLevel
        XCTAssertEqual(invalidCueError.errorDescription, "Invalid cue level selected. Please choose a valid cue level.")
        
        // Business Logic Errors
        let clientNotFoundError = TherapyAppError.clientNotFound(clientId: "123")
        XCTAssertEqual(clientNotFoundError.errorDescription, "Client not found. The client may have been deleted or moved.")
        
        let goalNotFoundError = TherapyAppError.goalTemplateNotFound(templateId: "456")
        XCTAssertEqual(goalNotFoundError.errorDescription, "Goal template not found. The template may have been deleted.")
        
        let sessionNotFoundError = TherapyAppError.sessionNotFound(sessionId: "789")
        XCTAssertEqual(sessionNotFoundError.errorDescription, "Session not found. The session may have been deleted.")
        
        let sessionActiveError = TherapyAppError.sessionAlreadyActive
        XCTAssertEqual(sessionActiveError.errorDescription, "Another session is already in progress. Please end the current session first.")
        
        let noActiveSessionError = TherapyAppError.noActiveSession
        XCTAssertEqual(noActiveSessionError.errorDescription, "No active session found. Please start a new session to continue.")
        
        let clientHasSessionsError = TherapyAppError.clientHasSessions
        XCTAssertEqual(clientHasSessionsError.errorDescription, "Cannot delete client with existing sessions. Archive the client instead.")
        
        let goalHasLogsError = TherapyAppError.goalTemplateHasLogs
        XCTAssertEqual(goalHasLogsError.errorDescription, "Cannot delete goal template with existing data. Deactivate the template instead.")
        
        // Network Errors
        let networkError = TherapyAppError.networkUnavailable
        XCTAssertEqual(networkError.errorDescription, "Network connection unavailable. Please check your internet connection.")
        
        let timeoutError = TherapyAppError.operationTimeout
        XCTAssertEqual(timeoutError.errorDescription, "Operation timed out. Please try again.")
        
        let watchError = TherapyAppError.watchConnectivityUnavailable
        XCTAssertEqual(watchError.errorDescription, "Watch connection unavailable. Please check your Apple Watch connection.")
        
        // Generic Errors
        let unknownError = TherapyAppError.unknown(NSError(domain: "Test", code: 0, userInfo: [:]))
        XCTAssertEqual(unknownError.errorDescription, "An unexpected error occurred. Please try again.")
        
        let cancelledError = TherapyAppError.cancelled
        XCTAssertEqual(cancelledError.errorDescription, "Operation was cancelled.")
    }
    
    /// Tests error recovery suggestions are appropriate
    func testTherapyAppErrorRecoverySuggestions() {
        // Core Data Errors should have recovery suggestions
        let saveError = TherapyAppError.saveFailure(NSError(domain: "Test", code: 0, userInfo: [:]))
        XCTAssertEqual(saveError.recoverySuggestion, "Try closing and reopening the app, then attempt the operation again.")
        
        let fetchError = TherapyAppError.fetchFailure(NSError(domain: "Test", code: 0, userInfo: [:]))
        XCTAssertEqual(fetchError.recoverySuggestion, "Pull down to refresh the data, or restart the app if the problem persists.")
        
        // Validation errors should have form-specific suggestions
        let clientNameError = TherapyAppError.clientNameRequired
        XCTAssertEqual(clientNameError.recoverySuggestion, "Enter a name for the client and try saving again.")
        
        let goalTitleError = TherapyAppError.goalTitleRequired
        XCTAssertEqual(goalTitleError.recoverySuggestion, "Enter a title for the goal template and try saving again.")
        
        // Business logic errors should have workflow suggestions
        let clientNotFoundError = TherapyAppError.clientNotFound(clientId: "123")
        XCTAssertEqual(clientNotFoundError.recoverySuggestion, "Return to the client list and select a different client.")
        
        let sessionActiveError = TherapyAppError.sessionAlreadyActive
        XCTAssertEqual(sessionActiveError.recoverySuggestion, "End the current session from the Sessions tab, then try starting a new session.")
        
        let clientHasSessionsError = TherapyAppError.clientHasSessions
        XCTAssertEqual(clientHasSessionsError.recoverySuggestion, "Use the 'Archive Client' option instead of deleting to preserve session data.")
        
        // Cancelled operations should have no recovery suggestion
        let cancelledError = TherapyAppError.cancelled
        XCTAssertNil(cancelledError.recoverySuggestion)
    }
    
    /// Tests error classification properties for UI behavior
    func testTherapyAppErrorClassification() {
        // Retryable errors
        let saveError = TherapyAppError.saveFailure(NSError(domain: "Test", code: 0, userInfo: [:]))
        XCTAssertTrue(saveError.isRetryable)
        XCTAssertFalse(saveError.isCritical)
        XCTAssertEqual(saveError.category, "CoreData")
        
        let networkError = TherapyAppError.networkUnavailable
        XCTAssertTrue(networkError.isRetryable)
        XCTAssertFalse(networkError.isCritical)
        XCTAssertEqual(networkError.category, "Network")
        
        // Non-retryable errors
        let validationError = TherapyAppError.clientNameRequired
        XCTAssertFalse(validationError.isRetryable)
        XCTAssertFalse(validationError.isCritical)
        XCTAssertEqual(validationError.category, "Validation")
        
        let notFoundError = TherapyAppError.clientNotFound(clientId: "123")
        XCTAssertFalse(notFoundError.isRetryable)
        XCTAssertFalse(notFoundError.isCritical)
        XCTAssertEqual(notFoundError.category, "BusinessLogic")
        
        // Critical errors
        let persistentStoreError = TherapyAppError.persistentStoreError(NSError(domain: "Test", code: 0, userInfo: [:]))
        XCTAssertTrue(persistentStoreError.isRetryable)
        XCTAssertTrue(persistentStoreError.isCritical)
        XCTAssertEqual(persistentStoreError.category, "CoreData")
        
        let clientHasSessionsError = TherapyAppError.clientHasSessions
        XCTAssertFalse(clientHasSessionsError.isRetryable)
        XCTAssertTrue(clientHasSessionsError.isCritical)
        XCTAssertEqual(clientHasSessionsError.category, "BusinessLogic")
        
        // Generic errors
        let unknownError = TherapyAppError.unknown(NSError(domain: "Test", code: 0, userInfo: [:]))
        XCTAssertTrue(unknownError.isRetryable)
        XCTAssertFalse(unknownError.isCritical)
        XCTAssertEqual(unknownError.category, "Generic")
        
        let cancelledError = TherapyAppError.cancelled
        XCTAssertFalse(cancelledError.isRetryable)
        XCTAssertFalse(cancelledError.isCritical)
        XCTAssertEqual(cancelledError.category, "Generic")
    }
    
    /// Tests factory methods for creating specific error types
    func testTherapyAppErrorFactoryMethods() {
        // Core Data error factory
        let coreDataError = NSError(domain: NSSQLiteErrorDomain, code: NSManagedObjectValidationError, userInfo: [:])
        let therapyError = TherapyAppError.coreDataError(coreDataError)
        
        if case .validationError(let field, let reason) = therapyError {
            XCTAssertEqual(field, "Data")
            XCTAssertEqual(reason, "Required information is missing")
        } else {
            XCTFail("Expected validation error from Core Data validation error")
        }
        
        // Validation error factory
        let validationError = TherapyAppError.validation(field: "Email", reason: "must be valid format")
        if case .validationError(let field, let reason) = validationError {
            XCTAssertEqual(field, "Email")
            XCTAssertEqual(reason, "must be valid format")
        } else {
            XCTFail("Expected validation error from factory method")
        }
        
        // Not found error factory
        let clientNotFound = TherapyAppError.notFound(entity: "client", id: "123")
        if case .clientNotFound(let clientId) = clientNotFound {
            XCTAssertEqual(clientId, "123")
        } else {
            XCTFail("Expected client not found error")
        }
        
        let goalNotFound = TherapyAppError.notFound(entity: "goaltemplate", id: "456")
        if case .goalTemplateNotFound(let templateId) = goalNotFound {
            XCTAssertEqual(templateId, "456")
        } else {
            XCTFail("Expected goal template not found error")
        }
        
        let sessionNotFound = TherapyAppError.notFound(entity: "session", id: "789")
        if case .sessionNotFound(let sessionId) = sessionNotFound {
            XCTAssertEqual(sessionId, "789")
        } else {
            XCTFail("Expected session not found error")
        }
        
        // Unknown entity should fall back to generic unknown error
        let unknownEntity = TherapyAppError.notFound(entity: "unknown", id: "999")
        if case .unknown = unknownEntity {
            // Expected behavior
        } else {
            XCTFail("Expected unknown error for unrecognized entity type")
        }
    }
    
    /// Tests failure reasons contain technical details for debugging
    func testTherapyAppErrorFailureReasons() {
        let underlyingError = NSError(domain: "TestDomain", code: 42, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        
        // Core Data errors should include underlying error details
        let saveError = TherapyAppError.saveFailure(underlyingError)
        XCTAssertTrue(saveError.failureReason?.contains("Core Data save failed") == true)
        XCTAssertTrue(saveError.failureReason?.contains("Test error") == true)
        
        let fetchError = TherapyAppError.fetchFailure(underlyingError)
        XCTAssertTrue(fetchError.failureReason?.contains("Core Data fetch failed") == true)
        XCTAssertTrue(fetchError.failureReason?.contains("Test error") == true)
        
        // Validation errors should include field and reason
        let validationError = TherapyAppError.validationError(field: "Name", reason: "cannot be empty")
        XCTAssertEqual(validationError.failureReason, "Validation failed for field 'Name': cannot be empty")
        
        // Not found errors should include entity and ID
        let clientNotFound = TherapyAppError.clientNotFound(clientId: "123")
        XCTAssertEqual(clientNotFound.failureReason, "Client with ID '123' not found in database")
        
        let goalNotFound = TherapyAppError.goalTemplateNotFound(templateId: "456")
        XCTAssertEqual(goalNotFound.failureReason, "Goal template with ID '456' not found in database")
        
        let sessionNotFound = TherapyAppError.sessionNotFound(sessionId: "789")
        XCTAssertEqual(sessionNotFound.failureReason, "Session with ID '789' not found in database")
        
        // Unknown errors should include underlying error
        let unknownError = TherapyAppError.unknown(underlyingError)
        XCTAssertEqual(unknownError.failureReason, "Underlying error: Test error")
        
        // Some errors should have no failure reason (user-facing only)
        let cancelledError = TherapyAppError.cancelled
        XCTAssertNil(cancelledError.failureReason)
        
        let sessionActiveError = TherapyAppError.sessionAlreadyActive
        XCTAssertNil(sessionActiveError.failureReason)
    }
    
    // MARK: - Error UI Components Tests
    
    /// Tests ErrorAlertModifier behavior and accessibility
    func testErrorAlertModifier() {
        let error = TherapyAppError.networkUnavailable
        var dismissCalled = false
        var retryCalled = false
        
        let modifier = ErrorAlertModifier(
            error: error,
            onDismiss: { dismissCalled = true },
            onRetry: { retryCalled = true }
        )
        
        // Test that modifier has proper error reference
        XCTAssertNotNil(modifier.error)
        XCTAssertEqual(modifier.error?.category, "Network")
        XCTAssertTrue(modifier.error?.isRetryable == true)
        
        // Test dismiss action
        modifier.onDismiss()
        XCTAssertTrue(dismissCalled)
        
        // Test retry action
        modifier.onRetry?()
        XCTAssertTrue(retryCalled)
    }
    
    /// Tests ErrorAlertModifier with non-retryable errors
    func testErrorAlertModifierNonRetryable() {
        let error = TherapyAppError.clientNameRequired
        var dismissCalled = false
        
        let modifier = ErrorAlertModifier(
            error: error,
            onDismiss: { dismissCalled = true },
            onRetry: nil
        )
        
        // Non-retryable error should not have retry action
        XCTAssertFalse(error.isRetryable)
        XCTAssertNil(modifier.onRetry)
        
        // Should still be dismissible
        modifier.onDismiss()
        XCTAssertTrue(dismissCalled)
    }
    
    /// Tests View extensions for error alerts
    func testViewErrorAlertExtensions() {
        let error = TherapyAppError.saveFailure(NSError(domain: "Test", code: 0, userInfo: [:]))
        var dismissCalled = false
        var retryCalled = false
        
        let view = Text("Test View")
            .errorAlert(error: error, onDismiss: {
                dismissCalled = true
            }, onRetry: {
                retryCalled = true
            })
        
        // View should be enhanced with error alert capability
        XCTAssertNotNil(view)
        
        // Test legacy string-based error alert
        let legacyView = Text("Legacy View")
            .errorAlert(errorMessage: "Test error", onDismiss: {
                dismissCalled = true
            })
        
        XCTAssertNotNil(legacyView)
    }
    
    // MARK: - Repository Error Handling Tests
    
    /// Tests SimpleCoreDataRepository propagates TherapyAppError correctly
    func testRepositoryErrorPropagation() async throws {
        // Create test repository with in-memory store
        let testContainer = NSPersistentContainer(name: "TherapyDataModel")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        testContainer.persistentStoreDescriptions = [description]
        
        testContainer.loadPersistentStores { _, error in
            XCTAssertNil(error, "Failed to load test store")
        }
        
        let testStack = CoreDataStack.shared
        testStack.persistentContainer = testContainer
        let repository = SimpleCoreDataRepository(coreDataStack: testStack)
        
        // Test client name validation
        let invalidClient = Client(name: "", dateOfBirth: nil, notes: nil)
        
        do {
            try await repository.createClient(invalidClient)
            XCTFail("Should have thrown clientNameRequired error")
        } catch let error as TherapyAppError {
            XCTAssertEqual(error, TherapyAppError.clientNameRequired)
            XCTAssertFalse(error.isRetryable)
            XCTAssertEqual(error.category, "Validation")
        } catch {
            XCTFail("Should have thrown TherapyAppError, got \(error)")
        }
        
        // Test goal template title validation
        let testClient = Client(name: "Test Client")
        try await repository.createClient(testClient)
        
        let invalidTemplate = GoalTemplate(
            title: "",
            description: nil,
            category: "Test",
            defaultCueLevel: .independent,
            clientId: testClient.id
        )
        
        do {
            try await repository.createGoalTemplate(invalidTemplate)
            XCTFail("Should have thrown goalTitleRequired error")
        } catch let error as TherapyAppError {
            XCTAssertEqual(error, TherapyAppError.goalTitleRequired)
            XCTAssertFalse(error.isRetryable)
            XCTAssertEqual(error.category, "Validation")
        } catch {
            XCTFail("Should have thrown TherapyAppError, got \(error)")
        }
    }
    
    /// Tests repository not found error scenarios
    func testRepositoryNotFoundErrors() async throws {
        let testContainer = NSPersistentContainer(name: "TherapyDataModel")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        testContainer.persistentStoreDescriptions = [description]
        
        testContainer.loadPersistentStores { _, error in
            XCTAssertNil(error, "Failed to load test store")
        }
        
        let testStack = CoreDataStack.shared
        testStack.persistentContainer = testContainer
        let repository = SimpleCoreDataRepository(coreDataStack: testStack)
        
        let nonExistentClientId = UUID()
        let nonExistentTemplateId = UUID()
        let nonExistentSessionId = UUID()
        
        // Test update non-existent client
        let client = Client(id: nonExistentClientId, name: "Test Client")
        
        do {
            try await repository.updateClient(client)
            XCTFail("Should have thrown clientNotFound error")
        } catch let error as TherapyAppError {
            if case .clientNotFound(let clientId) = error {
                XCTAssertEqual(clientId, nonExistentClientId.uuidString)
            } else {
                XCTFail("Expected clientNotFound error, got \(error)")
            }
        } catch {
            XCTFail("Should have thrown TherapyAppError, got \(error)")
        }
        
        // Test delete non-existent client
        do {
            try await repository.deleteClient(nonExistentClientId)
            XCTFail("Should have thrown clientNotFound error")
        } catch let error as TherapyAppError {
            if case .clientNotFound(let clientId) = error {
                XCTAssertEqual(clientId, nonExistentClientId.uuidString)
            } else {
                XCTFail("Expected clientNotFound error, got \(error)")
            }
        } catch {
            XCTFail("Should have thrown TherapyAppError, got \(error)")
        }
        
        // Test update non-existent goal template
        let template = GoalTemplate(
            id: nonExistentTemplateId,
            title: "Test Template",
            category: "Test",
            defaultCueLevel: .independent,
            clientId: UUID()
        )
        
        do {
            try await repository.updateGoalTemplate(template)
            XCTFail("Should have thrown goalTemplateNotFound error")
        } catch let error as TherapyAppError {
            if case .goalTemplateNotFound(let templateId) = error {
                XCTAssertEqual(templateId, nonExistentTemplateId.uuidString)
            } else {
                XCTFail("Expected goalTemplateNotFound error, got \(error)")
            }
        } catch {
            XCTFail("Should have thrown TherapyAppError, got \(error)")
        }
        
        // Test end non-existent session
        do {
            try await repository.endSession(nonExistentSessionId)
            XCTFail("Should have thrown sessionNotFound error")
        } catch let error as TherapyAppError {
            if case .sessionNotFound(let sessionId) = error {
                XCTAssertEqual(sessionId, nonExistentSessionId.uuidString)
            } else {
                XCTFail("Expected sessionNotFound error, got \(error)")
            }
        } catch {
            XCTFail("Should have thrown TherapyAppError, got \(error)")
        }
    }
    
    /// Tests repository business logic validation
    func testRepositoryBusinessLogicValidation() async throws {
        let testContainer = NSPersistentContainer(name: "TherapyDataModel")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        testContainer.persistentStoreDescriptions = [description]
        
        testContainer.loadPersistentStores { _, error in
            XCTAssertNil(error, "Failed to load test store")
        }
        
        let testStack = CoreDataStack.shared
        testStack.persistentContainer = testContainer
        let repository = SimpleCoreDataRepository(coreDataStack: testStack)
        
        // Create test client and session
        let testClient = Client(name: "Test Client")
        try await repository.createClient(testClient)
        
        let session1 = try await repository.startSession(for: testClient.id, location: nil, createdOn: "iPhone")
        
        // Test session already active error
        do {
            let _ = try await repository.startSession(for: testClient.id, location: nil, createdOn: "iPhone")
            XCTFail("Should have thrown sessionAlreadyActive error")
        } catch let error as TherapyAppError {
            XCTAssertEqual(error, TherapyAppError.sessionAlreadyActive)
            XCTAssertFalse(error.isRetryable)
            XCTAssertTrue(error.isCritical)
        } catch {
            XCTFail("Should have thrown TherapyAppError, got \(error)")
        }
        
        // Test ending already ended session
        try await repository.endSession(session1.id)
        
        do {
            try await repository.endSession(session1.id)
            XCTFail("Should have thrown validation error for already ended session")
        } catch let error as TherapyAppError {
            if case .validationError(let field, let reason) = error {
                XCTAssertEqual(field, "Session")
                XCTAssertTrue(reason.contains("already been ended"))
            } else {
                XCTFail("Expected validation error for ended session, got \(error)")
            }
        } catch {
            XCTFail("Should have thrown TherapyAppError, got \(error)")
        }
        
        // Test goal log validation
        let invalidGoalLog = GoalLog(
            goalDescription: "",  // Empty description should fail
            cueLevel: .independent,
            wasSuccessful: true,
            sessionId: session1.id
        )
        
        do {
            try await repository.logGoal(invalidGoalLog)
            XCTFail("Should have thrown validation error for empty goal description")
        } catch let error as TherapyAppError {
            if case .validationError(let field, let reason) = error {
                XCTAssertEqual(field, "Goal Description")
                XCTAssertEqual(reason, "Goal description cannot be empty")
            } else {
                XCTFail("Expected validation error for empty goal description, got \(error)")
            }
        } catch {
            XCTFail("Should have thrown TherapyAppError, got \(error)")
        }
    }
    
    // MARK: - ViewModel Error Integration Tests
    
    /// Tests ClientListViewModel TherapyAppError integration
    @MainActor
    func testClientListViewModelErrorIntegration() async {
        // Configure mock to throw TherapyAppError
        mockRepository.therapyErrorToThrow = .networkUnavailable
        
        let viewModel = ClientListViewModel(repository: mockRepository)
        
        // Test load clients error
        await viewModel.loadClients()
        
        // Verify TherapyAppError is properly handled
        XCTAssertNotNil(viewModel.error)
        XCTAssertEqual(viewModel.error, .networkUnavailable)
        XCTAssertTrue(viewModel.canRetry)
        XCTAssertNotNil(viewModel.errorMessage) // Legacy compatibility
        XCTAssertEqual(viewModel.errorMessage, "Network connection unavailable. Please check your internet connection.")
        
        // Test retry functionality
        mockRepository.therapyErrorToThrow = nil
        mockRepository.mockClients = [Client(name: "Test Client")]
        
        await viewModel.retryLastOperation()
        
        // Verify retry worked
        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.canRetry)
        XCTAssertEqual(viewModel.clients.count, 1)
        
        // Test clear error
        viewModel.error = .saveFailure(NSError(domain: "Test", code: 0, userInfo: [:]))
        viewModel.clearError()
        
        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.canRetry)
    }
    
    /// Tests GoalTemplateListViewModel TherapyAppError integration
    @MainActor
    func testGoalTemplateListViewModelErrorIntegration() async {
        let clientId = UUID()
        
        // Configure mock to throw specific TherapyAppError
        mockRepository.therapyErrorToThrow = .fetchFailure(NSError(domain: "Test", code: 0, userInfo: [:]))
        
        let viewModel = GoalTemplateListViewModel(clientId: clientId, repository: mockRepository)
        
        // Test load goal templates error
        await viewModel.loadGoalTemplates()
        
        // Verify TherapyAppError is properly handled
        XCTAssertNotNil(viewModel.error)
        if case .fetchFailure = viewModel.error {
            // Expected
        } else {
            XCTFail("Expected fetchFailure error")
        }
        XCTAssertTrue(viewModel.canRetry)
        XCTAssertEqual(viewModel.errorMessage, "Unable to load data. Please check your connection and try again.")
        
        // Test delete with business logic error
        mockRepository.therapyErrorToThrow = .goalTemplateHasLogs
        
        let testTemplate = GoalTemplate(
            title: "Test Template",
            category: "Test",
            defaultCueLevel: .independent,
            clientId: clientId
        )
        
        await viewModel.deleteGoalTemplate(testTemplate)
        
        // Verify critical business logic error
        XCTAssertNotNil(viewModel.error)
        XCTAssertEqual(viewModel.error, .goalTemplateHasLogs)
        XCTAssertTrue(viewModel.error?.isCritical == true)
        XCTAssertFalse(viewModel.error?.isRetryable == true)
        XCTAssertEqual(viewModel.errorMessage, "Cannot delete goal template with existing data. Deactivate the template instead.")
    }
    
    /// Tests ViewModel retry functionality with different error types
    @MainActor
    func testViewModelRetryFunctionality() async {
        // Test retryable error
        mockRepository.therapyErrorToThrow = .operationTimeout
        
        let viewModel = ClientListViewModel(repository: mockRepository)
        await viewModel.loadClients()
        
        XCTAssertTrue(viewModel.canRetry)
        XCTAssertEqual(viewModel.error, .operationTimeout)
        
        // Simulate successful retry
        mockRepository.therapyErrorToThrow = nil
        mockRepository.mockClients = [Client(name: "Retry Success")]
        
        await viewModel.retryLastOperation()
        
        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.canRetry)
        XCTAssertEqual(viewModel.clients.count, 1)
        
        // Test non-retryable error
        mockRepository.therapyErrorToThrow = .clientNameRequired
        
        let invalidClient = Client(name: "")
        await viewModel.deleteClient(invalidClient) // This would trigger validation
        
        if let error = viewModel.error {
            XCTAssertFalse(error.isRetryable)
            XCTAssertFalse(viewModel.canRetry)
        }
    }
    
    /// Tests backward compatibility with legacy error handling
    @MainActor
    func testBackwardCompatibilityWithLegacyErrorHandling() async {
        // Test that errorMessage property still works
        let viewModel = ClientListViewModel(repository: mockRepository)
        
        // Set a TherapyAppError
        viewModel.error = .networkUnavailable
        
        // Verify legacy property returns correct message
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, "Network connection unavailable. Please check your internet connection.")
        
        // Test with nil error
        viewModel.error = nil
        XCTAssertNil(viewModel.errorMessage)
        
        // Test View extension with string-based errors
        let stringError = "Legacy error message"
        let view = Text("Test")
            .errorAlert(errorMessage: stringError) { /* dismiss */ }
        
        XCTAssertNotNil(view)
    }
    
    // MARK: - Error Recovery Scenarios
    
    /// Tests error recovery workflows for common scenarios
    @MainActor
    func testErrorRecoveryWorkflows() async {
        let viewModel = ClientListViewModel(repository: mockRepository)
        
        // Scenario 1: Network error -> Retry -> Success
        mockRepository.therapyErrorToThrow = .networkUnavailable
        
        await viewModel.loadClients()
        XCTAssertEqual(viewModel.error, .networkUnavailable)
        XCTAssertTrue(viewModel.canRetry)
        
        // User fixes network and retries
        mockRepository.therapyErrorToThrow = nil
        mockRepository.mockClients = [Client(name: "Network Fixed")]
        
        await viewModel.retryLastOperation()
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.clients.count, 1)
        
        // Scenario 2: Validation error -> User fixes -> Success
        mockRepository.therapyErrorToThrow = .clientNameRequired
        
        let invalidClient = Client(name: "")
        // This would normally be caught at the UI level, but test repository error handling
        await viewModel.deleteClient(invalidClient)
        
        XCTAssertNotNil(viewModel.error)
        XCTAssertFalse(viewModel.canRetry) // Validation errors are not retryable
        
        // User must fix the validation issue, not retry the same operation
        viewModel.clearError()
        XCTAssertNil(viewModel.error)
        
        // Scenario 3: Critical error -> User must take specific action
        mockRepository.therapyErrorToThrow = .persistentStoreError(NSError(domain: "CoreData", code: 0, userInfo: [:]))
        
        await viewModel.loadClients()
        XCTAssertNotNil(viewModel.error)
        XCTAssertTrue(viewModel.error?.isCritical == true)
        XCTAssertTrue(viewModel.error?.isRetryable == true) // Critical errors may be retryable after user action
        
        // User restarts app, then retry works
        mockRepository.therapyErrorToThrow = nil
        await viewModel.retryLastOperation()
        XCTAssertNil(viewModel.error)
    }
    
    /// Tests HIPAA compliance in error messages (no PHI exposure)
    func testHIPAACompliantErrorMessages() {
        // Error messages should not contain client names, dates, or other PHI
        let clientId = UUID()
        let templateId = UUID()
        let sessionId = UUID()
        
        let clientNotFoundError = TherapyAppError.clientNotFound(clientId: clientId.uuidString)
        let goalNotFoundError = TherapyAppError.goalTemplateNotFound(templateId: templateId.uuidString)
        let sessionNotFoundError = TherapyAppError.sessionNotFound(sessionId: sessionId.uuidString)
        
        // User-facing messages should not contain UUIDs or other identifiers
        XCTAssertFalse(clientNotFoundError.errorDescription?.contains(clientId.uuidString) == true)
        XCTAssertFalse(goalNotFoundError.errorDescription?.contains(templateId.uuidString) == true)
        XCTAssertFalse(sessionNotFoundError.errorDescription?.contains(sessionId.uuidString) == true)
        
        // But failure reasons (for debugging) can contain technical details
        XCTAssertTrue(clientNotFoundError.failureReason?.contains(clientId.uuidString) == true)
        XCTAssertTrue(goalNotFoundError.failureReason?.contains(templateId.uuidString) == true)
        XCTAssertTrue(sessionNotFoundError.failureReason?.contains(sessionId.uuidString) == true)
        
        // Validation errors should be generic
        let validationError = TherapyAppError.validationError(field: "Client Name", reason: "cannot be empty")
        XCTAssertEqual(validationError.errorDescription, "Client Name: cannot be empty")
        
        // Business logic errors should not expose sensitive operations details
        let clientHasSessionsError = TherapyAppError.clientHasSessions
        XCTAssertFalse(clientHasSessionsError.errorDescription?.contains("database") == true)
        XCTAssertFalse(clientHasSessionsError.errorDescription?.contains("foreign key") == true)
        
        // Network errors should not expose internal URLs or endpoints
        let networkError = TherapyAppError.networkUnavailable
        XCTAssertFalse(networkError.errorDescription?.contains("http") == true)
        XCTAssertFalse(networkError.errorDescription?.contains("endpoint") == true)
    }
}

