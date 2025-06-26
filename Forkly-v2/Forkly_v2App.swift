//
//  Forkly_v2App.swift
//  Forkly-v2
//
//  Created by Juan Rodriguez on 6/23/25.
//

import SwiftUI
import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

/// Main application entry point
/// This is the root of the application that:
/// - Initializes Firebase services
/// - Configures global UI appearance
/// - Sets up environment objects for dependency injection
@main
struct Forkly_v2App: App {
    // MARK: - Properties
    
    /// Authentication manager for handling user login/logout
    /// This is injected into the view hierarchy as an environment object
    @StateObject private var authManager = AuthManager()
    
    /// Favorites manager for handling user's saved recipes
    /// This is injected into the view hierarchy as an environment object
    @StateObject private var favoritesManager = FavoritesManager()
    
    // MARK: - Initialization
    
    /// Initializes the app and configures required services
    init() {
        // Initialize Firebase - must be done once at app startup
        // This configures Firebase with the settings from GoogleService-Info.plist
        FirebaseApp.configure()
        
        // Configure TabBar appearance globally
        // This ensures consistent appearance across the app
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    
    // MARK: - Body
    
    /// The app's main scene
    var body: some Scene {
        WindowGroup {
            // ContentView is the root view of the application
            ContentView()
                // Inject environment objects for dependency injection
                // These will be available to all child views
                .environmentObject(authManager)
                .environmentObject(favoritesManager)
        }
    }
}
