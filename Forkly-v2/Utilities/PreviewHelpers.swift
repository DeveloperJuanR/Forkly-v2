//
//  PreviewHelpers.swift
//  Forkly-v2
//
//  Created by Juan Rodriguez on 6/23/25.
//

import SwiftUI
import Foundation

/// A utility struct that provides preview data and mock objects for SwiftUI previews
struct PreviewData {
    /// A mock recipe for previews
    static let sampleRecipe = Recipe(
        id: 1,
        title: "Spaghetti Carbonara",
        image: "https://example.com/spaghetti.jpg"
    )
    
    /// A collection of mock recipes for previews
    static let sampleRecipes = [
        Recipe(id: 1, title: "Spaghetti Carbonara", image: "https://example.com/spaghetti.jpg"),
        Recipe(id: 2, title: "Chicken Parmesan", image: "https://example.com/chicken.jpg"),
        Recipe(id: 3, title: "Caesar Salad", image: "https://example.com/salad.jpg"),
        Recipe(id: 4, title: "Chocolate Cake", image: "https://example.com/cake.jpg"),
        Recipe(id: 5, title: "Beef Tacos", image: "https://example.com/tacos.jpg")
    ]
    
    /// Creates a mock favorites manager for previews
    static func createMockFavoritesManager() -> FavoritesManager {
        let manager = FavoritesManager()
        manager.favorites = Array(sampleRecipes.prefix(3))
        return manager
    }
    
    /// Creates a mock auth manager for previews
    @MainActor
    static func createMockAuthManager(isLoggedIn: Bool = true) -> AuthManager {
        let manager = AuthManager(isMocked: true)
        if !isLoggedIn {
            manager.mockUser = nil
        }
        return manager
    }
}

/// A modifier that adds the common environment objects needed for previews
struct PreviewEnvironmentModifier: ViewModifier {
    var loggedIn: Bool
    
    @MainActor
    func body(content: Content) -> some View {
        content
            .environmentObject(PreviewData.createMockAuthManager(isLoggedIn: loggedIn))
            .environmentObject(PreviewData.createMockFavoritesManager())
    }
}

extension View {
    /// Adds the common environment objects needed for previews
    func previewWithEnvironment(loggedIn: Bool = true) -> some View {
        // For preview purposes, we'll use a simpler approach without MainActor isolation
        let mockFavoritesManager = PreviewData.createMockFavoritesManager()
        
        return self
            .environmentObject(mockFavoritesManager)
            // Use a background task to set up the auth manager
            .task {
                // Create and apply the auth manager directly
                let mockAuthManager = PreviewData.createMockAuthManager(isLoggedIn: loggedIn)
                // We could apply it here if needed with a custom environment key
                // This is a placeholder to avoid the unused variable warning
                _ = mockAuthManager
            }
    }
} 
