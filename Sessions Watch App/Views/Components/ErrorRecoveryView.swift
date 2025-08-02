import SwiftUI

/// Full-screen error recovery view for critical errors and empty states
/// 
/// **Usage Pattern:**
/// Display when content cannot be loaded or critical errors require user intervention:
/// ```swift
/// if let error = viewModel.criticalError {
///     ErrorRecoveryView(error: error) {
///         viewModel.retry()
///     }
/// } else {
///     ContentView()
/// }
/// ```
/// 
/// **Design Principles:**
/// - Clear, professional error presentation
/// - Prominent recovery actions
/// - Helpful context and guidance
/// - Maintains app branding and accessibility
/// 
/// **Use Cases:**
/// - Database connection failures
/// - Network unavailable states
/// - Data loading errors
/// - Critical system errors
/// - Empty state with errors
struct ErrorRecoveryView: View {
    /// The error requiring recovery action
    let error: TherapyAppError
    
    /// Primary recovery action (e.g., "Retry", "Reload")
    let primaryAction: (() -> Void)?
    
    /// Secondary action (e.g., "Go Back", "Settings")
    let secondaryAction: (() -> Void)?
    
    /// Custom primary action title
    let primaryActionTitle: String
    
    /// Custom secondary action title
    let secondaryActionTitle: String?
    
    /// Initializes error recovery view with single action
    /// 
    /// - Parameters:
    ///   - error: The TherapyAppError requiring recovery
    ///   - primaryActionTitle: Title for primary action button
    ///   - primaryAction: Closure for primary recovery action
    init(
        error: TherapyAppError,
        primaryActionTitle: String = "Try Again",
        primaryAction: (() -> Void)? = nil
    ) {
        self.error = error
        self.primaryAction = primaryAction
        self.secondaryAction = nil
        self.primaryActionTitle = primaryActionTitle
        self.secondaryActionTitle = nil
    }
    
    /// Initializes error recovery view with primary and secondary actions
    /// 
    /// - Parameters:
    ///   - error: The TherapyAppError requiring recovery
    ///   - primaryActionTitle: Title for primary action button
    ///   - primaryAction: Closure for primary recovery action
    ///   - secondaryActionTitle: Title for secondary action button
    ///   - secondaryAction: Closure for secondary action
    init(
        error: TherapyAppError,
        primaryActionTitle: String = "Try Again",
        primaryAction: (() -> Void)? = nil,
        secondaryActionTitle: String,
        secondaryAction: @escaping () -> Void
    ) {
        self.error = error
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
        self.primaryActionTitle = primaryActionTitle
        self.secondaryActionTitle = secondaryActionTitle
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Error icon and visual
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(errorColor.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: errorIcon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(errorColor)
                }
                .accessibilityHidden(true)
                
                // Error title
                Text(errorTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
            }
            
            // Error description and recovery guidance
            VStack(spacing: 12) {
                if let description = error.errorDescription {
                    Text(description)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .accessibilityLabel("Error description: \(description)")
                }
                
                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .accessibilityLabel("Recovery suggestion: \(suggestion)")
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 12) {
                // Primary action button
                if let primaryAction = primaryAction {
                    Button(action: primaryAction) {
                        HStack {
                            if error.isRetryable {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            Text(primaryActionTitle)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .accessibilityHint("Performs the primary recovery action")
                }
                
                // Secondary action button
                if let secondaryAction = secondaryAction,
                   let secondaryTitle = secondaryActionTitle {
                    Button(action: secondaryAction) {
                        Text(secondaryTitle)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.gray.opacity(0.1))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .accessibilityHint("Performs the secondary action")
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
    
    // MARK: - Private Computed Properties
    
    /// Error-specific icon
    private var errorIcon: String {
        switch error.category {
        case "CoreData":
            return "externaldrive.fill.trianglebadge.exclamationmark"
        case "Network":
            return "wifi.exclamationmark"
        case "Validation":
            return "exclamationmark.circle.fill"
        case "BusinessLogic":
            return "person.crop.circle.badge.exclamationmark"
        default:
            return "exclamationmark.triangle.fill"
        }
    }
    
    /// Error-specific color
    private var errorColor: Color {
        if error.isCritical {
            return .red
        } else {
            switch error.category {
            case "Network":
                return .orange
            case "Validation":
                return .blue
            case "CoreData":
                return .purple
            case "BusinessLogic":
                return .green
            default:
                return .gray
            }
        }
    }
    
    /// Error-specific title
    private var errorTitle: String {
        switch error {
        case .persistentStoreError:
            return "Database Unavailable"
        case .networkUnavailable:
            return "No Internet Connection"
        case .fetchFailure:
            return "Unable to Load Data"
        case .saveFailure:
            return "Unable to Save Changes"
        case .clientNotFound, .goalTemplateNotFound, .sessionNotFound:
            return "Item Not Found"
        case .sessionAlreadyActive:
            return "Session Already Active"
        case .noActiveSession:
            return "No Active Session"
        case .validationError, .clientNameRequired, .goalTitleRequired:
            return "Invalid Information"
        default:
            return "Something Went Wrong"
        }
    }
}

/// View extension for convenient error recovery usage
extension View {
    /// Overlays error recovery view when error is present
    /// 
    /// **Example Usage:**
    /// ```swift
    /// ContentView()
    ///     .errorRecovery(error: viewModel.criticalError) {
    ///         viewModel.retry()
    ///     }
    /// ```
    /// 
    /// - Parameters:
    ///   - error: Optional TherapyAppError to display
    ///   - primaryAction: Primary recovery action
    /// - Returns: Modified view with error recovery overlay
    func errorRecovery(
        error: TherapyAppError?,
        primaryAction: @escaping () -> Void
    ) -> some View {
        ZStack {
            self
            
            if let error = error {
                ErrorRecoveryView(error: error, primaryAction: primaryAction)
                    .transition(.opacity.combined(with: .scale))
            }
        }
    }
    
    /// Overlays error recovery view with secondary action
    /// 
    /// - Parameters:
    ///   - error: Optional TherapyAppError to display
    ///   - primaryAction: Primary recovery action
    ///   - secondaryActionTitle: Title for secondary action
    ///   - secondaryAction: Secondary action closure
    /// - Returns: Modified view with error recovery overlay
    func errorRecovery(
        error: TherapyAppError?,
        primaryAction: @escaping () -> Void,
        secondaryActionTitle: String,
        secondaryAction: @escaping () -> Void
    ) -> some View {
        ZStack {
            self
            
            if let error = error {
                ErrorRecoveryView(
                    error: error,
                    primaryAction: primaryAction,
                    secondaryActionTitle: secondaryActionTitle,
                    secondaryAction: secondaryAction
                )
                .transition(.opacity.combined(with: .scale))
            }
        }
    }
}

// MARK: - Specialized Error Recovery Views

/// Empty state with error for lists and collections
struct EmptyStateErrorView: View {
    let error: TherapyAppError
    let itemType: String
    let onRetry: () -> Void
    let onCreate: (() -> Void)?
    
    init(
        error: TherapyAppError,
        itemType: String,
        onRetry: @escaping () -> Void,
        onCreate: (() -> Void)? = nil
    ) {
        self.error = error
        self.itemType = itemType
        self.onRetry = onRetry
        self.onCreate = onCreate
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                Text("No \(itemType) Available")
                    .font(.headline)
                
                Text(error.errorDescription ?? "Unable to load \(itemType.lowercased())")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                Button("Try Again", action: onRetry)
                    .buttonStyle(.borderedProminent)
                
                if let createAction = onCreate {
                    Button("Create \(itemType)") {
                        createAction()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(32)
    }
}

// MARK: - Previews

#Preview("Network Error") {
    ErrorRecoveryView(
        error: .networkUnavailable,
        primaryAction: {}
    )
}

#Preview("Database Error") {
    ErrorRecoveryView(
        error: .persistentStoreError(NSError(domain: "CoreData", code: 0, userInfo: [:])),
        primaryAction: {},
        secondaryActionTitle: "Contact Support",
        secondaryAction: {}
    )
}

#Preview("Empty State Error") {
    EmptyStateErrorView(
        error: .fetchFailure(NSError(domain: "CoreData", code: 0, userInfo: [:])),
        itemType: "Clients",
        onRetry: {},
        onCreate: {}
    )
}