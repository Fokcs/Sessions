import Foundation

/// Swift model struct representing a therapy client
/// 
/// **HIPAA Compliance Considerations:**
/// - Contains PHI (Protected Health Information) including name and date of birth
/// - Includes privacy-focused display methods to limit data exposure
/// - Designed for secure storage with Core Data file protection
/// 
/// **Core Data Relationship:**
/// - Maps to CDClient entity in TherapyDataModel.xcdatamodeld
/// - Serves as value type for repository pattern data access
/// - Supports Codable for potential future sync/export functionality
/// 
/// **Architecture Notes:**
/// - Immutable struct design for thread safety
/// - UUID-based identification for global uniqueness
/// - Computed properties for derived data (age, display formatting)
struct Client: Identifiable, Codable, Equatable {
    /// Unique identifier for the client
    /// Used for Core Data relationships and cross-platform sync
    let id: UUID
    
    /// Client's full name (PHI - Protected Health Information)
    /// HIPAA Note: Consider data minimization in UI displays
    let name: String
    
    /// Optional date of birth for age calculation (PHI)
    /// Used for therapy planning and progress tracking
    let dateOfBirth: Date?
    
    /// Optional therapy notes and observations
    /// May contain sensitive treatment information
    let notes: String?
    
    /// Timestamp when client record was created
    /// Used for data auditing and HIPAA compliance tracking
    let createdDate: Date
    
    /// Timestamp of last modification
    /// Updated whenever client data changes
    let lastModified: Date
    
    /// Convenience initializer for creating new clients
    /// Automatically sets creation and modification timestamps
    /// 
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - name: Client's full name
    ///   - dateOfBirth: Optional birth date for age calculation
    ///   - notes: Optional therapy notes
    init(id: UUID = UUID(), name: String, dateOfBirth: Date? = nil, notes: String? = nil) {
        self.id = id
        self.name = name
        self.dateOfBirth = dateOfBirth
        self.notes = notes
        self.createdDate = Date()
        self.lastModified = Date()
    }
    
    /// Full initializer for reconstructing clients from persistent storage
    /// Used by repository layer when loading from Core Data
    /// 
    /// - Parameters:
    ///   - id: Unique identifier
    ///   - name: Client's full name
    ///   - dateOfBirth: Optional birth date
    ///   - notes: Optional therapy notes
    ///   - createdDate: Original creation timestamp
    ///   - lastModified: Last modification timestamp
    init(id: UUID, name: String, dateOfBirth: Date?, notes: String?, createdDate: Date, lastModified: Date) {
        self.id = id
        self.name = name
        self.dateOfBirth = dateOfBirth
        self.notes = notes
        self.createdDate = createdDate
        self.lastModified = lastModified
    }
    
    /// Standard display name for UI purposes
    /// Currently returns full name - consider privacy implications in sensitive contexts
    var displayName: String { 
        name 
    }
    
    /// Calculated age based on date of birth
    /// Returns nil if date of birth is not available
    /// Uses current date for calculation - consider timezone implications
    var age: Int? {
        guard let dateOfBirth = dateOfBirth else { return nil }
        return Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year
    }
    
    /// Formatted age string for UI display
    /// Provides user-friendly text for client information displays
    var displayDetails: String {
        if let age = age {
            return "Age \(age)"
        } else {
            return "Age not specified"
        }
    }
    
    /// Privacy-focused name display for HIPAA compliance
    /// Shows first name and last initial only (e.g., "John D.")
    /// 
    /// **HIPAA Note:** Use this for displays in shared environments
    /// or when full name visibility is not required
    var privacyName: String {
        let components = name.components(separatedBy: " ")
        guard components.count > 1 else { return name }
        let firstName = components.first ?? ""
        let lastInitial = String(components.last?.prefix(1) ?? "")
        return "\(firstName) \(lastInitial)."
    }
}