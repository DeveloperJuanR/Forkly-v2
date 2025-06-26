//
//  ProfileView.swift
//  Forkly-v2
//
//  Created by Juan Rodriguez on 6/23/25.
//

import SwiftUI

/// User profile view that displays user information and provides sign out functionality
struct ProfileView: View {
    // MARK: - Properties
    
    /// Authentication manager for user information and sign out functionality
    @EnvironmentObject var authManager: AuthManager
    
    /// Controls the display of the sign out confirmation dialog
    @State private var showingConfirmation = false
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // User profile section
                VStack(spacing: 10) {
                    // User avatar
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .foregroundColor(.orange)
                    
                    // User email display
                    Text(authManager.userEmail ?? "No Email")
                        .font(.title2)
                        .bold()
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Sign out button with confirmation dialog
                Button(action: {
                    showingConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Sign Out")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
                .confirmationDialog(
                    "Are you sure you want to sign out?",
                    isPresented: $showingConfirmation,
                    titleVisibility: .visible
                ) {
                    // Sign out action
                    Button("Sign Out", role: .destructive) {
                        authManager.signOut()
                    }
                    // Cancel action
                    Button("Cancel", role: .cancel) {}
                }
            }
            .navigationTitle("Profile")
        }
    }
}

// Note: Preview is not available for this view due to Firebase dependencies
// Use the simulator to see this view in action 