//
//  AuthManager.swift
//  Forkly-v2
//
//  Created by Juan Rodriguez on 6/23/25.
//

import Foundation
import FirebaseAuth
import SwiftUI

/// Mock User class for preview environments
/// This class mimics the Firebase User object for use in preview and testing
class MockUser {
    /// Unique identifier for the user
    let uid: String
    
    /// Email address of the user
    let email: String?
    
    /// Creates a new mock user with the specified ID and email
    /// - Parameters:
    ///   - uid: Unique identifier for the user
    ///   - email: Email address of the user
    init(uid: String, email: String?) {
        self.uid = uid
        self.email = email
    }
}

/// Authentication manager that handles user authentication operations
/// This class is responsible for:
/// - User sign-up
/// - User sign-in
/// - User sign-out
/// - Maintaining authentication state
@MainActor
class AuthManager: ObservableObject {
    // MARK: - Properties
    
    /// The current Firebase user, if authenticated
    @Published var user: User?
    
    /// Mock user for preview and testing environments
    @Published var mockUser: MockUser?
    
    /// Error message from the most recent authentication operation
    @Published var errorMessage: String?
    
    /// Indicates whether the manager is in mock mode (for previews and testing)
    let isMocked: Bool

    /// The email address of the current user
    var userEmail: String? {
        if isMocked {
            return mockUser?.email ?? "user@example.com"
        }
        return user?.email
    }
    
    /// Indicates whether a user is currently authenticated
    var isAuthenticated: Bool {
        if isMocked {
            return mockUser != nil
        }
        return user != nil
    }
    
    /// The unique identifier of the current user
    var userId: String? {
        if isMocked {
            return mockUser?.uid
        }
        return user?.uid
    }

    // MARK: - Initialization
    
    /// Creates a new authentication manager
    /// - Parameter isMocked: Whether to use mock data instead of real Firebase authentication
    init(isMocked: Bool = false) {
        self.isMocked = isMocked
        
        if isMocked {
            // Create a mock user for previews
            self.mockUser = MockUser(uid: "preview-user-id", email: "preview@example.com")
        } else {
            // Check for cached user for persisted login
            self.user = Auth.auth().currentUser
        }
    }

    // MARK: - Authentication Methods
    
    /// Creates a new user account with the provided email and password
    /// - Parameters:
    ///   - email: The email address for the new account
    ///   - password: The password for the new account
    func signUp(email: String, password: String) {
        if isMocked {
            self.mockUser = MockUser(uid: "mock-user-id", email: email)
            return
        }
        
        Task {
            do {
                let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
                self.user = authResult.user
                self.errorMessage = nil
            } catch {
                self.errorMessage = error.localizedDescription
                print("Sign up error: \(error.localizedDescription)")
            }
        }
    }

    /// Signs in an existing user with the provided email and password
    /// - Parameters:
    ///   - email: The email address of the user
    ///   - password: The password of the user
    func signIn(email: String, password: String) {
        if isMocked {
            self.mockUser = MockUser(uid: "mock-user-id", email: email)
            return
        }
        
        Task {
            do {
                let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
                self.user = authResult.user
                self.errorMessage = nil
            } catch {
                self.errorMessage = error.localizedDescription
                print("Sign in error: \(error.localizedDescription)")
            }
        }
    }

    /// Signs out the current user
    func signOut() {
        if isMocked {
            self.mockUser = nil
            return
        }
        
        do {
            try Auth.auth().signOut()
            user = nil
            errorMessage = nil
        } catch {
            self.errorMessage = error.localizedDescription
            print("Sign out error: \(error.localizedDescription)")
        }
    }
}
