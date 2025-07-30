import Foundation
import Combine

@MainActor
class ClientDetailViewModel: ObservableObject {
    @Published var client: Client?
    @Published var goalTemplates: [GoalTemplate] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showingDeleteConfirmation: Bool = false
    
    private let repository: TherapyRepository
    private let clientId: UUID
    
    init(clientId: UUID, repository: TherapyRepository = SimpleCoreDataRepository.shared) {
        self.clientId = clientId
        self.repository = repository
    }
    
    func loadClient() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedClient = try await repository.fetchClient(clientId)
            client = fetchedClient
            
            if client != nil {
                await loadGoalTemplates()
            }
        } catch {
            errorMessage = "Failed to load client: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadGoalTemplates() async {
        do {
            let fetchedTemplates = try await repository.fetchGoalTemplates(for: clientId)
            goalTemplates = fetchedTemplates
        } catch {
            errorMessage = "Failed to load goal templates: \(error.localizedDescription)"
        }
    }
    
    func deleteClient() async -> Bool {
        do {
            try await repository.deleteClient(clientId)
            return true
        } catch {
            errorMessage = "Failed to delete client: \(error.localizedDescription)"
            return false
        }
    }
    
    func refreshData() async {
        await loadClient()
    }
}