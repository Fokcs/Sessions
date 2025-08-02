import Foundation
import Combine

@MainActor
class GoalTemplateListViewModel: ObservableObject {
    @Published var goalTemplates: [GoalTemplate] = []
    @Published var isLoading: Bool = false
    @Published var error: TherapyAppError?
    @Published var searchText: String = ""
    @Published var selectedCategory: String = "All"
    
    private let repository: TherapyRepository
    private let clientId: UUID
    private var lastFailedOperation: (() async -> Void)?
    
    // MARK: - Computed Properties
    
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
    
    var hasGoalTemplates: Bool {
        !goalTemplates.isEmpty
    }
    
    var hasActiveFilters: Bool {
        selectedCategory != "All" || !searchText.isEmpty
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
    
    // MARK: - Initialization
    
    init(clientId: UUID, repository: TherapyRepository = SimpleCoreDataRepository.shared) {
        self.clientId = clientId
        self.repository = repository
    }
    
    // MARK: - Public Methods
    
    func loadGoalTemplates() async {
        isLoading = true
        error = nil
        lastFailedOperation = { [weak self] in
            await self?.loadGoalTemplates()
        }
        
        do {
            let fetchedTemplates = try await repository.fetchGoalTemplates(for: clientId)
            goalTemplates = fetchedTemplates
            error = nil
            lastFailedOperation = nil
        } catch let therapyError as TherapyAppError {
            error = therapyError
        } catch {
            self.error = .fetchFailure(error as NSError)
        }
        
        isLoading = false
    }
    
    func refreshGoalTemplates() async {
        await loadGoalTemplates()
    }
    
    func deleteGoalTemplate(_ template: GoalTemplate) async {
        // Store operation for potential retry
        lastFailedOperation = { [weak self] in
            await self?.deleteGoalTemplate(template)
        }
        
        do {
            try await repository.deleteGoalTemplate(template.id)
            goalTemplates.removeAll { $0.id == template.id }
            error = nil
            lastFailedOperation = nil
        } catch let therapyError as TherapyAppError {
            error = therapyError
        } catch {
            self.error = .saveFailure(error as NSError)
        }
    }
    
    func toggleTemplateActivation(_ template: GoalTemplate) async {
        var updatedTemplate = template
        updatedTemplate.isActive.toggle()
        
        lastFailedOperation = { [weak self] in
            await self?.toggleTemplateActivation(template)
        }
        
        do {
            try await repository.updateGoalTemplate(updatedTemplate)
            if let index = goalTemplates.firstIndex(where: { $0.id == template.id }) {
                goalTemplates[index] = updatedTemplate
            }
            error = nil
            lastFailedOperation = nil
        } catch let therapyError as TherapyAppError {
            error = therapyError
        } catch {
            self.error = .saveFailure(error as NSError)
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
    
    func clearFilters() {
        searchText = ""
        selectedCategory = "All"
    }
    
    func clearSearch() {
        searchText = ""
    }
    
    // MARK: - Helper Methods
    
    func goalTemplate(with id: UUID) -> GoalTemplate? {
        goalTemplates.first { $0.id == id }
    }
    
    func removeGoalTemplate(with id: UUID) {
        goalTemplates.removeAll { $0.id == id }
    }
    
    func templatesInCategory(_ category: String) -> [GoalTemplate] {
        if category == "All" {
            return goalTemplates
        }
        return goalTemplates.filter { $0.category == category }
    }
}