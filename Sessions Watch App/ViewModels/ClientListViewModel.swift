import Foundation
import Combine

@MainActor
class ClientListViewModel: ObservableObject {
    @Published var clients: [Client] = []
    @Published var isLoading: Bool = false
    @Published var error: TherapyAppError?
    @Published var searchText: String = ""
    
    private let repository: TherapyRepository
    private var lastFailedOperation: (() async -> Void)?
    
    init(repository: TherapyRepository = SimpleCoreDataRepository.shared) {
        self.repository = repository
    }
    
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
        error?.isRetryable == true && lastFailedOperation != nil
    }
    
    // MARK: - Legacy Support
    
    /// Legacy errorMessage property for backward compatibility
    /// New implementations should use the `error` property directly
    var errorMessage: String? {
        error?.errorDescription
    }
    
    // MARK: - Public Methods
    
    func loadClients() async {
        isLoading = true
        error = nil
        lastFailedOperation = { [weak self] in
            await self?.loadClients()
        }
        
        do {
            let fetchedClients = try await repository.fetchClients()
            clients = fetchedClients
            error = nil
            lastFailedOperation = nil
        } catch let therapyError as TherapyAppError {
            error = therapyError
        } catch {
            error = .fetchFailure(error as NSError)
        }
        
        isLoading = false
    }
    
    func refreshClients() async {
        await loadClients()
    }
    
    func deleteClient(_ client: Client) async {
        // Store operation for potential retry
        lastFailedOperation = { [weak self] in
            await self?.deleteClient(client)
        }
        
        do {
            try await repository.deleteClient(client.id)
            clients.removeAll { $0.id == client.id }
            error = nil
            lastFailedOperation = nil
        } catch let therapyError as TherapyAppError {
            error = therapyError
        } catch {
            error = .saveFailure(error as NSError)
        }
    }
    
    func retryLastOperation() async {
        guard let operation = lastFailedOperation else { return }
        await operation()
    }
    
    func clearError() {
        error = nil
        lastFailedOperation = nil
    }
    
    func clearSearch() {
        searchText = ""
    }
    
    // MARK: - Helper Methods
    
    func client(with id: UUID) -> Client? {
        clients.first { $0.id == id }
    }
    
    func removeClient(with id: UUID) {
        clients.removeAll { $0.id == id }
    }
}