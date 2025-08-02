import SwiftUI

struct StartView: View {
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @State private var showingClientSelection = false
    @State private var showingSettings = false
    @State private var selectedClient: Client?
    @State private var availableClients: [Client] = []
    
    private let repository: TherapyRepository
    
    init(repository: TherapyRepository) {
        self.repository = repository
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header Section
                headerView
                
                // Main Content
                mainContentView
                    .padding(.horizontal, 12)
                    .padding(.vertical, 15)
            }
        }
        .background(Color.black)
        .sheet(isPresented: $showingClientSelection) {
            clientSelectionView
        }
        .sheet(isPresented: $showingSettings) {
            settingsView
        }
        .onAppear {
            loadClients()
        }
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
            
            // Settings gear
            Button(action: { showingSettings = true }) {
                Image(systemName: "gear")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    // MARK: - Main Content View
    
    private var mainContentView: some View {
        VStack(spacing: 15) {
            // App Title
            Text("Goal Tracker")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Client Selection Section
            clientSelectionButton
            
            Spacer()
            
            // Start Button
            startButton
            
            Spacer()
        }
    }
    
    // MARK: - Client Selection Button
    
    private var clientSelectionButton: some View {
        Button(action: { showingClientSelection = true }) {
            VStack(spacing: 6) {
                Text("CURRENT CLIENT")
                    .font(.system(size: 7, weight: .medium))
                    .foregroundColor(.gray)
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedClient?.displayName ?? "Select Client")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.blue)
                        
                        Text("Tap to change")
                            .font(.system(size: 6))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Start Button
    
    private var startButton: some View {
        Button(action: startSession) {
            Text("START")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.black)
                .frame(width: 60, height: 60)
                .background(
                    LinearGradient(
                        colors: [Color.green, Color(red: 0.13, green: 0.55, blue: 0.13)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: Color.green.opacity(0.3), radius: 15, x: 0, y: 3)
                .scaleEffect(isStartButtonPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(selectedClient == nil)
        .opacity(selectedClient == nil ? 0.5 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, perform: {}, onPressingChanged: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isStartButtonPressed = pressing
            }
        })
    }
    
    @State private var isStartButtonPressed = false
    
    // MARK: - Client Selection View
    
    private var clientSelectionView: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    HStack {
                        Text("Select Client")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button("Done") {
                            showingClientSelection = false
                        }
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.blue)
                    }
                    
                    Text("Choose who you're working with")
                        .font(.system(size: 7))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                
                // Client List
                ScrollView {
                    LazyVStack(spacing: 5) {
                        ForEach(availableClients) { client in
                            clientRow(client)
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
            .background(Color.black)
            .navigationBarHidden(true)
        }
    }
    
    private func clientRow(_ client: Client) -> some View {
        Button(action: { selectClient(client) }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(client.displayName)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Age \(client.age)")
                        .font(.system(size: 6))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if selectedClient?.id == client.id {
                    Image(systemName: "checkmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                selectedClient?.id == client.id
                    ? Color.blue.opacity(0.2)
                    : Color.white.opacity(0.05)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        selectedClient?.id == client.id
                            ? Color.blue.opacity(0.3)
                            : Color.white.opacity(0.1),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Settings View
    
    private var settingsView: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Settings")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("Done") {
                        showingSettings = false
                    }
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.blue)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                
                // Settings List
                VStack(spacing: 6) {
                    settingRow(label: "Auto-timeout", value: "3 seconds")
                    settingRow(label: "Haptic feedback", value: "Enabled")
                    settingRow(label: "Data sync", value: "WiFi only")
                    settingRow(label: "App version", value: "1.0.0")
                }
                .padding(.horizontal, 12)
                
                Spacer()
            }
            .background(Color.black)
            .navigationBarHidden(true)
        }
    }
    
    private func settingRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 8))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    // MARK: - Helper Functions
    
    private var currentTimeFormatted: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: sessionViewModel.currentTime)
    }
    
    private func selectClient(_ client: Client) {
        selectedClient = client
        sessionViewModel.selectedClient = client
        
        // Auto-dismiss after selection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showingClientSelection = false
        }
        
        // Add haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    private func startSession() {
        guard let client = selectedClient else { return }
        
        // Use available goals from session view model
        let goals = Array(sessionViewModel.availableGoals.prefix(4))
        guard !goals.isEmpty else { return }
        
        sessionViewModel.startSession(with: client, goals: goals)
        
        // Navigation will be handled by parent view observing sessionViewModel.isSessionActive
    }
    
    private func loadClients() {
        Task {
            do {
                let clients = try await repository.getAllClients()
                await MainActor.run {
                    availableClients = clients
                    if selectedClient == nil, let firstClient = clients.first {
                        selectedClient = firstClient
                        sessionViewModel.selectedClient = firstClient
                    }
                }
            } catch {
                print("Error loading clients: \(error)")
            }
        }
    }
}