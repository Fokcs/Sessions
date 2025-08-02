import SwiftUI

struct CueLevelPickerView: View {
    @ObservedObject var sessionViewModel: SessionViewModel
    @State private var timeRemaining = 3
    @State private var selectedLevel: CueLevel? = nil
    @State private var timer: Timer?
    @State private var isButtonPressed: [CueLevel: Bool] = [:]
    
    private let pickerSize: CGFloat = 140
    private let buttonSize: CGFloat = 35
    private let centerSize: CGFloat = 70
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture {
                    // Prevent dismissal by tapping background
                }
            
            // Main picker container
            VStack {
                Spacer()
                
                ZStack {
                    // Center countdown circle
                    centerCountdown
                    
                    // Circular button layout
                    circularButtons
                }
                .frame(width: pickerSize, height: pickerSize)
                
                Spacer()
            }
        }
        .onAppear {
            startCountdown()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    // MARK: - Center Countdown
    
    private var centerCountdown: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: centerSize, height: centerSize)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                )
            
            // Countdown text
            Text("\(timeRemaining)")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Circular Buttons
    
    private var circularButtons: some View {
        ZStack {
            ForEach(CueLevel.allCases, id: \.self) { level in
                cueLevelButton(for: level)
                    .position(buttonPosition(for: level))
            }
        }
        .frame(width: pickerSize, height: pickerSize)
    }
    
    private func cueLevelButton(for level: CueLevel) -> some View {
        Button(action: { selectLevel(level) }) {
            Text(level.displayName.uppercased())
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white)
                .frame(width: buttonSize, height: buttonSize)
                .background(level.gradient)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.6), lineWidth: 2)
                )
                .scaleEffect(buttonScale(for: level))
                .shadow(
                    color: selectedLevel == level ? level.color : Color.clear,
                    radius: 15,
                    x: 0,
                    y: 0
                )
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, perform: {}) { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isButtonPressed[level] = pressing
            }
        }
    }
    
    // MARK: - Button Positioning
    
    private func buttonPosition(for level: CueLevel) -> CGPoint {
        let center = CGPoint(x: pickerSize / 2, y: pickerSize / 2)
        let radius = (pickerSize - buttonSize) / 2 - 8
        
        let angle: Double
        switch level {
        case .independent: angle = -90  // Top (12 o'clock)
        case .minimal: angle = 0        // Right (3 o'clock)
        case .moderate: angle = 90      // Bottom (6 o'clock)
        case .maximal: angle = 180      // Left (9 o'clock)
        }
        
        let radians = angle * .pi / 180
        let x = center.x + radius * cos(radians)
        let y = center.y + radius * sin(radians)
        
        return CGPoint(x: x, y: y)
    }
    
    // MARK: - Button Scaling
    
    private func buttonScale(for level: CueLevel) -> CGFloat {
        if selectedLevel == level {
            return 1.15
        } else if isButtonPressed[level] == true {
            return 1.1
        } else {
            return 1.0
        }
    }
    
    // MARK: - Level Selection
    
    private func selectLevel(_ level: CueLevel) {
        selectedLevel = level
        timer?.invalidate()
        
        // Add haptic feedback
        HapticManager.shared.cueLevelSelected()
        
        // Visual feedback with scaling animation
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedLevel = level
        }
        
        // Dismiss after brief delay for visual feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            sessionViewModel.addTrialWithCueLevel(level)
        }
    }
    
    // MARK: - Countdown Timer
    
    private func startCountdown() {
        timeRemaining = 3
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            timeRemaining -= 1
            
            if timeRemaining <= 0 {
                timer?.invalidate()
                autoSelectIndependent()
            }
        }
    }
    
    private func autoSelectIndependent() {
        selectedLevel = .independent
        
        // Add haptic feedback for auto-selection
        HapticManager.shared.autoTimeout()
        
        // Brief animation for auto-selection
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedLevel = .independent
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            sessionViewModel.addTrialWithCueLevel(.independent)
        }
    }
}

// MARK: - Preview

struct CueLevelPickerView_Previews: PreviewProvider {
    static var previews: some View {
        let stack = try! CoreDataStack(inMemory: true)
        let repository = SimpleCoreDataRepository(coreDataStack: stack)
        let sessionViewModel = SessionViewModel(repository: repository)
        sessionViewModel.showingCueLevelPicker = true
        
        return CueLevelPickerView(sessionViewModel: sessionViewModel)
            .previewDevice("Apple Watch Series 7 - 45mm")
    }
}