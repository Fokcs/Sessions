import SwiftUI

enum SessionState {
    case start
    case logging
    case summary
}

struct SessionCoordinatorView: View {
    @StateObject private var sessionViewModel: SessionViewModel
    @State private var sessionState: SessionState = .start
    @State private var sessionSummary: SessionSummary?
    
    private let repository: TherapyRepository
    
    init(repository: TherapyRepository) {
        self.repository = repository
        self._sessionViewModel = StateObject(wrappedValue: SessionViewModel(repository: repository))
    }
    
    var body: some View {
        Group {
            switch sessionState {
            case .start:
                StartView(repository: repository)
                    .onReceive(sessionViewModel.$isSessionActive) { isActive in
                        if isActive {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                sessionState = .logging
                            }
                        }
                    }
                
            case .logging:
                GoalLoggingView(sessionViewModel: sessionViewModel)
                    .navigationBarHidden(true)
                    .gesture(
                        // Add end session gesture (long press on crown or edge swipe)
                        DragGesture()
                            .onEnded { value in
                                // Swipe from left edge to end session
                                if value.startLocation.x < 20 && value.translation.x > 100 {
                                    endSession()
                                }
                            }
                    )
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("End") {
                                endSession()
                            }
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.red)
                        }
                    }
                
            case .summary:
                if let summary = sessionSummary {
                    SessionSummaryView(
                        sessionSummary: summary,
                        onNewSession: startNewSession,
                        onShare: shareSession
                    )
                } else {
                    // Fallback to start view if no summary
                    StartView(repository: repository)
                        .onAppear {
                            sessionState = .start
                        }
                }
            }
        }
        .environmentObject(sessionViewModel)
    }
    
    // MARK: - Navigation Actions
    
    private func endSession() {
        // Get session summary before ending
        sessionSummary = sessionViewModel.getSessionSummary()
        
        // End the session
        sessionViewModel.endSession()
        
        // Navigate to summary
        withAnimation(.easeInOut(duration: 0.3)) {
            sessionState = .summary
        }
        
        // Add haptic feedback
        HapticManager.shared.sessionEnd()
    }
    
    private func startNewSession() {
        // Reset state
        sessionSummary = nil
        
        // Navigate back to start
        withAnimation(.easeInOut(duration: 0.3)) {
            sessionState = .start
        }
        
        // Add haptic feedback
        HapticManager.shared.navigate()
    }
    
    private func shareSession() {
        guard let summary = sessionSummary else { return }
        
        // Create share content
        let shareText = createShareText(from: summary)
        
        // Present share sheet (simplified for Watch)
        // In a real implementation, this would use WatchConnectivity to send to iPhone
        print("Sharing session: \(shareText)")
        
        // Add haptic feedback
        HapticManager.shared.navigate()
        
        // For now, just show a confirmation
        // TODO: Implement actual sharing functionality
    }
    
    private func createShareText(from summary: SessionSummary) -> String {
        return """
        Therapy Session Summary
        Client: \(summary.clientName)
        Duration: \(summary.formattedDuration)
        Total Trials: \(summary.totalTrials)
        Success Rate: \(summary.successRate)%
        
        Goal Performance:
        \(summary.goalBreakdown.map { "• \($0.goalName): \($0.successRate)%" }.joined(separator: "\n"))
        """
    }
}

// MARK: - Preview

struct SessionCoordinatorView_Previews: PreviewProvider {
    static var previews: some View {
        let stack = try! CoreDataStack(inMemory: true)
        let repository = try! TherapyRepository(coreDataStack: stack)
        
        return SessionCoordinatorView(repository: repository)
            .previewDevice("Apple Watch Series 7 - 45mm")
    }
}