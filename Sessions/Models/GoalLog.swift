import Foundation

/// Swift model struct representing an individual goal attempt/trial within a therapy session
/// 
/// **Purpose:**
/// GoalLog represents the atomic unit of therapy data - a single attempt at a specific
/// therapeutic goal with its outcome, cue level, and contextual information.
/// Each log captures the granular data needed for progress tracking and analysis.
/// 
/// **Core Data Relationship:**
/// - Maps to CDGoalLog entity in TherapyDataModel.xcdatamodeld
/// - Many-to-one relationship with Session entity
/// - Optional relationship with GoalTemplate entity (may be ad-hoc goals)
/// 
/// **Data Integrity:**
/// - goalDescription is always stored to maintain data even if template is deleted
/// - goalTemplateId is optional to support both templated and custom goals
/// - timestamp provides precise ordering within session timeline
/// 
/// **Analytics Foundation:**
/// Multiple GoalLogs aggregate to provide session and long-term progress metrics
struct GoalLog: Identifiable, Codable, Equatable {
    /// Unique identifier for this goal log entry
    /// Used for Core Data relationships and log management
    let id: UUID
    
    /// Optional foreign key linking to associated goal template
    /// nil indicates this was an ad-hoc goal not based on a template
    /// Allows flexibility for spontaneous therapeutic opportunities
    let goalTemplateId: UUID?
    
    /// Description of the therapeutic goal attempted
    /// Always stored to preserve data integrity even if template is deleted
    /// Examples: "Say 'ball' with /b/ sound", "Point to red circle"
    let goalDescription: String
    
    /// Level of support/cuing provided during this attempt
    /// May differ from template's default based on client's current performance
    /// Used for tracking progress in independence levels
    let cueLevel: CueLevel
    
    /// Whether this goal attempt was successful
    /// Core outcome measure for progress tracking and session analysis
    /// Definition of 'success' may vary by therapeutic approach and goal type
    let wasSuccessful: Bool
    
    /// Foreign key linking to the containing therapy session
    /// Establishes many-to-one relationship (session has many goal logs)
    let sessionId: UUID
    
    /// Precise timestamp when this goal attempt occurred
    /// Used for temporal analysis and session timeline reconstruction
    /// Enables detailed analysis of therapy pacing and patterns
    let timestamp: Date
    
    /// Optional notes specific to this goal attempt
    /// May include observations, variations, or contextual information
    /// Examples: "Initially hesitated", "Needed extra time", "Self-corrected"
    let notes: String?
    
    /// Convenience initializer for creating new goal log entries
    /// Automatically sets timestamp to current time for real-time logging
    /// 
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - goalTemplateId: Optional template reference (nil for ad-hoc goals)
    ///   - goalDescription: Description of the therapeutic goal
    ///   - cueLevel: Level of support provided
    ///   - wasSuccessful: Whether the attempt was successful
    ///   - sessionId: Associated session identifier
    ///   - notes: Optional attempt-specific notes
    init(
        id: UUID = UUID(),
        goalTemplateId: UUID? = nil,
        goalDescription: String,
        cueLevel: CueLevel,
        wasSuccessful: Bool,
        sessionId: UUID,
        notes: String? = nil
    ) {
        self.id = id
        self.goalTemplateId = goalTemplateId
        self.goalDescription = goalDescription
        self.cueLevel = cueLevel
        self.wasSuccessful = wasSuccessful
        self.sessionId = sessionId
        self.timestamp = Date()  // Current timestamp for real-time logging
        self.notes = notes
    }
    
    /// Full initializer for reconstructing goal logs from persistent storage
    /// Used by repository layer when loading from Core Data
    /// 
    /// - Parameters:
    ///   - id: Unique identifier
    ///   - goalTemplateId: Optional template reference
    ///   - goalDescription: Description of the therapeutic goal
    ///   - cueLevel: Level of support provided
    ///   - wasSuccessful: Whether the attempt was successful
    ///   - sessionId: Associated session identifier
    ///   - timestamp: Original timestamp when attempt occurred
    ///   - notes: Optional attempt-specific notes
    init(
        id: UUID,
        goalTemplateId: UUID?,
        goalDescription: String,
        cueLevel: CueLevel,
        wasSuccessful: Bool,
        sessionId: UUID,
        timestamp: Date,
        notes: String?
    ) {
        self.id = id
        self.goalTemplateId = goalTemplateId
        self.goalDescription = goalDescription
        self.cueLevel = cueLevel
        self.wasSuccessful = wasSuccessful
        self.sessionId = sessionId
        self.timestamp = timestamp
        self.notes = notes
    }
}