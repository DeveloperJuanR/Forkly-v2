//
//  FeaturedRecipesViewModel.swift
//  Forkly-v2
//
//  Created by Juan Rodriguez on 4/12/25.
//

import Foundation
import Combine

class FeaturedRecipesViewModel: ObservableObject {
    @Published var featuredRecipes: [Recipe] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Make apiService accessible for debugging
    let apiService = RecipeAPIService()
    private var cancellables = Set<AnyCancellable>()
    
    // Track which API method to use
    private var useAlternativeMethod = true
    
    // Default ingredients for featured recipes
    private let defaultIngredients = "carrot,tomato,potato,chicken,beef,pasta"
    
    init() {
        // Print API key info on initialization for debugging
        print("🔑 FeaturedRecipesViewModel: API Key starts with: \(apiService.getApiKey())")
    }

    func loadFeaturedRecipes(forceRefresh: Bool = false) {
        isLoading = true
        errorMessage = nil
        
        print("🔍 FeaturedRecipesViewModel: Starting to load featured recipes")
        print("🔑 Using API Key that starts with: \(apiService.getApiKey())")
        
        // First try the random recipes endpoint with the exact Postman parameters
        apiService.fetchFeaturedRecipes(forceRefresh: forceRefresh) { [weak self] result in
            switch result {
            case .success(let recipes):
                print("✅ FeaturedRecipesViewModel: Successfully loaded \(recipes.count) recipes from random endpoint")
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.featuredRecipes = recipes
                }
            case .failure(let error):
                print("⚠️ FeaturedRecipesViewModel: Error with random endpoint: \(error.localizedDescription), trying findByIngredients instead")
                
                // If the random endpoint fails, fall back to the findByIngredients endpoint
                self?.apiService.findRecipesByIngredients(
                    ingredients: self?.defaultIngredients ?? "carrot,tomato,potato,chicken,beef,pasta",
                    number: 10,
                    limitLicense: true,
                    ranking: 1,
                    ignorePantry: false
                ) { [weak self] ingredientsResult in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        
                        switch ingredientsResult {
                        case .success(let recipes):
                            print("✅ FeaturedRecipesViewModel: Successfully loaded \(recipes.count) recipes from findByIngredients endpoint")
                            self?.featuredRecipes = recipes
                        case .failure(let ingredientsError):
                            print("❌ FeaturedRecipesViewModel: Both endpoints failed. Final error: \(ingredientsError.localizedDescription)")
                            self?.errorMessage = ingredientsError.localizedDescription
                            
                            // More detailed error logging
                            if let apiError = ingredientsError as? RecipeAPIError {
                                switch apiError {
                                case .serverError(let code, let message):
                                    print("❌ Server Error (\(code)): \(message)")
                                    if code == 401 {
                                        print("❌ Authentication Error: Your API key may be invalid or expired")
                                    } else if code == 402 {
                                        print("❌ Payment Required: You may have exceeded your API quota")
                                    } else if code == 429 {
                                        print("❌ Rate Limited: Too many requests in a short period")
                                    }
                                case .decodingError(let decodingError):
                                    print("❌ JSON Decoding Error: \(decodingError)")
                                default:
                                    print("❌ Other API Error: \(apiError)")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Helper method to retry loading recipes
    func retryLoading() {
        loadFeaturedRecipes(forceRefresh: true)
    }
    
    // Switch between API methods
    func toggleApiMethod() {
        useAlternativeMethod.toggle()
        print("🔄 Switched to \(useAlternativeMethod ? "alternative" : "standard") method")
    }
}
