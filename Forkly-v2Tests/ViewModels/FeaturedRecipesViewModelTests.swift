//
//  FeaturedRecipesViewModelTests.swift
//  Forkly-v2Tests
//
//  Created by Juan Rodriguez on 6/23/25.
//

import Testing
@testable import Forkly_v2

struct FeaturedRecipesViewModelTests {
    
    @Test func loadFeaturedRecipes_Success() async throws {
        // Arrange
        let mockService = MockRecipeAPIService()
        let viewModel = FeaturedRecipesViewModel()
        
        // Use reflection to inject the mock service
        let mirror = Mirror(reflecting: viewModel)
        if let apiServiceProperty = mirror.children.first(where: { $0.label == "apiService" }) {
            let apiServiceObject = apiServiceProperty.value as AnyObject
            // Replace the apiService with our mock
            Reflection.setProperty(named: "apiService", on: viewModel, to: mockService)
        }
        
        // Act
        viewModel.loadFeaturedRecipes()
        
        // Wait for async operation to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Assert
        #expect(mockService.fetchFeaturedRecipesCalled)
        #expect(viewModel.featuredRecipes.count == 2)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test func loadFeaturedRecipes_Error() async throws {
        // Arrange
        let mockService = MockRecipeAPIService()
        mockService.shouldReturnError = true
        let viewModel = FeaturedRecipesViewModel()
        
        // Use reflection to inject the mock service
        Reflection.setProperty(named: "apiService", on: viewModel, to: mockService)
        
        // Act
        viewModel.loadFeaturedRecipes()
        
        // Wait for async operation to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Assert
        #expect(mockService.fetchFeaturedRecipesCalled)
        #expect(viewModel.featuredRecipes.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage != nil)
    }
}

// Helper for setting private properties via reflection
enum Reflection {
    static func setProperty<T: AnyObject, V>(named propertyName: String, on target: T, to newValue: V) {
        var targetRef = target
        let mirror = Mirror(reflecting: target)
        
        for child in mirror.children {
            if child.label == propertyName {
                withUnsafeMutableBytes(of: &targetRef) { targetPtr in
                    let offset = MemoryLayout<T>.size - MemoryLayout<V>.size
                    let valuePtr = targetPtr.baseAddress!.advanced(by: offset).bindMemory(to: V.self, capacity: 1)
                    valuePtr.pointee = newValue
                }
                break
            }
        }
    }
} 