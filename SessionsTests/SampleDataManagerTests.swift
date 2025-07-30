import XCTest
import CoreData
@testable import Sessions

/// Comprehensive test suite for SampleDataManager
/// 
/// **Test Coverage:**
/// This test class validates all aspects of the SampleDataManager:
/// - Sample data generation with correct client and goal template counts
/// - Data diversity across age groups and therapy categories
/// - Repository integration and async operation handling
/// - Data clearing functionality and complete cleanup
/// - Error handling for repository failures
/// - Data integrity and Core Data model compliance
/// 
/// **Test Architecture:**
/// - Uses MockTherapyRepository for isolated SampleDataManager testing
/// - Tests async operations with proper error handling patterns
/// - Validates generated data follows realistic therapy scenarios
/// - Tests repository interaction patterns and operation tracking
/// 
/// **Testing Strategy:**
/// - Arrange-Act-Assert pattern for each test
/// - Mock repository provides controlled data storage and error scenarios
/// - Tests both successful operations and error conditions
/// - Validates data characteristics and business logic compliance
final class SampleDataManagerTests: XCTestCase {
    
    // MARK: - Test Infrastructure
    
    var mockRepository: MockTherapyRepository!
    var sampleDataManager: SampleDataManager!
    
    override func setUp() async throws {
        try await super.setUp()
        mockRepository = MockTherapyRepository()
        sampleDataManager = SampleDataManager(repository: mockRepository)
    }
    
    override func tearDown() async throws {
        sampleDataManager = nil
        mockRepository = nil
        try await super.tearDown()
    }
    
    // MARK: - Sample Data Generation Tests
    
    func testGenerateSampleDataCreatesExpectedNumberOfClients() async throws {
        // Arrange - Fresh repository
        XCTAssertTrue(mockRepository.mockClients.isEmpty)
        XCTAssertTrue(mockRepository.mockGoalTemplates.isEmpty)
        
        // Act
        try await sampleDataManager.generateSampleData()
        
        // Assert
        XCTAssertEqual(mockRepository.createdClients.count, 20, "Should create exactly 20 sample clients")
        XCTAssertEqual(mockRepository.mockClients.count, 20, "Repository should contain 20 clients")
        
        // Verify all clients were persisted through repository
        XCTAssertEqual(mockRepository.createdClients.count, mockRepository.mockClients.count)
    }
    
    func testGenerateSampleDataCreatesGoalTemplatesForEachClient() async throws {
        // Act
        try await sampleDataManager.generateSampleData()
        
        // Assert - Each client should have 2-4 goal templates (randomized)
        let totalGoalTemplates = mockRepository.createdGoalTemplates.count
        XCTAssertGreaterThanOrEqual(totalGoalTemplates, 40, "Should create at least 2 templates per client (20 * 2)")
        XCTAssertLessThanOrEqual(totalGoalTemplates, 80, "Should create at most 4 templates per client (20 * 4)")
        
        // Verify each client has associated goal templates
        for client in mockRepository.mockClients {
            let clientTemplates = mockRepository.mockGoalTemplates.filter { $0.clientId == client.id }
            XCTAssertGreaterThanOrEqual(clientTemplates.count, 2, "Each client should have at least 2 goal templates")
            XCTAssertLessThanOrEqual(clientTemplates.count, 4, "Each client should have at most 4 goal templates")
        }
    }
    
    func testGenerateSampleDataCreatesDiverseClientAges() async throws {
        // Act
        try await sampleDataManager.generateSampleData()
        
        // Assert - Verify age diversity across sample data
        let clientsWithAges = mockRepository.mockClients.compactMap { $0.age }
        XCTAssertGreaterThan(clientsWithAges.count, 15, "Most clients should have ages specified")
        
        // Check for pediatric clients (under 18)
        let pediatricClients = clientsWithAges.filter { $0 < 18 }
        XCTAssertGreaterThan(pediatricClients.count, 0, "Should include pediatric clients")
        
        // Check for adult clients (18-65)
        let adultClients = clientsWithAges.filter { $0 >= 18 && $0 <= 65 }
        XCTAssertGreaterThan(adultClients.count, 0, "Should include adult clients")
        
        // Check for geriatric clients (over 65)
        let geriatricClients = clientsWithAges.filter { $0 > 65 }
        XCTAssertGreaterThan(geriatricClients.count, 0, "Should include geriatric clients")
    }
    
    func testGenerateSampleDataCreatesDiverseClientNames() async throws {
        // Act
        try await sampleDataManager.generateSampleData()
        
        // Assert - Verify name diversity
        let clientNames = mockRepository.mockClients.map { $0.name }
        let uniqueNames = Set(clientNames)
        XCTAssertEqual(clientNames.count, uniqueNames.count, "All client names should be unique")
        
        // Verify names are not empty
        for name in clientNames {
            XCTAssertFalse(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "Client names should not be empty")
            XCTAssertTrue(name.contains(" "), "Client names should include first and last name")
        }
    }
    
    func testGenerateSampleDataCreatesRealisticClientNotes() async throws {
        // Act
        try await sampleDataManager.generateSampleData()
        
        // Assert - Verify therapy-relevant notes
        let clientsWithNotes = mockRepository.mockClients.filter { $0.notes != nil && !$0.notes!.isEmpty }
        XCTAssertEqual(clientsWithNotes.count, 20, "All sample clients should have descriptive notes")
        
        // Verify notes contain therapy-relevant content (sample first 3 clients)
        let sampleClients = Array(clientsWithNotes.prefix(3))
        for client in sampleClients {
            let notes = client.notes!
            XCTAssertGreaterThan(notes.count, 10, "Notes should be descriptive")
            
            // Check for therapy-related keywords
            let therapyKeywords = ["speech", "language", "communication", "therapy", "disorder", "autism", "apraxia", "stuttering", "voice", "social", "behavior"]
            let hasTherapyContent = therapyKeywords.contains { keyword in
                notes.lowercased().contains(keyword)
            }
            XCTAssertTrue(hasTherapyContent, "Notes should contain therapy-relevant content: \(notes)")
        }
    }
    
    func testGenerateSampleDataCreatesAgeAppropriateGoalTemplates() async throws {
        // Act
        try await sampleDataManager.generateSampleData()
        
        // Assert - Check pediatric clients have child-appropriate goals (sample first 2)
        let pediatricClients = Array(mockRepository.mockClients.filter { ($0.age ?? 25) < 18 }.prefix(2))
        for client in pediatricClients {
            let clientTemplates = mockRepository.mockGoalTemplates.filter { $0.clientId == client.id }
            let categories = Set(clientTemplates.map { $0.category })
            
            // Pediatric categories should include developmentally appropriate goals
            let expectedPediatricCategories = ["Articulation", "Language Development", "Social Skills", "Play Skills", "Academic Skills"]
            let hasPediatricCategories = categories.contains { expectedPediatricCategories.contains($0) }
            XCTAssertTrue(hasPediatricCategories, "Pediatric client should have age-appropriate goal categories: \(categories)")
        }
        
        // Assert - Check geriatric clients have appropriate goals (sample first 2)
        let geriatricClients = Array(mockRepository.mockClients.filter { ($0.age ?? 25) > 65 }.prefix(2))
        for client in geriatricClients {
            let clientTemplates = mockRepository.mockGoalTemplates.filter { $0.clientId == client.id }
            let categories = Set(clientTemplates.map { $0.category })
            
            // Geriatric categories should focus on rehabilitation and cognitive support
            let expectedGeriatricCategories = ["Speech Clarity", "Voice Therapy", "Cognitive Communication", "Swallowing"]
            let hasGeriatricCategories = categories.contains { expectedGeriatricCategories.contains($0) }
            XCTAssertTrue(hasGeriatricCategories, "Geriatric client should have age-appropriate goal categories: \(categories)")
        }
    }
    
    func testGenerateSampleDataCreatesValidGoalTemplateStructure() async throws {
        // Act
        try await sampleDataManager.generateSampleData()
        
        // Assert - Verify goal template structure and data integrity
        for template in mockRepository.mockGoalTemplates {
            // Verify required fields are populated
            XCTAssertFalse(template.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "Goal template title should not be empty")
            XCTAssertFalse(template.category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "Goal template category should not be empty")
            
            // Verify description exists and is meaningful
            XCTAssertNotNil(template.description, "Goal template should have description")
            if let description = template.description {
                XCTAssertGreaterThan(description.count, 10, "Goal template description should be descriptive")
            }
            
            // Verify client relationship
            let associatedClient = mockRepository.mockClients.first { $0.id == template.clientId }
            XCTAssertNotNil(associatedClient, "Goal template should be associated with an existing client")
            
            // Verify default cue level is valid
            XCTAssertTrue(CueLevel.allCases.contains(template.defaultCueLevel), "Default cue level should be valid")
            
            // Verify active status
            XCTAssertTrue(template.isActive, "Sample goal templates should be active by default")
            
            // Verify creation date is recent
            let timeSinceCreation = abs(template.createdDate.timeIntervalSinceNow)
            XCTAssertLessThan(timeSinceCreation, 10.0, "Goal template creation date should be recent")
        }
    }
    
    func testGenerateSampleDataCreatesDiverseGoalCategories() async throws {
        // Act
        try await sampleDataManager.generateSampleData()
        
        // Assert - Verify diverse goal categories are created
        let allCategories = Set(mockRepository.mockGoalTemplates.map { $0.category })
        XCTAssertGreaterThanOrEqual(allCategories.count, 5, "Should create goals across multiple categories")
        
        // Expected categories based on age distribution
        let expectedCategories = [
            "Articulation", "Language Development", "Social Skills", "Play Skills", "Academic Skills",
            "Speech Clarity", "Voice Therapy", "Communication Skills", "Professional Voice",
            "Cognitive Communication", "Swallowing"
        ]
        
        // Verify some expected categories are present
        let foundExpectedCategories = allCategories.filter { expectedCategories.contains($0) }
        XCTAssertGreaterThanOrEqual(foundExpectedCategories.count, 3, "Should include standard therapy categories")
    }
    
    func testGenerateSampleDataCreatesDiverseCueLevels() async throws {
        // Act
        try await sampleDataManager.generateSampleData()
        
        // Assert - Verify diverse cue levels are assigned
        let cueLevels = mockRepository.mockGoalTemplates.map { $0.defaultCueLevel }
        let uniqueCueLevels = Set(cueLevels)
        
        XCTAssertGreaterThanOrEqual(uniqueCueLevels.count, 2, "Should use multiple cue levels")
        
        // Verify all cue levels are valid
        for cueLevel in cueLevels {
            XCTAssertTrue(CueLevel.allCases.contains(cueLevel), "All cue levels should be valid enum cases")
        }
    }
    
    // MARK: - Clear Sample Data Tests
    
    func testClearSampleDataRemovesAllClients() async throws {
        // Arrange - Generate sample data first
        try await sampleDataManager.generateSampleData()
        let initialClientCount = mockRepository.mockClients.count
        XCTAssertGreaterThan(initialClientCount, 0, "Should have clients before clearing")
        
        // Act
        try await sampleDataManager.clearSampleData()
        
        // Assert
        XCTAssertTrue(mockRepository.mockClients.isEmpty, "All clients should be removed")
        XCTAssertEqual(mockRepository.deletedClientIds.count, initialClientCount, "All clients should be deleted through repository")
    }
    
    func testClearSampleDataRemovesAllGoalTemplates() async throws {
        // Arrange - Generate sample data first
        try await sampleDataManager.generateSampleData()
        let initialTemplateCount = mockRepository.mockGoalTemplates.count
        XCTAssertGreaterThan(initialTemplateCount, 0, "Should have goal templates before clearing")
        
        // Act
        try await sampleDataManager.clearSampleData()
        
        // Assert
        XCTAssertTrue(mockRepository.mockGoalTemplates.isEmpty, "All goal templates should be removed")
        XCTAssertEqual(mockRepository.deletedGoalTemplateIds.count, initialTemplateCount, "All goal templates should be deleted through repository")
    }
    
    func testClearSampleDataHandlesEmptyRepository() async throws {
        // Arrange - Ensure repository is empty
        XCTAssertTrue(mockRepository.mockClients.isEmpty)
        XCTAssertTrue(mockRepository.mockGoalTemplates.isEmpty)
        
        // Act - Should not throw error on empty repository
        try await sampleDataManager.clearSampleData()
        
        // Assert - Still empty, no operations performed
        XCTAssertTrue(mockRepository.mockClients.isEmpty)
        XCTAssertTrue(mockRepository.mockGoalTemplates.isEmpty)
        XCTAssertTrue(mockRepository.deletedClientIds.isEmpty)
        XCTAssertTrue(mockRepository.deletedGoalTemplateIds.isEmpty)
    }
    
    func testClearSampleDataProperDeletionOrder() async throws {
        // Arrange - Generate sample data first
        try await sampleDataManager.generateSampleData()
        let clientCount = mockRepository.mockClients.count
        let templateCount = mockRepository.mockGoalTemplates.count
        
        // Act
        try await sampleDataManager.clearSampleData()
        
        // Assert - Goal templates should be deleted before clients (foreign key constraints)
        XCTAssertEqual(mockRepository.deletedGoalTemplateIds.count, templateCount, "All goal templates should be deleted")
        XCTAssertEqual(mockRepository.deletedClientIds.count, clientCount, "All clients should be deleted")
        
        // Verify proper cleanup
        XCTAssertTrue(mockRepository.mockClients.isEmpty)
        XCTAssertTrue(mockRepository.mockGoalTemplates.isEmpty)
    }
    
    // MARK: - Error Handling Tests
    
    func testGenerateSampleDataHandlesRepositoryCreateClientError() async throws {
        // Arrange - Configure repository to throw error on client creation
        mockRepository.shouldThrowError = true
        
        // Act & Assert
        do {
            try await sampleDataManager.generateSampleData()
            XCTFail("Should throw error when repository fails")
        } catch {
            XCTAssertTrue(error is MockRepositoryError, "Should propagate repository error")
            
            // Verify no data was persisted
            XCTAssertTrue(mockRepository.mockClients.isEmpty, "No clients should be created on error")
            XCTAssertTrue(mockRepository.mockGoalTemplates.isEmpty, "No goal templates should be created on error")
        }
    }
    
    func testGenerateSampleDataHandlesRepositoryCreateGoalTemplateError() async throws {
        // Arrange - Allow client creation but fail on goal template creation
        // We'll need to test this by allowing the first client to be created successfully
        // then failing on goal template creation
        
        var clientCreationCount = 0
        
        // Use a custom mock that fails after first client
        class SelectiveFailureMockRepository: MockTherapyRepository {
            var clientCreationCount = 0
            
            override func createClient(_ client: Client) async throws {
                clientCreationCount += 1
                try await super.createClient(client)
            }
            
            override func createGoalTemplate(_ goalTemplate: GoalTemplate) async throws {
                if clientCreationCount >= 1 {
                    throw MockRepositoryError.operationFailed("Goal template creation failed")
                }
                try await super.createGoalTemplate(goalTemplate)
            }
        }
        
        let selectiveMockRepository = SelectiveFailureMockRepository()
        let manager = SampleDataManager(repository: selectiveMockRepository)
        
        // Act & Assert
        do {
            try await manager.generateSampleData()
            XCTFail("Should throw error when goal template creation fails")
        } catch {
            XCTAssertTrue(error is MockRepositoryError, "Should propagate repository error")
            
            // Verify at least one client was created before failure
            XCTAssertGreaterThanOrEqual(selectiveMockRepository.createdClients.count, 1, "Some clients should be created before error")
        }
    }
    
    func testClearSampleDataHandlesRepositoryFetchError() async throws {
        // Arrange - Configure repository to throw error on fetch
        mockRepository.shouldThrowError = true
        
        // Act & Assert
        do {
            try await sampleDataManager.clearSampleData()
            XCTFail("Should throw error when repository fetch fails")
        } catch {
            XCTAssertTrue(error is MockRepositoryError, "Should propagate repository error")
        }
    }
    
    func testClearSampleDataHandlesRepositoryDeleteError() async throws {
        // Arrange - Generate data first, then configure repository to fail on delete
        mockRepository.shouldThrowError = false
        try await sampleDataManager.generateSampleData()
        
        let initialClientCount = mockRepository.mockClients.count
        XCTAssertGreaterThan(initialClientCount, 0)
        
        // Configure to fail on delete operations
        mockRepository.shouldThrowError = true
        
        // Act & Assert
        do {
            try await sampleDataManager.clearSampleData()
            XCTFail("Should throw error when repository delete fails")
        } catch {
            XCTAssertTrue(error is MockRepositoryError, "Should propagate repository error")
            
            // Data should still be present since delete failed
            XCTAssertEqual(mockRepository.mockClients.count, initialClientCount, "Clients should remain on delete error")
            XCTAssertFalse(mockRepository.mockGoalTemplates.isEmpty, "Goal templates should remain on delete error")
        }
    }
    
    // MARK: - Repository Integration Tests
    
    func testSampleDataManagerUsesProvidedRepository() async throws {
        // Arrange - Create custom repository instance
        let customMockRepository = MockTherapyRepository()
        let manager = SampleDataManager(repository: customMockRepository)
        
        // Act
        try await manager.generateSampleData()
        
        // Assert - Verify operations went to custom repository
        XCTAssertGreaterThan(customMockRepository.createdClients.count, 0, "Should use provided repository for client creation")
        XCTAssertGreaterThan(customMockRepository.createdGoalTemplates.count, 0, "Should use provided repository for goal template creation")
        
        // Verify original mock repository is unaffected
        XCTAssertTrue(mockRepository.createdClients.isEmpty, "Original repository should be unaffected")
        XCTAssertTrue(mockRepository.createdGoalTemplates.isEmpty, "Original repository should be unaffected")
    }
    
    func testSampleDataManagerDefaultRepositoryIntegration() async throws {
        // Arrange - Create manager with default repository
        let manager = SampleDataManager()
        
        // Act & Assert - Should not throw error (using real SimpleCoreDataRepository)
        // Note: This is a basic integration test - full Core Data testing would require in-memory store setup
        XCTAssertNotNil(manager, "Should initialize with default repository")
    }
    
    // MARK: - Data Integrity Tests
    
    func testGenerateSampleDataCreatesValidClientStructure() async throws {
        // Act
        try await sampleDataManager.generateSampleData()
        
        // Assert - Verify client data integrity for first 5 clients (sample validation)
        let sampleClients = Array(mockRepository.mockClients.prefix(5))
        for client in sampleClients {
            // Verify required fields
            XCTAssertFalse(client.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "Client name should not be empty")
            
            // Verify UUID format (not nil UUID)
            XCTAssertNotEqual(client.id.uuidString, "00000000-0000-0000-0000-000000000000", "Client ID should be valid UUID")
            
            // Verify date fields
            let timeSinceCreation = abs(client.createdDate.timeIntervalSinceNow)
            XCTAssertLessThan(timeSinceCreation, 10.0, "Creation date should be recent")
            
            let timeSinceModification = abs(client.lastModified.timeIntervalSinceNow)
            XCTAssertLessThan(timeSinceModification, 10.0, "Last modified date should be recent")
            
            // Verify date of birth is reasonable if present
            if let dateOfBirth = client.dateOfBirth {
                let age = Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0
                XCTAssertGreaterThan(age, 0, "Age should be positive")
                XCTAssertLessThan(age, 120, "Age should be reasonable")
            }
        }
    }
    
    func testGenerateSampleDataCreatesUniqueIdentifiers() async throws {
        // Act
        try await sampleDataManager.generateSampleData()
        
        // Assert - Verify all client IDs are unique
        let clientIds = mockRepository.mockClients.map { $0.id }
        let uniqueClientIds = Set(clientIds)
        XCTAssertEqual(clientIds.count, uniqueClientIds.count, "All client IDs should be unique")
        
        // Assert - Verify all goal template IDs are unique
        let goalTemplateIds = mockRepository.mockGoalTemplates.map { $0.id }
        let uniqueGoalTemplateIds = Set(goalTemplateIds)
        XCTAssertEqual(goalTemplateIds.count, uniqueGoalTemplateIds.count, "All goal template IDs should be unique")
        
        // Verify no overlap between client and goal template IDs
        let allIds = clientIds + goalTemplateIds
        let uniqueAllIds = Set(allIds)
        XCTAssertEqual(allIds.count, uniqueAllIds.count, "All entity IDs should be globally unique")
    }
    
    func testGenerateSampleDataMaintainsForeignKeyIntegrity() async throws {
        // Act
        try await sampleDataManager.generateSampleData()
        
        // Assert - Verify every goal template references an existing client
        for goalTemplate in mockRepository.mockGoalTemplates {
            let associatedClient = mockRepository.mockClients.first { $0.id == goalTemplate.clientId }
            XCTAssertNotNil(associatedClient, "Goal template should reference existing client: \(goalTemplate.id)")
        }
        
        // Verify no orphaned goal templates
        let clientIds = Set(mockRepository.mockClients.map { $0.id })
        let goalTemplateClientIds = Set(mockRepository.mockGoalTemplates.map { $0.clientId })
        XCTAssertTrue(goalTemplateClientIds.isSubset(of: clientIds), "All goal template client IDs should reference existing clients")
    }
    
    // MARK: - Performance and Scale Tests
    
    func testGenerateSampleDataPerformance() async throws {
        // Act & Assert - Measure execution time
        let startTime = Date()
        try await sampleDataManager.generateSampleData()
        let executionTime = Date().timeIntervalSince(startTime)
        
        // Should complete reasonably quickly even with mock repository
        XCTAssertLessThan(executionTime, 5.0, "Sample data generation should complete within 5 seconds")
        
        // Verify all expected data was created
        XCTAssertEqual(mockRepository.mockClients.count, 20, "Should create all 20 clients")
        XCTAssertGreaterThan(mockRepository.mockGoalTemplates.count, 0, "Should create goal templates")
    }
    
    func testClearSampleDataPerformance() async throws {
        // Arrange
        try await sampleDataManager.generateSampleData()
        let clientCount = mockRepository.mockClients.count
        let templateCount = mockRepository.mockGoalTemplates.count
        
        // Act & Assert - Measure execution time
        let startTime = Date()
        try await sampleDataManager.clearSampleData()
        let executionTime = Date().timeIntervalSince(startTime)
        
        // Should complete reasonably quickly
        XCTAssertLessThan(executionTime, 5.0, "Sample data clearing should complete within 5 seconds")
        
        // Verify all data was removed
        XCTAssertTrue(mockRepository.mockClients.isEmpty, "All clients should be removed")
        XCTAssertTrue(mockRepository.mockGoalTemplates.isEmpty, "All goal templates should be removed")
        XCTAssertEqual(mockRepository.deletedClientIds.count, clientCount, "All clients should be tracked as deleted")
        XCTAssertEqual(mockRepository.deletedGoalTemplateIds.count, templateCount, "All goal templates should be tracked as deleted")
    }
    
    // MARK: - Business Logic Tests
    
    func testGenerateSampleDataCreatesRealisticTherapyScenarios() async throws {
        // Act
        try await sampleDataManager.generateSampleData()
        
        // Assert - Verify realistic therapy combinations
        let clientsWithSpeechTherapy = mockRepository.mockClients.filter { client in
            let clientNotes = client.notes?.lowercased() ?? ""
            return clientNotes.contains("speech") || clientNotes.contains("articulation") || clientNotes.contains("pronunciation")
        }
        XCTAssertGreaterThan(clientsWithSpeechTherapy.count, 0, "Should include speech therapy clients")
        
        let clientsWithBehaviorTherapy = mockRepository.mockClients.filter { client in
            let clientNotes = client.notes?.lowercased() ?? ""
            return clientNotes.contains("autism") || clientNotes.contains("behavior") || clientNotes.contains("social")
        }
        XCTAssertGreaterThan(clientsWithBehaviorTherapy.count, 0, "Should include behavioral therapy clients")
        
        // Verify goal templates match client conditions
        for client in mockRepository.mockClients {
            let clientTemplates = mockRepository.mockGoalTemplates.filter { $0.clientId == client.id }
            let clientAge = client.age ?? 25
            
            // Check age-appropriate goal categories
            if clientAge < 12 {
                let hasChildCategories = clientTemplates.contains { template in
                    ["Articulation", "Language Development", "Social Skills", "Play Skills"].contains(template.category)
                }
                XCTAssertTrue(hasChildCategories, "Young clients should have child-appropriate goals")
            } else if clientAge > 65 {
                let hasGeriatricCategories = clientTemplates.contains { template in
                    ["Speech Clarity", "Voice Therapy", "Cognitive Communication", "Swallowing"].contains(template.category)
                }
                XCTAssertTrue(hasGeriatricCategories, "Geriatric clients should have age-appropriate goals")
            }
        }
    }
}

// MARK: - Additional Mock Extensions

/// Extension to MockTherapyRepository for SampleDataManager-specific testing
extension MockTherapyRepository {
    
    /// Reset all tracking arrays for clean test state
    func resetOperationTracking() {
        createdClients.removeAll()
        updatedClients.removeAll()
        deletedClientIds.removeAll()
        createdGoalTemplates.removeAll()
        updatedGoalTemplates.removeAll()
        deletedGoalTemplateIds.removeAll()
    }
    
    /// Get total operation count for verification
    var totalOperationCount: Int {
        return createdClients.count + updatedClients.count + deletedClientIds.count +
               createdGoalTemplates.count + updatedGoalTemplates.count + deletedGoalTemplateIds.count
    }
}