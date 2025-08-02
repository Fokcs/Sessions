import SwiftUI

/// Non-blocking error banner for inline error display
/// 
/// **Usage Pattern:**
/// Display errors inline within views without blocking user interaction:
/// ```swift
/// VStack {
///     ErrorBanner(error: viewModel.error) {
///         viewModel.clearError()
///     }
///     ContentView()
/// }
/// ```
/// 
/// **Design Principles:**
/// - Non-intrusive error display that doesn't block workflow
/// - Dismissible by user interaction
/// - Visual prominence for critical errors
/// - Smooth animations for better user experience
/// 
/// **Use Cases:**
/// - Form validation errors
/// - Network connectivity issues
/// - Background operation failures
/// - Non-critical warnings and notices
struct ErrorBanner: View {
    /// The error to display
    let error: TherapyAppError?
    
    /// Action to perform when banner is dismissed
    let onDismiss: () -> Void
    
    /// Optional retry action for retryable errors
    let onRetry: (() -> Void)?
    
    /// Controls banner visibility with animation
    @State private var isVisible: Bool = false
    
    /// Auto-dismiss timer for non-critical errors
    @State private var dismissTimer: Timer?
    
    /// Initializes the error banner
    /// 
    /// - Parameters:
    ///   - error: The TherapyAppError to display
    ///   - onDismiss: Closure called when banner is dismissed
    ///   - onRetry: Optional closure for retry action
    init(error: TherapyAppError?, onDismiss: @escaping () -> Void, onRetry: (() -> Void)? = nil) {
        self.error = error
        self.onDismiss = onDismiss
        self.onRetry = onRetry
    }
    
    var body: some View {
        if let error = error, isVisible {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    // Error icon
                    Image(systemName: errorIcon(for: error))
                        .foregroundStyle(errorColor(for: error))
                        .font(.system(size: 20, weight: .medium))
                        .accessibilityHidden(true)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // Error message
                        Text(error.errorDescription ?? "An error occurred")
                            .font(.system(.body, design: .default, weight: .medium))
                            .foregroundStyle(.primary)
                        
                        // Recovery suggestion (if available)
                        if let suggestion = error.recoverySuggestion {
                            Text(suggestion)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    HStack(spacing: 8) {
                        // Retry button for retryable errors
                        if error.isRetryable, let retryAction = onRetry {
                            Button("Retry") {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    retryAction()
                                    dismissBanner()
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .accessibilityHint("Retry the failed operation")
                        }
                        
                        // Dismiss button
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                dismissBanner()
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Dismiss error")
                        .accessibilityHint("Hide this error message")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(errorBackgroundColor(for: error))
                        .stroke(errorColor(for: error), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
            .padding(.horizontal, 16)
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .move(edge: .top).combined(with: .opacity)
            ))
            .onAppear {
                startAutoDismissTimer(for: error)
            }
            .onDisappear {
                dismissTimer?.invalidate()
                dismissTimer = nil
            }
        } else {
            EmptyView()
                .onAppear {
                    if error != nil {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isVisible = true
                        }
                    }
                }
                .onChange(of: error) { newError in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isVisible = newError != nil
                    }
                }
        }
    }
    
    // MARK: - Private Methods
    
    /// Dismisses the banner with animation
    private func dismissBanner() {
        dismissTimer?.invalidate()
        dismissTimer = nil
        isVisible = false
        onDismiss()
    }
    
    /// Starts auto-dismiss timer for non-critical errors
    private func startAutoDismissTimer(for error: TherapyAppError) {
        // Only auto-dismiss non-critical errors
        guard !error.isCritical else { return }
        
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                dismissBanner()
            }
        }
    }
    
    /// Returns appropriate icon for error type
    private func errorIcon(for error: TherapyAppError) -> String {
        if error.isCritical {
            return "exclamationmark.triangle.fill"
        } else if error.isRetryable {
            return "arrow.clockwise.circle.fill"
        } else {
            return "info.circle.fill"
        }
    }
    
    /// Returns appropriate color for error type
    private func errorColor(for error: TherapyAppError) -> Color {
        if error.isCritical {
            return .red
        } else if error.category == "Network" {
            return .orange
        } else if error.category == "Validation" {
            return .blue
        } else {
            return .secondary
        }
    }
    
    /// Returns appropriate background color for error type
    private func errorBackgroundColor(for error: TherapyAppError) -> Color {
        if error.isCritical {
            return .red.opacity(0.1)
        } else if error.category == "Network" {
            return .orange.opacity(0.1)
        } else if error.category == "Validation" {
            return .blue.opacity(0.1)
        } else {
            return Color.gray.opacity(0.1)
        }
    }
}

/// View extension for convenient error banner usage
extension View {
    /// Displays an error banner above the content
    /// 
    /// **Example Usage:**
    /// ```swift
    /// ContentView()
    ///     .errorBanner(error: viewModel.error) {
    ///         viewModel.clearError()
    ///     }
    /// ```
    /// 
    /// - Parameters:
    ///   - error: The TherapyAppError to display
    ///   - onDismiss: Action to perform when banner is dismissed
    /// - Returns: Modified view with error banner
    func errorBanner(error: TherapyAppError?, onDismiss: @escaping () -> Void) -> some View {
        VStack(spacing: 0) {
            ErrorBanner(error: error, onDismiss: onDismiss)
            self
        }
    }
    
    /// Displays an error banner with retry option
    /// 
    /// - Parameters:
    ///   - error: The TherapyAppError to display
    ///   - onDismiss: Action to perform when banner is dismissed
    ///   - onRetry: Action to perform when retry button is tapped
    /// - Returns: Modified view with error banner and retry capability
    func errorBanner(
        error: TherapyAppError?,
        onDismiss: @escaping () -> Void,
        onRetry: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 0) {
            ErrorBanner(error: error, onDismiss: onDismiss, onRetry: onRetry)
            self
        }
    }
}

/// Legacy support for String-based error messages
extension View {
    /// Displays an error banner for String-based error messages
    /// 
    /// **Migration Path:**
    /// This method converts String errors to TherapyAppError.unknown for consistent handling.
    /// ViewModels should be updated to use TherapyAppError directly.
    /// 
    /// - Parameters:
    ///   - errorMessage: String error message to display
    ///   - onDismiss: Action to perform when banner is dismissed
    /// - Returns: Modified view with error banner
    func errorBanner(errorMessage: String?, onDismiss: @escaping () -> Void) -> some View {
        let therapyError: TherapyAppError? = errorMessage.map { message in
            .unknown(NSError(domain: "TherapyApp", code: 0, userInfo: [NSLocalizedDescriptionKey: message]))
        }
        return errorBanner(error: therapyError, onDismiss: onDismiss)
    }
    
    /// Displays an error banner for String-based error messages with retry
    /// 
    /// - Parameters:
    ///   - errorMessage: String error message to display
    ///   - onDismiss: Action to perform when banner is dismissed
    ///   - onRetry: Action to perform when retry button is tapped
    /// - Returns: Modified view with error banner and retry capability
    func errorBanner(
        errorMessage: String?,
        onDismiss: @escaping () -> Void,
        onRetry: @escaping () -> Void
    ) -> some View {
        let therapyError: TherapyAppError? = errorMessage.map { message in
            .unknown(NSError(domain: "TherapyApp", code: 0, userInfo: [NSLocalizedDescriptionKey: message]))
        }
        return errorBanner(error: therapyError, onDismiss: onDismiss, onRetry: onRetry)
    }
}

// MARK: - Previews

#Preview("Critical Error") {
    VStack {
        ErrorBanner(
            error: .persistentStoreError(NSError(domain: "CoreData", code: 0, userInfo: [:])),
            onDismiss: {}
        )
        Spacer()
    }
    .padding()
}

#Preview("Retryable Error") {
    VStack {
        ErrorBanner(
            error: .networkUnavailable,
            onDismiss: {},
            onRetry: {}
        )
        Spacer()
    }
    .padding()
}

#Preview("Validation Error") {
    VStack {
        ErrorBanner(
            error: .clientNameRequired,
            onDismiss: {}
        )
        Spacer()
    }
    .padding()
}