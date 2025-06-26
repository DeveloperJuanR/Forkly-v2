//
//  RecipeCardView.swift
//  Forkly
//
//  Created by Juan Rodriguez on 4/12/25.
//

import SwiftUI

struct RecipeCardView: View {
    let recipe: Recipe
    @EnvironmentObject var favoritesManager: FavoritesManager
    @State private var showConfirmUnfavorite = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Image background (local or remote)
            Group {
                if recipe.isLocalImage {
                    Image(recipe.image ?? "")
                        .resizable()
                        .scaledToFill()
                } else if let imageUrl = recipe.image, !imageUrl.isEmpty, let url = URL(string: imageUrl) {
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
            }
            .frame(width: 375, height: 275)
            .clipped()
            .cornerRadius(16)

            // Gradient overlay for readability
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.7), Color.clear]),
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(height: 80)
            .cornerRadius(16)

            // Title + Heart button
            HStack {
                Text(recipe.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .shadow(radius: 2)

                Spacer()

                Button(action: {
                    if favoritesManager.isFavorite(recipe) {
                        showConfirmUnfavorite = true
                    } else {
                        favoritesManager.toggleFavorite(recipe)
                    }
                }) {
                    Image(systemName: favoritesManager.isFavorite(recipe) ? "heart.fill" : "heart")
                        .foregroundColor(.white)
                        .padding(.leading, 8)
                }
                .alert(isPresented: $showConfirmUnfavorite) {
                    Alert(
                        title: Text("Unfavorite Recipe"),
                        message: Text("Are you sure you want to remove this recipe from your favorites?"),
                        primaryButton: .destructive(Text("Remove")) {
                            favoritesManager.toggleFavorite(recipe)
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
            .padding()
        }
        .frame(width: 375, height: 275)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.35), radius: 8, x: 0, y: 4)
    }
}



#Preview {
    let manager = FavoritesManager()
    manager.favorites = [
        Recipe(id: 1, title: "Avocado Toast", image: "avocado_toast"),
        Recipe(id: 2, title: "Spaghetti Carbonara", image: "spaghetti_carbonara")
    ]

    return ContentView()
        .environmentObject(manager)
}
