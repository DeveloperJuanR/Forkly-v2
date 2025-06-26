//
//  FavoritesView.swift
//  Forkly
//
//  Created by Juan Rodriguez on 4/12/25.
//

import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var favoritesManager: FavoritesManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                // Top bar
                Text("Your Favorites")
                    .font(.custom("Pacifico-Regular", size: 28))
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top)

                Divider()

                if favoritesManager.favorites.isEmpty {
                    VStack {
                        Text("No favorites yet.")
                            .foregroundColor(.secondary)
                            .padding()
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(favoritesManager.favorites) { recipe in
                                NavigationLink(value: recipe.id) {
                                    RecipeCardView(recipe: recipe)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationDestination(for: Int.self) { recipeID in
                RecipeDetailLoaderView(recipeID: recipeID)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(FavoritesManager())
}
