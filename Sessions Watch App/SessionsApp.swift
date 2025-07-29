//
//  SessionsApp.swift
//  Sessions Watch App
//
//  Created by Aaron Fuchs on 7/27/25.
//

import SwiftUI

/// Main entry point for the Sessions watchOS application
/// 
/// **Platform-Specific Design:**
/// The watchOS version of Sessions is designed for quick, glanceable therapy logging
/// during active sessions. It complements the iOS app with streamlined interactions
/// optimized for the smaller screen and gesture-based navigation.
/// 
/// **Architecture Consistency:**
/// - Shares the same Core Data model and repository patterns as iOS
/// - Uses identical Swift model structs for data consistency
/// - Accesses shared app group container for real-time data sync
/// 
/// **Key Differences from iOS:**
/// - Optimized for quick session logging and timer functions
/// - Simplified navigation suitable for small screen real estate
/// - Focus on active session management rather than comprehensive client management
/// - Designed for therapist's non-dominant hand during therapy sessions
/// 
/// **Future Integration (Stage 4):**
/// Will include WatchConnectivity for seamless data sync and session handoff
/// between iOS and watchOS platforms during therapy sessions.
@main
struct Sessions_Watch_AppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
