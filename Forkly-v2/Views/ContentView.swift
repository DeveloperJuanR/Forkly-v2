//
//  ContentView.swift
//  Forkly
//
//  Created by Juan Rodriguez on 4/12/25.
//

import SwiftUI

/// Main container view that handles app navigation and authentication state
/// This view determines which screen to show based on authentication state:
/// - Loading screen when app is initializing
/// - Login screen when user is not authenticated
/// - Main tab view when user is authenticated
struct ContentView: View {
    // MARK: - Properties
    
    /// Favorites manager for accessing user's saved recipes
    @EnvironmentObject var favoritesManager: FavoritesManager
    
    /// Authentication manager for user login state
    @EnvironmentObject var authManager: AuthManager
    
    /// Controls display of loading screen
    @State private var isLoading = true

    // MARK: - Body
    var body: some View {
        ZStack {
            // Show loading screen during initial app load
            if isLoading {
                LoadingView()
            } 
            // Show login screen if user is not authenticated
            else if authManager.isAuthenticated == false {
                LoginView()
            } 
            // Show main app interface if user is authenticated
            else {
                MainTabView()
            }
        }
        .onAppear {
            // Short artificial delay for better UX during app launch
            // Gives time for Firebase to initialize and check authentication state
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                isLoading = false
            }
        }
    }
}

/// Main tab view containing all primary app screens
/// This view is shown after successful authentication
struct MainTabView: View {
    // MARK: - Properties
    
    /// Favorites manager for accessing user's saved recipes
    @EnvironmentObject var favoritesManager: FavoritesManager
    
    // MARK: - Body
    var body: some View {
        TabView {
            // Featured recipes tab
            FeaturedRecipesView()
                .tabItem {
                    Label("Featured", systemImage: "star.fill")
                }

            // Favorites tab
            FavoritesView()
                .tabItem {
                    Label("Favorites", systemImage: "heart.fill")
                }

            // Search tab
            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
            
            // User profile tab
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .accentColor(.orange)
        .onAppear {
            // Configure the tab bar appearance for consistent glass effect
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

// Note: Preview is not available for this view due to Firebase dependencies
// Use the simulator to see this view in action
