//
//  RecipeDetailViewModelTests.swift
//  Forkly-v2Tests
//
//  Created by Juan Rodriguez on 6/23/25.
//

import Testing
@testable import Forkly_v2

struct RecipeDetailViewModelTests {
    
    @Test func loadRecipeDetails_Success() async throws {
        // Arrange
        let mockService = MockRecipeAPIService()
        let viewModel = RecipeDetailViewModel()
        
        // Use reflection to inject the mock service
        Reflection.setProperty(named: "apiService", on: viewModel, to: mockService)
        
        // Act
        viewModel.loadRecipeDetails(id: 1)
        
        // Wait for async operation to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Assert
        #expect(mockService.getRecipeDetailsCalled)
        #expect(mockService.lastRecipeId == 1)
        #expect(viewModel.recipeDetail != nil)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test func loadRecipeDetails_Error() async throws {
        // Arrange
        let mockService = MockRecipeAPIService()
        mockService.shouldReturnError = true
        let viewModel = RecipeDetailViewModel()
        
        // Use reflection to inject the mock service
        Reflection.setProperty(named: "apiService", on: viewModel, to: mockService)
        
        // Act
        viewModel.loadRecipeDetails(id: 1)
        
        // Wait for async operation to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Assert
        #expect(mockService.getRecipeDetailsCalled)
        #expect(viewModel.recipeDetail == nil)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage != nil)
    }
    
    @Test func cleanedSummary_RemovesHTMLTags() async throws {
        // Arrange
        let mockService = MockRecipeAPIService()
        let viewModel = RecipeDetailViewModel()
        
        // Use reflection to inject the mock service
        Reflection.setProperty(named: "apiService", on: viewModel, to: mockService)
        
        // Act
        viewModel.loadRecipeDetails(id: 1)
        
        // Wait for async operation to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Assert
        let cleanedSummary = viewModel.cleanedSummary()
        #expect(!cleanedSummary.contains("<b>"))
        #expect(!cleanedSummary.contains("</b>"))
        #expect(cleanedSummary.contains("HTML"))
    }
    
    @Test func instructionSteps_SplitsIntoSteps() async throws {
        // Arrange
        let mockService = MockRecipeAPIService()
        mockService.mockRecipeDetail = RecipeDetail(
            id: 1,
            title: "Test Recipe",
            summary: "Test summary",
            image: "test_image",
            instructions: "First step. Second step. Third step."
        )
        let viewModel = RecipeDetailViewModel()
        
        // Use reflection to inject the mock service
        Reflection.setProperty(named: "apiService", on: viewModel, to: mockService)
        
        // Act
        viewModel.loadRecipeDetails(id: 1)
        
        // Wait for async operation to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Assert
        let steps = viewModel.instructionSteps()
        #expect(steps.count == 3)
        #expect(steps[0] == "First step")
        #expect(steps[1] == "Second step")
        #expect(steps[2] == "Third step")
    }
    
    @Test func getSimpleRecipe_ReturnsRecipeFromDetail() async throws {
        // Arrange
        let mockService = MockRecipeAPIService()
        let viewModel = RecipeDetailViewModel()
        
        // Use reflection to inject the mock service
        Reflection.setProperty(named: "apiService", on: viewModel, to: mockService)
        
        // Act
        viewModel.loadRecipeDetails(id: 1)
        
        // Wait for async operation to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Assert
        let recipe = viewModel.getSimpleRecipe()
        #expect(recipe != nil)
        #expect(recipe?.id == 1)
        #expect(recipe?.title == "Test Recipe Detail")
        #expect(recipe?.image == "test_detail_image")
    }
} 