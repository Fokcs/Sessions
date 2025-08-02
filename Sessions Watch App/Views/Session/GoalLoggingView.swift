import SwiftUI
import WatchKit

struct GoalLoggingView: View {
    @ObservedObject var sessionViewModel: SessionViewModel
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var showingTrialFeedback = false
    @State private var feedbackText = ""
    
    private let swipeThreshold: CGFloat = 25
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                
                // Swipe prompts
                swipePrompts
                
                // Main content area
                mainContent
                    .offset(y: dragOffset.height * 0.1) // Subtle visual feedback during drag
                    .scaleEffect(isDragging ? 0.98 : 1.0)
                
                // Trial feedback overlay
                if showingTrialFeedback {
                    trialFeedbackOverlay
                }
                
                // Cue level picker overlay
                if sessionViewModel.showingCueLevelPicker {
                    CueLevelPickerView(sessionViewModel: sessionViewModel)
                }
            }
        }
        .navigationBarHidden(true)
        .gesture(
            DragGesture()
                .onChanged(handleDragChanged)
                .onEnded(handleDragEnded)
        )
        .onReceive(NotificationCenter.default.publisher(for: .crownDidRotate)) { notification in
            handleCrownRotation(notification)
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            // Session timer
            Text(sessionViewModel.sessionDuration)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.green)
            
            Spacer()
            
            // Current time
            Text(currentTimeFormatted)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.gray)
            
            Spacer()
            
            // Undo button
            Button(action: sessionViewModel.undoLastTrial) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(sessionViewModel.undoButtonEnabled ? .orange : .gray)
            }
            .disabled(!sessionViewModel.undoButtonEnabled)
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    // MARK: - Swipe Prompts
    
    private var swipePrompts: some View {
        VStack {
            // Success prompt (top)
            HStack {
                Spacer()
                Text("↑ SUCCESS ↑")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        dragOffset.height < -10 
                            ? Color.green.opacity(0.8)
                            : Color.green.opacity(0.3)
                    )
                    .clipShape(Capsule())
                Spacer()
            }
            .padding(.top, 8)
            
            Spacer()
            
            // Failure prompt (bottom)
            HStack {
                Spacer()
                Text("↓ FAILURE ↓")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        dragOffset.height > 10 
                            ? Color.red.opacity(0.8)
                            : Color.red.opacity(0.3)
                    )
                    .clipShape(Capsule())
                Spacer()
            }
            .padding(.bottom, 8)
        }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        VStack(spacing: 15) {
            // Header
            headerView
            
            Spacer()
            
            // Client name badge
            if let clientName = sessionViewModel.selectedClient?.displayName {
                Text(clientName)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.3))
                    .clipShape(Capsule())
            }
            
            // Current goal description
            if let goal = sessionViewModel.currentGoal {
                Text(goal.description)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 15)
            }
            
            // Success percentage
            Text(sessionViewModel.successRate)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(sessionViewModel.successRateColor)
                .padding(.vertical, 4)
            
            Spacer()
            
            // Navigation dots
            navigationDotsView
            
            Spacer(minLength: 20)
        }
    }
    
    // MARK: - Navigation Dots
    
    private var navigationDotsView: some View {
        HStack(spacing: 8) {
            ForEach(0..<sessionViewModel.totalGoals, id: \.self) { index in
                Circle()
                    .fill(index == sessionViewModel.currentGoalIndex ? Color.green : Color.gray.opacity(0.5))
                    .frame(width: index == sessionViewModel.currentGoalIndex ? 8 : 6, height: index == sessionViewModel.currentGoalIndex ? 8 : 6)
                    .scaleEffect(index == sessionViewModel.currentGoalIndex ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: sessionViewModel.currentGoalIndex)
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Trial Feedback Overlay
    
    private var trialFeedbackOverlay: some View {
        Text(feedbackText)
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(
                feedbackText.contains("Success") 
                    ? Color.green.opacity(0.9)
                    : Color.red.opacity(0.9)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(showingTrialFeedback ? 1.0 : 0.5)
            .opacity(showingTrialFeedback ? 1.0 : 0.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showingTrialFeedback)
    }
    
    // MARK: - Gesture Handling
    
    private func handleDragChanged(_ value: DragGesture.Value) {
        dragOffset = value.translation
        
        if !isDragging {
            withAnimation(.easeInOut(duration: 0.1)) {
                isDragging = true
            }
        }
    }
    
    private func handleDragEnded(_ value: DragGesture.Value) {
        let translation = value.translation
        let velocity = value.velocity
        
        // Reset drag state
        withAnimation(.easeInOut(duration: 0.2)) {
            dragOffset = .zero
            isDragging = false
        }
        
        // Check for swipe gestures
        let verticalMovement = translation.height
        let verticalVelocity = velocity.height
        
        // Swipe up for success
        if verticalMovement < -swipeThreshold || verticalVelocity < -200 {
            logSuccess()
        }
        // Swipe down for failure
        else if verticalMovement > swipeThreshold || verticalVelocity > 200 {
            logFailure()
        }
    }
    
    // MARK: - Crown Handling
    
    private func handleCrownRotation(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let delta = userInfo["delta"] as? Double else { return }
        
        // Positive delta = crown rotated away from user (next goal)
        // Negative delta = crown rotated toward user (previous goal)
        
        if delta > 0.5 {
            sessionViewModel.moveToNextGoal()
        } else if delta < -0.5 {
            sessionViewModel.moveToPreviousGoal()
        }
    }
    
    // MARK: - Trial Logging
    
    private func logSuccess() {
        feedbackText = "+1 Success"
        showTrialFeedback()
        sessionViewModel.logSuccess()
    }
    
    private func logFailure() {
        feedbackText = "+1 Failure"
        showTrialFeedback()
        sessionViewModel.logFailure()
    }
    
    private func showTrialFeedback() {
        showingTrialFeedback = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingTrialFeedback = false
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var currentTimeFormatted: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
}

// MARK: - Crown Rotation Extension

extension Notification.Name {
    static let crownDidRotate = Notification.Name("crownDidRotate")
}

// Mock crown rotation handling for simulator
extension GoalLoggingView {
    func simulateCrownRotation(_ delta: Double) {
        let userInfo = ["delta": delta]
        NotificationCenter.default.post(
            name: .crownDidRotate,
            object: nil,
            userInfo: userInfo
        )
    }
}