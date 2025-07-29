//
//  SessionsApp.swift
//  Sessions
//
//  Created by Aaron Fuchs on 7/27/25.
//

import SwiftUI

/// Main entry point for the Sessions iOS application
/// 
/// Sessions is a HIPAA-compliant therapy data logging app designed for speech and ABA therapists.
/// The app provides secure local storage using Core Data with app group sharing for iOS/watchOS sync.
/// 
/// **Architecture Overview:**
/// - SwiftUI-based UI with MVVM pattern
/// - Core Data for local persistence with NSFileProtectionComplete for HIPAA compliance
/// - Repository pattern for data access layer abstraction
/// - App Groups (`group.com.AAFU.Sessions`) for secure data sharing between iOS and watchOS
/// 
/// **Key Features:**
/// - Client management with therapy goal tracking
/// - Session logging with customizable goal templates
/// - Progress tracking with cue level support
/// - Cross-platform sync between iOS and watchOS (Stage 4)
@main
struct SessionsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
