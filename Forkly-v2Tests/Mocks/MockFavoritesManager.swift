//
//  MockFavoritesManager.swift
//  Forkly-v2Tests
//
//  Created by Juan Rodriguez on 6/23/25.
//

import Foundation
@testable import Forkly_v2

class MockFavoritesManager: FavoritesManager {
    // MARK: - Mock Data
    var mockFavorites: [Recipe] = []
    
    // MARK: - Call Tracking
    var toggleFavoriteCalled = false
    var isFavoriteCalled = false
    var getFavoriteCalled = false
    var lastToggledRecipe: Recipe?
    var lastCheckedRecipe: Recipe?
    var lastCheckedId: Int?
    
    // MARK: - Override Methods
    override func toggleFavorite(_ recipe: Recipe) {
        toggleFavoriteCalled = true
        lastToggledRecipe = recipe
        
        if let index = mockFavorites.firstIndex(where: { $0.id == recipe.id }) {
            mockFavorites.remove(at: index)
        } else {
            mockFavorites.append(recipe)
        }
    }
    
    override func isFavorite(_ recipe: Recipe) -> Bool {
        isFavoriteCalled = true
        lastCheckedRecipe = recipe
        return mockFavorites.contains { $0.id == recipe.id }
    }
    
    override func getFavorite(withID id: Int) -> Recipe? {
        getFavoriteCalled = true
        lastCheckedId = id
        return mockFavorites.first { $0.id == id }
    }
    
    // MARK: - Helper Methods
    func reset() {
        mockFavorites = []
        toggleFavoriteCalled = false
        isFavoriteCalled = false
        getFavoriteCalled = false
        lastToggledRecipe = nil
        lastCheckedRecipe = nil
        lastCheckedId = nil
    }
} 