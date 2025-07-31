import Foundation
import CoreData

/// Custom error types for the Sessions therapy app
/// 
/// **Error Handling Strategy:**
/// This enum provides app-specific error types with user-friendly messages and recovery suggestions.
/// Each error case includes localized descriptions that can be displayed to therapists without
/// exposing technical implementation details or sensitive patient information.
/// 
/// **HIPAA Compliance:**
/// Error messages are carefully crafted to avoid exposing patient data while providing
/// actionable guidance for error recovery and troubleshooting.
/// 
/// **Usage:**
/// Replace generic Swift errors with TherapyAppError throughout the app to provide
/// consistent, user-friendly error presentation and recovery options.
enum TherapyAppError: LocalizedError {
    // MARK: - Core Data Errors
    
    /// Core Data save operation failed
    case saveFailure(NSError)
    
    /// Core Data fetch operation failed
    case fetchFailure(NSError)
    
    /// Core Data context synchronization failed
    case contextSyncFailure(NSError)
    
    /// Persistent store is unavailable or corrupted
    case persistentStoreError(NSError)
    
    // MARK: - Data Validation Errors
    
    /// Required field is missing or invalid
    case validationError(field: String, reason: String)
    
    /// Client name is required but not provided
    case clientNameRequired
    
    /// Goal template title is required but not provided
    case goalTitleRequired
    
    /// Invalid cue level provided
    case invalidCueLevel
    
    // MARK: - Business Logic Errors
    
    /// Requested client was not found
    case clientNotFound(clientId: String)
    
    /// Requested goal template was not found
    case goalTemplateNotFound(templateId: String)
    
    /// Requested session was not found
    case sessionNotFound(sessionId: String)
    
    /// Cannot start session - another session is already active
    case sessionAlreadyActive
    
    /// Cannot perform operation - no active session exists
    case noActiveSession
    
    /// Cannot delete client with existing sessions
    case clientHasSessions
    
    /// Cannot delete goal template with existing logs
    case goalTemplateHasLogs
    
    // MARK: - Network and Connectivity Errors
    
    /// Network connection is unavailable
    case networkUnavailable
    
    /// Operation timed out
    case operationTimeout
    
    /// Watch connectivity is unavailable
    case watchConnectivityUnavailable
    
    // MARK: - Generic Errors
    
    /// Unknown error occurred
    case unknown(Error)
    
    /// Operation was cancelled by user
    case cancelled
    
    // MARK: - LocalizedError Protocol Implementation
    
    /// User-facing error description
    /// Provides clear, actionable error messages without technical jargon
    var errorDescription: String? {
        switch self {
        // Core Data Errors
        case .saveFailure:
            return "Unable to save your changes. Please try again."
            
        case .fetchFailure:
            return "Unable to load data. Please check your connection and try again."
            
        case .contextSyncFailure:
            return "Data synchronization failed. Your changes may not be saved."
            
        case .persistentStoreError:
            return "Database is temporarily unavailable. Please restart the app."
            
        // Validation Errors
        case .validationError(let field, let reason):
            return "\(field): \(reason)"
            
        case .clientNameRequired:
            return "Client name is required. Please enter a name for this client."
            
        case .goalTitleRequired:
            return "Goal title is required. Please enter a title for this goal template."
            
        case .invalidCueLevel:
            return "Invalid cue level selected. Please choose a valid cue level."
            
        // Business Logic Errors
        case .clientNotFound:
            return "Client not found. The client may have been deleted or moved."
            
        case .goalTemplateNotFound:
            return "Goal template not found. The template may have been deleted."
            
        case .sessionNotFound:
            return "Session not found. The session may have been deleted."
            
        case .sessionAlreadyActive:
            return "Another session is already in progress. Please end the current session first."
            
        case .noActiveSession:
            return "No active session found. Please start a new session to continue."
            
        case .clientHasSessions:
            return "Cannot delete client with existing sessions. Archive the client instead."
            
        case .goalTemplateHasLogs:
            return "Cannot delete goal template with existing data. Deactivate the template instead."
            
        // Network Errors
        case .networkUnavailable:
            return "Network connection unavailable. Please check your internet connection."
            
        case .operationTimeout:
            return "Operation timed out. Please try again."
            
        case .watchConnectivityUnavailable:
            return "Watch connection unavailable. Please check your Apple Watch connection."
            
        // Generic Errors
        case .unknown:
            return "An unexpected error occurred. Please try again."
            
        case .cancelled:
            return "Operation was cancelled."
        }
    }
    
    /// Recovery suggestion for the user
    /// Provides specific steps the user can take to resolve the error
    var recoverySuggestion: String? {
        switch self {
        // Core Data Errors
        case .saveFailure:
            return "Try closing and reopening the app, then attempt the operation again."
            
        case .fetchFailure:
            return "Pull down to refresh the data, or restart the app if the problem persists."
            
        case .contextSyncFailure:
            return "Force close the app and reopen it to ensure data consistency."
            
        case .persistentStoreError:
            return "Restart the app. If the problem persists, contact support."
            
        // Validation Errors
        case .validationError:
            return "Please correct the highlighted field and try again."
            
        case .clientNameRequired:
            return "Enter a name for the client and try saving again."
            
        case .goalTitleRequired:
            return "Enter a title for the goal template and try saving again."
            
        case .invalidCueLevel:
            return "Select a valid cue level (Independent, Minimal, Moderate, or Maximal)."
            
        // Business Logic Errors
        case .clientNotFound:
            return "Return to the client list and select a different client."
            
        case .goalTemplateNotFound:
            return "Return to the goal template list and select a different template."
            
        case .sessionNotFound:
            return "Return to the session list and select a different session."
            
        case .sessionAlreadyActive:
            return "End the current session from the Sessions tab, then try starting a new session."
            
        case .noActiveSession:
            return "Start a new session from the Sessions tab to begin logging goals."
            
        case .clientHasSessions:
            return "Use the 'Archive Client' option instead of deleting to preserve session data."
            
        case .goalTemplateHasLogs:
            return "Use the 'Deactivate Template' option to hide it while preserving historical data."
            
        // Network Errors
        case .networkUnavailable:
            return "Check your Wi-Fi or cellular connection and try again."
            
        case .operationTimeout:
            return "Ensure you have a stable internet connection and try the operation again."
            
        case .watchConnectivityUnavailable:
            return "Ensure your Apple Watch is nearby and connected, then try again."
            
        // Generic Errors
        case .unknown:
            return "If this error continues, please restart the app or contact support."
            
        case .cancelled:
            return nil // No recovery needed for cancelled operations
        }
    }
    
    /// Failure reason for debugging and logging
    /// Provides technical details for troubleshooting without exposing to users
    var failureReason: String? {
        switch self {
        case .saveFailure(let error):
            return "Core Data save failed: \(error.localizedDescription)"
            
        case .fetchFailure(let error):
            return "Core Data fetch failed: \(error.localizedDescription)"
            
        case .contextSyncFailure(let error):
            return "Core Data context sync failed: \(error.localizedDescription)"
            
        case .persistentStoreError(let error):
            return "Persistent store error: \(error.localizedDescription)"
            
        case .validationError(let field, let reason):
            return "Validation failed for field '\(field)': \(reason)"
            
        case .clientNotFound(let clientId):
            return "Client with ID '\(clientId)' not found in database"
            
        case .goalTemplateNotFound(let templateId):
            return "Goal template with ID '\(templateId)' not found in database"
            
        case .sessionNotFound(let sessionId):
            return "Session with ID '\(sessionId)' not found in database"
            
        case .unknown(let error):
            return "Underlying error: \(error.localizedDescription)"
            
        default:
            return nil
        }
    }
    
    // MARK: - Error Classification
    
    /// Indicates if this error suggests the user should retry the operation
    var isRetryable: Bool {
        switch self {
        case .saveFailure, .fetchFailure, .contextSyncFailure:
            return true
        case .networkUnavailable, .operationTimeout, .watchConnectivityUnavailable:
            return true
        case .validationError, .clientNameRequired, .goalTitleRequired, .invalidCueLevel:
            return false
        case .clientNotFound, .goalTemplateNotFound, .sessionNotFound:
            return false
        case .sessionAlreadyActive, .noActiveSession, .clientHasSessions, .goalTemplateHasLogs:
            return false
        case .persistentStoreError, .unknown:
            return true
        case .cancelled:
            return false
        }
    }
    
    /// Indicates if this error requires immediate user attention
    var isCritical: Bool {
        switch self {
        case .persistentStoreError:
            return true
        case .sessionAlreadyActive, .clientHasSessions, .goalTemplateHasLogs:
            return true
        default:
            return false
        }
    }
    
    /// Category of error for analytics and debugging
    var category: String {
        switch self {
        case .saveFailure, .fetchFailure, .contextSyncFailure, .persistentStoreError:
            return "CoreData"
        case .validationError, .clientNameRequired, .goalTitleRequired, .invalidCueLevel:
            return "Validation"
        case .clientNotFound, .goalTemplateNotFound, .sessionNotFound, .sessionAlreadyActive, .noActiveSession, .clientHasSessions, .goalTemplateHasLogs:
            return "BusinessLogic"
        case .networkUnavailable, .operationTimeout, .watchConnectivityUnavailable:
            return "Network"
        case .unknown, .cancelled:
            return "Generic"
        }
    }
}

// MARK: - Convenience Factory Methods

extension TherapyAppError {
    /// Create a TherapyAppError from a Core Data NSError
    static func coreDataError(_ error: NSError) -> TherapyAppError {
        // Analyze the Core Data error code to provide specific error types
        switch error.code {
        case NSManagedObjectValidationError, NSValidationMissingMandatoryPropertyError:
            return .validationError(field: "Data", reason: "Required information is missing")
        case NSManagedObjectContextLockingError, NSPersistentStoreTimeoutError:
            return .contextSyncFailure(error)
        case NSPersistentStoreOpenError, NSPersistentStoreIncompatibleVersionHashError:
            return .persistentStoreError(error)
        case NSManagedObjectReferentialIntegrityError:
            return .saveFailure(error)
        default:
            return .unknown(error)
        }
    }
    
    /// Create a validation error with field and reason
    static func validation(field: String, reason: String) -> TherapyAppError {
        return .validationError(field: field, reason: reason)
    }
    
    /// Create a not found error with entity type and ID
    static func notFound(entity: String, id: String) -> TherapyAppError {
        switch entity.lowercased() {
        case "client":
            return .clientNotFound(clientId: id)
        case "goaltemplate", "goal":
            return .goalTemplateNotFound(templateId: id)
        case "session":
            return .sessionNotFound(sessionId: id)
        default:
            return .unknown(NSError(domain: "TherapyApp", code: 404, userInfo: [NSLocalizedDescriptionKey: "\(entity) with ID \(id) not found"]))
        }
    }
}