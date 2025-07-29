//
//  ContentView.swift
//  Sessions
//
//  Created by Aaron Fuchs on 7/27/25.
//

import SwiftUI

/// Main content view for the Sessions iOS application
/// 
/// **Current State:** TabView navigation structure with Clients, Goals, and Sessions tabs
/// 
/// **Implementation (Stage 2):**
/// This view serves as the primary navigation hub for the therapy app, containing:
/// - Client management interface (ClientsView)
/// - Goal template management (GoalsView)  
/// - Session history and tracking (SessionsView)
/// 
/// **Architecture Notes:**
/// - Follows SwiftUI declarative UI patterns with TabView navigation
/// - Each tab contains its own NavigationStack for proper navigation hierarchy
/// - Integrates with repository pattern for data access (future enhancement)
/// - Designed for MVVM architecture with ObservableObject ViewModels
/// - Supports iOS-specific navigation patterns and accessibility
struct ContentView: View {
    var body: some View {
        TabView {
            ClientsView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Clients")
                }
                .accessibilityLabel("Clients tab")
                .accessibilityHint("Manage therapy clients")
            
            GoalsView()
                .tabItem {
                    Image(systemName: "target")
                    Text("Goals")
                }
                .accessibilityLabel("Goals tab")
                .accessibilityHint("Manage goal templates")
            
            SessionsView()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("Sessions")
                }
                .accessibilityLabel("Sessions tab")
                .accessibilityHint("View session history")
        }
    }
}

/// SwiftUI preview for ContentView
/// Provides design-time preview in Xcode canvas for rapid UI development
#Preview {
    ContentView()
}
