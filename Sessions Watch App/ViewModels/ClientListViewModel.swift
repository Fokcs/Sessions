import Foundation
import Combine

@MainActor
class ClientListViewModel: ObservableObject {
    @Published var clients: [Client] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var searchText: String = ""
    
    private let repository: TherapyRepository
    
    init(repository: TherapyRepository = SimpleCoreDataRepository.shared) {
        self.repository = repository
    }
    
    var filteredClients: [Client] {
        if searchText.isEmpty {
            return clients
        } else {
            return clients.filter { client in
                client.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    func loadClients() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedClients = try await repository.fetchClients()
            clients = fetchedClients
        } catch {
            errorMessage = "Failed to load clients: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func refreshClients() async {
        await loadClients()
    }
    
    func deleteClient(_ client: Client) async {
        do {
            try await repository.deleteClient(client.id)
            clients.removeAll { $0.id == client.id }
        } catch {
            errorMessage = "Failed to delete client: \(error.localizedDescription)"
        }
    }
}