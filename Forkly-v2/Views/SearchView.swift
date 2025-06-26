//
//  SearchView.swift
//  Forkly
//
//  Created by Juan Rodriguez on 4/12/25.
//

import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = RecipeSearchViewModel()
    @EnvironmentObject var favoritesManager: FavoritesManager
    @Environment(\.dismiss) var dismiss
    
    // For text field focus management
    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Text("Find a Recipe")
                    .font(.custom("Pacifico-Regular", size: 28))
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top)
//                    .foregroundColor(Color(red: 0.0, green: 112/255, blue: 74/255))
//                    .shadow(color: Color.black.opacity(0.25), radius: 2, x: 1, y: 1)
                
                // Search bar
                HStack {
                    TextField("Search for recipes...", text: $viewModel.query)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isSearchFieldFocused)
                        .onSubmit {
                            viewModel.search()
                        }
                    
                    Button(action: viewModel.search) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.orange)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Advanced search toggle
                HStack {
                    Button(action: {
                        withAnimation {
                            viewModel.showAdvancedOptions.toggle()
                        }
                    }) {
                        HStack {
                            Text(viewModel.showAdvancedOptions ? "Hide Filters" : "Show Filters")
                                .font(.subheadline)
                            
                            Image(systemName: viewModel.showAdvancedOptions ? "chevron.up" : "chevron.down")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    if viewModel.showAdvancedOptions {
                        Button("Reset", action: viewModel.resetFilters)
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 4)
                
                // Advanced search options
                if viewModel.showAdvancedOptions {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Cuisine picker
                            VStack(alignment: .leading) {
                                Text("Cuisine:")
                                    .font(.headline)
                                    .padding(.bottom, 4)
                                
                                Picker("Select a cuisine", selection: $viewModel.selectedCuisine) {
                                    Text("Any").tag(String?.none)
                                    ForEach(viewModel.availableCuisines, id: \.self) { cuisine in
                                        Text(cuisine).tag(String?.some(cuisine))
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                            
                            // Diet picker
                            VStack(alignment: .leading) {
                                Text("Diet:")
                                    .font(.headline)
                                    .padding(.bottom, 4)
                                
                                Picker("Select a diet", selection: $viewModel.selectedDiet) {
                                    Text("Any").tag(String?.none)
                                    ForEach(viewModel.availableDiets, id: \.self) { diet in
                                        Text(diet).tag(String?.some(diet))
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                            
                            // Meal Type picker
                            VStack(alignment: .leading) {
                                Text("Meal Type:")
                                    .font(.headline)
                                    .padding(.bottom, 4)
                                
                                Picker("Select a meal type", selection: $viewModel.selectedMealType) {
                                    Text("Any").tag(String?.none)
                                    ForEach(viewModel.availableMealTypes, id: \.self) { type in
                                        Text(type).tag(String?.some(type))
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                            
                            // Include ingredients
                            VStack(alignment: .leading) {
                                Text("Include Ingredients:")
                                    .font(.headline)
                                    .padding(.bottom, 4)
                                
                                TextField("e.g., tomato,cheese,pasta", text: Binding(
                                    get: { viewModel.includeIngredients ?? "" },
                                    set: { viewModel.includeIngredients = $0.isEmpty ? nil : $0 }
                                ))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                            }
                            
                            // Exclude ingredients
                            VStack(alignment: .leading) {
                                Text("Exclude Ingredients:")
                                    .font(.headline)
                                    .padding(.bottom, 4)
                                
                                TextField("e.g., nuts,shellfish", text: Binding(
                                    get: { viewModel.excludeIngredients ?? "" },
                                    set: { viewModel.excludeIngredients = $0.isEmpty ? nil : $0 }
                                ))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                            }
                            
                            // Max ready time
                            VStack(alignment: .leading) {
                                Text("Max Preparation Time (minutes):")
                                    .font(.headline)
                                    .padding(.bottom, 4)
                                
                                TextField("e.g., 30", text: Binding(
                                    get: { viewModel.maxReadyTime != nil ? String(viewModel.maxReadyTime!) : "" },
                                    set: { viewModel.maxReadyTime = Int($0) }
                                ))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                            }
                            
                            // Sort by
                            VStack(alignment: .leading) {
                                Text("Sort By:")
                                    .font(.headline)
                                    .padding(.bottom, 4)
                                
                                Picker("Sort by", selection: $viewModel.sortBy) {
                                    Text("Default").tag(String?.none)
                                    Text("Popularity").tag(String?.some("popularity"))
                                    Text("Healthiness").tag(String?.some("healthiness"))
                                    Text("Time").tag(String?.some("time"))
                                    Text("Calories").tag(String?.some("calories"))
                                }
                                .pickerStyle(MenuPickerStyle())
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                            
                            // Search button
                            Button(action: {
                                isSearchFieldFocused = false
                                viewModel.search()
                            }) {
                                Text("Search with Filters")
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.orange)
                                    .cornerRadius(10)
                            }
                            .padding(.vertical)
                        }
                        .padding()
                    }
                    .frame(height: 400)
                }

                // Loading state
                if viewModel.isLoading {
                    ProgressView("Searching...")
                        .padding()
                }

                // Error message
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }

                // Results
                ScrollView {
                    if viewModel.results.isEmpty && !viewModel.isLoading && viewModel.errorMessage == nil {
                        VStack(spacing: 20) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                                .padding(.top, 50)
                            
                            Text("Search for recipes by name or ingredients")
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.results, id: \.id) { recipe in
                                NavigationLink(value: recipe.id) {
                                    RecipeCardView(recipe: Recipe(
                                        id: recipe.id,
                                        title: recipe.title,
                                        image: recipe.image
                                    ))
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
//            .navigationTitle("Search")
//            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Int.self) { recipeID in
                // ✅ Using explicit return type here prevents "Generic parameter 'V'" error
                AnyView(RecipeDetailLoaderView(recipeID: recipeID))
            }
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        isSearchFieldFocused = false
                    }
                }
            }
        }
    }
}

#Preview {
    SearchView()
        .environmentObject(FavoritesManager()) // ✅ required for preview
}
