//
//  Forkly_v2Tests.swift
//  Forkly-v2Tests
//
//  Created by Juan Rodriguez on 6/23/25.
//

import Testing
@testable import Forkly_v2

struct Forkly_v2Tests {
    // Main test suite that includes all the test cases
    @Test func runAllTests() async throws {
        // Run all the ViewModel tests
        try await FeaturedRecipesViewModelTests().loadFeaturedRecipes_Success()
        try await FeaturedRecipesViewModelTests().loadFeaturedRecipes_Error()
        
        try await RecipeSearchViewModelTests().search_WithEmptyQuery_ShouldNotCallAPI()
        try await RecipeSearchViewModelTests().search_WithWhitespaceQuery_ShouldNotCallAPI()
        try await RecipeSearchViewModelTests().search_WithValidQuery_Success()
        try await RecipeSearchViewModelTests().search_WithValidQuery_Error()
        
        try await RecipeDetailViewModelTests().loadRecipeDetails_Success()
        try await RecipeDetailViewModelTests().loadRecipeDetails_Error()
        try await RecipeDetailViewModelTests().cleanedSummary_RemovesHTMLTags()
        try await RecipeDetailViewModelTests().instructionSteps_SplitsIntoSteps()
        try await RecipeDetailViewModelTests().getSimpleRecipe_ReturnsRecipeFromDetail()
        
        try await FavoritesManagerTests().toggleFavorite_AddToEmptyFavorites()
        try await FavoritesManagerTests().toggleFavorite_RemoveFromFavorites()
        try await FavoritesManagerTests().isFavorite_WhenRecipeExists_ReturnsTrue()
        try await FavoritesManagerTests().isFavorite_WhenRecipeDoesNotExist_ReturnsFalse()
        try await FavoritesManagerTests().getFavorite_WhenRecipeExists_ReturnsRecipe()
        try await FavoritesManagerTests().getFavorite_WhenRecipeDoesNotExist_ReturnsNil()
    }
}
