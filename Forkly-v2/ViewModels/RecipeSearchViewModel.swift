//
//  RecipeSearchViewModel.swift
//  Forkly-v2
//
//  Created by Juan Rodriguez on 4/12/25.
//

import Foundation
import Combine

class RecipeSearchViewModel: ObservableObject {
    // MARK: - Search Parameters
    @Published var query: String = ""
    @Published var results: [Recipe] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Advanced search filters
    @Published var selectedCuisine: String? = nil
    @Published var selectedDiet: String? = nil
    @Published var selectedIntolerances: String? = nil
    @Published var selectedMealType: String? = nil
    @Published var includeIngredients: String? = nil
    @Published var excludeIngredients: String? = nil
    @Published var maxReadyTime: Int? = nil
    @Published var sortBy: String? = nil
    @Published var showAdvancedOptions: Bool = false
    
    // MARK: - Available Options
    let availableCuisines = [
        "African", "American", "British", "Cajun", "Caribbean", "Chinese", "Eastern European", 
        "European", "French", "German", "Greek", "Indian", "Irish", "Italian", "Japanese", 
        "Jewish", "Korean", "Latin American", "Mediterranean", "Mexican", "Middle Eastern", 
        "Nordic", "Southern", "Spanish", "Thai", "Vietnamese"
    ]
    
    let availableDiets = [
        "Gluten Free", "Ketogenic", "Vegetarian", "Lacto-Vegetarian", "Ovo-Vegetarian", 
        "Vegan", "Pescetarian", "Paleo", "Primal", "Low FODMAP", "Whole30"
    ]
    
    let availableIntolerances = [
        "Dairy", "Egg", "Gluten", "Grain", "Peanut", "Seafood", "Sesame", "Shellfish", 
        "Soy", "Sulfite", "Tree Nut", "Wheat"
    ]
    
    let availableMealTypes = [
        "Main Course", "Side Dish", "Dessert", "Appetizer", "Salad", "Bread", "Breakfast", 
        "Soup", "Beverage", "Sauce", "Marinade", "Fingerfood", "Snack", "Drink"
    ]
    
    let availableSortOptions = [
        "popularity", "healthiness", "price", "time", "random", 
        "max-used-ingredients", "min-missing-ingredients", "alcohol", "caffeine", 
        "copper", "energy", "calories", "calcium", "carbohydrates", "carbs", 
        "cholesterol", "choline", "fat", "fluoride", "fiber", "folate"
    ]

    private let apiService = RecipeAPIService()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Search Trigger
    func search() {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if we have any search criteria
        let hasQuery = !trimmedQuery.isEmpty
        let hasFilters = selectedCuisine != nil || selectedDiet != nil || 
                         selectedIntolerances != nil || selectedMealType != nil ||
                         includeIngredients != nil || excludeIngredients != nil ||
                         maxReadyTime != nil
        
        guard hasQuery || hasFilters else {
            results = []
            return
        }

        isLoading = true
        errorMessage = nil
        
        // If we have ingredients but no query, use the findByIngredients endpoint
        if !hasQuery && includeIngredients != nil && !includeIngredients!.isEmpty {
            print("🔍 Searching by ingredients: \(includeIngredients!)")
            
            apiService.findRecipesByIngredients(
                ingredients: includeIngredients!,
                number: 20,
                limitLicense: true,
                ranking: 1,
                ignorePantry: false
            ) { [weak self] result in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    switch result {
                    case .success(let recipes):
                        self?.results = recipes
                        if recipes.isEmpty {
                            self?.errorMessage = "No recipes found with these ingredients."
                        } else {
                            self?.errorMessage = nil
                        }
                    case .failure(let error):
                        self?.results = []
                        self?.errorMessage = error.localizedDescription
                    }
                }
            }
        } else {
            // Otherwise use the regular search endpoint
            print("🔍 Searching with query: \(trimmedQuery), cuisine: \(selectedCuisine ?? "none"), diet: \(selectedDiet ?? "none")")
            
            apiService.searchRecipes(
                query: trimmedQuery,
                cuisine: selectedCuisine,
                diet: selectedDiet,
                intolerances: selectedIntolerances,
                type: selectedMealType,
                includeIngredients: includeIngredients,
                excludeIngredients: excludeIngredients,
                maxReadyTime: maxReadyTime,
                sort: sortBy,
                number: 20,
                addRecipeInformation: false
            ) { [weak self] result in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    switch result {
                    case .success(let recipes):
                        self?.results = recipes
                        if recipes.isEmpty {
                            self?.errorMessage = "No recipes found matching your criteria."
                        } else {
                            self?.errorMessage = nil
                        }
                    case .failure(let error):
                        self?.results = []
                        self?.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Reset all search filters to their default values
    func resetFilters() {
        selectedCuisine = nil
        selectedDiet = nil
        selectedIntolerances = nil
        selectedMealType = nil
        includeIngredients = nil
        excludeIngredients = nil
        maxReadyTime = nil
        sortBy = nil
    }
}
