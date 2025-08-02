import Foundation
import Combine

/// Protocol defining the data access layer for therapy app operations
/// 
/// **Repository Pattern:**
/// This protocol abstracts all data persistence operations, allowing for different
/// implementations (Core Data, CloudKit, mock data, etc.) while maintaining a
/// consistent interface for the application layer.
/// 
/// **Design Principles:**
/// - All operations are async to prevent UI blocking
/// - Uses Swift model structs as parameters and return types
/// - ObservableObject conformance enables SwiftUI integration
/// - Throws errors for proper error handling up the call stack
/// 
/// **MVVM Integration:**
/// ViewModels depend on this protocol rather than concrete implementations,
/// enabling dependency injection, easier testing, and flexibility in data sources.
/// 
/// **Error Handling:**
/// All methods can throw errors - implementations should provide meaningful
/// error types for different failure scenarios (network, storage, validation, etc.)
protocol TherapyRepository: ObservableObject {
    
    // MARK: - Client Operations
    
    /// Creates a new client record
    /// - Parameter client: Client model to persist
    /// - Throws: Persistence or validation errors
    func createClient(_ client: Client) async throws
    
    /// Retrieves all clients, typically sorted for UI presentation
    /// - Returns: Array of all Client models
    /// - Throws: Data access errors
    func fetchClients() async throws -> [Client]
    
    /// Updates an existing client record
    /// - Parameter client: Updated client model
    /// - Throws: Persistence errors or client not found
    func updateClient(_ client: Client) async throws
    
    /// Deletes a client and associated data
    /// - Parameter clientId: UUID of client to delete
    /// - Throws: Persistence errors or client not found
    /// - Note: Consider cascading delete implications for sessions/goals
    func deleteClient(_ clientId: UUID) async throws
    
    /// Retrieves a specific client by ID
    /// - Parameter clientId: UUID of requested client
    /// - Returns: Client model or nil if not found
    /// - Throws: Data access errors
    func fetchClient(_ clientId: UUID) async throws -> Client?
    
    // MARK: - Goal Template Operations
    
    /// Creates a new goal template
    /// - Parameter template: GoalTemplate model to persist
    /// - Throws: Persistence or validation errors
    func createGoalTemplate(_ template: GoalTemplate) async throws
    
    /// Retrieves active goal templates for a specific client
    /// - Parameter clientId: UUID of associated client
    /// - Returns: Array of active GoalTemplate models
    /// - Throws: Data access errors
    func fetchGoalTemplates(for clientId: UUID) async throws -> [GoalTemplate]
    
    /// Retrieves all goal templates across all clients
    /// - Returns: Array of all GoalTemplate models (active and inactive)
    /// - Throws: Data access errors
    func fetchAllGoalTemplates() async throws -> [GoalTemplate]
    
    /// Updates an existing goal template
    /// - Parameter template: Updated template model
    /// - Throws: Persistence errors or template not found
    func updateGoalTemplate(_ template: GoalTemplate) async throws
    
    /// Deactivates a goal template (typically soft delete)
    /// - Parameter templateId: UUID of template to deactivate
    /// - Throws: Persistence errors or template not found
    func deleteGoalTemplate(_ templateId: UUID) async throws
    
    /// Retrieves a specific goal template by ID
    /// - Parameter templateId: UUID of requested template
    /// - Returns: GoalTemplate model or nil if not found
    /// - Throws: Data access errors
    func fetchGoalTemplate(_ templateId: UUID) async throws -> GoalTemplate?
    
    // MARK: - Session Operations
    
    /// Creates and starts a new therapy session
    /// - Parameters:
    ///   - clientId: Associated client identifier
    ///   - location: Optional session location
    ///   - createdOn: Device/platform identifier
    /// - Returns: Newly created active Session model
    /// - Throws: Persistence errors or invalid client
    func startSession(for clientId: UUID, location: String?, createdOn: String) async throws -> Session
    
    /// Ends an active therapy session
    /// - Parameter sessionId: UUID of session to complete
    /// - Throws: Persistence errors or session not found
    func endSession(_ sessionId: UUID) async throws
    
    /// Retrieves all sessions for a specific client
    /// - Parameter clientId: UUID of associated client
    /// - Returns: Array of Session models, typically sorted by date
    /// - Throws: Data access errors
    func fetchSessions(for clientId: UUID) async throws -> [Session]
    
    /// Retrieves the currently active session (if any)
    /// - Returns: Active Session model or nil if no active session
    /// - Throws: Data access errors
    func fetchActiveSession() async throws -> Session?
    
    /// Retrieves a specific session with all associated goal logs
    /// - Parameter sessionId: UUID of requested session
    /// - Returns: Complete Session model with goal logs or nil if not found
    /// - Throws: Data access errors
    func fetchSession(_ sessionId: UUID) async throws -> Session?
    
    // MARK: - Goal Log Operations
    
    /// Records a goal attempt/trial during a therapy session
    /// - Parameter goalLog: GoalLog model containing attempt details
    /// - Throws: Persistence errors or invalid session reference
    func logGoal(_ goalLog: GoalLog) async throws
    
    /// Retrieves all goal logs for a specific session
    /// - Parameter sessionId: UUID of associated session
    /// - Returns: Array of GoalLog models, typically sorted by timestamp
    /// - Throws: Data access errors
    func fetchGoalLogs(for sessionId: UUID) async throws -> [GoalLog]
    
    /// Deletes a specific goal log entry
    /// - Parameter goalLogId: UUID of goal log to delete
    /// - Throws: Persistence errors or goal log not found
    func deleteGoalLog(_ goalLogId: UUID) async throws
}