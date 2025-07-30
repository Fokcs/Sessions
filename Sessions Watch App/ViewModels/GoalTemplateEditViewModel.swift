import Foundation
import Combine

@MainActor
class GoalTemplateEditViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var category: String = ""
    @Published var defaultCueLevel: CueLevel = .independent
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let repository: TherapyRepository
    private let clientId: UUID
    private var existingTemplate: GoalTemplate?
    
    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var isEditing: Bool {
        existingTemplate != nil
    }
    
    var formTitle: String {
        isEditing ? "Edit Goal Template" : "New Goal Template"
    }
    
    let availableCueLevels = CueLevel.allCases
    
    init(clientId: UUID, repository: TherapyRepository = SimpleCoreDataRepository.shared) {
        self.clientId = clientId
        self.repository = repository
    }
    
    func loadGoalTemplate(_ template: GoalTemplate) {
        existingTemplate = template
        title = template.title
        description = template.description ?? ""
        category = template.category
        defaultCueLevel = template.defaultCueLevel
    }
    
    func save() async -> Bool {
        guard isValid else {
            errorMessage = "Title and category are required"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            if let existingTemplate = existingTemplate {
                let updatedTemplate = GoalTemplate(
                    id: existingTemplate.id,
                    title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                    description: description.isEmpty ? nil : description,
                    category: category.trimmingCharacters(in: .whitespacesAndNewlines),
                    defaultCueLevel: defaultCueLevel,
                    clientId: clientId,
                    isActive: existingTemplate.isActive,
                    createdDate: existingTemplate.createdDate
                )
                try await repository.updateGoalTemplate(updatedTemplate)
            } else {
                let newTemplate = GoalTemplate(
                    title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                    description: description.isEmpty ? nil : description,
                    category: category.trimmingCharacters(in: .whitespacesAndNewlines),
                    defaultCueLevel: defaultCueLevel,
                    clientId: clientId
                )
                try await repository.createGoalTemplate(newTemplate)
            }
            
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to save goal template: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    func validateForm() -> Bool {
        return isValid
    }
    
    func clearForm() {
        title = ""
        description = ""
        category = ""
        defaultCueLevel = .independent
        errorMessage = nil
        existingTemplate = nil
    }
}