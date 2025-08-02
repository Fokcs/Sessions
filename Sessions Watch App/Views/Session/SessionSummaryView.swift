import SwiftUI

struct SessionSummaryView: View {
    let sessionSummary: SessionSummary
    @Environment(\.dismiss) private var dismiss
    
    let onNewSession: () -> Void
    let onShare: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Scrollable content
                ScrollView {
                    LazyVStack(spacing: 15) {
                        summaryHeaderSection
                        primaryStatsGrid
                        cuingLevelSection
                        goalBreakdownSection
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 15)
                }
                
                // Action buttons (fixed at bottom)
                actionButtons
            }
        }
        .background(Color.black)
        .navigationBarHidden(true)
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            // Current time
            Text(currentTimeFormatted)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.gray)
            
            Spacer()
            
            // Close button
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.03))
    }
    
    // MARK: - Summary Header Section
    
    private var summaryHeaderSection: some View {
        VStack(spacing: 6) {
            Text("Session Complete")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
            
            Text("\(sessionSummary.clientName) • \(sessionSummary.formattedDuration) duration")
                .font(.system(size: 8))
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Primary Stats Grid
    
    private var primaryStatsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
            StatCard(
                value: sessionSummary.successTrials,
                label: "SUCCESS",
                color: .green
            )
            
            StatCard(
                value: sessionSummary.failureTrials,
                label: "FAILED",
                color: .red
            )
            
            StatCard(
                value: sessionSummary.totalTrials,
                label: "TOTAL",
                color: .blue
            )
            
            StatCard(
                value: sessionSummary.successRate,
                label: "SUCCESS RATE",
                color: .orange,
                suffix: "%"
            )
        }
    }
    
    // MARK: - Cuing Level Section
    
    private var cuingLevelSection: some View {
        VStack(spacing: 8) {
            Text("CUING LEVELS USED")
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.gray)
            
            HStack(spacing: 0) {
                CuingLevelItem(
                    value: sessionSummary.cuingLevelBreakdown.independent,
                    label: "IND",
                    color: .blue
                )
                
                CuingLevelItem(
                    value: sessionSummary.cuingLevelBreakdown.minimal,
                    label: "MIN",
                    color: .green
                )
                
                CuingLevelItem(
                    value: sessionSummary.cuingLevelBreakdown.moderate,
                    label: "MOD",
                    color: .orange
                )
                
                CuingLevelItem(
                    value: sessionSummary.cuingLevelBreakdown.maximal,
                    label: "MAX",
                    color: .red
                )
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Goal Breakdown Section
    
    private var goalBreakdownSection: some View {
        VStack(spacing: 8) {
            Text("GOAL PERFORMANCE")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.gray)
            
            ForEach(sessionSummary.goalBreakdown, id: \.goalName) { goal in
                GoalPerformanceRow(goal: goal)
            }
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 8) {
            // Share button (secondary)
            Button(action: onShare) {
                Text("SHARE")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .frame(height: 32)
                    .background(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(PlainButtonStyle())
            
            // New session button (primary)
            Button(action: onNewSession) {
                Text("NEW SESSION")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 32)
                    .background(
                        LinearGradient(
                            colors: [Color.green, Color(red: 0.13, green: 0.55, blue: 0.13)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Color.black)
    }
    
    // MARK: - Helper Properties
    
    private var currentTimeFormatted: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let value: Int
    let label: String
    let color: Color
    let suffix: String?
    
    init(value: Int, label: String, color: Color, suffix: String? = nil) {
        self.value = value
        self.label = label
        self.color = color
        self.suffix = suffix
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)\(suffix ?? "")")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 7, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct CuingLevelItem: View {
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 6, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

struct GoalPerformanceRow: View {
    let goal: GoalPerformance
    
    var body: some View {
        HStack {
            Text(goal.goalName)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
            
            Spacer()
            
            HStack(spacing: 8) {
                // Percentage badge
                Text("\(goal.successRate)%")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(goal.performanceLevel.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(goal.performanceLevel.color.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
                // Count
                Text("\(goal.successCount)/\(goal.totalCount)")
                    .font(.system(size: 7))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Preview

struct SessionSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        let summary = SessionSummary(
            sessionId: UUID(),
            clientId: UUID(),
            clientName: "Sarah M.",
            startTime: Date().addingTimeInterval(-1200),
            endTime: Date(),
            duration: 1200,
            totalTrials: 30,
            successTrials: 23,
            failureTrials: 7,
            cuingLevelBreakdown: CueLevelStats(
                independent: 15,
                minimal: 8,
                moderate: 5,
                maximal: 2
            ),
            goalBreakdown: [
                GoalPerformance(goalName: "Water Drinking", successCount: 8, totalCount: 10),
                GoalPerformance(goalName: "Eye Contact", successCount: 6, totalCount: 8),
                GoalPerformance(goalName: "Verbal Response", successCount: 5, totalCount: 7),
                GoalPerformance(goalName: "Following Instructions", successCount: 4, totalCount: 5)
            ]
        )
        
        return SessionSummaryView(
            sessionSummary: summary,
            onNewSession: {},
            onShare: {}
        )
        .previewDevice("Apple Watch Series 7 - 45mm")
    }
}