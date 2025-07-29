import Foundation
import SwiftUI

/// Enumeration representing different levels of support/cuing in therapy
/// 
/// **Therapy Context:**
/// Cue levels represent the amount of assistance or prompting a client needs
/// to successfully complete a therapy goal. This is a fundamental concept in
/// speech therapy, ABA therapy, and other therapeutic interventions.
/// 
/// **Progress Tracking:**
/// - Independent: Client performs task without any assistance (highest level)
/// - Minimal: Client needs slight prompting or encouragement
/// - Moderate: Client requires some assistance or modeling
/// - Maximal: Client needs significant support or hand-over-hand guidance
/// 
/// **UI Integration:**
/// Each level includes color coding and gradients for intuitive visual representation
/// in therapy logging interfaces, progress charts, and session summaries.
/// 
/// **Data Storage:**
/// Codable compliance enables storage in Core Data and potential future sync functionality
enum CueLevel: String, CaseIterable, Codable {
    /// No assistance required - client performs independently
    /// Represents highest level of skill mastery
    case independent = "independent"
    
    /// Minimal prompting or encouragement needed
    /// Client has good grasp of skill but needs slight support
    case minimal = "minimal"
    
    /// Moderate assistance required
    /// Client understands concept but needs regular prompting or modeling
    case moderate = "moderate"
    
    /// Maximum support needed
    /// Client requires significant assistance or hand-over-hand guidance
    case maximal = "maximal"
    
    /// Abbreviated display name for compact UI elements
    /// Used in space-constrained interfaces like watchOS or table cells
    var displayName: String {
        switch self {
        case .independent: return "Independent"
        case .minimal: return "Min"
        case .moderate: return "Mod"
        case .maximal: return "Max"
        }
    }
    
    /// Full display name for detailed UI elements
    /// Used in settings, detailed views, and professional documentation
    var fullDisplayName: String {
        switch self {
        case .independent: return "Independent"
        case .minimal: return "Minimal"
        case .moderate: return "Moderate"
        case .maximal: return "Maximal"
        }
    }
    
    /// SwiftUI color for visual representation
    /// 
    /// **Color Psychology:**
    /// - Blue (Independent): Calm, professional, represents mastery
    /// - Green (Minimal): Positive, encouraging, represents good progress
    /// - Orange (Moderate): Attention-getting, represents need for focus
    /// - Red (Maximal): Alert color, represents need for significant support
    var color: Color {
        switch self {
        case .independent: return .blue
        case .minimal: return .green
        case .moderate: return .orange
        case .maximal: return .red
        }
    }
    
    /// Linear gradient for enhanced visual elements
    /// 
    /// **Usage:** Buttons, progress indicators, and highlighted UI components
    /// Each gradient uses a lighter-to-darker variation of the base color
    /// for depth and visual appeal in therapy logging interfaces
    var gradient: LinearGradient {
        switch self {
        case .independent:
            return LinearGradient(
                colors: [.blue, Color(red: 0, green: 0.34, blue: 0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .minimal:
            return LinearGradient(
                colors: [.green, Color(red: 0.13, green: 0.55, blue: 0.13)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .moderate:
            return LinearGradient(
                colors: [.orange, Color(red: 0.8, green: 0.47, blue: 0)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .maximal:
            return LinearGradient(
                colors: [.red, Color(red: 0.8, green: 0.16, blue: 0.13)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}