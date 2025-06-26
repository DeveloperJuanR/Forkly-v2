//
//  RecipeDetailView.swift
//  Forkly-v2
//
//  Created by Juan Rodriguez on 4/12/25.
//

import SwiftUI

struct RecipeDetailView: View {
    let recipe: RecipeDetail
    @EnvironmentObject var favoritesManager: FavoritesManager
    
    var body: some View {
        let cleanedSummary = recipe.summary?.cleanHTMLTags() ?? ""
        let cleanedInstructions = recipe.instructions?.cleanHTMLTags() ?? ""
        let instructionSteps = cleanedInstructions.splitIntoSteps()
        
        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Image
                if let imageUrl = recipe.image, !imageUrl.isEmpty, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(height: 250)
                    .clipped()
                    .cornerRadius(16)
                } else {
                    // Fallback image or empty space
                    Color.gray
                        .frame(height: 250)
                        .cornerRadius(16)
                }
                
                // Title
                Text(recipe.title)
                    .font(.title)
                    .bold()
                
                let favoriteRecipe = Recipe(id: recipe.id, title: recipe.title, image: recipe.image)
                let isFavorite = favoritesManager.isFavorite(favoriteRecipe)

                Button(action: {
                    favoritesManager.toggleFavorite(favoriteRecipe)
                }) {
                    HStack {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(.red)
                        Text(isFavorite ? "Remove from Favorites" : "Add to Favorites")
                    }
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }               
                
                // Summary
                if !cleanedSummary.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Summary")
                            .font(.headline)

                        Text(cleanedSummary)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                            .lineSpacing(6)
                            .padding(.leading, 4) // this creates a paragraph indent feel
                    }
                }
                
                // Instructions
                VStack(alignment: .leading, spacing: 8) {
                    Text("Instructions")
                        .font(.headline)
                    
                    if instructionSteps.isEmpty {
                        Text("No instructions available.")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(Array(instructionSteps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top) {
                                Text("\(index + 1).")
                                    .bold()
                                Text(step)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Recipe Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
