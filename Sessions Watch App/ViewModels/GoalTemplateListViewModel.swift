import Foundation
import Combine

@MainActor
class GoalTemplateListViewModel: ObservableObject {
    @Published var goalTemplates: [GoalTemplate] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var searchText: String = ""
    @Published var selectedCategory: String = "All"
    
    private let repository: TherapyRepository
    private let clientId: UUID
    
    var availableCategories: [String] {
        let categories = Set(goalTemplates.map { $0.category })
        return ["All"] + Array(categories).sorted()
    }
    
    var filteredGoalTemplates: [GoalTemplate] {
        var filtered = goalTemplates
        
        if selectedCategory != "All" {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter { template in
                template.title.localizedCaseInsensitiveContains(searchText) ||
                (template.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        return filtered
    }
    
    init(clientId: UUID, repository: TherapyRepository = SimpleCoreDataRepository.shared) {
        self.clientId = clientId
        self.repository = repository
    }
    
    func loadGoalTemplates() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedTemplates = try await repository.fetchGoalTemplates(for: clientId)
            goalTemplates = fetchedTemplates
        } catch {
            errorMessage = "Failed to load goal templates: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func refreshGoalTemplates() async {
        await loadGoalTemplates()
    }
    
    func deleteGoalTemplate(_ template: GoalTemplate) async {
        do {
            try await repository.deleteGoalTemplate(template.id)
            goalTemplates.removeAll { $0.id == template.id }
        } catch {
            errorMessage = "Failed to delete goal template: \(error.localizedDescription)"
        }
    }
    
    func clearFilters() {
        searchText = ""
        selectedCategory = "All"
    }
}