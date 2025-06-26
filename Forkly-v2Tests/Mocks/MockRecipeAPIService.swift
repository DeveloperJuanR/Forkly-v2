//
//  MockRecipeAPIService.swift
//  Forkly-v2Tests
//
//  Created by Juan Rodriguez on 6/23/25.
//

import Foundation
@testable import Forkly_v2

class MockRecipeAPIService: RecipeAPIService {
    // MARK: - Mock Data
    var mockRecipes: [Recipe] = [
        Recipe(id: 1, title: "Test Recipe 1", image: "test_image_1"),
        Recipe(id: 2, title: "Test Recipe 2", image: "test_image_2")
    ]
    
    var mockRecipeDetail = RecipeDetail(
        id: 1,
        title: "Test Recipe Detail",
        summary: "This is a test summary with <b>HTML</b> tags.",
        image: "test_detail_image",
        instructions: "Step 1: Do this. Step 2: Do that."
    )
    
    // MARK: - Error Simulation
    var shouldReturnError = false
    var error: RecipeAPIError = .networkError(NSError(domain: "test", code: -1, userInfo: nil))
    
    // MARK: - Call Tracking
    var searchRecipesCalled = false
    var getRecipeDetailsCalled = false
    var fetchFeaturedRecipesCalled = false
    var lastSearchQuery: String?
    var lastRecipeId: Int?
    
    // MARK: - Override Methods
    override func searchRecipes(query: String, completion: @escaping (Result<[Recipe], RecipeAPIError>) -> Void) {
        searchRecipesCalled = true
        lastSearchQuery = query
        
        if shouldReturnError {
            completion(.failure(error))
        } else {
            completion(.success(mockRecipes))
        }
    }
    
    override func getRecipeDetails(id: Int, completion: @escaping (Result<RecipeDetail, RecipeAPIError>) -> Void) {
        getRecipeDetailsCalled = true
        lastRecipeId = id
        
        if shouldReturnError {
            completion(.failure(error))
        } else {
            completion(.success(mockRecipeDetail))
        }
    }
    
    override func fetchFeaturedRecipes(completion: @escaping (Result<[Recipe], RecipeAPIError>) -> Void) {
        fetchFeaturedRecipesCalled = true
        
        if shouldReturnError {
            completion(.failure(error))
        } else {
            completion(.success(mockRecipes))
        }
    }
    
    // MARK: - Helper Methods
    func reset() {
        searchRecipesCalled = false
        getRecipeDetailsCalled = false
        fetchFeaturedRecipesCalled = false
        lastSearchQuery = nil
        lastRecipeId = nil
        shouldReturnError = false
    }
} 