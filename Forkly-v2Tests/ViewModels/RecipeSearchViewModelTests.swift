//
//  RecipeSearchViewModelTests.swift
//  Forkly-v2Tests
//
//  Created by Juan Rodriguez on 6/23/25.
//

import Testing
@testable import Forkly_v2

struct RecipeSearchViewModelTests {
    
    @Test func search_WithEmptyQuery_ShouldNotCallAPI() async throws {
        // Arrange
        let mockService = MockRecipeAPIService()
        let viewModel = RecipeSearchViewModel()
        
        // Use reflection to inject the mock service
        Reflection.setProperty(named: "apiService", on: viewModel, to: mockService)
        
        // Act
        viewModel.query = ""
        viewModel.search()
        
        // Wait for async operation to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Assert
        #expect(!mockService.searchRecipesCalled)
        #expect(viewModel.results.isEmpty)
    }
    
    @Test func search_WithWhitespaceQuery_ShouldNotCallAPI() async throws {
        // Arrange
        let mockService = MockRecipeAPIService()
        let viewModel = RecipeSearchViewModel()
        
        // Use reflection to inject the mock service
        Reflection.setProperty(named: "apiService", on: viewModel, to: mockService)
        
        // Act
        viewModel.query = "   "
        viewModel.search()
        
        // Wait for async operation to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Assert
        #expect(!mockService.searchRecipesCalled)
        #expect(viewModel.results.isEmpty)
    }
    
    @Test func search_WithValidQuery_Success() async throws {
        // Arrange
        let mockService = MockRecipeAPIService()
        let viewModel = RecipeSearchViewModel()
        
        // Use reflection to inject the mock service
        Reflection.setProperty(named: "apiService", on: viewModel, to: mockService)
        
        // Act
        viewModel.query = "pasta"
        viewModel.search()
        
        // Wait for async operation to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Assert
        #expect(mockService.searchRecipesCalled)
        #expect(mockService.lastSearchQuery == "pasta")
        #expect(viewModel.results.count == 2)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test func search_WithValidQuery_Error() async throws {
        // Arrange
        let mockService = MockRecipeAPIService()
        mockService.shouldReturnError = true
        let viewModel = RecipeSearchViewModel()
        
        // Use reflection to inject the mock service
        Reflection.setProperty(named: "apiService", on: viewModel, to: mockService)
        
        // Act
        viewModel.query = "pasta"
        viewModel.search()
        
        // Wait for async operation to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Assert
        #expect(mockService.searchRecipesCalled)
        #expect(viewModel.results.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage != nil)
    }
} 