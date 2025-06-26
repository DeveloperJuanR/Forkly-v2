//
//  RecipeDetailLoaderView.swift
//  Forkly-v2
//
//  Created by Juan Rodriguez on 4/12/25.
//

import SwiftUI

struct RecipeDetailLoaderView: View {
    let recipeID: Int
    @StateObject private var viewModel = RecipeDetailViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading recipe...")
            } else if let recipe = viewModel.recipeDetail {
                RecipeDetailView(recipe: recipe)
            } else {
                Text(viewModel.errorMessage ?? "Failed to load recipe.")
                    .foregroundColor(.red)
            }
        }
        .onAppear {
            viewModel.loadRecipeDetails(id: recipeID)
        }
    }
}
