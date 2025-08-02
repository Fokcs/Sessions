import SwiftUI

/// Client creation and editing view with comprehensive form validation and modern UI design
/// 
/// **Implementation Features:**
/// - Create new clients with complete profile information
/// - Edit existing client details with pre-populated form fields
/// - Real-time form validation with user-friendly error messaging
/// - Date picker for birth date with automatic age calculation
/// - Notes field with character limits and guidance
/// - Save/Cancel actions with unsaved changes warning
/// - Comprehensive accessibility support for VoiceOver users
/// 
/// **Architecture Notes:**
/// - Follows MVVM pattern with ClientEditViewModel
/// - Integrates with SimpleCoreDataRepository via repository pattern
/// - Uses established error handling patterns with TherapyAppError
/// - Supports modern iOS design guidelines with proper form UX
struct ClientEditView: View {
    @StateObject private var viewModel = ClientEditViewModel()
    @Binding var isPresented: Bool
    @State private var showingUnsavedChangesAlert = false
    
    let client: Client?
    let onSave: () -> Void
    
    init(client: Client? = nil, isPresented: Binding<Bool>, onSave: @escaping () -> Void) {
        self.client = client
        self._isPresented = isPresented
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Personal Information Section
                Section {
                    // Name Field
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Client Name", text: $viewModel.name)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityLabel("Client name")
                            .accessibilityHint("Enter the client's full name")
                        
                        if !viewModel.name.isEmpty && !viewModel.isValid {
                            Text("Name cannot be empty")
                                .font(.caption)
                                .foregroundStyle(.red)
                                .accessibilityLabel("Error: Name cannot be empty")
                        }
                    }
                    
                    // Date of Birth Field
                    VStack(alignment: .leading, spacing: 8) {
                        DatePicker(
                            "Date of Birth",
                            selection: Binding(
                                get: { viewModel.dateOfBirth ?? Date() },
                                set: { viewModel.dateOfBirth = $0 }
                            ),
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .accessibilityLabel("Date of birth")
                        .accessibilityHint("Select the client's birth date for age calculation")
                        
                        Toggle("Include Date of Birth", isOn: Binding(
                            get: { viewModel.dateOfBirth != nil },
                            set: { isEnabled in
                                if isEnabled && viewModel.dateOfBirth == nil {
                                    viewModel.dateOfBirth = Calendar.current.date(byAdding: .year, value: -30, to: Date())
                                } else if !isEnabled {
                                    viewModel.dateOfBirth = nil
                                }
                            }
                        ))
                        .accessibilityLabel("Include date of birth")
                        .accessibilityHint("Toggle to include or exclude birth date information")
                        
                        if let dateOfBirth = viewModel.dateOfBirth {
                            let age = Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0
                            Text("Age: \(age) years")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .accessibilityLabel("Calculated age: \(age) years")
                        }
                    }
                    
                } header: {
                    Text("Personal Information")
                        .accessibilityAddTraits(.isHeader)
                } footer: {
                    Text("Client name is required. Date of birth is optional but helpful for therapy planning.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Notes Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .accessibilityAddTraits(.isHeader)
                        
                        TextEditor(text: $viewModel.notes)
                            .frame(minHeight: 100)
                            .accessibilityLabel("Client notes")
                            .accessibilityHint("Enter additional notes about the client's therapy needs or background")
                        
                        HStack {
                            Spacer()
                            Text("\(viewModel.notes.count)/500")
                                .font(.caption)
                                .foregroundStyle(viewModel.notes.count > 500 ? .red : .secondary)
                                .accessibilityLabel("Character count: \(viewModel.notes.count) of 500")
                        }
                        
                        if viewModel.notes.count > 500 {
                            Text("Notes should be 500 characters or less")
                                .font(.caption)
                                .foregroundStyle(.red)
                                .accessibilityLabel("Error: Notes should be 500 characters or less")
                        }
                    }
                    
                } header: {
                    Text("Therapy Information")
                        .accessibilityAddTraits(.isHeader)
                } footer: {
                    Text("Optional notes about therapy goals, special considerations, or relevant background information.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Form Actions Section
                if viewModel.isLoading {
                    Section {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Saving client...")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Saving client information")
                    }
                }
            }
            .navigationTitle(viewModel.title)
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
                    .accessibilityLabel("Save client")
                    .accessibilityHint("Save client information and close the form")
                }
            }
            .onAppear {
                if let client = client {
                    viewModel.loadClient(client)
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
        viewModel.notes.count <= 500
    }
    
    /// Checks if there are unsaved changes
    private var hasUnsavedChanges: Bool {
        guard let client = client else {
            // New client - check if any fields have been modified
            return !viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                   viewModel.dateOfBirth != nil ||
                   !viewModel.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        
        // Existing client - check if any fields have been modified
        let trimmedName = viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = viewModel.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let originalNotes = client.notes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        return trimmedName != client.name ||
               viewModel.dateOfBirth != client.dateOfBirth ||
               trimmedNotes != originalNotes
    }
}

/// Helper extension for date formatting
private extension Date {
    var formattedForDisplay: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: self)
    }
}

/// SwiftUI preview for ClientEditView
#Preview("New Client") {
    ClientEditView(
        client: nil,
        isPresented: .constant(true),
        onSave: { }
    )
}

#Preview("Edit Existing Client") {
    ClientEditView(
        client: Client(
            name: "John Doe",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -25, to: Date()),
            notes: "Sample therapy notes for this client"
        ),
        isPresented: .constant(true),
        onSave: { }
    )
}