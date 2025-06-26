//
//  Recipe.swift
//  Forkly
//
//  Created by Juan Rodriguez on 4/12/25.
//

import Foundation

struct Recipe: Identifiable, Codable, Hashable {
    let id: Int
    let title: String
    let image: String?

    // Additional fields that might be in the API response
    let imageType: String?
    let servings: Int?
    let readyInMinutes: Int?
    let sourceName: String?
    let sourceUrl: String?
    let spoonacularScore: Double?
    let healthScore: Double?
    let pricePerServing: Double?
    
    // CodingKeys to make some fields optional
    enum CodingKeys: String, CodingKey {
        case id, title, image, imageType, servings, readyInMinutes
        case sourceName, sourceUrl, spoonacularScore, healthScore, pricePerServing
    }
    
    // Custom initializer with required fields only
    init(id: Int, title: String, image: String?) {
        self.id = id
        self.title = title
        self.image = image
        self.imageType = nil
        self.servings = nil
        self.readyInMinutes = nil
        self.sourceName = nil
        self.sourceUrl = nil
        self.spoonacularScore = nil
        self.healthScore = nil
        self.pricePerServing = nil
    }
    
    // Property to determine if image is local or remote
    var isLocalImage: Bool {
        if let image = image {
            return !image.contains("http")
        }
        return false
    }
}
