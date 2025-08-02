import SwiftUI

/// Goal template creation and editing view with comprehensive form validation and cue level selection
/// 
/// **Implementation Features:**
/// - Create new goal templates with complete template information
/// - Edit existing goal templates with pre-populated form fields
/// - Real-time form validation with user-friendly error messaging
/// - Category selection with common therapy categories
/// - Cue level selection with visual indicators and descriptions
/// - Character limits and guidance for description field
/// - Save/Cancel actions with unsaved changes warning
/// - Comprehensive accessibility support for VoiceOver users
/// 
/// **Architecture Notes:**
/// - Follows MVVM pattern with GoalTemplateEditViewModel
/// - Integrates with SimpleCoreDataRepository via repository pattern
/// - Uses established error handling patterns with TherapyAppError
/// - Supports modern iOS design guidelines with proper form UX
struct GoalTemplateEditView: View {
    @StateObject private var viewModel: GoalTemplateEditViewModel
    @Binding var isPresented: Bool
    @State private var showingUnsavedChangesAlert = false
    
    let goalTemplate: GoalTemplate?
    let onSave: () -> Void
    
    init(goalTemplate: GoalTemplate? = nil, clientId: UUID? = nil, isPresented: Binding<Bool>, onSave: @escaping () -> Void) {
        self.goalTemplate = goalTemplate
        self._isPresented = isPresented
        self.onSave = onSave
        
        // Use clientId from parameter or existing template
        let clientForTemplate = clientId ?? goalTemplate?.clientId ?? UUID()
        self._viewModel = StateObject(wrappedValue: GoalTemplateEditViewModel(clientId: clientForTemplate))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Template Information Section
                Section {
                    // Title Field
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Goal Template Title", text: $viewModel.title)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityLabel("Goal template title")
                            .accessibilityHint("Enter a descriptive title for this therapy goal")
                        
                        if !viewModel.title.isEmpty && !viewModel.isValid {
                            Text("Title cannot be empty")
                                .font(.caption)
                                .foregroundStyle(.red)
                                .accessibilityLabel("Error: Title cannot be empty")
                        }
                    }
                    
                    // Category Selection
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Category")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Menu {
                                ForEach(commonTherapyCategories, id: \.self) { category in
                                    Button(category) {
                                        viewModel.category = category
                                    }
                                }
                                
                                Divider()
                                
                                Button("Custom Category") {
                                    // Keep current text for custom input
                                }
                            } label: {
                                HStack {
                                    Text("Select Category")
                                        .font(.caption)
                                    Image(systemName: "chevron.down")
                                        .font(.caption2)
                                }
                                .foregroundStyle(.secondary)
                            }
                            .accessibilityLabel("Select therapy category")
                        }
                        
                        TextField("Enter category", text: $viewModel.category)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityLabel("Therapy category")
                            .accessibilityHint("Enter or select the therapy category for this goal")
                        
                        if !viewModel.category.isEmpty && !viewModel.isValid && !viewModel.title.isEmpty {
                            Text("Category cannot be empty")
                                .font(.caption)
                                .foregroundStyle(.red)
                                .accessibilityLabel("Error: Category cannot be empty")
                        }
                    }
                    
                } header: {
                    Text("Goal Information")
                        .accessibilityAddTraits(.isHeader)
                } footer: {
                    Text("Goal title and category are required for organizing therapy objectives.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Description Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .accessibilityAddTraits(.isHeader)
                        
                        TextEditor(text: $viewModel.description)
                            .frame(minHeight: 80)
                            .accessibilityLabel("Goal description")
                            .accessibilityHint("Enter detailed description or instructions for this therapy goal")
                        
                        HStack {
                            Spacer()
                            Text("\(viewModel.description.count)/300")
                                .font(.caption)
                                .foregroundStyle(viewModel.description.count > 300 ? .red : .secondary)
                                .accessibilityLabel("Character count: \(viewModel.description.count) of 300")
                        }
                        
                        if viewModel.description.count > 300 {
                            Text("Description should be 300 characters or less")
                                .font(.caption)
                                .foregroundStyle(.red)
                                .accessibilityLabel("Error: Description should be 300 characters or less")
                        }
                    }
                    
                } header: {
                    Text("Goal Details")
                        .accessibilityAddTraits(.isHeader)
                } footer: {
                    Text("Optional detailed description with implementation instructions or specific criteria.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Cue Level Selection Section
                Section {
                    CueLevelSelectionView(selectedCueLevel: $viewModel.defaultCueLevel)
                    
                } header: {
                    Text("Default Cue Level")
                        .accessibilityAddTraits(.isHeader)
                } footer: {
                    Text("The typical level of assistance needed for this goal. This can be adjusted during individual therapy sessions.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Form Actions Section
                if viewModel.isLoading {
                    Section {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Saving goal template...")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Saving goal template")
                    }
                }
            }
            .navigationTitle(viewModel.formTitle)
            .navigationBarTitleDisplayMode(.inline)
            .errorAlert(errorMessage: viewModel.errorMessage) {
                // Error handling - viewModel manages error state
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if hasUnsavedChanges {
                            showingUnsavedChangesAlert = true
                        } else {
                            isPresented = false
                        }
                    }
                    .accessibilityLabel("Cancel editing")
                    .accessibilityHint("Discard changes and close the form")
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            let success = await viewModel.save()
                            if success {
                                onSave()
                                isPresented = false
                            }
                        }
                    }
                    .disabled(!canSave)
                    .accessibilityLabel("Save goal template")
                    .accessibilityHint("Save goal template and close the form")
                }
            }
            .onAppear {
                if let template = goalTemplate {
                    viewModel.loadGoalTemplate(template)
                }
            }
            .alert("Unsaved Changes", isPresented: $showingUnsavedChangesAlert) {
                Button("Discard Changes", role: .destructive) {
                    isPresented = false
                }
                Button("Continue Editing", role: .cancel) { }
            } message: {
                Text("You have unsaved changes. Are you sure you want to discard them?")
            }
            .interactiveDismissDisabled(hasUnsavedChanges)
        }
    }
    
    // MARK: - Computed Properties
    
    /// Determines if the form can be saved
    private var canSave: Bool {
        viewModel.isValid && 
        !viewModel.isLoading && 
        viewModel.description.count <= 300
    }
    
    /// Checks if there are unsaved changes
    private var hasUnsavedChanges: Bool {
        guard let template = goalTemplate else {
            // New template - check if any fields have been modified
            return !viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                   !viewModel.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                   !viewModel.category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                   viewModel.defaultCueLevel != .independent
        }
        
        // Existing template - check if any fields have been modified
        let trimmedTitle = viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = viewModel.description.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCategory = viewModel.category.trimmingCharacters(in: .whitespacesAndNewlines)
        let originalDescription = template.description?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        return trimmedTitle != template.title ||
               trimmedDescription != originalDescription ||
               trimmedCategory != template.category ||
               viewModel.defaultCueLevel != template.defaultCueLevel
    }
    
    /// Common therapy categories for quick selection
    private var commonTherapyCategories: [String] {
        [
            "Speech Therapy",
            "Language Development", 
            "Articulation",
            "Voice Therapy",
            "ABA Therapy",
            "Social Skills",
            "Communication",
            "Play Skills",
            "Academic Skills",
            "Occupational Therapy",
            "Fine Motor Skills",
            "Gross Motor Skills",
            "Sensory Processing",
            "Cognitive Therapy",
            "Memory Skills",
            "Problem Solving"
        ]
    }
}

/// Cue level selection component with visual indicators
private struct CueLevelSelectionView: View {
    @Binding var selectedCueLevel: CueLevel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(CueLevel.allCases, id: \.self) { cueLevel in
                CueLevelOption(
                    cueLevel: cueLevel,
                    isSelected: selectedCueLevel == cueLevel,
                    onSelect: { selectedCueLevel = cueLevel }
                )
            }
        }
    }
}

/// Individual cue level option with description and visual indicator
private struct CueLevelOption: View {
    let cueLevel: CueLevel
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(cueLevel.color, lineWidth: 2)
                        .frame(width: 20, height: 20)
                    
                    if isSelected {
                        Circle()
                            .fill(cueLevel.color)
                            .frame(width: 12, height: 12)
                    }
                }
                .accessibilityHidden(true)
                
                // Cue level info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(cueLevel.fullDisplayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        // Visual cue level indicator
                        Circle()
                            .fill(cueLevel.color)
                            .frame(width: 8, height: 8)
                            .accessibilityHidden(true)
                    }
                    
                    Text(cueLevelDescription(for: cueLevel))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                isSelected ? cueLevel.color.opacity(0.1) : Color.clear,
                in: RoundedRectangle(cornerRadius: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? cueLevel.color : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(cueLevel.fullDisplayName) - \(cueLevelDescription(for: cueLevel))")
        .accessibilityHint(isSelected ? "Currently selected" : "Tap to select this cue level")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    
    /// Returns a user-friendly description for each cue level
    private func cueLevelDescription(for cueLevel: CueLevel) -> String {
        switch cueLevel {
        case .independent:
            return "Client performs task without any assistance or prompting"
        case .minimal:
            return "Client needs slight prompting, encouragement, or verbal cues"
        case .moderate:
            return "Client requires regular assistance, modeling, or physical guidance"
        case .maximal:
            return "Client needs significant support or hand-over-hand assistance"
        }
    }
}

/// SwiftUI preview for GoalTemplateEditView
#Preview("New Goal Template") {
    GoalTemplateEditView(
        clientId: UUID(),
        isPresented: .constant(true),
        onSave: { }
    )
}

#Preview("Edit Existing Goal Template") {
    GoalTemplateEditView(
        goalTemplate: GoalTemplate(
            title: "Improve Articulation",
            description: "Practice /r/ sound production in words and sentences",
            category: "Speech Therapy",
            defaultCueLevel: .minimal,
            clientId: UUID()
        ),
        isPresented: .constant(true),
        onSave: { }
    )
}