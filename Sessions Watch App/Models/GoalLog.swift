import Foundation

struct GoalLog: Identifiable, Codable, Equatable {
    let id: UUID
    let goalTemplateId: UUID?
    let goalDescription: String
    let cueLevel: CueLevel
    let wasSuccessful: Bool
    let sessionId: UUID
    let timestamp: Date
    let notes: String?
    
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
        self.timestamp = Date()
        self.notes = notes
    }
    
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