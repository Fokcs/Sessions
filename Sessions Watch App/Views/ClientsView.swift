//
//  ClientsView.swift
//  Sessions Watch App
//
//  Created by Aaron Fuchs on 7/29/25.
//

import SwiftUI

/// Client management view with search functionality for the Sessions watchOS application
/// 
/// **Implementation Features:**
/// - Browse clients with search functionality
/// - Empty states and loading indicators
/// - Pull-to-refresh functionality
/// - Comprehensive accessibility support
/// - Error handling with retry options
/// 
/// **Architecture Notes:**
/// - Follows MVVM pattern with ClientListViewModel
/// - Integrates with SimpleCoreDataRepository via repository pattern
/// - Uses established error handling patterns with TherapyAppError
/// - Supports watchOS navigation patterns and VoiceOver accessibility
struct ClientsView: View {
    @StateObject private var viewModel = ClientListViewModel()
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.clients.isEmpty {
                    LoadingView()
                } else if viewModel.filteredClients.isEmpty {
                    EmptyStateView(isSearchActive: !viewModel.searchText.isEmpty)
                } else {
                    ClientListView(clients: viewModel.filteredClients)
                }
            }
            .navigationTitle("Clients")
            .searchable(text: $viewModel.searchText, prompt: "Search clients by name")
            .refreshable {
                await viewModel.refreshClients()
            }
            .errorAlert(error: viewModel.error) {
                viewModel.clearError()
            } onRetry: {
                Task { await viewModel.retryLastOperation() }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // TODO: Navigation to ClientEditView (future enhancement)
                    }) {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add new client")
                    .accessibilityHint("Creates a new client profile")
                }
            }
        }
        .task {
            await viewModel.loadClients()
        }
    }
}

/// Loading state view displayed during client data fetch
private struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading clients...")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading clients")
    }
}

/// Empty state view for when no clients exist or search returns no results
private struct EmptyStateView: View {
    let isSearchActive: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: isSearchActive ? "magnifyingglass" : "person.2.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            // Content
            VStack(spacing: 12) {
                Text(isSearchActive ? "No Results" : "No Clients")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(isSearchActive ? 
                     "No clients match your search." : 
                     "Add your first client to get started with therapy sessions.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isSearchActive ? "No search results found" : "No clients added yet")
    }
}

/// List view displaying client entries with navigation links
private struct ClientListView: View {
    let clients: [Client]
    
    var body: some View {
        List(clients) { client in
            NavigationLink(destination: ClientDetailViewPlaceholder(client: client)) {
                ClientRowView(client: client)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Client: \(client.displayName), \(client.displayDetails)")
            .accessibilityHint("Tap to view client details")
        }
        .listStyle(.plain)
    }
}

/// Individual client row view with name and details
private struct ClientRowView: View {
    let client: Client
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(client.displayName)
                .font(.headline)
                .foregroundStyle(.primary)
            
            Text(client.displayDetails)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

/// Placeholder view for client detail navigation (future implementation)
private struct ClientDetailViewPlaceholder: View {
    let client: Client
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.primary)
            
            Text(client.displayName)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Client details will be implemented in a future update")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .navigationTitle("Client Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// SwiftUI preview for ClientsView
/// Provides design-time preview in Xcode canvas for rapid UI development
#Preview {
    ClientsView()
}