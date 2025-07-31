import SwiftUI

/// Reusable SwiftUI view modifier for consistent error presentation
/// 
/// **Usage Pattern:**
/// Apply this modifier to any view that needs to display errors from ViewModels:
/// ```swift
/// ContentView()
///     .errorAlert(error: viewModel.errorMessage) {
///         viewModel.clearError()
///     }
/// ```
/// 
/// **Design Principles:**
/// - Consistent error presentation across all views
/// - User-friendly error messages with recovery actions
/// - Automatic dismissal handling
/// - Support for retry operations when applicable
/// 
/// **Accessibility:**
/// - Proper accessibility labels and hints
/// - VoiceOver support for error messages and actions
/// - High contrast support for error indicators
struct ErrorAlertModifier: ViewModifier {
    /// The error to display (nil when no error)
    let error: TherapyAppError?
    
    /// Action to perform when error is dismissed
    let onDismiss: () -> Void
    
    /// Optional retry action for retryable errors
    let onRetry: (() -> Void)?
    
    /// Initializes the error alert modifier
    /// 
    /// - Parameters:
    ///   - error: The TherapyAppError to display, or nil if no error
    ///   - onDismiss: Closure called when error alert is dismissed
    ///   - onRetry: Optional closure for retry action on retryable errors
    init(error: TherapyAppError?, onDismiss: @escaping () -> Void, onRetry: (() -> Void)? = nil) {
        self.error = error
        self.onDismiss = onDismiss
        self.onRetry = onRetry
    }
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: .constant(error != nil)) {
                // Primary action buttons
                if let error = error, error.isRetryable, let retryAction = onRetry {
                    Button("Retry") {
                        retryAction()
                        onDismiss()
                    }
                    .accessibilityHint("Retry the failed operation")
                }
                
                Button("OK") {
                    onDismiss()
                }
                .accessibilityHint("Dismiss this error message")
                
            } message: {
                VStack(alignment: .leading, spacing: 8) {
                    // Error description
                    if let errorDescription = error?.errorDescription {
                        Text(errorDescription)
                            .accessibilityLabel("Error message: \(errorDescription)")
                    }
                    
                    // Recovery suggestion
                    if let recoverySuggestion = error?.recoverySuggestion {
                        Text(recoverySuggestion)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Suggestion: \(recoverySuggestion)")
                    }
                }
            }
    }
}

/// View extension for convenient error alert usage
extension View {
    /// Presents an error alert when an error occurs
    /// 
    /// **Example Usage:**
    /// ```swift
    /// List(clients) { client in
    ///     ClientRow(client: client)
    /// }
    /// .errorAlert(error: viewModel.error) {
    ///     viewModel.clearError()
    /// }
    /// ```
    /// 
    /// - Parameters:
    ///   - error: The TherapyAppError to display
    ///   - onDismiss: Action to perform when alert is dismissed
    /// - Returns: Modified view with error alert capability
    func errorAlert(error: TherapyAppError?, onDismiss: @escaping () -> Void) -> some View {
        modifier(ErrorAlertModifier(error: error, onDismiss: onDismiss))
    }
    
    /// Presents an error alert with retry option for retryable errors
    /// 
    /// **Example Usage:**
    /// ```swift
    /// List(clients) { client in
    ///     ClientRow(client: client)
    /// }
    /// .errorAlert(error: viewModel.error, onDismiss: {
    ///     viewModel.clearError()
    /// }, onRetry: {
    ///     viewModel.retryLastOperation()
    /// })
    /// ```
    /// 
    /// - Parameters:
    ///   - error: The TherapyAppError to display
    ///   - onDismiss: Action to perform when alert is dismissed
    ///   - onRetry: Action to perform when retry button is tapped
    /// - Returns: Modified view with error alert and retry capability
    func errorAlert(
        error: TherapyAppError?,
        onDismiss: @escaping () -> Void,
        onRetry: @escaping () -> Void
    ) -> some View {
        modifier(ErrorAlertModifier(error: error, onDismiss: onDismiss, onRetry: onRetry))
    }
}

/// Legacy support for String-based error messages
/// 
/// **Note:** This extension provides backward compatibility with existing ViewModels
/// that use String error messages. New implementations should use TherapyAppError directly.
extension View {
    /// Presents an error alert for String-based error messages
    /// 
    /// **Migration Path:**
    /// This method converts String errors to TherapyAppError.unknown for consistent handling.
    /// ViewModels should be updated to use TherapyAppError directly for better error categorization.
    /// 
    /// - Parameters:
    ///   - errorMessage: String error message to display
    ///   - onDismiss: Action to perform when alert is dismissed
    /// - Returns: Modified view with error alert capability
    func errorAlert(errorMessage: String?, onDismiss: @escaping () -> Void) -> some View {
        let therapyError: TherapyAppError? = errorMessage.map { message in
            .unknown(NSError(domain: "TherapyApp", code: 0, userInfo: [NSLocalizedDescriptionKey: message]))
        }
        return errorAlert(error: therapyError, onDismiss: onDismiss)
    }
    
    /// Presents an error alert for String-based error messages with retry
    /// 
    /// - Parameters:
    ///   - errorMessage: String error message to display
    ///   - onDismiss: Action to perform when alert is dismissed  
    ///   - onRetry: Action to perform when retry button is tapped
    /// - Returns: Modified view with error alert and retry capability
    func errorAlert(
        errorMessage: String?,
        onDismiss: @escaping () -> Void,
        onRetry: @escaping () -> Void
    ) -> some View {
        let therapyError: TherapyAppError? = errorMessage.map { message in
            .unknown(NSError(domain: "TherapyApp", code: 0, userInfo: [NSLocalizedDescriptionKey: message]))
        }
        return errorAlert(error: therapyError, onDismiss: onDismiss, onRetry: onRetry)
    }
}