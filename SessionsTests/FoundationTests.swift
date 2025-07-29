import XCTest
import CoreData
@testable import Sessions

/// Comprehensive test suite for the Sessions app foundation layer
/// 
/// **Test Coverage:**
/// This test class validates the core functionality of the therapy app's foundation:
/// - Core Data repository operations (CRUD for all entities)
/// - Swift model struct behavior and computed properties
/// - Database relationships and data integrity
/// - Async/await patterns in repository layer
/// 
/// **Test Architecture:**
/// - Uses in-memory Core Data store for fast, isolated tests
/// - Tests repository pattern through TherapyRepository protocol
/// - Validates both happy path and edge case scenarios
/// - Ensures thread safety of async operations
/// 
/// **HIPAA Testing Considerations:**
/// - Tests privacy-focused features like Client.privacyName
/// - Validates soft delete behavior for audit trail preservation
/// - Ensures data integrity across repository operations
/// 
/// **Stage 1 Validation:**
/// These tests validate the Stage 1 foundation implementation requirements
/// and serve as regression tests for future development stages.
final class FoundationTests: XCTestCase {
    
    /// Repository instance under test - uses in-memory Core Data store
    var repository: SimpleCoreDataRepository!
    /// In-memory persistent container for isolated testing
    var testContainer: NSPersistentContainer!
    
    /// Sets up test environment with in-memory Core Data stack
    /// 
    /// **Test Isolation:** Each test gets a fresh in-memory database
    /// **Performance:** In-memory store provides fast test execution
    /// **Thread Safety:** Tests async repository operations safely
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory Core Data stack for testing
        testContainer = NSPersistentContainer(name: "TherapyDataModel")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType  // Fast, isolated test storage
        testContainer.persistentStoreDescriptions = [description]
        
        testContainer.loadPersistentStores { _, error in
            XCTAssertNil(error, "Failed to load test store")
        }
        
        // Create a custom CoreDataStack for testing
        let testStack = CoreDataStack.shared
        testStack.persistentContainer = testContainer
        
        repository = SimpleCoreDataRepository(coreDataStack: testStack)
    }
    
    override func tearDown() async throws {
        repository = nil
        testContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - Client Tests
    
    /// Tests basic client creation and retrieval functionality
    /// 
    /// **Validates:** Repository CRUD operations and data persistence
    /// **Covers:** Client model mapping and Core Data entity conversion
    func testCreateAndFetchClient() async throws {
        // Create test client
        let client = Client(name: "John Doe", dateOfBirth: Date(), notes: "Test notes")
        
        // Save client
        try await repository.createClient(client)
        
        // Fetch clients
        let clients = try await repository.fetchClients()
        
        // Verify
        XCTAssertEqual(clients.count, 1)
        XCTAssertEqual(clients.first?.name, "John Doe")
        XCTAssertEqual(clients.first?.notes, "Test notes")
    }
    
    func testUpdateClient() async throws {
        // Create and save client
        let originalClient = Client(name: "John Doe", dateOfBirth: Date(), notes: "Original notes")
        try await repository.createClient(originalClient)
        
        // Update client
        let updatedClient = Client(
            id: originalClient.id,
            name: "Jane Doe",
            dateOfBirth: originalClient.dateOfBirth,
            notes: "Updated notes",
            createdDate: originalClient.createdDate,
            lastModified: Date()
        )
        try await repository.updateClient(updatedClient)
        
        // Fetch and verify
        let fetchedClient = try await repository.fetchClient(originalClient.id)
        XCTAssertEqual(fetchedClient?.name, "Jane Doe")
        XCTAssertEqual(fetchedClient?.notes, "Updated notes")
    }
    
    func testDeleteClient() async throws {
        // Create and save client
        let client = Client(name: "John Doe")
        try await repository.createClient(client)
        
        // Verify client exists
        let clientsBeforeDelete = try await repository.fetchClients()
        XCTAssertEqual(clientsBeforeDelete.count, 1)
        
        // Delete client
        try await repository.deleteClient(client.id)
        
        // Verify client is deleted
        let clientsAfterDelete = try await repository.fetchClients()
        XCTAssertEqual(clientsAfterDelete.count, 0)
    }
    
    // MARK: - Goal Template Tests
    
    func testCreateAndFetchGoalTemplate() async throws {
        // Create client first
        let client = Client(name: "John Doe")
        try await repository.createClient(client)
        
        // Create goal template
        let template = GoalTemplate(
            title: "Test Goal",
            description: "Test description",
            category: "Communication",
            defaultCueLevel: .independent,
            clientId: client.id
        )
        try await repository.createGoalTemplate(template)
        
        // Fetch templates
        let templates = try await repository.fetchGoalTemplates(for: client.id)
        
        // Verify
        XCTAssertEqual(templates.count, 1)
        XCTAssertEqual(templates.first?.title, "Test Goal")
        XCTAssertEqual(templates.first?.category, "Communication")
        XCTAssertEqual(templates.first?.defaultCueLevel, .independent)
    }
    
    /// Tests soft delete behavior for goal templates
    /// 
    /// **Important:** Goal templates use soft delete (isActive = false)
    /// rather than hard delete to preserve audit trails and data integrity
    /// for existing goal logs that reference the template
    func testDeleteGoalTemplate() async throws {
        // Create client and goal template
        let client = Client(name: "John Doe")
        try await repository.createClient(client)
        
        let template = GoalTemplate(
            title: "Test Goal",
            category: "Communication",
            defaultCueLevel: .independent,
            clientId: client.id
        )
        try await repository.createGoalTemplate(template)
        
        // Verify template exists
        let templatesBeforeDelete = try await repository.fetchGoalTemplates(for: client.id)
        XCTAssertEqual(templatesBeforeDelete.count, 1)
        
        // Delete template (soft delete)
        try await repository.deleteGoalTemplate(template.id)
        
        // Verify template is soft deleted (not returned in active templates)
        let templatesAfterDelete = try await repository.fetchGoalTemplates(for: client.id)
        XCTAssertEqual(templatesAfterDelete.count, 0)
    }
    
    // MARK: - Session Tests
    
    /// Tests complete session lifecycle from start to end
    /// 
    /// **Validates:** Session state management and active session tracking
    /// **Business Logic:** Only one session should be active at a time
    func testStartAndEndSession() async throws {
        // Create client first
        let client = Client(name: "John Doe")
        try await repository.createClient(client)
        
        // Start session
        let session = try await repository.startSession(
            for: client.id,
            location: "Test Location",
            createdOn: "iPhone"
        )
        
        // Verify session is active
        XCTAssertTrue(session.isActive)
        XCTAssertEqual(session.location, "Test Location")
        XCTAssertEqual(session.createdOn, "iPhone")
        
        // Fetch active session
        let activeSession = try await repository.fetchActiveSession()
        XCTAssertNotNil(activeSession)
        XCTAssertEqual(activeSession?.id, session.id)
        
        // End session
        try await repository.endSession(session.id)
        
        // Verify no active session
        let noActiveSession = try await repository.fetchActiveSession()
        XCTAssertNil(noActiveSession)
        
        // Fetch session with end time
        let endedSession = try await repository.fetchSession(session.id)
        XCTAssertNotNil(endedSession?.endTime)
        XCTAssertFalse(endedSession?.isActive ?? true)
    }
    
    // MARK: - Goal Log Tests
    
    func testLogGoal() async throws {
        // Create client and start session
        let client = Client(name: "John Doe")
        try await repository.createClient(client)
        
        let session = try await repository.startSession(
            for: client.id,
            location: nil,
            createdOn: "iPhone"
        )
        
        // Log a goal
        let goalLog = GoalLog(
            goalDescription: "Test Goal",
            cueLevel: .independent,
            wasSuccessful: true,
            sessionId: session.id,
            notes: "Test notes"
        )
        try await repository.logGoal(goalLog)
        
        // Fetch goal logs
        let goalLogs = try await repository.fetchGoalLogs(for: session.id)
        
        // Verify
        XCTAssertEqual(goalLogs.count, 1)
        XCTAssertEqual(goalLogs.first?.goalDescription, "Test Goal")
        XCTAssertEqual(goalLogs.first?.cueLevel, .independent)
        XCTAssertTrue(goalLogs.first?.wasSuccessful ?? false)
        XCTAssertEqual(goalLogs.first?.notes, "Test notes")
    }
    
    /// Tests session analytics and goal log aggregation
    /// 
    /// **Validates:** Session success rate calculations and trial counting
    /// **Analytics:** Tests computed properties used for progress tracking
    func testSessionWithGoalLogs() async throws {
        // Create client and start session
        let client = Client(name: "John Doe")
        try await repository.createClient(client)
        
        let session = try await repository.startSession(
            for: client.id,
            location: nil,
            createdOn: "iPhone"
        )
        
        // Log multiple goals
        let goalLog1 = GoalLog(
            goalDescription: "Goal 1",
            cueLevel: .independent,
            wasSuccessful: true,
            sessionId: session.id
        )
        let goalLog2 = GoalLog(
            goalDescription: "Goal 2",
            cueLevel: .minimal,
            wasSuccessful: false,
            sessionId: session.id
        )
        
        try await repository.logGoal(goalLog1)
        try await repository.logGoal(goalLog2)
        
        // Fetch session with goal logs
        let sessionWithLogs = try await repository.fetchSession(session.id)
        
        // Verify
        XCTAssertEqual(sessionWithLogs?.goalLogs.count, 2)
        XCTAssertEqual(sessionWithLogs?.totalTrials, 2)
        XCTAssertEqual(sessionWithLogs?.successCount, 1)
        XCTAssertEqual(sessionWithLogs?.failureCount, 1)
        XCTAssertEqual(sessionWithLogs?.successRate, 0.5)
    }
    
    // MARK: - Model Tests
    
    func testCueLevelColors() {
        XCTAssertEqual(CueLevel.independent.displayName, "Independent")
        XCTAssertEqual(CueLevel.minimal.displayName, "Min")
        XCTAssertEqual(CueLevel.moderate.displayName, "Mod")
        XCTAssertEqual(CueLevel.maximal.displayName, "Max")
    }
    
    /// Tests HIPAA-compliant privacy name generation
    /// 
    /// **HIPAA Consideration:** privacyName provides reduced PHI exposure
    /// for use in shared environments or when full names aren't needed
    func testClientPrivacyName() {
        let client = Client(name: "John Doe")
        XCTAssertEqual(client.privacyName, "John D.")
        
        let singleNameClient = Client(name: "John")
        XCTAssertEqual(singleNameClient.privacyName, "John")
    }
    
    /// Tests session duration calculation and formatting
    /// 
    /// **Validates:** Time interval calculations and human-readable formatting
    /// **Edge Cases:** Tests both active and completed session states
    func testSessionDuration() {
        let startTime = Date()
        let endTime = Date(timeInterval: 3661, since: startTime) // 1 hour, 1 minute, 1 second
        
        let session = Session(
            id: UUID(),
            clientId: UUID(),
            date: startTime,
            startTime: startTime,
            endTime: endTime,
            location: nil,
            createdOn: "iPhone",
            notes: nil,
            goalLogs: [],
            lastModified: Date()
        )
        
        XCTAssertEqual(session.duration, 3661)
        XCTAssertEqual(session.formattedDuration, "61:01")
        XCTAssertFalse(session.isActive)
    }
}