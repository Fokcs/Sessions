import Foundation
import Combine

@MainActor
class ClientEditViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var dateOfBirth: Date?
    @Published var notes: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let repository: TherapyRepository
    private var existingClient: Client?
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var isEditing: Bool {
        existingClient != nil
    }
    
    var title: String {
        isEditing ? "Edit Client" : "New Client"
    }
    
    init(repository: TherapyRepository = SimpleCoreDataRepository.shared) {
        self.repository = repository
    }
    
    func loadClient(_ client: Client) {
        existingClient = client
        name = client.name
        dateOfBirth = client.dateOfBirth
        notes = client.notes ?? ""
    }
    
    func save() async -> Bool {
        guard isValid else {
            errorMessage = "Client name is required"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            if let existingClient = existingClient {
                let updatedClient = Client(
                    id: existingClient.id,
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    dateOfBirth: dateOfBirth,
                    notes: notes.isEmpty ? nil : notes,
                    createdDate: existingClient.createdDate,
                    lastModified: Date()
                )
                try await repository.updateClient(updatedClient)
            } else {
                let newClient = Client(
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    dateOfBirth: dateOfBirth,
                    notes: notes.isEmpty ? nil : notes
                )
                try await repository.createClient(newClient)
            }
            
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to save client: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    func validateForm() -> Bool {
        return isValid
    }
    
    func clearForm() {
        name = ""
        dateOfBirth = nil
        notes = ""
        errorMessage = nil
        existingClient = nil
    }
}