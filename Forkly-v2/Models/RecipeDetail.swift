//
//  RecipeDetail.swift
//  Forkly
//
//  Created by Juan Rodriguez on 4/12/25.
//

import Foundation

struct RecipeDetail: Identifiable, Codable, Hashable {
    let id: Int
    let title: String
    let summary: String?
    let image: String?
    let instructions: String?
    
    // Additional fields that might be in the API response
    let servings: Int?
    let readyInMinutes: Int?
    let sourceName: String?
    let sourceUrl: String?
    let spoonacularScore: Double?
    let healthScore: Double?
    let pricePerServing: Double?
    let dishTypes: [String]?
    let diets: [String]?
    let occasions: [String]?
    let extendedIngredients: [Ingredient]?
    
    // CodingKeys to make some fields optional
    enum CodingKeys: String, CodingKey {
        case id, title, summary, image, instructions
        case servings, readyInMinutes, sourceName, sourceUrl
        case spoonacularScore, healthScore, pricePerServing
        case dishTypes, diets, occasions, extendedIngredients
    }
    
    // Custom initializer with required fields only
    init(id: Int, title: String, summary: String?, image: String?, instructions: String?) {
        self.id = id
        self.title = title
        self.summary = summary
        self.image = image
        self.instructions = instructions
        self.servings = nil
        self.readyInMinutes = nil
        self.sourceName = nil
        self.sourceUrl = nil
        self.spoonacularScore = nil
        self.healthScore = nil
        self.pricePerServing = nil
        self.dishTypes = nil
        self.diets = nil
        self.occasions = nil
        self.extendedIngredients = nil
    }
}

// Ingredient model for recipe details
struct Ingredient: Codable, Hashable {
    let id: Int?
    let name: String?
    let amount: Double?
    let unit: String?
    let original: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, amount, unit, original
    }
}
