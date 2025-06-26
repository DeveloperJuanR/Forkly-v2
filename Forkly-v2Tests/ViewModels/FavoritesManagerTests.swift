//
//  FavoritesManagerTests.swift
//  Forkly-v2Tests
//
//  Created by Juan Rodriguez on 6/23/25.
//

import Testing
@testable import Forkly_v2

struct FavoritesManagerTests {
    
    // Helper function to create a test recipe
    func createTestRecipe(id: Int, title: String) -> Recipe {
        return Recipe(id: id, title: title, image: "test_image_\(id)")
    }
    
    @Test func toggleFavorite_AddToEmptyFavorites() async throws {
        // Arrange
        let mockManager = MockFavoritesManager()
        let recipe = createTestRecipe(id: 1, title: "Test Recipe 1")
        
        // Act
        mockManager.toggleFavorite(recipe)
        
        // Assert
        #expect(mockManager.toggleFavoriteCalled)
        #expect(mockManager.lastToggledRecipe?.id == 1)
        #expect(mockManager.mockFavorites.count == 1)
        #expect(mockManager.mockFavorites[0].id == 1)
    }
    
    @Test func toggleFavorite_RemoveFromFavorites() async throws {
        // Arrange
        let mockManager = MockFavoritesManager()
        let recipe = createTestRecipe(id: 1, title: "Test Recipe 1")
        mockManager.mockFavorites = [recipe]
        
        // Act
        mockManager.toggleFavorite(recipe)
        
        // Assert
        #expect(mockManager.toggleFavoriteCalled)
        #expect(mockManager.lastToggledRecipe?.id == 1)
        #expect(mockManager.mockFavorites.isEmpty)
    }
    
    @Test func isFavorite_WhenRecipeExists_ReturnsTrue() async throws {
        // Arrange
        let mockManager = MockFavoritesManager()
        let recipe = createTestRecipe(id: 1, title: "Test Recipe 1")
        mockManager.mockFavorites = [recipe]
        
        // Act
        let result = mockManager.isFavorite(recipe)
        
        // Assert
        #expect(mockManager.isFavoriteCalled)
        #expect(mockManager.lastCheckedRecipe?.id == 1)
        #expect(result)
    }
    
    @Test func isFavorite_WhenRecipeDoesNotExist_ReturnsFalse() async throws {
        // Arrange
        let mockManager = MockFavoritesManager()
        let recipe = createTestRecipe(id: 1, title: "Test Recipe 1")
        
        // Act
        let result = mockManager.isFavorite(recipe)
        
        // Assert
        #expect(mockManager.isFavoriteCalled)
        #expect(mockManager.lastCheckedRecipe?.id == 1)
        #expect(!result)
    }
    
    @Test func getFavorite_WhenRecipeExists_ReturnsRecipe() async throws {
        // Arrange
        let mockManager = MockFavoritesManager()
        let recipe = createTestRecipe(id: 1, title: "Test Recipe 1")
        mockManager.mockFavorites = [recipe]
        
        // Act
        let result = mockManager.getFavorite(withID: 1)
        
        // Assert
        #expect(mockManager.getFavoriteCalled)
        #expect(mockManager.lastCheckedId == 1)
        #expect(result != nil)
        #expect(result?.id == 1)
        #expect(result?.title == "Test Recipe 1")
    }
    
    @Test func getFavorite_WhenRecipeDoesNotExist_ReturnsNil() async throws {
        // Arrange
        let mockManager = MockFavoritesManager()
        
        // Act
        let result = mockManager.getFavorite(withID: 1)
        
        // Assert
        #expect(mockManager.getFavoriteCalled)
        #expect(mockManager.lastCheckedId == 1)
        #expect(result == nil)
    }
} 