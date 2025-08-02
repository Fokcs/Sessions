import Foundation
import SwiftUI

/// Represents an active therapy session state in memory for Watch app
struct ActiveSession: Identifiable {
    let id: UUID
    let clientId: UUID
    let clientName: String
    let startTime: Date
    let goalTemplates: [GoalTemplate]
    
    private(set) var currentGoalIndex: Int = 0
    private(set) var trials: [TrialEntry] = []
    private(set) var sessionTimer: Timer?
    
    init(clientId: UUID, clientName: String, goalTemplates: [GoalTemplate]) {
        self.id = UUID()
        self.clientId = clientId
        self.clientName = clientName
        self.startTime = Date()
        self.goalTemplates = goalTemplates
    }
    
    // MARK: - Current Goal Management
    
    var currentGoal: GoalTemplate? {
        guard currentGoalIndex < goalTemplates.count else { return nil }
        return goalTemplates[currentGoalIndex]
    }
    
    mutating func moveToNextGoal() {
        guard currentGoalIndex < goalTemplates.count - 1 else { return }
        currentGoalIndex += 1
    }
    
    mutating func moveToPreviousGoal() {
        guard currentGoalIndex > 0 else { return }
        currentGoalIndex -= 1
    }
    
    mutating func setGoalIndex(_ index: Int) {
        guard index >= 0 && index < goalTemplates.count else { return }
        currentGoalIndex = index
    }
    
    // MARK: - Trial Management
    
    mutating func addTrial(wasSuccessful: Bool, cueLevel: CueLevel) {
        guard let currentGoal = currentGoal else { return }
        
        let trial = TrialEntry(
            goalTemplateId: currentGoal.id,
            goalDescription: currentGoal.description,
            wasSuccessful: wasSuccessful,
            cueLevel: cueLevel,
            timestamp: Date()
        )
        
        trials.append(trial)
    }
    
    mutating func removeLastTrial() -> TrialEntry? {
        guard !trials.isEmpty else { return nil }
        return trials.removeLast()
    }
    
    // MARK: - Session Statistics
    
    var sessionDuration: TimeInterval {
        Date().timeIntervalSince(startTime)
    }
    
    var formattedDuration: String {
        let duration = sessionDuration
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var totalTrials: Int {
        trials.count
    }
    
    var successCount: Int {
        trials.filter { $0.wasSuccessful }.count
    }
    
    var failureCount: Int {
        trials.filter { !$0.wasSuccessful }.count
    }
    
    var successRate: Double {
        guard totalTrials > 0 else { return 0.0 }
        return Double(successCount) / Double(totalTrials)
    }
    
    var successPercentage: Int {
        Int(successRate * 100)
    }
    
    var formattedSuccessRate: String {
        if totalTrials == 0 {
            return "0% (0/0)"
        }
        return "\(successPercentage)% (\(successCount)/\(totalTrials))"
    }
    
    // MARK: - Goal-Specific Statistics
    
    func statsForGoal(_ goalTemplateId: UUID) -> GoalStats {
        let goalTrials = trials.filter { $0.goalTemplateId == goalTemplateId }
        let successCount = goalTrials.filter { $0.wasSuccessful }.count
        let totalCount = goalTrials.count
        let successRate = totalCount > 0 ? Double(successCount) / Double(totalCount) : 0.0
        
        return GoalStats(
            goalTemplateId: goalTemplateId,
            successCount: successCount,
            totalCount: totalCount,
            successRate: successRate
        )
    }
    
    var allGoalStats: [GoalStats] {
        goalTemplates.map { statsForGoal($0.id) }
    }
    
    // MARK: - Cue Level Statistics
    
    var cueLevelBreakdown: CueLevelStats {
        let independent = trials.filter { $0.cueLevel == .independent }.count
        let minimal = trials.filter { $0.cueLevel == .minimal }.count
        let moderate = trials.filter { $0.cueLevel == .moderate }.count
        let maximal = trials.filter { $0.cueLevel == .maximal }.count
        
        return CueLevelStats(
            independent: independent,
            minimal: minimal,
            moderate: moderate,
            maximal: maximal
        )
    }
    
    // MARK: - Session Conversion
    
    func toSession() -> Session {
        var session = Session(
            clientId: clientId,
            location: nil,
            createdOn: "Watch"
        )
        
        session.goalLogs = trials.map { trial in
            GoalLog(
                goalTemplateId: trial.goalTemplateId,
                goalDescription: trial.goalDescription,
                cueLevel: trial.cueLevel,
                wasSuccessful: trial.wasSuccessful,
                sessionId: session.id
            )
        }
        
        return session
    }
}

/// Individual trial entry during active session
struct TrialEntry: Identifiable {
    let id = UUID()
    let goalTemplateId: UUID
    let goalDescription: String
    let wasSuccessful: Bool
    let cueLevel: CueLevel
    let timestamp: Date
}

/// Statistics for a specific goal
struct GoalStats: Identifiable {
    let goalTemplateId: UUID
    let successCount: Int
    let totalCount: Int
    let successRate: Double
    
    var id: UUID { goalTemplateId }
    
    var successPercentage: Int {
        Int(successRate * 100)
    }
    
    var performanceLevel: PerformanceLevel {
        switch successPercentage {
        case 85...100: return .excellent
        case 70...84: return .good
        default: return .needsWork
        }
    }
}

/// Cue level usage statistics
struct CueLevelStats {
    let independent: Int
    let minimal: Int
    let moderate: Int
    let maximal: Int
    
    var total: Int {
        independent + minimal + moderate + maximal
    }
}

/// Performance level categorization
enum PerformanceLevel {
    case excellent, good, needsWork
    
    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .orange
        case .needsWork: return .red
        }
    }
    
    var description: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .needsWork: return "Needs Work"
        }
    }
}