import SwiftUI

/// Detailed client profile view displaying client information, session statistics, and goal templates
/// 
/// **Implementation Features:**
/// - Complete client profile with personal details and therapy information
/// - Goal templates list with creation, editing, and management capabilities
/// - Session count and activity summary
/// - Edit and delete client functionality with confirmation dialogs
/// - Comprehensive accessibility support for VoiceOver users
/// 
/// **Architecture Notes:**
/// - Follows MVVM pattern with ClientDetailViewModel
/// - Integrates with SimpleCoreDataRepository via repository pattern
/// - Uses established error handling patterns with TherapyAppError
/// - Supports modern iOS design guidelines with SF Symbols
struct ClientDetailView: View {
    let clientId: UUID
    @StateObject private var viewModel: ClientDetailViewModel
    @State private var showingEditView = false
    @State private var showingDeleteAlert = false
    @State private var navigateBackAfterDelete = false
    @Environment(\.dismiss) private var dismiss
    
    init(clientId: UUID) {
        self.clientId = clientId
        self._viewModel = StateObject(wrappedValue: ClientDetailViewModel(clientId: clientId))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    LoadingView()
                } else if let client = viewModel.client {
                    ClientDetailContent(
                        client: client,
                        goalTemplates: viewModel.goalTemplates,
                        onEditClient: { showingEditView = true },
                        onDeleteClient: { showingDeleteAlert = true }
                    )
                } else {
                    ClientNotFoundView()
                }
            }
            .navigationTitle(viewModel.client?.displayName ?? "Client")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.refreshData()
            }
            .errorAlert(errorMessage: viewModel.errorMessage) {
                // Clear error when dismissed - viewModel should have clearError method
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if viewModel.client != nil {
                        Button(action: { showingEditView = true }) {
                            Image(systemName: "pencil")
                        }
                        .accessibilityLabel("Edit client")
                        .accessibilityHint("Opens client editing form")
                    }
                }
            }
        }
        .task {
            await viewModel.loadClient()
        }
        .sheet(isPresented: $showingEditView) {
            if let client = viewModel.client {
                ClientEditView(client: client, isPresented: $showingEditView) {
                    // Refresh client data after edit
                    Task { await viewModel.refreshData() }
                }
            }
        }
        .alert("Delete Client", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    let success = await viewModel.deleteClient()
                    if success {
                        navigateBackAfterDelete = true
                        dismiss()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this client? This action cannot be undone and will remove all associated goal templates and session data.")
        }
        .onChange(of: navigateBackAfterDelete) {
            if navigateBackAfterDelete {
                dismiss()
            }
        }
    }
}

/// Main content view displaying client details and goal templates
private struct ClientDetailContent: View {
    let client: Client
    let goalTemplates: [GoalTemplate]
    let onEditClient: () -> Void
    let onDeleteClient: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Client Profile Section
                ClientProfileSection(client: client)
                
                // Statistics Section
                ClientStatisticsSection(client: client, goalTemplateCount: goalTemplates.count)
                
                // Goal Templates Section
                GoalTemplatesSection(goalTemplates: goalTemplates, clientId: client.id)
            }
            .padding()
        }
    }
}

/// Client profile information section
private struct ClientProfileSection: View {
    let client: Client
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Icon
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.primary)
                .accessibilityHidden(true)
            
            // Client Name and Details
            VStack(spacing: 8) {
                Text(client.displayName)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .accessibilityAddTraits(.isHeader)
                
                Text(client.displayDetails)
                    .font(.body)
                    .foregroundStyle(.secondary)
                
                if let notes = client.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Client profile: \(client.displayName), \(client.displayDetails)")
    }
}

/// Client statistics section showing counts and activity
private struct ClientStatisticsSection: View {
    let client: Client
    let goalTemplateCount: Int
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Activity Summary")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            
            HStack(spacing: 20) {
                StatisticCard(
                    icon: "target",
                    title: "Goal Templates",
                    value: "\(goalTemplateCount)",
                    description: goalTemplateCount == 1 ? "template" : "templates"
                )
                
                StatisticCard(
                    icon: "clock.fill",
                    title: "Sessions",
                    value: "0", // TODO: Add session count from repository
                    description: "completed"
                )
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

/// Individual statistic card component
private struct StatisticCard: View {
    let icon: String
    let title: String
    let value: String
    let description: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value) \(description)")
    }
}

/// Goal templates section with list of client's goal templates
private struct GoalTemplatesSection: View {
    let goalTemplates: [GoalTemplate]
    let clientId: UUID
    @State private var showingCreateGoalTemplate = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Goal Templates")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                
                Spacer()
                
                Button(action: { showingCreateGoalTemplate = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .accessibilityLabel("Add goal template")
                .accessibilityHint("Creates a new goal template for this client")
            }
            
            if goalTemplates.isEmpty {
                EmptyGoalTemplatesView()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(goalTemplates) { template in
                        GoalTemplateRow(template: template)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .sheet(isPresented: $showingCreateGoalTemplate) {
            GoalTemplateEditView(clientId: clientId, isPresented: $showingCreateGoalTemplate) {
                // Refresh goal templates after creation
                // This will be handled by the parent view model
            }
        }
    }
}

/// Empty state for when client has no goal templates
private struct EmptyGoalTemplatesView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "target")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            
            Text("No Goal Templates")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text("Add your first goal template to start tracking therapy progress")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No goal templates. Add your first goal template to start tracking therapy progress")
    }
}

/// Individual goal template row component
private struct GoalTemplateRow: View {
    let template: GoalTemplate
    @State private var showingEditView = false
    
    var body: some View {
        Button(action: { showingEditView = true }) {
            HStack(spacing: 12) {
                // Cue level indicator
                Circle()
                    .fill(template.defaultCueLevel.color)
                    .frame(width: 12, height: 12)
                    .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        Text(template.category)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text(template.defaultCueLevel.displayName)
                            .font(.caption)
                            .foregroundStyle(template.defaultCueLevel.color)
                            .fontWeight(.medium)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .padding()
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Goal template: \(template.title), Category: \(template.category), Cue level: \(template.defaultCueLevel.fullDisplayName)")
        .accessibilityHint("Tap to edit this goal template")
        .sheet(isPresented: $showingEditView) {
            GoalTemplateEditView(goalTemplate: template, isPresented: $showingEditView) {
                // Refresh will be handled by parent view model
            }
        }
    }
}

/// Loading state view for client data fetch
private struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading client details...")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading client details")
    }
}

/// Error state view when client is not found
private struct ClientNotFoundView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.slash")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            
            VStack(spacing: 12) {
                Text("Client Not Found")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("The requested client could not be found. They may have been deleted or you may not have permission to view this client.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Client not found. The requested client could not be found.")
    }
}



/// SwiftUI preview for ClientDetailView
#Preview {
    NavigationStack {
        ClientDetailView(clientId: UUID())
    }
}