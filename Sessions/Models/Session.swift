import Foundation

/// Swift model struct representing a therapy session
/// 
/// **Session Lifecycle:**
/// A session represents a complete therapy encounter with a client, containing:
/// - Basic session metadata (date, time, location, device)
/// - Goal-specific logs documenting specific therapeutic activities
/// - Progress metrics calculated from goal achievements
/// 
/// **Core Data Relationship:**
/// - Maps to CDSession entity in TherapyDataModel.xcdatamodeld
/// - One-to-many relationship with GoalLog entities
/// - Many-to-one relationship with Client entity
/// 
/// **State Management:**
/// - Sessions can be active (endTime = nil) or completed (endTime set)
/// - Active sessions allow real-time goal logging
/// - Completed sessions are used for historical analysis and reporting
/// 
/// **Analytics Support:**
/// Includes computed properties for session analysis:
/// - Duration calculation, success rates, trial counts
/// - Used for progress tracking and therapy outcome measurement
struct Session: Identifiable, Codable, Equatable {
    /// Unique identifier for the session
    /// Used for Core Data relationships and session management
    let id: UUID
    
    /// Foreign key linking to the associated client
    /// Establishes many-to-one relationship (client has many sessions)
    let clientId: UUID
    
    /// Calendar date when session occurred
    /// Used for scheduling, reporting, and historical analysis
    let date: Date
    
    /// Timestamp when session began
    /// Used for duration calculation and detailed timing analysis
    let startTime: Date
    
    /// Optional timestamp when session ended
    /// nil indicates session is still active
    /// Set when therapist completes/closes the session
    var endTime: Date?
    
    /// Optional location where session took place
    /// Examples: "Clinic Room 1", "Client Home", "School"
    /// Used for service tracking and billing purposes
    let location: String?
    
    /// Device/platform where session was created
    /// Examples: "iPhone", "iPad", "Apple Watch"
    /// Used for analytics and technical support
    let createdOn: String
    
    /// Optional session-level notes from therapist
    /// May contain overall session observations, behavior notes, or next steps
    var notes: String?
    
    /// Collection of individual goal attempts/logs within this session
    /// Each goal log represents a specific therapeutic activity or trial
    var goalLogs: [GoalLog]
    
    /// Timestamp of last modification to session data
    /// Updated when session details or goal logs change
    let lastModified: Date
    
    /// Convenience initializer for starting a new therapy session
    /// Creates active session with current timestamp and empty goal logs
    /// 
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - clientId: Associated client identifier
    ///   - location: Optional session location
    ///   - createdOn: Device/platform identifier (defaults to "iPhone")
    init(
        id: UUID = UUID(),
        clientId: UUID,
        location: String? = nil,
        createdOn: String = "iPhone"
    ) {
        self.id = id
        self.clientId = clientId
        self.date = Date()
        self.startTime = Date()
        self.endTime = nil  // Active session
        self.location = location
        self.createdOn = createdOn
        self.notes = nil
        self.goalLogs = []  // Start with empty goal logs
        self.lastModified = Date()
    }
    
    /// Full initializer for reconstructing sessions from persistent storage
    /// Used by repository layer when loading from Core Data
    /// 
    /// - Parameters:
    ///   - id: Unique identifier
    ///   - clientId: Associated client identifier
    ///   - date: Session date
    ///   - startTime: Session start timestamp
    ///   - endTime: Optional session end timestamp
    ///   - location: Optional session location
    ///   - createdOn: Device/platform identifier
    ///   - notes: Optional session notes
    ///   - goalLogs: Collection of goal logs from this session
    ///   - lastModified: Last modification timestamp
    init(
        id: UUID,
        clientId: UUID,
        date: Date,
        startTime: Date,
        endTime: Date?,
        location: String?,
        createdOn: String,
        notes: String?,
        goalLogs: [GoalLog],
        lastModified: Date
    ) {
        self.id = id
        self.clientId = clientId
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.location = location
        self.createdOn = createdOn
        self.notes = notes
        self.goalLogs = goalLogs
        self.lastModified = lastModified
    }
    
    /// Calculated session duration in seconds
    /// Returns nil if session is still active (no end time)
    /// Used for billing, analysis, and session management
    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
    
    /// Indicates if session is currently active
    /// Active sessions can accept new goal logs and be modified
    /// Used to control UI state and data entry permissions
    var isActive: Bool {
        endTime == nil
    }
    
    /// Calculated success rate as decimal (0.0 to 1.0)
    /// Represents percentage of successful goal attempts in this session
    /// Returns 0.0 if no goal logs exist
    /// Used for progress tracking and outcome measurement
    var successRate: Double {
        guard !goalLogs.isEmpty else { return 0.0 }
        let successCount = goalLogs.filter { $0.wasSuccessful }.count
        return Double(successCount) / Double(goalLogs.count)
    }
    
    /// Total number of goal attempts/trials in this session
    /// Used for session productivity analysis and billing
    var totalTrials: Int {
        goalLogs.count
    }
    
    /// Number of successful goal attempts in this session
    /// Used for progress reporting and motivation tracking
    var successCount: Int {
        goalLogs.filter { $0.wasSuccessful }.count
    }
    
    /// Number of unsuccessful goal attempts in this session
    /// Used for identifying areas needing additional focus
    var failureCount: Int {
        goalLogs.filter { !$0.wasSuccessful }.count
    }
    
    /// Human-readable formatted duration string
    /// Returns "Active" for ongoing sessions, "MM:SS" format for completed sessions
    /// Used in UI displays and session summaries
    var formattedDuration: String {
        guard let duration = duration else { return "Active" }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}