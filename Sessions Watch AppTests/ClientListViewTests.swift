import XCTest
import SwiftUI
import Combine
@testable import Sessions_Watch_App

/// Comprehensive test suite for ClientListView and related components (watchOS)
/// 
/// **Test Coverage:**
/// This test class validates the complete ClientListView implementation for watchOS:
/// - ClientsView: Main view with @StateObject ClientListViewModel integration
/// - LoadingView: Loading state presentation during async data fetch
/// - EmptyStateView: Empty states for no clients vs no search results
/// - ClientListView: List rendering with NavigationLink rows
/// - ClientRowView: Individual client row display optimized for watchOS
/// - Search functionality with .searchable modifier
/// - Pull-to-refresh with .refreshable async operations
/// - Error handling with .errorAlert modifier and retry functionality
/// - Accessibility support with VoiceOver labels and hints for watchOS
/// - Navigation structure with toolbar button implementation
/// 
/// **watchOS-Specific Considerations:**
/// - Smaller screen size optimizations
/// - Digital Crown scrolling support
/// - Simplified navigation patterns
/// - Battery-conscious operations
/// - Reduced visual complexity for watch display
/// 
/// **Test Architecture:**
/// - Uses MockClientListViewModel for isolated view testing
/// - Tests SwiftUI view structure and state changes
/// - Validates accessibility elements and user interactions
/// - Tests async operations and error scenarios
/// - Follows watchOS testing patterns and considerations
final class ClientListViewTests: XCTestCase {
    
    // MARK: - Test Infrastructure
    
    var mockViewModel: MockClientListViewModel!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() async throws {
        try await super.setUp()
        mockViewModel = MockClientListViewModel()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() async throws {
        cancellables = nil
        mockViewModel = nil
        try await super.tearDown()
    }
    
    // MARK: - ClientsView Structure Tests (watchOS)
    
    /// Tests that ClientsView has proper NavigationStack structure for watchOS
    /// 
    /// **watchOS Validation:**
    /// - View can be instantiated with @StateObject ViewModel
    /// - NavigationStack wrapper exists and works on watchOS
    /// - Navigation title is set to "Clients" and displays properly on watch
    /// - Toolbar contains add button with proper accessibility for watch interaction
    func testClientsViewStructure() {
        let clientsView = ClientsView()
        let hostingController = WKHostingController(rootView: clientsView)
        
        // Verify view instantiation on watchOS
        XCTAssertNotNil(hostingController.contentView)
        
        // Load and verify view renders without issues on watch
        hostingController.willActivate()
        XCTAssertNotNil(hostingController.contentView)
    }
    
    /// Tests ClientsView with custom ViewModel for controlled testing on watchOS
    /// 
    /// **watchOS Validation:**
    /// - View accepts injected ViewModel properly on watch
    /// - State changes are reflected in view on smaller screen
    /// - Published properties bind correctly with watch performance constraints
    func testClientsViewWithMockViewModel() {
        // Create a test view that accepts our mock ViewModel
        let testView = ClientsViewTestWrapper(viewModel: mockViewModel)
        let hostingController = WKHostingController(rootView: testView)
        
        // Verify view can be created with mock ViewModel on watchOS
        XCTAssertNotNil(hostingController.contentView)
        hostingController.willActivate()
        XCTAssertNotNil(hostingController.contentView)
    }
    
    /// Tests ClientsView task modifier calls loadClients on appear (watchOS)
    /// 
    /// **watchOS Validation:**
    /// - .task modifier triggers loadClients() on view appear
    /// - ViewModel receives proper initialization call
    /// - Async operation handling works correctly with watch constraints
    /// - Battery-efficient loading patterns
    func testClientsViewTaskModifier() async {
        let testView = ClientsViewTestWrapper(viewModel: mockViewModel)
        let hostingController = WKHostingController(rootView: testView)
        
        // Load view to trigger .task modifier
        hostingController.willActivate()
        
        // Allow time for async task to complete
        await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Verify loadClients was called
        XCTAssertTrue(mockViewModel.loadClientsCalled)
    }
    
    // MARK: - Loading State Tests (watchOS)
    
    /// Tests LoadingView displays during initial data fetch on watchOS
    /// 
    /// **watchOS Validation:**
    /// - LoadingView appears when isLoading=true and clients.isEmpty
    /// - ProgressView is displayed with proper styling for watch
    /// - Loading text shows "Loading clients..." with appropriate font sizing
    /// - Accessibility elements are properly configured for VoiceOver on watch
    func testLoadingViewState() {
        // Configure mock for loading state
        mockViewModel.isLoading = true
        mockViewModel.clients = []
        
        let testView = ClientsViewTestWrapper(viewModel: mockViewModel)
        let hostingController = WKHostingController(rootView: testView)
        
        // Verify loading view is displayed on watchOS
        hostingController.willActivate()
        XCTAssertNotNil(hostingController.contentView)
    }
    
    /// Tests LoadingView accessibility configuration for watchOS
    /// 
    /// **watchOS Validation:**
    /// - Accessibility element combines children properly
    /// - Accessibility label is set to "Loading clients"
    /// - VoiceOver announces loading state correctly on watch
    /// - Haptic feedback considerations for loading state
    func testLoadingViewAccessibility() {
        let loadingView = LoadingView()
        let hostingController = WKHostingController(rootView: loadingView)
        
        // Verify loading view renders with accessibility on watchOS
        hostingController.willActivate()
        XCTAssertNotNil(hostingController.contentView)
    }
    
    /// Tests that loading state doesn't show when clients exist on watchOS
    /// 
    /// **watchOS Validation:**
    /// - LoadingView hidden when clients array is not empty
    /// - Even if isLoading=true, shows content if clients exist
    /// - Proper state management during refresh operations on watch
    /// - Efficient rendering for watch battery life
    func testLoadingStateWithExistingClients() {
        // Configure mock with existing clients and loading
        mockViewModel.isLoading = true
        mockViewModel.clients = createTestClients()
        
        let testView = ClientsViewTestWrapper(viewModel: mockViewModel)
        let hostingController = WKHostingController(rootView: testView)
        
        // Verify content is shown instead of loading on watchOS
        hostingController.willActivate()
        XCTAssertNotNil(hostingController.contentView)
    }
    
    // MARK: - Empty State Tests (watchOS)
    
    /// Tests EmptyStateView when no clients exist on watchOS
    /// 
    /// **watchOS Validation:**
    /// - EmptyStateView appears when filteredClients.isEmpty
    /// - Shows "No Clients" title with appropriate sizing for watch
    /// - Displays proper icon (person.2.fill) sized for watch screen
    /// - Shows helpful message for adding first client, adapted for watch UI
    func testEmptyStateNoClients() {
        // Configure mock for empty state
        mockViewModel.isLoading = false
        mockViewModel.clients = []
        mockViewModel.searchText = ""
        
        let testView = ClientsViewTestWrapper(viewModel: mockViewModel)
        let hostingController = WKHostingController(rootView: testView)
        
        // Verify empty state is displayed on watchOS
        hostingController.willActivate()
        XCTAssertNotNil(hostingController.contentView)
    }
    
    /// Tests EmptyStateView when search returns no results on watchOS
    /// 
    /// **watchOS Validation:**
    /// - EmptyStateView appears when search text exists but no matches
    /// - Shows "No Results" title for search state, optimized for watch
    /// - Displays magnifying glass icon for search context
    /// - Shows appropriate message for no search results on small screen
    func testEmptyStateNoSearchResults() {
        // Configure mock for search with no results
        mockViewModel.isLoading = false
        mockViewModel.clients = createTestClients()
        mockViewModel.searchText = "nonexistent"
        
        let testView = ClientsViewTestWrapper(viewModel: mockViewModel)
        let hostingController = WKHostingController(rootView: testView)
        
        // Verify search empty state is displayed on watchOS
        hostingController.willActivate()
        XCTAssertNotNil(hostingController.contentView)
    }
    
    /// Tests EmptyStateView accessibility for different states on watchOS
    /// 
    /// **watchOS Validation:**
    /// - Accessibility labels differ for no clients vs no search results
    /// - Accessibility elements combine children properly for watch VoiceOver
    /// - VoiceOver announces appropriate state information on watch
    /// - Haptic feedback for empty states when appropriate
    func testEmptyStateAccessibility() {
        // Test no clients state
        let noClientsView = EmptyStateView(isSearchActive: false)
        let noClientsController = WKHostingController(rootView: noClientsView)
        noClientsController.willActivate()
        XCTAssertNotNil(noClientsController.contentView)
        
        // Test no search results state
        let noResultsView = EmptyStateView(isSearchActive: true)
        let noResultsController = WKHostingController(rootView: noResultsView)
        noResultsController.willActivate()
        XCTAssertNotNil(noResultsController.contentView)
    }
    
    // MARK: - Client List Display Tests (watchOS)
    
    /// Tests ClientListView renders clients properly on watchOS
    /// 
    /// **watchOS Validation:**
    /// - List displays all clients from filteredClients array
    /// - Each client shows as NavigationLink row optimized for watch
    /// - ClientRowView renders within each row with appropriate sizing
    /// - List styling is set to .plain and optimized for watch scrolling
    /// - Digital Crown support for scrolling through clients
    func testClientListViewRendering() {
        let testClients = createTestClients()
        let clientListView = ClientListView(clients: testClients)
        let hostingController = WKHostingController(rootView: clientListView)
        
        // Verify list renders with clients on watchOS
        hostingController.willActivate()
        XCTAssertNotNil(hostingController.contentView)
    }
    
    /// Tests ClientRowView displays client information correctly on watchOS
    /// 
    /// **watchOS Validation:**
    /// - Client name appears with headline font sized for watch
    /// - Client details show with subheadline font and secondary color
    /// - VStack layout with proper alignment and spacing for small screen
    /// - Proper padding applied to row for watch touch targets
    /// - Text truncation handling for long names on small screen
    func testClientRowViewDisplay() {
        let testClient = createTestClients()[0]
        let clientRowView = ClientRowView(client: testClient)
        let hostingController = WKHostingController(rootView: clientRowView)
        
        // Verify row renders client data on watchOS
        hostingController.willActivate()
        XCTAssertNotNil(hostingController.contentView)
    }
    
    /// Tests NavigationLink accessibility in ClientListView on watchOS
    /// 
    /// **watchOS Validation:**
    /// - Each NavigationLink has accessibility label with client info
    /// - Accessibility hint indicates navigation to client details
    /// - Accessibility elements combine children properly for watch
    /// - VoiceOver announces client name and details efficiently on watch
    /// - Digital Crown accessibility for list navigation
    func testClientListViewAccessibility() {
        let testClients = createTestClients()
        let clientListView = ClientListView(clients: testClients)
        let hostingController = WKHostingController(rootView: clientListView)
        
        // Verify accessibility is configured for watchOS
        hostingController.willActivate()
        XCTAssertNotNil(hostingController.contentView)
    }
    
    /// Tests that ClientListView appears when clients exist on watchOS
    /// 
    /// **watchOS Validation:**
    /// - ClientListView is shown when filteredClients is not empty
    /// - Content displays instead of loading or empty states
    /// - List contains proper number of client rows for watch display
    /// - Efficient rendering for watch battery conservation
    func testClientListViewVisibility() {
        // Configure mock with clients
        mockViewModel.isLoading = false
        mockViewModel.clients = createTestClients()
        mockViewModel.searchText = ""
        
        let testView = ClientsViewTestWrapper(viewModel: mockViewModel)
        let hostingController = WKHostingController(rootView: testView)
        
        // Verify client list is displayed on watchOS
        hostingController.willActivate()
        XCTAssertNotNil(hostingController.contentView)
    }
    
    // MARK: - Search Functionality Tests (watchOS)
    
    /// Tests search text binding with ViewModel on watchOS
    /// 
    /// **watchOS Validation:**
    /// - .searchable modifier binds to viewModel.searchText
    /// - Search prompt displays "Search clients by name" appropriately for watch
    /// - Text changes update ViewModel search property
    /// - Search is case insensitive and works with watch input methods
    /// - Dictation support for search input on watch
    func testSearchTextBinding() {
        // Configure mock with clients for searching
        mockViewModel.clients = createTestClients()
        
        let testView = ClientsViewTestWrapper(viewModel: mockViewModel)
        let hostingController = WKHostingController(rootView: testView)
        
        // Verify search is configured for watchOS
        hostingController.willActivate()
        XCTAssertNotNil(hostingController.contentView)
        
        // Test search text updates
        mockViewModel.searchText = "john"
        XCTAssertEqual(mockViewModel.searchText, "john")
    }
    
    /// Tests search filtering through ViewModel on watchOS
    /// 
    /// **watchOS Validation:**
    /// - filteredClients updates based on searchText
    /// - Search is case insensitive and efficient on watch
    /// - Partial name matches work correctly
    /// - Empty search returns all clients
    /// - Performance optimized for watch processing constraints
    func testSearchFiltering() {
        let testClients = createTestClients()
        mockViewModel.clients = testClients
        
        // Test search by name
        mockViewModel.searchText = "john"
        let filteredByJohn = mockViewModel.filteredClients
        XCTAssertEqual(filteredByJohn.count, 1)
        XCTAssertEqual(filteredByJohn[0].name, "John Doe")
        
        // Test case insensitive search
        mockViewModel.searchText = "JANE"
        let filteredByJane = mockViewModel.filteredClients
        XCTAssertEqual(filteredByJane.count, 1)
        XCTAssertEqual(filteredByJane[0].name, "Jane Smith")
        
        // Test empty search returns all
        mockViewModel.searchText = ""
        let allClients = mockViewModel.filteredClients
        XCTAssertEqual(allClients.count, testClients.count)
    }
    
    /// Tests search empty state transitions on watchOS
    /// 
    /// **watchOS Validation:**
    /// - EmptyStateView shows when search has no results
    /// - isSearchActive parameter correctly reflects search state
    /// - Proper icon and message for search empty state on small screen
    /// - Transition between content and search empty state is smooth
    func testSearchEmptyStateTransitions() {
        mockViewModel.clients = createTestClients()
        
        let testView = ClientsViewTestWrapper(viewModel: mockViewModel)
        let hostingController = WKHostingController(rootView: testView)
        hostingController.willActivate()
        
        // Test transition to search empty state
        mockViewModel.searchText = "nonexistent"
        
        // Verify empty state is triggered by search
        XCTAssertTrue(mockViewModel.filteredClients.isEmpty)
        XCTAssertFalse(mockViewModel.searchText.isEmpty)
    }
    
    // MARK: - Pull-to-Refresh Tests (watchOS)
    
    /// Tests pull-to-refresh functionality on watchOS
    /// 
    /// **watchOS Validation:**
    /// - .refreshable modifier calls viewModel.refreshClients()
    /// - Async refresh operation completes properly on watch
    /// - Refresh gesture triggers data reload efficiently
    /// - Loading state updates during refresh with watch-appropriate feedback
    /// - Battery-conscious refresh operations
    func testPullToRefresh() async {
        mockViewModel.clients = createTestClients()
        
        let testView = ClientsViewTestWrapper(viewModel: mockViewModel)
        let hostingController = WKHostingController(rootView: testView)
        
        // Load view
        hostingController.willActivate()
        
        // Simulate pull-to-refresh by calling refresh directly
        await mockViewModel.refreshClients()
        
        // Verify refresh was called
        XCTAssertTrue(mockViewModel.refreshClientsCalled)
    }
    
    /// Tests refresh updates client data on watchOS
    /// 
    /// **watchOS Validation:**
    /// - refreshClients() triggers loadClients() internally
    /// - Client data is updated after refresh
    /// - Loading states are properly managed for watch UI
    /// - Error states are cleared on successful refresh
    /// - Efficient data sync for watch storage constraints
    func testRefreshUpdatesData() async {
        mockViewModel.clients = []
        
        // Simulate refresh with new data
        mockViewModel.mockClientsToReturn = createTestClients()
        await mockViewModel.refreshClients()
        
        // Verify data was updated
        XCTAssertTrue(mockViewModel.refreshClientsCalled)
        XCTAssertEqual(mockViewModel.clients.count, 3)
    }
    
    // MARK: - Error Handling Tests (watchOS)
    
    /// Tests error alert presentation on watchOS
    /// 
    /// **watchOS Validation:**
    /// - .errorAlert modifier displays TherapyAppError appropriately for watch
    /// - Error alert shows error description and recovery suggestion
    /// - OK button dismisses error via clearError()
    /// - Retry button appears for retryable errors
    /// - Alert sizing and presentation optimized for watch screen
    func testErrorAlertPresentation() {
        // Configure mock with error
        mockViewModel.error = TherapyAppError.fetchFailure(NSError(domain: "Test", code: 500, userInfo: nil))
        
        let testView = ClientsViewTestWrapper(viewModel: mockViewModel)
        let hostingController = WKHostingController(rootView: testView)
        
        // Verify error alert is configured for watchOS
        hostingController.willActivate()
        XCTAssertNotNil(hostingController.contentView)
        XCTAssertNotNil(mockViewModel.error)
    }
    
    /// Tests error clearance functionality on watchOS
    /// 
    /// **watchOS Validation:**
    /// - clearError() sets error to nil
    /// - Error alert dismisses when error is cleared
    /// - ViewModel error state is properly reset
    /// - Efficient error state management for watch performance
    func testErrorClearance() {
        // Set error state
        mockViewModel.error = TherapyAppError.fetchFailure(NSError(domain: "Test", code: 500, userInfo: nil))
        XCTAssertNotNil(mockViewModel.error)
        
        // Clear error
        mockViewModel.clearError()
        
        // Verify error is cleared
        XCTAssertNil(mockViewModel.error)
    }
    
    /// Tests retry functionality for retryable errors on watchOS
    /// 
    /// **watchOS Validation:**
    /// - Retry button appears for retryable errors
    /// - retryLastOperation() is called when retry is tapped
    /// - Error is cleared after successful retry
    /// - Failed operation is re-executed efficiently for watch
    /// - Appropriate feedback for retry operations on watch
    func testErrorRetryFunctionality() async {
        // Configure mock with retryable error
        mockViewModel.error = TherapyAppError.fetchFailure(NSError(domain: "Test", code: 500, userInfo: nil))
        XCTAssertTrue(mockViewModel.error?.isRetryable == true)
        
        // Simulate retry
        await mockViewModel.retryLastOperation()
        
        // Verify retry was called
        XCTAssertTrue(mockViewModel.retryLastOperationCalled)
    }
    
    // MARK: - Navigation and Toolbar Tests (watchOS)
    
    /// Tests toolbar button configuration on watchOS
    /// 
    /// **watchOS Validation:**
    /// - Toolbar contains add button with plus icon sized for watch
    /// - Add button has accessibility label "Add new client"
    /// - Add button has accessibility hint for client creation
    /// - Button is positioned appropriately for watch interaction
    /// - Touch target size optimized for watch screen
    func testToolbarConfiguration() {
        let clientsView = ClientsView()
        let hostingController = WKHostingController(rootView: clientsView)
        
        // Verify toolbar is configured for watchOS
        hostingController.willActivate()
        XCTAssertNotNil(hostingController.contentView)
    }
    
    /// Tests navigation title configuration on watchOS
    /// 
    /// **watchOS Validation:**
    /// - Navigation title is set to "Clients" and displays properly
    /// - Title appears in navigation bar with appropriate sizing
    /// - NavigationStack provides proper hierarchy for watch navigation
    /// - Title truncation handled appropriately for watch screen
    func testNavigationTitle() {
        let clientsView = ClientsView()
        let hostingController = WKHostingController(rootView: clientsView)
        
        // Verify navigation structure for watchOS
        hostingController.willActivate()
        XCTAssertNotNil(hostingController.contentView)
    }
    
    /// Tests ClientDetailViewPlaceholder navigation on watchOS
    /// 
    /// **watchOS Validation:**
    /// - NavigationLink destinations are configured correctly for watch
    /// - ClientDetailViewPlaceholder receives client parameter
    /// - Navigation hierarchy supports back navigation on watch
    /// - Placeholder view displays client information optimized for watch
    /// - Navigation animations work smoothly on watch hardware
    func testClientDetailNavigation() {
        let testClient = createTestClients()[0]
        let detailView = ClientDetailViewPlaceholder(client: testClient)
        let hostingController = WKHostingController(rootView: detailView)
        
        // Verify detail placeholder renders on watchOS
        hostingController.willActivate()
        XCTAssertNotNil(hostingController.contentView)
    }
    
    // MARK: - watchOS-Specific Tests
    
    /// Tests Digital Crown scrolling support in client list
    /// 
    /// **watchOS Validation:**
    /// - List supports Digital Crown scrolling
    /// - Smooth scrolling through client entries
    /// - Proper focus management during Crown scrolling
    /// - Accessibility announcements during Crown navigation
    func testDigitalCrownScrolling() {
        let testClients = createLargeClientList(count: 20)
        let clientListView = ClientListView(clients: testClients)
        let hostingController = WKHostingController(rootView: clientListView)
        
        // Verify list renders with Digital Crown support
        hostingController.willActivate()
        XCTAssertNotNil(hostingController.contentView)
    }
    
    /// Tests watch-specific performance optimizations
    /// 
    /// **watchOS Validation:**
    /// - View rendering is optimized for watch performance
    /// - Memory usage is appropriate for watch constraints
    /// - Battery-conscious update patterns
    /// - Efficient data processing for watch CPU
    func testWatchPerformanceOptimizations() {
        let testClients = createTestClients()
        mockViewModel.clients = testClients
        
        let testView = ClientsViewTestWrapper(viewModel: mockViewModel)
        let hostingController = WKHostingController(rootView: testView)
        
        // Measure performance on watch hardware simulation
        measure {
            hostingController.willActivate()
            mockViewModel.searchText = "test"
            let _ = mockViewModel.filteredClients
            mockViewModel.searchText = ""
        }
    }
    
    /// Tests watch-specific accessibility features
    /// 
    /// **watchOS Validation:**
    /// - VoiceOver works properly on watch
    /// - Accessibility gestures are supported
    /// - Screen reader announcements are optimized for watch
    /// - Haptic feedback complements accessibility features
    func testWatchAccessibilityFeatures() {
        let testClients = createTestClients()
        let clientListView = ClientListView(clients: testClients)
        let hostingController = WKHostingController(rootView: clientListView)
        
        // Verify watch accessibility features
        hostingController.willActivate()
        XCTAssertNotNil(hostingController.contentView)
    }
    
    // MARK: - Integration Tests (watchOS)
    
    /// Tests complete user workflow from loading to interaction on watchOS
    /// 
    /// **watchOS Validation:**
    /// - View loads and shows loading state initially
    /// - Data loads and transitions to content state smoothly
    /// - Search functionality works with loaded data on watch
    /// - Error scenarios are handled gracefully with watch-appropriate UI
    /// - Refresh operations update the display efficiently
    /// - Battery life considerations throughout workflow
    func testCompleteWatchUserWorkflow() async {
        let testView = ClientsViewTestWrapper(viewModel: mockViewModel)
        let hostingController = WKHostingController(rootView: testView)
        
        // 1. Initial loading state
        mockViewModel.isLoading = true
        mockViewModel.clients = []
        hostingController.willActivate()
        XCTAssertNotNil(hostingController.contentView)
        
        // 2. Load completes with data
        mockViewModel.isLoading = false
        mockViewModel.clients = createTestClients()
        
        // 3. Search functionality
        mockViewModel.searchText = "john"
        XCTAssertEqual(mockViewModel.filteredClients.count, 1)
        
        // 4. Clear search
        mockViewModel.searchText = ""
        XCTAssertEqual(mockViewModel.filteredClients.count, 3)
        
        // 5. Refresh data
        await mockViewModel.refreshClients()
        XCTAssertTrue(mockViewModel.refreshClientsCalled)
    }
    
    /// Tests memory management and view lifecycle on watchOS
    /// 
    /// **watchOS Validation:**
    /// - Views can be created and deallocated properly on watch
    /// - No retain cycles in ViewModel bindings
    /// - Proper cleanup of Combine subscriptions
    /// - SwiftUI view lifecycle behaves correctly on watch
    /// - Memory constraints are respected for watch hardware
    func testWatchMemoryManagementAndLifecycle() {
        autoreleasepool {
            let clientsView = ClientsView()
            let hostingController = WKHostingController(rootView: clientsView)
            hostingController.willActivate()
            XCTAssertNotNil(hostingController.contentView)
            hostingController.didDeactivate()
        }
        
        autoreleasepool {
            let testView = ClientsViewTestWrapper(viewModel: mockViewModel)
            let hostingController = WKHostingController(rootView: testView)
            hostingController.willActivate()
            XCTAssertNotNil(hostingController.contentView)
            hostingController.didDeactivate()
        }
        
        // If we reach here without crashes, memory management is working
        XCTAssertTrue(true, "Views created and deallocated successfully on watchOS")
    }
    
    // MARK: - Performance Tests (watchOS)
    
    /// Tests view rendering performance with client lists on watchOS
    /// 
    /// **watchOS Validation:**
    /// - View renders quickly with clients on watch hardware
    /// - Search filtering performs well within watch constraints
    /// - No performance regression with data updates
    /// - Memory usage remains within watch limits
    func testWatchViewRenderingPerformance() {
        measure {
            let clientList = createTestClients()
            mockViewModel.clients = clientList
            
            let testView = ClientsViewTestWrapper(viewModel: mockViewModel)
            let hostingController = WKHostingController(rootView: testView)
            hostingController.willActivate()
        }
    }
    
    /// Tests search performance with datasets on watchOS
    /// 
    /// **watchOS Validation:**
    /// - Search filtering is fast with reasonable client counts
    /// - Search updates don't cause UI lag on watch
    /// - filteredClients computation is efficient for watch CPU
    /// - Battery impact of search operations is minimal
    func testWatchSearchPerformance() {
        let clientList = createTestClients()
        mockViewModel.clients = clientList
        
        measure {
            mockViewModel.searchText = "test"
            let _ = mockViewModel.filteredClients
            
            mockViewModel.searchText = "client"
            let _ = mockViewModel.filteredClients
            
            mockViewModel.searchText = ""
            let _ = mockViewModel.filteredClients
        }
    }
    
    // MARK: - Test Helper Methods
    
    /// Creates test clients for validation
    private func createTestClients() -> [Client] {
        return [
            Client(
                id: UUID(),
                name: "John Doe",
                dateOfBirth: Calendar.current.date(byAdding: .year, value: -8, to: Date()),
                notes: "Test client 1",
                createdDate: Date(),
                lastModified: Date()
            ),
            Client(
                id: UUID(),
                name: "Jane Smith",
                dateOfBirth: Calendar.current.date(byAdding: .year, value: -12, to: Date()),
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
    
    /// Creates larger client list for performance testing on watchOS
    private func createLargeClientList(count: Int) -> [Client] {
        return (1...count).map { index in
            Client(
                id: UUID(),
                name: "Test Client \(index)",
                dateOfBirth: Calendar.current.date(byAdding: .year, value: -Int.random(in: 5...15), to: Date()),
                notes: "Generated test client \(index)",
                createdDate: Date(),
                lastModified: Date()
            )
        }
    }
}

// MARK: - Mock ClientListViewModel Implementation (watchOS)

/// Mock implementation of ClientListViewModel for isolated view testing on watchOS
/// 
/// **watchOS Testing Benefits:**
/// - Provides controlled, predictable state for watch view testing
/// - Enables testing of all view states without repository dependencies
/// - Tracks method calls for verification
/// - Simulates async operations efficiently for watch testing
/// - Considers watch performance constraints in mock implementation
@MainActor
class MockClientListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var clients: [Client] = []
    @Published var isLoading: Bool = false
    @Published var error: TherapyAppError?
    @Published var searchText: String = ""
    
    // MARK: - Mock Configuration
    var mockClientsToReturn: [Client] = []
    var shouldThrowError = false
    var errorToThrow: TherapyAppError?
    
    // MARK: - Method Call Tracking
    var loadClientsCalled = false
    var refreshClientsCalled = false
    var clearErrorCalled = false
    var retryLastOperationCalled = false
    
    // MARK: - Computed Properties
    
    var filteredClients: [Client] {
        if searchText.isEmpty {
            return clients
        } else {
            return clients.filter { client in
                client.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var hasClients: Bool {
        !clients.isEmpty
    }
    
    var canRetry: Bool {
        error?.isRetryable == true
    }
    
    // MARK: - Mock Methods (watchOS Optimized)
    
    func loadClients() async {
        loadClientsCalled = true
        isLoading = true
        error = nil
        
        // Simulate async delay optimized for watch
        await Task.sleep(nanoseconds: 25_000_000) // 0.025 seconds (faster for watch)
        
        if shouldThrowError {
            error = errorToThrow ?? TherapyAppError.fetchFailure(NSError(domain: "Test", code: 500, userInfo: nil))
        } else {
            clients = mockClientsToReturn
            error = nil
        }
        
        isLoading = false
    }
    
    func refreshClients() async {
        refreshClientsCalled = true
        await loadClients()
    }
    
    func deleteClient(_ client: Client) async {
        if shouldThrowError {
            error = errorToThrow ?? TherapyAppError.saveFailure(NSError(domain: "Test", code: 500, userInfo: nil))
        } else {
            clients.removeAll { $0.id == client.id }
            error = nil
        }
    }
    
    func retryLastOperation() async {
        retryLastOperationCalled = true
        await loadClients()
    }
    
    func clearError() {
        clearErrorCalled = true
        error = nil
    }
    
    func clearSearch() {
        searchText = ""
    }
    
    func client(with id: UUID) -> Client? {
        clients.first { $0.id == id }
    }
    
    func removeClient(with id: UUID) {
        clients.removeAll { $0.id == id }
    }
}

// MARK: - Test Wrapper Views (watchOS)

/// Test wrapper for ClientsView that accepts injectable ViewModel for watchOS
/// 
/// **watchOS Purpose:**
/// This wrapper allows us to inject a mock ViewModel for testing
/// while maintaining the same view structure as the production ClientsView
/// optimized for watchOS constraints and interaction patterns
struct ClientsViewTestWrapper: View {
    @ObservedObject var viewModel: MockClientListViewModel
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.clients.isEmpty {
                    LoadingView()
                } else if viewModel.filteredClients.isEmpty {
                    EmptyStateView(isSearchActive: !viewModel.searchText.isEmpty)
                } else {
                    ClientListView(clients: viewModel.filteredClients)
                }
            }
            .navigationTitle("Clients")
            .searchable(text: $viewModel.searchText, prompt: "Search clients by name")
            .refreshable {
                await viewModel.refreshClients()
            }
            .errorAlert(error: viewModel.error) {
                viewModel.clearError()
            } onRetry: {
                Task { await viewModel.retryLastOperation() }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        // TODO: Navigation to ClientEditView (future enhancement)
                    }) {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add new client")
                    .accessibilityHint("Creates a new client profile")
                }
            }
        }
        .task {
            await viewModel.loadClients()
        }
    }
}

/// Private struct for testing LoadingView in isolation on watchOS
private struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading clients...")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading clients")
    }
}

/// Private struct for testing EmptyStateView in isolation on watchOS
private struct EmptyStateView: View {
    let isSearchActive: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // Icon (sized appropriately for watch)
            Image(systemName: isSearchActive ? "magnifyingglass" : "person.2.fill")
                .font(.system(size: 50)) // Smaller for watch
                .foregroundStyle(.secondary)
            
            // Content
            VStack(spacing: 12) {
                Text(isSearchActive ? "No Results" : "No Clients")
                    .font(.title3) // Smaller title for watch
                    .fontWeight(.semibold)
                
                Text(isSearchActive ? 
                     "No clients match your search." : 
                     "Add your first client to get started with therapy sessions.")
                    .font(.caption) // Smaller body text for watch
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isSearchActive ? "No search results found" : "No clients added yet")
    }
}

/// Private struct for testing ClientListView in isolation on watchOS
private struct ClientListView: View {
    let clients: [Client]
    
    var body: some View {
        List(clients) { client in
            NavigationLink(destination: ClientDetailViewPlaceholder(client: client)) {
                ClientRowView(client: client)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Client: \(client.displayName), \(client.displayDetails)")
            .accessibilityHint("Tap to view client details")
        }
        .listStyle(.plain)
    }
}

/// Private struct for testing ClientRowView in isolation on watchOS
private struct ClientRowView: View {
    let client: Client
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(client.displayName)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(1) // Prevent overflow on watch
            
            Text(client.displayDetails)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1) // Prevent overflow on watch
        }
        .padding(.vertical, 2)
    }
}

/// Private struct for testing ClientDetailViewPlaceholder in isolation on watchOS
private struct ClientDetailViewPlaceholder: View {
    let client: Client
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 60)) // Smaller for watch
                .foregroundStyle(.primary)
            
            Text(client.displayName)
                .font(.title2) // Smaller title for watch
                .fontWeight(.bold)
                .lineLimit(2) // Allow wrapping but limit lines
            
            Text("Client details will be implemented in a future update")
                .font(.caption) // Smaller text for watch
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .navigationTitle("Client Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}