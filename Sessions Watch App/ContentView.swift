//
//  ContentView.swift
//  Sessions Watch App
//
//  Created by Aaron Fuchs on 7/27/25.
//

import SwiftUI

/// Main content view for the Sessions watchOS application
/// 
/// **Stage 3 Implementation:** Complete Apple Watch session workflow
/// 
/// This view serves as the primary interface for watchOS therapy logging, featuring:
/// - Quick session start/stop controls with large, accessible buttons
/// - Real-time session timer and progress indicators
/// - Simplified goal logging interface optimized for glanceable interactions
/// - Integration with Digital Crown for rapid cue level selection
/// - Haptic feedback for confirmation of logged actions
/// 
/// **watchOS Design Principles:**
/// - Large touch targets for easy interaction during therapy sessions
/// - High contrast colors and clear typography for quick recognition
/// - Minimal navigation depth to reduce interaction complexity
/// - Support for both tap and Digital Crown input methods
/// - Swipe gestures for rapid trial logging
/// 
/// **Platform Integration:**
/// - Designed to work seamlessly alongside iOS app
/// - Optimized for therapist's non-dominant hand usage
/// - Quick access to most frequently used therapy logging functions
struct ContentView: View {
    @State private var repository: TherapyRepository?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                // Loading view
                VStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading...")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                }
            } else if let repository = repository {
                SessionCoordinatorView(repository: repository)
            } else {
                // Error view
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text("Error loading app")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                }
            }
        }
        .onAppear {
            initializeRepository()
        }
    }
    
    private func initializeRepository() {
        Task {
            do {
                let coreDataStack = try CoreDataStack()
                let therapyRepository = try TherapyRepository(coreDataStack: coreDataStack)
                
                await MainActor.run {
                    self.repository = therapyRepository
                    self.isLoading = false
                }
            } catch {
                print("Error initializing repository: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

/// SwiftUI preview for watchOS ContentView
/// Provides design-time preview in Xcode canvas optimized for Apple Watch screen sizes
#Preview {
    ContentView()
}
