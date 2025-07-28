import Foundation
import SwiftUI

enum CueLevel: String, CaseIterable, Codable {
    case independent = "independent"
    case minimal = "minimal"
    case moderate = "moderate"
    case maximal = "maximal"
    
    var displayName: String {
        switch self {
        case .independent: return "Independent"
        case .minimal: return "Min"
        case .moderate: return "Mod"
        case .maximal: return "Max"
        }
    }
    
    var fullDisplayName: String {
        switch self {
        case .independent: return "Independent"
        case .minimal: return "Minimal"
        case .moderate: return "Moderate"
        case .maximal: return "Maximal"
        }
    }
    
    var color: Color {
        switch self {
        case .independent: return .blue
        case .minimal: return .green
        case .moderate: return .orange
        case .maximal: return .red
        }
    }
    
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