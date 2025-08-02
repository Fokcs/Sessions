//
//  GoalsView.swift
//  Sessions
//
//  Created by Aaron Fuchs on 7/29/25.
//

import SwiftUI

/// Goal template management view for the Sessions iOS application
/// 
/// **Implementation Features:**
/// - Browse goal templates across all clients with category filtering
/// - Search functionality by template title and description
/// - Create new goal templates (assigned to selected client)
/// - Edit existing goal templates with full CRUD operations
/// - Template activation/deactivation (soft delete) with visual indicators
/// - Modern iOS design with accessibility support
/// 
/// **Architecture Notes:**
/// - Uses custom AllGoalTemplatesViewModel for cross-client template viewing
/// - Follows MVVM pattern with ObservableObject ViewModels
/// - Integrates with SimpleCoreDataRepository for data persistence
/// - Supports goal template categorization and cue level management with visual indicators
struct GoalsView: View {
    @StateObject private var viewModel = AllGoalTemplatesViewModel()
    @StateObject private var clientListViewModel = ClientListViewModel()
    @State private var showingCreateTemplate = false
    @State private var selectedClientForNewTemplate: Client?
    @State private var showingClientSelection = false
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.goalTemplates.isEmpty {
                    LoadingView()
                } else if viewModel.filteredGoalTemplates.isEmpty {
                    EmptyStateView(
                        hasFilters: viewModel.hasActiveFilters,
                        onClearFilters: { viewModel.clearFilters() },
                        onCreateTemplate: { showingClientSelection = true }
                    )
                } else {
                    GoalTemplateListContent(
                        templates: viewModel.filteredGoalTemplates,
                        categories: viewModel.availableCategories,
                        selectedCategory: $viewModel.selectedCategory,
                        viewModel: viewModel
                    )
                }
            }
            .navigationTitle("Goal Templates")
            .searchable(text: $viewModel.searchText, prompt: "Search goal templates")
            .refreshable {
                await viewModel.refreshGoalTemplates()
            }
            .errorAlert(error: viewModel.error) {
                viewModel.clearError()
            } onRetry: {
                Task { await viewModel.retryLastOperation() }
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button(action: { showingClientSelection = true }) {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add new goal template")
                    .accessibilityHint("Creates a new goal template")
                }
            }
        }
        .task {
            await viewModel.loadGoalTemplates()
            await clientListViewModel.loadClients()
        }
        .sheet(isPresented: $showingCreateTemplate) {
            if let client = selectedClientForNewTemplate {
                GoalTemplateEditView(clientId: client.id, isPresented: $showingCreateTemplate) {
                    Task { await viewModel.refreshGoalTemplates() }
                }
            }
        }
        .sheet(isPresented: $showingClientSelection) {
            ClientSelectionView(
                clients: clientListViewModel.clients,
                isPresented: $showingClientSelection
            ) { client in
                selectedClientForNewTemplate = client
                showingCreateTemplate = true
            }
        }
    }
}

/// Custom ViewModel for managing goal templates across all clients
@MainActor
class AllGoalTemplatesViewModel: ObservableObject {
    @Published var goalTemplates: [GoalTemplate] = []
    @Published var isLoading: Bool = false
    @Published var error: TherapyAppError?
    @Published var searchText: String = ""
    @Published var selectedCategory: String = "All"
    
    private let repository: TherapyRepository
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
        
        return filtered.sorted { $0.title < $1.title }
    }
    
    var hasActiveFilters: Bool {
        selectedCategory != "All" || !searchText.isEmpty
    }
    
    init(repository: TherapyRepository = SimpleCoreDataRepository.shared) {
        self.repository = repository
    }
    
    // MARK: - Public Methods
    
    func loadGoalTemplates() async {
        isLoading = true
        error = nil
        
        do {
            // Fetch all goal templates across all clients
            let allTemplates = try await repository.fetchAllGoalTemplates()
            goalTemplates = allTemplates
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
        do {
            try await repository.deleteGoalTemplate(template.id)
            goalTemplates.removeAll { $0.id == template.id }
            error = nil
        } catch let therapyError as TherapyAppError {
            error = therapyError
        } catch {
            self.error = .saveFailure(error as NSError)
        }
    }
    
    func toggleTemplateActivation(_ template: GoalTemplate) async {
        var updatedTemplate = template
        updatedTemplate.isActive.toggle()
        
        do {
            try await repository.updateGoalTemplate(updatedTemplate)
            if let index = goalTemplates.firstIndex(where: { $0.id == template.id }) {
                goalTemplates[index] = updatedTemplate
            }
            error = nil
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
}

/// Loading state view for goal templates
private struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading goal templates...")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading goal templates")
    }
}

/// Empty state view for when no goal templates exist or search returns no results
private struct EmptyStateView: View {
    let hasFilters: Bool
    let onClearFilters: () -> Void
    let onCreateTemplate: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: hasFilters ? "magnifyingglass" : "target")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            
            VStack(spacing: 12) {
                Text(hasFilters ? "No Results" : "No Goal Templates")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(hasFilters ? 
                     "No goal templates match your current filters." : 
                     "Create your first goal template to start organizing therapy objectives.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if hasFilters {
                Button("Clear Filters") {
                    onClearFilters()
                }
                .buttonStyle(.bordered)
                .accessibilityHint("Remove all active filters")
            } else {
                Button("Create Goal Template") {
                    onCreateTemplate()
                }
                .buttonStyle(.borderedProminent)
                .accessibilityHint("Create your first goal template")
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(hasFilters ? "No search results found" : "No goal templates created yet")
    }
}

/// Main content view displaying the list of goal templates
private struct GoalTemplateListContent: View {
    let templates: [GoalTemplate]
    let categories: [String]
    @Binding var selectedCategory: String
    @ObservedObject var viewModel: AllGoalTemplatesViewModel
    
    var body: some View {
        List {
            ForEach(templates) { template in
                GoalTemplateRow(template: template, viewModel: viewModel)
            }
        }
        .listStyle(.plain)
    }
}

/// Individual goal template row with cue level indicators and actions
private struct GoalTemplateRow: View {
    let template: GoalTemplate
    @ObservedObject var viewModel: AllGoalTemplatesViewModel
    @State private var showingEditView = false
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Cue level indicator
                Circle()
                    .fill(template.defaultCueLevel.color)
                    .frame(width: 12, height: 12)
                    .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(template.title)
                            .font(.headline)
                            .foregroundStyle(template.isActive ? .primary : .secondary)
                        
                        Spacer()
                        
                        if !template.isActive {
                            Text("Inactive")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(.secondary.opacity(0.2), in: Capsule())
                        }
                    }
                    
                    Text(template.category)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    if let description = template.description, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(2)
                    }
                    
                    HStack {
                        Text("Client: Loading...") // TODO: Add client name lookup
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text(template.defaultCueLevel.displayName)
                            .font(.caption)
                            .foregroundStyle(template.defaultCueLevel.color)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            showingEditView = true
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("Delete", role: .destructive) {
                showingDeleteConfirmation = true
            }
            .accessibilityLabel("Delete goal template")
            
            Button(template.isActive ? "Deactivate" : "Activate") {
                Task {
                    await viewModel.toggleTemplateActivation(template)
                }
            }
            .tint(template.isActive ? .orange : .green)
            .accessibilityLabel(template.isActive ? "Deactivate goal template" : "Activate goal template")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Goal template: \(template.title), Category: \(template.category), Cue level: \(template.defaultCueLevel.fullDisplayName)")
        .accessibilityHint("Tap to edit, swipe for more actions")
        .sheet(isPresented: $showingEditView) {
            GoalTemplateEditView(goalTemplate: template, isPresented: $showingEditView) {
                Task { await viewModel.refreshGoalTemplates() }
            }
        }
        .alert("Delete Goal Template", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteGoalTemplate(template)
                }
            }
        } message: {
            Text("Are you sure you want to delete '\(template.title)'? This action cannot be undone.")
        }
    }
}

/// Client selection view for choosing which client to assign a new goal template to
private struct ClientSelectionView: View {
    let clients: [Client]
    @Binding var isPresented: Bool
    let onClientSelected: (Client) -> Void
    
    var body: some View {
        NavigationStack {
            List(clients) { client in
                Button(action: {
                    onClientSelected(client)
                    isPresented = false
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(client.displayName)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Text(client.displayDetails)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Select Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}


/// SwiftUI preview for GoalsView
#Preview {
    GoalsView()
}