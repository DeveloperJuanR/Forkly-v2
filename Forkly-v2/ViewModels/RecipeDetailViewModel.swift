//
//  RecipeDetailViewModel.swift
//  Forkly-v2
//
//  Created by Juan Rodriguez on 6/23/25.
//

import Foundation
import Combine

class RecipeDetailViewModel: ObservableObject {
    @Published var recipeDetail: RecipeDetail?
    @Published var isLoading = true
    @Published var errorMessage: String?
    
    private let apiService = RecipeAPIService()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Load Recipe Details
    func loadRecipeDetails(id: Int) {
        isLoading = true
        errorMessage = nil
        
        apiService.getRecipeDetails(id: id) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let detail):
                    self?.recipeDetail = detail
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    func cleanedSummary() -> String {
        return recipeDetail?.summary?.cleanHTMLTags() ?? ""
    }
    
    func cleanedInstructions() -> String {
        return recipeDetail?.instructions?.cleanHTMLTags() ?? ""
    }
    
    func instructionSteps() -> [String] {
        return cleanedInstructions().splitIntoSteps()
    }
    
    func getSimpleRecipe() -> Recipe? {
        guard let detail = recipeDetail else { return nil }
        return Recipe(id: detail.id, title: detail.title, image: detail.image)
    }
} 