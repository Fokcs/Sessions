import Foundation
import UIKit

/// Centralized haptic feedback management for consistent user experience across the Watch app
class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    // MARK: - Haptic Feedback Types
    
    /// Light impact for minor interactions (button presses, selections)
    func lightImpact() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    /// Medium impact for significant actions (session start, major state changes)
    func mediumImpact() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    /// Heavy impact for critical actions (session end, errors)
    func heavyImpact() {
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()
    }
    
    /// Success notification for positive outcomes
    func success() {
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
    }
    
    /// Warning notification for attention-needed situations
    func warning() {
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.warning)
    }
    
    /// Error notification for failures or problems
    func error() {
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.error)
    }
    
    // MARK: - Context-Specific Feedback
    
    /// Feedback for successful trial logging
    func trialSuccess() {
        success()
    }
    
    /// Feedback for failed trial logging
    func trialFailure() {
        lightImpact()
    }
    
    /// Feedback for cue level selection
    func cueLevelSelected() {
        lightImpact()
    }
    
    /// Feedback for goal navigation (Digital Crown)
    func goalNavigation() {
        lightImpact()
    }
    
    /// Feedback for session start
    func sessionStart() {
        mediumImpact()
    }
    
    /// Feedback for session end
    func sessionEnd() {
        mediumImpact()
    }
    
    /// Feedback for undo action
    func undoAction() {
        lightImpact()
    }
    
    /// Feedback for client selection
    func clientSelected() {
        lightImpact()
    }
    
    /// Feedback for interface navigation
    func navigate() {
        lightImpact()
    }
    
    /// Feedback for auto-timeout selection
    func autoTimeout() {
        lightImpact()
    }
}

// MARK: - SwiftUI Integration

import SwiftUI

extension View {
    /// Add haptic feedback to any view interaction
    func hapticFeedback(_ type: HapticFeedbackType) -> some View {
        self.onTapGesture {
            switch type {
            case .light:
                HapticManager.shared.lightImpact()
            case .medium:
                HapticManager.shared.mediumImpact()
            case .heavy:
                HapticManager.shared.heavyImpact()
            case .success:
                HapticManager.shared.success()
            case .warning:
                HapticManager.shared.warning()
            case .error:
                HapticManager.shared.error()
            }
        }
    }
}

enum HapticFeedbackType {
    case light, medium, heavy, success, warning, error
}