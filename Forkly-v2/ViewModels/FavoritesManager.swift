//
//  FavoritesManager.swift
//  Forkly-v2
//
//  Created by Juan Rodriguez on 4/12/25.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

/// Manages the user's favorite recipes with cloud synchronization
/// This class handles:
/// - Storing favorites in Firestore when the user is logged in
/// - Local storage fallback when offline or not logged in
/// - Adding and removing favorites
/// - Checking favorite status
class FavoritesManager: ObservableObject {
    // MARK: - Published Properties
    
    /// Array of the user's favorite recipes
    @Published var favorites: [Recipe] = []
    
    /// Indicates whether a data operation is in progress
    @Published var isLoading: Bool = false
    
    /// Error message from the most recent operation
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    /// Reference to the Firestore database
    private var db = Firestore.firestore()
    
    /// The current user's ID from Firebase Authentication
    private var userID: String? {
        Auth.auth().currentUser?.uid
    }
    
    /// Set of cancellables for managing Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Handle for the Firebase authentication state listener
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    /// Key used for local storage of favorites
    private let localKey = "favoriteRecipes" // Fallback for offline

    // MARK: - Initialization
    
    /// Creates a new favorites manager and loads initial data
    init() {
        loadFavorites()
        
        // Set up listener for authentication state changes
        // This ensures favorites are reloaded when the user signs in or out
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            if user != nil {
                self?.loadFavorites()
            } else {
                self?.favorites = []
            }
        }
    }
    
    /// Cleans up resources when the object is deallocated
    deinit {
        // Remove auth state listener to prevent memory leaks
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }

    // MARK: - Public Methods
    
    /// Toggles the favorite status of a recipe
    /// - Parameter recipe: The recipe to toggle
    func toggleFavorite(_ recipe: Recipe) {
        if let index = favorites.firstIndex(where: { $0.id == recipe.id }) {
            // Recipe is already a favorite, remove it
            favorites.remove(at: index)
        } else {
            // Recipe is not a favorite, add it
            favorites.append(recipe)
        }
        saveFavorites()
    }

    /// Checks if a recipe is in the user's favorites
    /// - Parameter recipe: The recipe to check
    /// - Returns: True if the recipe is a favorite, false otherwise
    func isFavorite(_ recipe: Recipe) -> Bool {
        favorites.contains { $0.id == recipe.id }
    }
    
    /// Gets a favorite recipe by its ID
    /// - Parameter id: The ID of the recipe to find
    /// - Returns: The favorite recipe if found, nil otherwise
    func getFavorite(withID id: Int) -> Recipe? {
        return favorites.first { $0.id == id }
    }

    // MARK: - Private Methods
    
    /// Saves favorites to Firestore and local storage
    private func saveFavorites() {
        isLoading = true
        
        // Always save to local storage as a fallback
        if let encoded = try? JSONEncoder().encode(self.favorites) {
            UserDefaults.standard.set(encoded, forKey: self.localKey)
        }
        
        // Check if we're using Firebase or in preview mode
        guard !isPreview() else {
            // In preview mode, just use local storage
            self.isLoading = false
            return
        }
        
        // Save to Firestore if user is logged in
        if let userID = userID {
            // Reference to the user's favorites collection
            let favoritesRef = db.collection("users").document(userID).collection("favorites")
            
            // First get existing docs to delete them
            favoritesRef.getDocuments { [weak self] (snapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = "Error loading favorites: \(error.localizedDescription)"
                    self.isLoading = false
                    return
                }
                
                guard let snapshot = snapshot else {
                    self.isLoading = false
                    return
                }
                
                // Create a batch operation for better performance and atomicity
                let batch = self.db.batch()
                
                // Delete all existing documents
                for document in snapshot.documents {
                    batch.deleteDocument(document.reference)
                }
                
                // Add new favorites
                for recipe in self.favorites {
                    if let recipeData = try? JSONEncoder().encode(recipe),
                       let recipeDict = try? JSONSerialization.jsonObject(with: recipeData) as? [String: Any] {
                        let docRef = favoritesRef.document("\(recipe.id)")
                        batch.setData(recipeDict, forDocument: docRef)
                    }
                }
                
                // Commit the batch
                batch.commit { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            self.errorMessage = "Error saving favorites: \(error.localizedDescription)"
                        }
                        self.isLoading = false
                    }
                }
            }
        } else {
            // No user logged in, just use local storage
            self.isLoading = false
        }
    }

    /// Loads favorites from Firestore if logged in, or local storage if not
    private func loadFavorites() {
        isLoading = true
        
        // Check if we're using Firebase or in preview mode
        guard !isPreview() else {
            // In preview mode, just use local storage
            loadFromLocal()
            return
        }
        
        // If user is logged in, try to load from Firestore
        if let userID = userID {
            let favoritesRef = db.collection("users").document(userID).collection("favorites")
            
            favoritesRef.getDocuments { [weak self] (snapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = "Error loading favorites: \(error.localizedDescription)"
                    self.loadFromLocal() // Fallback to local
                    return
                }
                
                guard let snapshot = snapshot else {
                    self.loadFromLocal() // Fallback to local
                    return
                }
                
                var loadedFavorites: [Recipe] = []
                
                // Convert Firestore documents to Recipe objects
                for document in snapshot.documents {
                    if let recipeData = try? JSONSerialization.data(withJSONObject: document.data()),
                       let recipe = try? JSONDecoder().decode(Recipe.self, from: recipeData) {
                        loadedFavorites.append(recipe)
                    }
                }
                
                DispatchQueue.main.async {
                    self.favorites = loadedFavorites
                    self.isLoading = false
                }
            }
        } else {
            // No user logged in, load from local
            loadFromLocal()
        }
    }
    
    /// Loads favorites from local storage (UserDefaults)
    private func loadFromLocal() {
        if let data = UserDefaults.standard.data(forKey: localKey),
           let decoded = try? JSONDecoder().decode([Recipe].self, from: data) {
            DispatchQueue.main.async {
                self.favorites = decoded
                self.isLoading = false
            }
        } else {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
    
    /// Detects if the code is running in a preview environment
    /// - Returns: True if in preview mode, false otherwise
    private func isPreview() -> Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}

