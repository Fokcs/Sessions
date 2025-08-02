import Foundation

/// Swift model struct representing a therapy goal template
/// 
/// **Purpose:**
/// Goal templates define reusable therapy objectives that can be applied across multiple sessions.
/// They provide standardized goals with default cue levels and categorization for consistent
/// therapy documentation and progress tracking.
/// 
/// **Core Data Relationship:**
/// - Maps to CDGoalTemplate entity in TherapyDataModel.xcdatamodeld
/// - Linked to specific clients via clientId foreign key relationship
/// - Used as foundation for creating GoalLog entries during therapy sessions
/// 
/// **Workflow Integration:**
/// - Created during therapy planning phase
/// - Selected during active therapy sessions
/// - Provides baseline cue level for progress measurement
/// - Can be activated/deactivated without deletion for historical tracking
struct GoalTemplate: Identifiable, Codable, Equatable {
    /// Unique identifier for the goal template
    /// Used for Core Data relationships and template selection
    let id: UUID
    
    /// Concise title describing the therapy goal
    /// Should be clear and specific for easy identification during sessions
    let title: String
    
    /// Optional detailed description of the goal
    /// May include specific instructions, criteria, or implementation notes
    let description: String?
    
    /// Category classification for goal organization
    /// Examples: "Speech", "Motor Skills", "Cognitive", "Social"
    /// Used for filtering and grouping in UI displays
    let category: String
    
    /// Default cue level for this goal
    /// Represents the typical level of support needed for this objective
    /// Can be overridden during individual session logging
    let defaultCueLevel: CueLevel
    
    /// Foreign key linking to the associated client
    /// Establishes one-to-many relationship (client has many goal templates)
    let clientId: UUID
    
    /// Indicates if this goal template is currently active
    /// Inactive templates are hidden from session selection but preserved for historical data
    var isActive: Bool
    
    /// Timestamp when goal template was created
    /// Used for sorting and audit trail purposes
    let createdDate: Date
    
    /// Convenience initializer for creating new goal templates
    /// Automatically sets creation timestamp and defaults to active status
    /// 
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - title: Concise goal title
    ///   - description: Optional detailed description
    ///   - category: Goal category for organization
    ///   - defaultCueLevel: Expected cue level for this goal
    ///   - clientId: Associated client identifier
    ///   - isActive: Active status (defaults to true)
    init(
        id: UUID = UUID(),
        title: String,
        description: String? = nil,
        category: String,
        defaultCueLevel: CueLevel,
        clientId: UUID,
        isActive: Bool = true
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.defaultCueLevel = defaultCueLevel
        self.clientId = clientId
        self.isActive = isActive
        self.createdDate = Date()
    }
    
    /// Full initializer for reconstructing goal templates from persistent storage
    /// Used by repository layer when loading from Core Data
    /// 
    /// - Parameters:
    ///   - id: Unique identifier
    ///   - title: Goal title
    ///   - description: Optional detailed description
    ///   - category: Goal category
    ///   - defaultCueLevel: Expected cue level
    ///   - clientId: Associated client identifier
    ///   - isActive: Current active status
    ///   - createdDate: Original creation timestamp
    init(
        id: UUID,
        title: String,
        description: String?,
        category: String,
        defaultCueLevel: CueLevel,
        clientId: UUID,
        isActive: Bool,
        createdDate: Date
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.defaultCueLevel = defaultCueLevel
        self.clientId = clientId
        self.isActive = isActive
        self.createdDate = createdDate
    }
}