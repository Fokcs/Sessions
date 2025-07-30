import XCTest
import CoreData
import Combine
@testable import Sessions

/// Comprehensive test suite for ViewModel layer in MVVM architecture
/// 
/// **Test Coverage:**
/// This test class validates the behavior of all ViewModels:
/// - ClientListViewModel: List management, search/filter, CRUD operations
/// - ClientDetailViewModel: Individual client details and goal template loading
/// - ClientEditViewModel: Form validation, create/update operations
/// - GoalTemplateListViewModel: Template filtering, category management
/// - GoalTemplateEditViewModel: Template form validation and persistence
/// 
/// **Test Architecture:**
/// - Uses MockTherapyRepository for isolated ViewModel testing
/// - Tests async operations with proper error handling
/// - Validates @Published property updates and state management
/// - Tests dependency injection and repository patterns
/// 
/// **Testing Strategy:**
/// - Arrange-Act-Assert pattern for each test
/// - Mock repository provides controlled data and error scenarios
/// - Tests both happy path and error conditions
/// - Validates computed properties and form validation logic
final class ViewModelTests: XCTestCase {
    
    // MARK: - Test Infrastructure
    
    var mockRepository: MockTherapyRepository!
    var cancellables: Set<AnyCancellable>!
    
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
    
    // MARK: - ClientListViewModel Tests
    
    @MainActor
    func testClientListViewModelInitialization() async {
        // Arrange & Act
        let viewModel = ClientListViewModel(repository: mockRepository)
        
        // Assert
        XCTAssertTrue(viewModel.clients.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.searchText.isEmpty)
        XCTAssertTrue(viewModel.filteredClients.isEmpty)
    }
    
    @MainActor
    func testClientListViewModelLoadClientsSuccess() async {
        // Arrange
        let testClients = createTestClients()
        mockRepository.mockClients = testClients
        let viewModel = ClientListViewModel(repository: mockRepository)
        
        // Act
        await viewModel.loadClients()
        
        // Assert
        XCTAssertEqual(viewModel.clients.count, 3)
        XCTAssertEqual(viewModel.clients[0].name, "John Doe")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    @MainActor
    func testClientListViewModelLoadClientsError() async {
        // Arrange
        mockRepository.shouldThrowError = true
        let viewModel = ClientListViewModel(repository: mockRepository)
        
        // Track loading state changes
        var loadingStates: [Bool] = []
        viewModel.$isLoading
            .sink { loadingStates.append($0) }
            .store(in: &cancellables)
        
        // Act
        await viewModel.loadClients()
        
        // Assert
        XCTAssertTrue(viewModel.clients.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage!.contains("Failed to load clients"))
        
        // Verify loading state transitions: false -> true -> false
        XCTAssertTrue(loadingStates.contains(false))
        XCTAssertTrue(loadingStates.contains(true))
    }
    
    @MainActor
    func testClientListViewModelSearchFiltering() async {
        // Arrange
        let testClients = createTestClients()
        mockRepository.mockClients = testClients
        let viewModel = ClientListViewModel(repository: mockRepository)
        await viewModel.loadClients()
        
        // Act - Test search by name
        viewModel.searchText = "jane"
        
        // Assert
        XCTAssertEqual(viewModel.filteredClients.count, 1)
        XCTAssertEqual(viewModel.filteredClients[0].name, "Jane Smith")
        
        // Act - Test case insensitive search
        viewModel.searchText = "JOHN"
        
        // Assert
        XCTAssertEqual(viewModel.filteredClients.count, 1)
        XCTAssertEqual(viewModel.filteredClients[0].name, "John Doe")
        
        // Act - Test empty search returns all
        viewModel.searchText = ""
        
        // Assert
        XCTAssertEqual(viewModel.filteredClients.count, 3)
    }
    
    @MainActor
    func testClientListViewModelDeleteClientSuccess() async {
        // Arrange
        let testClients = createTestClients()
        mockRepository.mockClients = testClients
        let viewModel = ClientListViewModel(repository: mockRepository)
        await viewModel.loadClients()
        
        let clientToDelete = testClients[0]
        let initialCount = viewModel.clients.count
        
        // Act
        await viewModel.deleteClient(clientToDelete)
        
        // Assert
        XCTAssertEqual(viewModel.clients.count, initialCount - 1)
        XCTAssertFalse(viewModel.clients.contains { $0.id == clientToDelete.id })
        XCTAssertNil(viewModel.errorMessage)
    }
    
    @MainActor
    func testClientListViewModelDeleteClientError() async {
        // Arrange
        let testClients = createTestClients()
        mockRepository.mockClients = testClients
        mockRepository.shouldThrowError = true
        let viewModel = ClientListViewModel(repository: mockRepository)
        await viewModel.loadClients()
        
        mockRepository.shouldThrowError = true // Set error for delete operation
        let clientToDelete = testClients[0]
        let initialCount = viewModel.clients.count
        
        // Act
        await viewModel.deleteClient(clientToDelete)
        
        // Assert
        XCTAssertEqual(viewModel.clients.count, initialCount) // No change
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage!.contains("Failed to delete client"))
    }
    
    @MainActor
    func testClientListViewModelRefreshClients() async {
        // Arrange
        let viewModel = ClientListViewModel(repository: mockRepository)
        mockRepository.mockClients = createTestClients()
        
        // Act
        await viewModel.refreshClients()
        
        // Assert
        XCTAssertEqual(viewModel.clients.count, 3)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - ClientDetailViewModel Tests
    
    @MainActor
    func testClientDetailViewModelInitialization() async {
        // Arrange
        let clientId = UUID()
        
        // Act
        let viewModel = ClientDetailViewModel(clientId: clientId, repository: mockRepository)
        
        // Assert
        XCTAssertNil(viewModel.client)
        XCTAssertTrue(viewModel.goalTemplates.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showingDeleteConfirmation)
    }
    
    @MainActor
    func testClientDetailViewModelLoadClientSuccess() async {
        // Arrange
        let testClient = createTestClients()[0]
        let testGoalTemplates = createTestGoalTemplates(clientId: testClient.id)
        mockRepository.mockClients = [testClient]
        mockRepository.mockGoalTemplates = testGoalTemplates
        
        let viewModel = ClientDetailViewModel(clientId: testClient.id, repository: mockRepository)
        
        // Act
        await viewModel.loadClient()
        
        // Assert
        XCTAssertNotNil(viewModel.client)
        XCTAssertEqual(viewModel.client?.id, testClient.id)
        XCTAssertEqual(viewModel.client?.name, testClient.name)
        XCTAssertEqual(viewModel.goalTemplates.count, 2)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    @MainActor
    func testClientDetailViewModelLoadClientError() async {
        // Arrange
        let clientId = UUID()
        mockRepository.shouldThrowError = true
        let viewModel = ClientDetailViewModel(clientId: clientId, repository: mockRepository)
        
        // Act
        await viewModel.loadClient()
        
        // Assert
        XCTAssertNil(viewModel.client)
        XCTAssertTrue(viewModel.goalTemplates.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage!.contains("Failed to load client"))
    }
    
    @MainActor
    func testClientDetailViewModelLoadGoalTemplatesError() async {
        // Arrange
        let testClient = createTestClients()[0]
        mockRepository.mockClients = [testClient]
        mockRepository.shouldThrowErrorOnGoalTemplates = true
        
        let viewModel = ClientDetailViewModel(clientId: testClient.id, repository: mockRepository)
        
        // Act
        await viewModel.loadClient()
        
        // Assert
        XCTAssertNotNil(viewModel.client) // Client loaded successfully
        XCTAssertTrue(viewModel.goalTemplates.isEmpty) // Goal templates failed to load
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage!.contains("Failed to load goal templates"))
    }
    
    @MainActor
    func testClientDetailViewModelDeleteClientSuccess() async {
        // Arrange
        let testClient = createTestClients()[0]
        mockRepository.mockClients = [testClient]
        let viewModel = ClientDetailViewModel(clientId: testClient.id, repository: mockRepository)
        
        // Act
        let result = await viewModel.deleteClient()
        
        // Assert
        XCTAssertTrue(result)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    @MainActor
    func testClientDetailViewModelDeleteClientError() async {
        // Arrange
        let testClient = createTestClients()[0]
        mockRepository.mockClients = [testClient]
        mockRepository.shouldThrowError = true
        let viewModel = ClientDetailViewModel(clientId: testClient.id, repository: mockRepository)
        
        // Act
        let result = await viewModel.deleteClient()
        
        // Assert
        XCTAssertFalse(result)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage!.contains("Failed to delete client"))
    }
    
    @MainActor
    func testClientDetailViewModelRefreshData() async {
        // Arrange
        let testClient = createTestClients()[0]
        mockRepository.mockClients = [testClient]
        let viewModel = ClientDetailViewModel(clientId: testClient.id, repository: mockRepository)
        
        // Act
        await viewModel.refreshData()
        
        // Assert
        XCTAssertNotNil(viewModel.client)
        XCTAssertEqual(viewModel.client?.id, testClient.id)
    }
    
    // MARK: - ClientEditViewModel Tests
    
    @MainActor
    func testClientEditViewModelInitialization() async {
        // Arrange & Act
        let viewModel = ClientEditViewModel(repository: mockRepository)
        
        // Assert
        XCTAssertTrue(viewModel.name.isEmpty)
        XCTAssertNil(viewModel.dateOfBirth)
        XCTAssertTrue(viewModel.notes.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isValid)
        XCTAssertFalse(viewModel.isEditing)
        XCTAssertEqual(viewModel.title, "New Client")
    }
    
    @MainActor
    func testClientEditViewModelFormValidation() async {
        // Arrange
        let viewModel = ClientEditViewModel(repository: mockRepository)
        
        // Act & Assert - Empty name is invalid
        XCTAssertFalse(viewModel.isValid)
        XCTAssertFalse(viewModel.validateForm())
        
        // Act & Assert - Whitespace-only name is invalid
        viewModel.name = "   "
        XCTAssertFalse(viewModel.isValid)
        
        // Act & Assert - Valid name
        viewModel.name = "John Doe"
        XCTAssertTrue(viewModel.isValid)
        XCTAssertTrue(viewModel.validateForm())
    }
    
    @MainActor
    func testClientEditViewModelLoadExistingClient() async {
        // Arrange
        let testClient = createTestClients()[0]
        let viewModel = ClientEditViewModel(repository: mockRepository)
        
        // Act
        viewModel.loadClient(testClient)
        
        // Assert
        XCTAssertEqual(viewModel.name, testClient.name)
        XCTAssertEqual(viewModel.dateOfBirth, testClient.dateOfBirth)
        XCTAssertEqual(viewModel.notes, testClient.notes ?? "")
        XCTAssertTrue(viewModel.isEditing)
        XCTAssertEqual(viewModel.title, "Edit Client")
    }
    
    @MainActor
    func testClientEditViewModelSaveNewClientSuccess() async {
        // Arrange
        let viewModel = ClientEditViewModel(repository: mockRepository)
        viewModel.name = "New Client"
        viewModel.notes = "Test notes"
        
        // Act
        let result = await viewModel.save()
        
        // Assert
        XCTAssertTrue(result)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(mockRepository.createdClients.count, 1)
        XCTAssertEqual(mockRepository.createdClients[0].name, "New Client")
    }
    
    @MainActor
    func testClientEditViewModelSaveExistingClientSuccess() async {
        // Arrange
        let testClient = createTestClients()[0]
        let viewModel = ClientEditViewModel(repository: mockRepository)
        viewModel.loadClient(testClient)
        viewModel.name = "Updated Name"
        viewModel.notes = "Updated notes"
        
        // Act
        let result = await viewModel.save()
        
        // Assert
        XCTAssertTrue(result)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(mockRepository.updatedClients.count, 1)
        XCTAssertEqual(mockRepository.updatedClients[0].name, "Updated Name")
    }
    
    @MainActor
    func testClientEditViewModelSaveInvalidForm() async {
        // Arrange
        let viewModel = ClientEditViewModel(repository: mockRepository)
        viewModel.name = "" // Invalid
        
        // Act
        let result = await viewModel.save()
        
        // Assert
        XCTAssertFalse(result)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, "Client name is required")
        XCTAssertTrue(mockRepository.createdClients.isEmpty)
    }
    
    @MainActor
    func testClientEditViewModelSaveError() async {
        // Arrange
        let viewModel = ClientEditViewModel(repository: mockRepository)
        viewModel.name = "Valid Name"
        mockRepository.shouldThrowError = true
        
        // Act
        let result = await viewModel.save()
        
        // Assert
        XCTAssertFalse(result)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage!.contains("Failed to save client"))
    }
    
    @MainActor
    func testClientEditViewModelClearForm() async {
        // Arrange
        let testClient = createTestClients()[0]
        let viewModel = ClientEditViewModel(repository: mockRepository)
        viewModel.loadClient(testClient)
        viewModel.errorMessage = "Test error"
        
        // Act
        viewModel.clearForm()
        
        // Assert
        XCTAssertTrue(viewModel.name.isEmpty)
        XCTAssertNil(viewModel.dateOfBirth)
        XCTAssertTrue(viewModel.notes.isEmpty)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isEditing)
    }
    
    // MARK: - GoalTemplateListViewModel Tests
    
    @MainActor
    func testGoalTemplateListViewModelInitialization() async {
        // Arrange
        let clientId = UUID()
        
        // Act
        let viewModel = GoalTemplateListViewModel(clientId: clientId, repository: mockRepository)
        
        // Assert
        XCTAssertTrue(viewModel.goalTemplates.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.searchText.isEmpty)
        XCTAssertEqual(viewModel.selectedCategory, "All")
        XCTAssertEqual(viewModel.availableCategories, ["All"])
        XCTAssertTrue(viewModel.filteredGoalTemplates.isEmpty)
    }
    
    @MainActor
    func testGoalTemplateListViewModelLoadGoalTemplatesSuccess() async {
        // Arrange
        let clientId = UUID()
        let testGoalTemplates = createTestGoalTemplates(clientId: clientId)
        mockRepository.mockGoalTemplates = testGoalTemplates
        let viewModel = GoalTemplateListViewModel(clientId: clientId, repository: mockRepository)
        
        // Act
        await viewModel.loadGoalTemplates()
        
        // Assert
        XCTAssertEqual(viewModel.goalTemplates.count, 2)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.availableCategories.count, 3) // "All" + 2 categories
        XCTAssertTrue(viewModel.availableCategories.contains("Speech"))
        XCTAssertTrue(viewModel.availableCategories.contains("Behavior"))
    }
    
    @MainActor
    func testGoalTemplateListViewModelLoadGoalTemplatesError() async {
        // Arrange
        let clientId = UUID()
        mockRepository.shouldThrowError = true
        let viewModel = GoalTemplateListViewModel(clientId: clientId, repository: mockRepository)
        
        // Act
        await viewModel.loadGoalTemplates()
        
        // Assert
        XCTAssertTrue(viewModel.goalTemplates.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage!.contains("Failed to load goal templates"))
    }
    
    @MainActor
    func testGoalTemplateListViewModelCategoryFiltering() async {
        // Arrange
        let clientId = UUID()
        let testGoalTemplates = createTestGoalTemplates(clientId: clientId)
        mockRepository.mockGoalTemplates = testGoalTemplates
        let viewModel = GoalTemplateListViewModel(clientId: clientId, repository: mockRepository)
        await viewModel.loadGoalTemplates()
        
        // Act - Filter by Speech category
        viewModel.selectedCategory = "Speech"
        
        // Assert
        XCTAssertEqual(viewModel.filteredGoalTemplates.count, 1)
        XCTAssertEqual(viewModel.filteredGoalTemplates[0].category, "Speech")
        
        // Act - Filter by Behavior category
        viewModel.selectedCategory = "Behavior"
        
        // Assert
        XCTAssertEqual(viewModel.filteredGoalTemplates.count, 1)
        XCTAssertEqual(viewModel.filteredGoalTemplates[0].category, "Behavior")
        
        // Act - Show all categories
        viewModel.selectedCategory = "All"
        
        // Assert
        XCTAssertEqual(viewModel.filteredGoalTemplates.count, 2)
    }
    
    @MainActor
    func testGoalTemplateListViewModelSearchFiltering() async {
        // Arrange
        let clientId = UUID()
        let testGoalTemplates = createTestGoalTemplates(clientId: clientId)
        mockRepository.mockGoalTemplates = testGoalTemplates
        let viewModel = GoalTemplateListViewModel(clientId: clientId, repository: mockRepository)
        await viewModel.loadGoalTemplates()
        
        // Act - Search by title
        viewModel.searchText = "pronunciation"
        
        // Assert
        XCTAssertEqual(viewModel.filteredGoalTemplates.count, 1)
        XCTAssertEqual(viewModel.filteredGoalTemplates[0].title, "Improve Pronunciation")
        
        // Act - Search by description
        viewModel.searchText = "sounds"
        
        // Assert
        XCTAssertEqual(viewModel.filteredGoalTemplates.count, 1)
        
        // Act - Case insensitive search
        viewModel.searchText = "BEHAVIOR"
        
        // Assert
        XCTAssertEqual(viewModel.filteredGoalTemplates.count, 1)
        XCTAssertEqual(viewModel.filteredGoalTemplates[0].title, "Reduce Disruptive Behavior")
    }
    
    @MainActor
    func testGoalTemplateListViewModelCombinedFiltering() async {
        // Arrange
        let clientId = UUID()
        let testGoalTemplates = createTestGoalTemplates(clientId: clientId)
        mockRepository.mockGoalTemplates = testGoalTemplates
        let viewModel = GoalTemplateListViewModel(clientId: clientId, repository: mockRepository)
        await viewModel.loadGoalTemplates()
        
        // Act - Combine category and search filters
        viewModel.selectedCategory = "Speech"
        viewModel.searchText = "improve"
        
        // Assert
        XCTAssertEqual(viewModel.filteredGoalTemplates.count, 1)
        XCTAssertEqual(viewModel.filteredGoalTemplates[0].title, "Improve Pronunciation")
        XCTAssertEqual(viewModel.filteredGoalTemplates[0].category, "Speech")
    }
    
    @MainActor
    func testGoalTemplateListViewModelDeleteGoalTemplateSuccess() async {
        // Arrange
        let clientId = UUID()
        let testGoalTemplates = createTestGoalTemplates(clientId: clientId)
        mockRepository.mockGoalTemplates = testGoalTemplates
        let viewModel = GoalTemplateListViewModel(clientId: clientId, repository: mockRepository)
        await viewModel.loadGoalTemplates()
        
        let templateToDelete = testGoalTemplates[0]
        let initialCount = viewModel.goalTemplates.count
        
        // Act
        await viewModel.deleteGoalTemplate(templateToDelete)
        
        // Assert
        XCTAssertEqual(viewModel.goalTemplates.count, initialCount - 1)
        XCTAssertFalse(viewModel.goalTemplates.contains { $0.id == templateToDelete.id })
        XCTAssertNil(viewModel.errorMessage)
    }
    
    @MainActor
    func testGoalTemplateListViewModelDeleteGoalTemplateError() async {
        // Arrange
        let clientId = UUID()
        let testGoalTemplates = createTestGoalTemplates(clientId: clientId)
        mockRepository.mockGoalTemplates = testGoalTemplates
        let viewModel = GoalTemplateListViewModel(clientId: clientId, repository: mockRepository)
        await viewModel.loadGoalTemplates()
        
        mockRepository.shouldThrowError = true
        let templateToDelete = testGoalTemplates[0]
        let initialCount = viewModel.goalTemplates.count
        
        // Act
        await viewModel.deleteGoalTemplate(templateToDelete)
        
        // Assert
        XCTAssertEqual(viewModel.goalTemplates.count, initialCount) // No change
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage!.contains("Failed to delete goal template"))
    }
    
    @MainActor
    func testGoalTemplateListViewModelClearFilters() async {
        // Arrange
        let clientId = UUID()
        let viewModel = GoalTemplateListViewModel(clientId: clientId, repository: mockRepository)
        viewModel.searchText = "test search"
        viewModel.selectedCategory = "Speech"
        
        // Act
        viewModel.clearFilters()
        
        // Assert
        XCTAssertTrue(viewModel.searchText.isEmpty)
        XCTAssertEqual(viewModel.selectedCategory, "All")
    }
    
    @MainActor
    func testGoalTemplateListViewModelRefreshGoalTemplates() async {
        // Arrange
        let clientId = UUID()
        let testGoalTemplates = createTestGoalTemplates(clientId: clientId)
        mockRepository.mockGoalTemplates = testGoalTemplates
        let viewModel = GoalTemplateListViewModel(clientId: clientId, repository: mockRepository)
        
        // Act
        await viewModel.refreshGoalTemplates()
        
        // Assert
        XCTAssertEqual(viewModel.goalTemplates.count, 2)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - GoalTemplateEditViewModel Tests
    
    @MainActor
    func testGoalTemplateEditViewModelInitialization() async {
        // Arrange
        let clientId = UUID()
        
        // Act
        let viewModel = GoalTemplateEditViewModel(clientId: clientId, repository: mockRepository)
        
        // Assert
        XCTAssertTrue(viewModel.title.isEmpty)
        XCTAssertTrue(viewModel.description.isEmpty)
        XCTAssertTrue(viewModel.category.isEmpty)
        XCTAssertEqual(viewModel.defaultCueLevel, .independent)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isValid)
        XCTAssertFalse(viewModel.isEditing)
        XCTAssertEqual(viewModel.formTitle, "New Goal Template")
        XCTAssertEqual(viewModel.availableCueLevels.count, 4)
    }
    
    @MainActor
    func testGoalTemplateEditViewModelFormValidation() async {
        // Arrange
        let clientId = UUID()
        let viewModel = GoalTemplateEditViewModel(clientId: clientId, repository: mockRepository)
        
        // Act & Assert - Empty title and category are invalid
        XCTAssertFalse(viewModel.isValid)
        XCTAssertFalse(viewModel.validateForm())
        
        // Act & Assert - Only title is not enough
        viewModel.title = "Test Title"
        XCTAssertFalse(viewModel.isValid)
        
        // Act & Assert - Only category is not enough
        viewModel.title = ""
        viewModel.category = "Test Category"
        XCTAssertFalse(viewModel.isValid)
        
        // Act & Assert - Both title and category are required
        viewModel.title = "Test Title"
        viewModel.category = "Test Category"
        XCTAssertTrue(viewModel.isValid)
        XCTAssertTrue(viewModel.validateForm())
        
        // Act & Assert - Whitespace-only values are invalid
        viewModel.title = "   "
        viewModel.category = "   "
        XCTAssertFalse(viewModel.isValid)
    }
    
    @MainActor
    func testGoalTemplateEditViewModelLoadExistingTemplate() async {
        // Arrange
        let clientId = UUID()
        let testTemplate = createTestGoalTemplates(clientId: clientId)[0]
        let viewModel = GoalTemplateEditViewModel(clientId: clientId, repository: mockRepository)
        
        // Act
        viewModel.loadGoalTemplate(testTemplate)
        
        // Assert
        XCTAssertEqual(viewModel.title, testTemplate.title)
        XCTAssertEqual(viewModel.description, testTemplate.description ?? "")
        XCTAssertEqual(viewModel.category, testTemplate.category)
        XCTAssertEqual(viewModel.defaultCueLevel, testTemplate.defaultCueLevel)
        XCTAssertTrue(viewModel.isEditing)
        XCTAssertEqual(viewModel.formTitle, "Edit Goal Template")
    }
    
    @MainActor
    func testGoalTemplateEditViewModelSaveNewTemplateSuccess() async {
        // Arrange
        let clientId = UUID()
        let viewModel = GoalTemplateEditViewModel(clientId: clientId, repository: mockRepository)
        viewModel.title = "New Template"
        viewModel.category = "Test Category"
        viewModel.description = "Test description"
        viewModel.defaultCueLevel = .minimal
        
        // Act
        let result = await viewModel.save()
        
        // Assert
        XCTAssertTrue(result)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(mockRepository.createdGoalTemplates.count, 1)
        XCTAssertEqual(mockRepository.createdGoalTemplates[0].title, "New Template")
        XCTAssertEqual(mockRepository.createdGoalTemplates[0].category, "Test Category")
        XCTAssertEqual(mockRepository.createdGoalTemplates[0].defaultCueLevel, .minimal)
    }
    
    @MainActor
    func testGoalTemplateEditViewModelSaveExistingTemplateSuccess() async {
        // Arrange
        let clientId = UUID()
        let testTemplate = createTestGoalTemplates(clientId: clientId)[0]
        let viewModel = GoalTemplateEditViewModel(clientId: clientId, repository: mockRepository)
        viewModel.loadGoalTemplate(testTemplate)
        viewModel.title = "Updated Title"
        viewModel.category = "Updated Category"
        viewModel.defaultCueLevel = .maximal
        
        // Act
        let result = await viewModel.save()
        
        // Assert
        XCTAssertTrue(result)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(mockRepository.updatedGoalTemplates.count, 1)
        XCTAssertEqual(mockRepository.updatedGoalTemplates[0].title, "Updated Title")
        XCTAssertEqual(mockRepository.updatedGoalTemplates[0].category, "Updated Category")
        XCTAssertEqual(mockRepository.updatedGoalTemplates[0].defaultCueLevel, .maximal)
    }
    
    @MainActor
    func testGoalTemplateEditViewModelSaveInvalidForm() async {
        // Arrange
        let clientId = UUID()
        let viewModel = GoalTemplateEditViewModel(clientId: clientId, repository: mockRepository)
        viewModel.title = "" // Invalid
        viewModel.category = "Valid Category"
        
        // Act
        let result = await viewModel.save()
        
        // Assert
        XCTAssertFalse(result)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, "Title and category are required")
        XCTAssertTrue(mockRepository.createdGoalTemplates.isEmpty)
    }
    
    @MainActor
    func testGoalTemplateEditViewModelSaveError() async {
        // Arrange
        let clientId = UUID()
        let viewModel = GoalTemplateEditViewModel(clientId: clientId, repository: mockRepository)
        viewModel.title = "Valid Title"
        viewModel.category = "Valid Category"
        mockRepository.shouldThrowError = true
        
        // Act
        let result = await viewModel.save()
        
        // Assert
        XCTAssertFalse(result)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage!.contains("Failed to save goal template"))
    }
    
    @MainActor
    func testGoalTemplateEditViewModelClearForm() async {
        // Arrange
        let clientId = UUID()
        let testTemplate = createTestGoalTemplates(clientId: clientId)[0]
        let viewModel = GoalTemplateEditViewModel(clientId: clientId, repository: mockRepository)
        viewModel.loadGoalTemplate(testTemplate)
        viewModel.errorMessage = "Test error"
        
        // Act
        viewModel.clearForm()
        
        // Assert
        XCTAssertTrue(viewModel.title.isEmpty)
        XCTAssertTrue(viewModel.description.isEmpty)
        XCTAssertTrue(viewModel.category.isEmpty)
        XCTAssertEqual(viewModel.defaultCueLevel, .independent)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isEditing)
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
    
    private func createTestGoalTemplates(clientId: UUID) -> [GoalTemplate] {
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
            )
        ]
    }
}

// MARK: - Mock Repository Implementation

/// Mock implementation of TherapyRepository for isolated ViewModel testing
/// 
/// **Testing Benefits:**
/// - Provides controlled, predictable data responses
/// - Enables testing of error scenarios without database dependencies
/// - Fast execution with no I/O operations
/// - Tracks repository method calls for verification
/// 
/// **Usage Pattern:**
/// - Configure mock data before test execution
/// - Set error flags to test error handling
/// - Verify repository interactions through tracked arrays
class MockTherapyRepository: TherapyRepository {
    
    // MARK: - Mock Data Storage
    var mockClients: [Client] = []
    var mockGoalTemplates: [GoalTemplate] = []
    var mockSessions: [Session] = []
    var mockGoalLogs: [GoalLog] = []
    
    // MARK: - Error Control
    var shouldThrowError = false
    var shouldThrowErrorOnGoalTemplates = false
    
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
        if shouldThrowError {
            throw MockRepositoryError.operationFailed("Mock fetch clients error")
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
        if shouldThrowError {
            throw MockRepositoryError.operationFailed("Mock delete client error")
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
        if shouldThrowErrorOnGoalTemplates || shouldThrowError {
            throw MockRepositoryError.operationFailed("Mock fetch goal templates error")
        }
        return mockGoalTemplates.filter { $0.clientId == clientId }
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
        if shouldThrowError {
            throw MockRepositoryError.operationFailed("Mock delete goal template error")
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
    
    // MARK: - Session Operations (Stubs for protocol compliance)
    
    func startSession(for clientId: UUID, location: String?, createdOn: String) async throws -> Session {
        if shouldThrowError {
            throw MockRepositoryError.operationFailed("Mock start session error")
        }
        // Return a basic session for testing
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
        // Stub implementation
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
    
    // MARK: - Goal Log Operations (Stubs for protocol compliance)
    
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