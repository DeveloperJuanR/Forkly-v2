//
//  FeaturedRecipesView.swift
//  Forkly
//
//  Created by Juan Rodriguez on 4/12/25.
//

import SwiftUI

struct FeaturedRecipesView: View {
    @StateObject private var viewModel = FeaturedRecipesViewModel()
    @State private var isTestingApiKey = false
    @State private var apiKeyStatus: String = ""
    @State private var apiKeyValid: Bool = false

    var body: some View {
        NavigationStack {
            VStack {
                Text("Featured Recipes")
                    .font(.custom("Pacifico-Regular", size: 28))
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top)
//                        .foregroundColor(Color(red: 0.0, green: 112/255, blue: 74/255))
//                        .shadow(color: Color.black.opacity(0.25), radius: 2, x: 1, y: 1)
                    
                Divider()

                if viewModel.isLoading {
                    ProgressView("Loading Recipes...")
                        .padding()
                } else if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Text("Error loading recipes:")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // API Key testing section
                        Button("Test API Key") {
                            isTestingApiKey = true
                            apiKeyStatus = "Testing API key..."
                            
                            viewModel.apiService.testApiKey { isValid, message in
                                apiKeyValid = isValid
                                apiKeyStatus = message
                                isTestingApiKey = false
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(.blue)
                        
                        if isTestingApiKey {
                            ProgressView("Testing API key...")
                        } else if !apiKeyStatus.isEmpty {
                            Text(apiKeyStatus)
                                .foregroundColor(apiKeyValid ? .green : .red)
                                .padding(.vertical, 5)
                        }
                        
                        // Toggle API method button
                        Button("Toggle API Method") {
                            viewModel.toggleApiMethod()
                            viewModel.retryLoading()
                        }
                        .buttonStyle(.bordered)
                        .tint(.orange)
                        
                        Button("Try Again") {
                            viewModel.retryLoading()
                        }
                        .buttonStyle(.bordered)
                        .tint(.blue)
                        
                        // Troubleshooting tips
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Troubleshooting Tips:")
                                .font(.headline)
                                .padding(.top)
                            
                            Text("• Check that your API key is correct")
                            Text("• Verify you haven't exceeded API quota limits")
                            Text("• Check your internet connection")
                            Text("• Try again in a few minutes")
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                    .padding()
                } else if viewModel.featuredRecipes.isEmpty {
                    VStack {
                        Text("No recipes found")
                            .font(.headline)
                            .padding()
                        
                        Button("Refresh") {
                            viewModel.loadFeaturedRecipes()
                        }
                        .buttonStyle(.bordered)
                        .tint(.blue)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(viewModel.featuredRecipes) { recipe in
                                NavigationLink(value: recipe.id) {
                                    RecipeCardView(recipe: recipe)
                                }
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        viewModel.loadFeaturedRecipes()
                    }
                }
            }
            .onAppear {
                viewModel.loadFeaturedRecipes()
            }
            .navigationDestination(for: Int.self) { recipeID in
                RecipeDetailLoaderView(recipeID: recipeID)
            }
        }
    }
}

#Preview {
    FeaturedRecipesView()
}
