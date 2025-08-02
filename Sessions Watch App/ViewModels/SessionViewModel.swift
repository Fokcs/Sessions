import Foundation
import SwiftUI
import Combine

@MainActor
class SessionViewModel: ObservableObject {
    @Published private(set) var activeSession: ActiveSession?
    @Published private(set) var sessionTimer: Timer?
    @Published private(set) var currentTime = Date()
    @Published var selectedClient: Client?
    @Published var availableGoals: [GoalTemplate] = []
    @Published var isSessionActive = false
    @Published var showingCueLevelPicker = false
    @Published var lastTrialWasSuccess = false
    @Published var undoButtonEnabled = false
    
    private let repository: TherapyRepository
    private var timeTimer: Timer?
    
    init(repository: TherapyRepository) {
        self.repository = repository
        startTimeTimer()
        loadSampleData()
    }
    
    deinit {
        timeTimer?.invalidate()
        sessionTimer?.invalidate()
    }
    
    // MARK: - Time Management
    
    private func startTimeTimer() {
        timeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                self.currentTime = Date()
            }
        }
    }
    
    // MARK: - Session Management
    
    func startSession(with client: Client, goals: [GoalTemplate]) {
        guard !goals.isEmpty else { return }
        
        selectedClient = client
        availableGoals = goals
        
        let session = ActiveSession(
            clientId: client.id,
            clientName: client.displayName,
            goalTemplates: goals
        )
        
        activeSession = session
        isSessionActive = true
        undoButtonEnabled = false
        
        startSessionTimer()
        
        // Add haptic feedback
        HapticManager.shared.sessionStart()
    }
    
    func endSession() {
        guard let session = activeSession else { return }
        
        // Save session to Core Data
        Task {
            do {
                let completedSession = session.toSession()
                try await repository.createSession(completedSession)
            } catch {
                print("Error saving session: \(error)")
            }
        }
        
        // Clean up
        activeSession = nil
        isSessionActive = false
        sessionTimer?.invalidate()
        sessionTimer = nil
        undoButtonEnabled = false
        
        // Add haptic feedback
        HapticManager.shared.sessionEnd()
    }
    
    private func startSessionTimer() {
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                self.objectWillChange.send()
            }
        }
    }
    
    // MARK: - Goal Navigation
    
    func moveToNextGoal() {
        guard var session = activeSession else { return }
        session.moveToNextGoal()
        activeSession = session
    }
    
    func moveToPreviousGoal() {
        guard var session = activeSession else { return }
        session.moveToPreviousGoal()
        activeSession = session
    }
    
    func setCurrentGoal(at index: Int) {
        guard var session = activeSession else { return }
        session.setGoalIndex(index)
        activeSession = session
    }
    
    // MARK: - Trial Logging
    
    func logSuccess() {
        logTrial(wasSuccessful: true)
    }
    
    func logFailure() {
        logTrial(wasSuccessful: false)
    }
    
    private func logTrial(wasSuccessful: Bool) {
        lastTrialWasSuccess = wasSuccessful
        showingCueLevelPicker = true
        
        // Add haptic feedback
        if wasSuccessful {
            HapticManager.shared.trialSuccess()
        } else {
            HapticManager.shared.trialFailure()
        }
    }
    
    func addTrialWithCueLevel(_ cueLevel: CueLevel) {
        guard var session = activeSession else { return }
        
        session.addTrial(wasSuccessful: lastTrialWasSuccess, cueLevel: cueLevel)
        activeSession = session
        showingCueLevelPicker = false
        undoButtonEnabled = true
        
        // Add haptic feedback for completion
        HapticManager.shared.cueLevelSelected()
    }
    
    func undoLastTrial() {
        guard var session = activeSession else { return }
        
        if let removedTrial = session.removeLastTrial() {
            activeSession = session
            undoButtonEnabled = session.totalTrials > 0
            
            // Add haptic feedback
            HapticManager.shared.undoAction()
        }
    }
    
    // MARK: - Computed Properties
    
    var currentGoal: GoalTemplate? {
        activeSession?.currentGoal
    }
    
    var sessionDuration: String {
        activeSession?.formattedDuration ?? "00:00"
    }
    
    var currentGoalIndex: Int {
        activeSession?.currentGoalIndex ?? 0
    }
    
    var totalGoals: Int {
        activeSession?.goalTemplates.count ?? 0
    }
    
    var successRate: String {
        activeSession?.formattedSuccessRate ?? "0% (0/0)"
    }
    
    var successRateColor: Color {
        guard let rate = activeSession?.successPercentage else { return .gray }
        
        switch rate {
        case 70...100: return .green
        case 40...69: return .orange
        case 1...39: return .red
        default: return .gray
        }
    }
    
    var navigationDots: [Bool] {
        guard let session = activeSession else { return [] }
        return (0..<session.goalTemplates.count).map { $0 == session.currentGoalIndex }
    }
    
    // MARK: - Session Summary
    
    func getSessionSummary() -> SessionSummary? {
        guard let session = activeSession else { return nil }
        
        let goalStats = session.allGoalStats.compactMap { stats -> GoalPerformance? in
            guard let goal = session.goalTemplates.first(where: { $0.id == stats.goalTemplateId }) else {
                return nil
            }
            return GoalPerformance(
                goalName: goal.description ?? "Unknown Goal",
                successCount: stats.successCount,
                totalCount: stats.totalCount
            )
        }
        
        return SessionSummary(
            sessionId: session.id,
            clientId: session.clientId,
            clientName: session.clientName,
            startTime: session.startTime,
            endTime: Date(),
            duration: session.sessionDuration,
            totalTrials: session.totalTrials,
            successTrials: session.successCount,
            failureTrials: session.failureCount,
            cuingLevelBreakdown: session.cueLevelBreakdown,
            goalBreakdown: goalStats
        )
    }
    
    // MARK: - Sample Data Loading
    
    private func loadSampleData() {
        Task {
            do {
                let clients = try await repository.getAllClients()
                if let firstClient = clients.first {
                    selectedClient = firstClient
                }
                
                let goals = try await repository.getAllGoalTemplates()
                availableGoals = Array(goals.prefix(4)) // Limit to 4 goals for Watch UI
            } catch {
                print("Error loading sample data: \(error)")
            }
        }
    }
}

// MARK: - Supporting Models

struct SessionSummary {
    let sessionId: UUID
    let clientId: UUID
    let clientName: String
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    
    let totalTrials: Int
    let successTrials: Int
    let failureTrials: Int
    
    let cuingLevelBreakdown: CueLevelStats
    let goalBreakdown: [GoalPerformance]
    
    var successRate: Int {
        guard totalTrials > 0 else { return 0 }
        return Int((Double(successTrials) / Double(totalTrials)) * 100)
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct GoalPerformance {
    let goalName: String
    let successCount: Int
    let totalCount: Int
    
    var successRate: Int {
        guard totalCount > 0 else { return 0 }
        return Int((Double(successCount) / Double(totalCount)) * 100)
    }
    
    var performanceLevel: PerformanceLevel {
        switch successRate {
        case 85...100: return .excellent
        case 70...84: return .good
        default: return .needsWork
        }
    }
}