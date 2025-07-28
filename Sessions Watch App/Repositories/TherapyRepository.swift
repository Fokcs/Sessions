import Foundation
import Combine

protocol TherapyRepository: ObservableObject {
    // Client operations
    func createClient(_ client: Client) async throws
    func fetchClients() async throws -> [Client]
    func updateClient(_ client: Client) async throws
    func deleteClient(_ clientId: UUID) async throws
    func fetchClient(_ clientId: UUID) async throws -> Client?
    
    // Goal template operations
    func createGoalTemplate(_ template: GoalTemplate) async throws
    func fetchGoalTemplates(for clientId: UUID) async throws -> [GoalTemplate]
    func updateGoalTemplate(_ template: GoalTemplate) async throws
    func deleteGoalTemplate(_ templateId: UUID) async throws
    func fetchGoalTemplate(_ templateId: UUID) async throws -> GoalTemplate?
    
    // Session operations
    func startSession(for clientId: UUID, location: String?, createdOn: String) async throws -> Session
    func endSession(_ sessionId: UUID) async throws
    func fetchSessions(for clientId: UUID) async throws -> [Session]
    func fetchActiveSession() async throws -> Session?
    func fetchSession(_ sessionId: UUID) async throws -> Session?
    
    // Goal log operations
    func logGoal(_ goalLog: GoalLog) async throws
    func fetchGoalLogs(for sessionId: UUID) async throws -> [GoalLog]
    func deleteGoalLog(_ goalLogId: UUID) async throws
}