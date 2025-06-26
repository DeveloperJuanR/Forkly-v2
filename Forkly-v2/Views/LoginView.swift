//
//  LoginView.swift
//  Forkly-v2
//
//  Created by Juan Rodriguez on 6/23/25.
//

import SwiftUI

/// The login and signup view for user authentication
/// This view handles both new user registration and existing user login
struct LoginView: View {
    // MARK: - Properties
    
    /// Access to the authentication manager via environment
    @EnvironmentObject private var authManager: AuthManager
    
    /// User input fields
    @State private var email: String = ""
    @State private var password: String = ""
    
    /// Error handling states
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    /// Toggle between login and signup modes
    @State private var isSignUp = false
    
    // UI Colors
    private let accentColor = Color.orange
    private let backgroundColor = Color(.systemBackground)
    private let secondaryColor = Color(.systemGray5)

    // MARK: - Body
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [backgroundColor, backgroundColor.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Logo and welcome text section
                VStack(spacing: 10) {
                    Image(systemName: "fork.knife.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundColor(accentColor)
                    
                    Text("Welcome to Forkly")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(isSignUp ? "Create your account" : "Sign in to continue")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Input fields section
                VStack(spacing: 20) {
                    // Email field with icon
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.secondary)
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    .padding()
                    .background(secondaryColor.opacity(0.3))
                    .cornerRadius(12)
                    
                    // Password field with icon
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.secondary)
                        SecureField("Password", text: $password)
                            .textContentType(isSignUp ? .newPassword : .password)
                    }
                    .padding()
                    .background(secondaryColor.opacity(0.3))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 30)
                
                // Action buttons section
                VStack(spacing: 15) {
                    // Primary action button (Sign up or Login)
                    Button(action: {
                        if validateInputs() {
                            if isSignUp {
                                authManager.signUp(email: email, password: password)
                            } else {
                                authManager.signIn(email: email, password: password)
                            }
                        }
                    }) {
                        Text(isSignUp ? "Create Account" : "Sign In")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(accentColor)
                            .cornerRadius(12)
                    }
                    
                    // Toggle between signup and login
                    Button(action: {
                        withAnimation {
                            isSignUp.toggle()
                            showError = false
                        }
                    }) {
                        Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .font(.footnote)
                            .foregroundColor(accentColor)
                    }
                    .padding(.top, 5)
                }
                .padding(.horizontal, 30)
                
                // Error message display
                if showError {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .padding(.top, 10)
                }
                
                // Firebase authentication error display
                if let errorMsg = authManager.errorMessage {
                    Text(errorMsg)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .padding(.top, 10)
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    // MARK: - Helper Methods
    
    /// Validates user input and shows appropriate error messages
    /// - Returns: True if inputs are valid, false otherwise
    private func validateInputs() -> Bool {
        // Check for empty fields
        if email.isEmpty || password.isEmpty {
            errorMessage = "Email and password cannot be empty"
            showError = true
            return false
        }
        
        // Basic email format validation
        if !email.contains("@") || !email.contains(".") {
            errorMessage = "Please enter a valid email"
            showError = true
            return false
        }
        
        // Password length validation
        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters"
            showError = true
            return false
        }
        
        showError = false
        return true
    }
}

// Note: Preview is not available for this view due to Firebase dependencies
// Use the simulator to see this view in action
