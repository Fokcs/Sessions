import Foundation

struct Session: Identifiable, Codable, Equatable {
    let id: UUID
    let clientId: UUID
    let date: Date
    let startTime: Date
    var endTime: Date?
    let location: String?
    let createdOn: String
    var notes: String?
    var goalLogs: [GoalLog]
    let lastModified: Date
    
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
        self.endTime = nil
        self.location = location
        self.createdOn = createdOn
        self.notes = nil
        self.goalLogs = []
        self.lastModified = Date()
    }
    
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
    
    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
    
    var isActive: Bool {
        endTime == nil
    }
    
    var successRate: Double {
        guard !goalLogs.isEmpty else { return 0.0 }
        let successCount = goalLogs.filter { $0.wasSuccessful }.count
        return Double(successCount) / Double(goalLogs.count)
    }
    
    var totalTrials: Int {
        goalLogs.count
    }
    
    var successCount: Int {
        goalLogs.filter { $0.wasSuccessful }.count
    }
    
    var failureCount: Int {
        goalLogs.filter { !$0.wasSuccessful }.count
    }
    
    var formattedDuration: String {
        guard let duration = duration else { return "Active" }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}