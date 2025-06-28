//
//  RecipeAPIService.swift
//  Forkly-v2
//
//  Created by Juan Rodriguez on 4/12/25.
//

import Foundation

/// Error types for the Recipe API
enum RecipeAPIError: Error {
    case invalidURL
    case networkError(Error)
    case noData
    case decodingError(Error)
    case serverError(Int, String)
    case jsonParsingError
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .noData:
            return "No data received"
        case .decodingError(let error):
            return "Failed to decode data: \(error.localizedDescription)"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        case .jsonParsingError:
            return "Failed to parse JSON response"
        }
    }
}

/// Service for interacting with the Spoonacular Recipe API
/// Handles searching recipes, fetching details, and getting featured recipes
class RecipeAPIService {
    // MARK: - Properties
    
    /// API key from the ApiKeys file (not committed to source control)
    private let apiKey: String
    
    /// Base URLs for different API endpoints
    private let baseSearchURL = "https://api.spoonacular.com/recipes/complexSearch"
    private let detailURL = "https://api.spoonacular.com/recipes/"
    private let randomURL = "https://api.spoonacular.com/recipes/random"
    private let findByIngredientsURL = "https://api.spoonacular.com/recipes/findByIngredients"
    
    /// Session configuration with extended timeout
    private let session: URLSession
    
    /// Cache for featured recipes
    private var cachedFeaturedRecipes: [Recipe]?
    private var featuredRecipesCacheTimestamp: Date?
    private let cacheValidityDuration: TimeInterval = 3600 // 1 hour
    
    // MARK: - Initialization
    
    /// Initialize the API service with the API key from ApiKeys
    init(apiKey: String = ApiKeys.spoonacularApiKey) {
        self.apiKey = apiKey
        
        // Create a session with extended timeout values
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 90 // 90 seconds for request timeout (default is 60)
        config.timeoutIntervalForResource = 180 // 3 minutes for resource timeout
        self.session = URLSession(configuration: config)
        
        print("📱 RecipeAPIService initialized with API key: \(String(apiKey.prefix(5)))...")
    }
    
    // MARK: - Debug Methods
    
    /// Get the API key (for debugging only)
    func getApiKey() -> String {
        // Only show first 5 characters for security
        return "\(String(apiKey.prefix(5)))..."
    }
    
    /// Test the API key with a simple request
    func testApiKey(completion: @escaping (Bool, String) -> Void) {
        // Use a simple ping endpoint to test the API key
        let urlString = "https://api.spoonacular.com/recipes/715538/information?apiKey=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            completion(false, "Invalid URL")
            return
        }
        
        print("🧪 Testing API key with a simple request...")
        let request = createRequest(url: url)
        
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(false, "Network error: \(error.localizedDescription)")
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(false, "Invalid response")
                }
                return
            }
            
            print("🧪 API Key test response code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 {
                DispatchQueue.main.async {
                    completion(true, "API key is valid")
                }
            } else if httpResponse.statusCode == 401 {
                var message = "API key is invalid (401 Unauthorized)"
                if let data = data, let errorString = String(data: data, encoding: .utf8) {
                    message += ": \(errorString)"
                }
                DispatchQueue.main.async {
                    completion(false, message)
                }
            } else {
                var message = "Unexpected status code: \(httpResponse.statusCode)"
                if let data = data, let errorString = String(data: data, encoding: .utf8) {
                    message += ": \(errorString)"
                }
                DispatchQueue.main.async {
                    completion(false, message)
                }
            }
        }.resume()
    }
    
    /// Helper method to log JSON data for debugging
    private func logJSONResponse(data: Data, endpoint: String) {
        do {
            // Try to parse as JSON to pretty print
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let prettyData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
                if let prettyString = String(data: prettyData, encoding: .utf8) {
                    print("📥 JSON Response from \(endpoint):")
                    print(prettyString)
                    return
                }
            } else if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                let prettyData = try JSONSerialization.data(withJSONObject: jsonArray, options: .prettyPrinted)
                if let prettyString = String(data: prettyData, encoding: .utf8) {
                    print("📥 JSON Array Response from \(endpoint):")
                    print(prettyString)
                    return
                }
            }
        } catch {
            // If JSON parsing fails, just print the raw string
            if let rawString = String(data: data, encoding: .utf8) {
                print("📥 Raw Response from \(endpoint) (not valid JSON):")
                print(rawString)
            } else {
                print("⚠️ Could not decode response data as string")
            }
        }
    }
    
    /// Create a URLRequest with proper headers for Spoonacular API
    private func createRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        // Add x-api-key header as an alternative authentication method
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        return request
    }

    // MARK: - Public Methods
    
    /// Search for recipes matching a query string with advanced filtering options
    /// - Parameters:
    ///   - query: The search query
    ///   - cuisine: Optional cuisine filter (e.g., "italian", "mexican")
    ///   - diet: Optional diet filter (e.g., "vegetarian", "vegan")
    ///   - intolerances: Optional intolerances filter (e.g., "gluten", "dairy")
    ///   - type: Optional meal type filter (e.g., "main course", "dessert")
    ///   - includeIngredients: Optional ingredients that should be included
    ///   - excludeIngredients: Optional ingredients that should be excluded
    ///   - maxReadyTime: Optional maximum preparation time in minutes
    ///   - sort: Optional sorting strategy (e.g., "popularity", "healthiness")
    ///   - number: Number of results to return (default: 10)
    ///   - addRecipeInformation: Whether to include additional recipe information
    ///   - completion: Callback with search results or error
    func searchRecipes(
        query: String,
        cuisine: String? = nil,
        diet: String? = nil,
        intolerances: String? = nil,
        type: String? = nil,
        includeIngredients: String? = nil,
        excludeIngredients: String? = nil,
        maxReadyTime: Int? = nil,
        sort: String? = nil,
        number: Int = 10,
        addRecipeInformation: Bool = false,
        completion: @escaping (Result<[Recipe], RecipeAPIError>) -> Void
    ) {
        guard var urlComponents = URLComponents(string: baseSearchURL) else {
            completion(.failure(.invalidURL))
            return
        }

        // Required parameters
        var queryItems = [
            URLQueryItem(name: "apiKey", value: apiKey),
            URLQueryItem(name: "number", value: String(number))
        ]
        
        // Add query if provided
        if !query.isEmpty {
            queryItems.append(URLQueryItem(name: "query", value: query))
        }
        
        // Add optional parameters if provided
        if let cuisine = cuisine {
            queryItems.append(URLQueryItem(name: "cuisine", value: cuisine))
        }
        
        if let diet = diet {
            queryItems.append(URLQueryItem(name: "diet", value: diet))
        }
        
        if let intolerances = intolerances {
            queryItems.append(URLQueryItem(name: "intolerances", value: intolerances))
        }
        
        if let type = type {
            queryItems.append(URLQueryItem(name: "type", value: type))
        }
        
        if let includeIngredients = includeIngredients {
            queryItems.append(URLQueryItem(name: "includeIngredients", value: includeIngredients))
        }
        
        if let excludeIngredients = excludeIngredients {
            queryItems.append(URLQueryItem(name: "excludeIngredients", value: excludeIngredients))
        }
        
        if let maxReadyTime = maxReadyTime {
            queryItems.append(URLQueryItem(name: "maxReadyTime", value: String(maxReadyTime)))
        }
        
        if let sort = sort {
            queryItems.append(URLQueryItem(name: "sort", value: sort))
        }
        
        // Add additional recipe information if requested
        if addRecipeInformation {
            queryItems.append(URLQueryItem(name: "addRecipeInformation", value: "true"))
        }
        
        urlComponents.queryItems = queryItems

        guard let url = urlComponents.url else {
            completion(.failure(.invalidURL))
            return
        }
        
        // Print the full URL for debugging (with API key masked)
        let maskedURL = url.absoluteString.replacingOccurrences(of: apiKey, with: "API_KEY")
        print("🌐 Making API request to: \(maskedURL)")
        
        // For debugging: Print the raw URL components
        print("🔍 URL Components:")
        print("  - Scheme: \(urlComponents.scheme ?? "nil")")
        print("  - Host: \(urlComponents.host ?? "nil")")
        print("  - Path: \(urlComponents.path)")
        print("  - Query Items:")
        for item in queryItems {
            let value = item.name == "apiKey" ? "API_KEY" : (item.value ?? "nil")
            print("    - \(item.name): \(value)")
        }
        
        let request = createRequest(url: url)
        
        // Print request headers for debugging
        print("📋 Request Headers:")
        request.allHTTPHeaderFields?.forEach { key, value in
            print("  - \(key): \(key.lowercased() == "x-api-key" ? "API_KEY" : value)")
        }
        
        session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(.networkError(error)))
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                DispatchQueue.main.async {
                    completion(.failure(.networkError(NSError(domain: "RecipeAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"]))))
                }
                return
            }
            
            print("📡 API Response status code: \(httpResponse.statusCode)")
            
            // Check for HTTP error status codes
            if httpResponse.statusCode < 200 || httpResponse.statusCode >= 300 {
                var errorMessage = "Server returned error status"
                if let data = data, let errorResponse = String(data: data, encoding: .utf8) {
                    errorMessage = errorResponse
                    print("❌ Error response: \(errorResponse)")
                }
                DispatchQueue.main.async {
                    completion(.failure(.serverError(httpResponse.statusCode, errorMessage)))
                }
                return
            }

            guard let data = data else {
                print("❌ No data received")
                DispatchQueue.main.async {
                    completion(.failure(.noData))
                }
                return
            }
            
            // Log the JSON response for debugging
            self.logJSONResponse(data: data, endpoint: "Search")

            do {
                let decoder = JSONDecoder()
                let decoded = try decoder.decode(RecipeSearchResponse.self, from: data)
                print("✅ Successfully decoded \(decoded.results.count) recipes")
                
                // Ensure we're updating UI on the main thread
                DispatchQueue.main.async {
                    completion(.success(decoded.results))
                }
            } catch {
                print("❌ Decoding error: \(error.localizedDescription)")
                
                // More detailed error logging for decoding errors
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("❌ Key '\(key.stringValue)' not found: \(context.debugDescription)")
                        print("❌ CodingPath: \(context.codingPath)")
                    case .valueNotFound(let type, let context):
                        print("❌ Value of type '\(type)' not found: \(context.debugDescription)")
                        print("❌ CodingPath: \(context.codingPath)")
                    case .typeMismatch(let type, let context):
                        print("❌ Type '\(type)' mismatch: \(context.debugDescription)")
                        print("❌ CodingPath: \(context.codingPath)")
                    case .dataCorrupted(let context):
                        print("❌ Data corrupted: \(context.debugDescription)")
                        print("❌ CodingPath: \(context.codingPath)")
                    @unknown default:
                        print("❌ Unknown decoding error: \(error)")
                    }
                }
                
                DispatchQueue.main.async {
                    completion(.failure(.decodingError(error)))
                }
            }
        }.resume()
    }

    /// Get detailed information about a specific recipe
    /// - Parameters:
    ///   - id: The recipe ID
    ///   - completion: Callback with recipe details or error
    func getRecipeDetails(id: Int, completion: @escaping (Result<RecipeDetail, RecipeAPIError>) -> Void) {
        guard var urlComponents = URLComponents(string: "\(detailURL)\(id)/information") else {
            completion(.failure(.invalidURL))
            return
        }
        
        // Use the exact parameters from the working Postman request
        urlComponents.queryItems = [
            URLQueryItem(name: "apiKey", value: apiKey),
            URLQueryItem(name: "includeNutrition", value: "false")
        ]
        
        guard let url = urlComponents.url else {
            completion(.failure(.invalidURL))
            return
        }
        
        print("🌐 Making API request to: \(url.absoluteString.replacingOccurrences(of: apiKey, with: "API_KEY"))")
        
        let request = createRequest(url: url)

        session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(.networkError(error)))
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                DispatchQueue.main.async {
                    completion(.failure(.networkError(NSError(domain: "RecipeAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"]))))
                }
                return
            }
            
            print("📡 API Response status code: \(httpResponse.statusCode)")
            
            // Check for HTTP error status codes
            if httpResponse.statusCode < 200 || httpResponse.statusCode >= 300 {
                var errorMessage = "Server returned error status"
                if let data = data, let errorResponse = String(data: data, encoding: .utf8) {
                    errorMessage = errorResponse
                    print("❌ Error response: \(errorResponse)")
                }
                DispatchQueue.main.async {
                    completion(.failure(.serverError(httpResponse.statusCode, errorMessage)))
                }
                return
            }

            guard let data = data else {
                print("❌ No data received")
                DispatchQueue.main.async {
                    completion(.failure(.noData))
                }
                return
            }
            
            // Log the JSON response for debugging
            self.logJSONResponse(data: data, endpoint: "RecipeDetail")

            do {
                let decoder = JSONDecoder()
                let detail = try decoder.decode(RecipeDetail.self, from: data)
                print("✅ Successfully decoded recipe detail: \(detail.title)")
                DispatchQueue.main.async {
                    completion(.success(detail))
                }
            } catch {
                print("❌ Decoding error: \(error.localizedDescription)")
                
                // More detailed error logging for decoding errors
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("❌ Key '\(key.stringValue)' not found: \(context.debugDescription)")
                        print("❌ CodingPath: \(context.codingPath)")
                    case .valueNotFound(let type, let context):
                        print("❌ Value of type '\(type)' not found: \(context.debugDescription)")
                        print("❌ CodingPath: \(context.codingPath)")
                    case .typeMismatch(let type, let context):
                        print("❌ Type '\(type)' mismatch: \(context.debugDescription)")
                        print("❌ CodingPath: \(context.codingPath)")
                    case .dataCorrupted(let context):
                        print("❌ Data corrupted: \(context.debugDescription)")
                        print("❌ CodingPath: \(context.codingPath)")
                    @unknown default:
                        print("❌ Unknown decoding error: \(error)")
                    }
                }
                
                DispatchQueue.main.async {
                    completion(.failure(.decodingError(error)))
                }
            }
        }.resume()
    }
    
    /// Get featured (random) recipes for the home screen
    /// - Parameter completion: Callback with featured recipes or error
    func fetchFeaturedRecipes(forceRefresh: Bool = false, completion: @escaping (Result<[Recipe], RecipeAPIError>) -> Void) {
        // Return cached data if available and not expired
        if !forceRefresh, 
           let cached = cachedFeaturedRecipes, 
           let timestamp = featuredRecipesCacheTimestamp,
           Date().timeIntervalSince(timestamp) < cacheValidityDuration {
            print("📋 Returning cached featured recipes (cached \(Int(Date().timeIntervalSince(timestamp))) seconds ago)")
            completion(.success(cached))
            return
        }
        
        // Use the exact parameters from the working Postman request
        guard var urlComponents = URLComponents(string: randomURL) else {
            completion(.failure(.invalidURL))
            return
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "apiKey", value: apiKey),
            URLQueryItem(name: "number", value: "5"),
            URLQueryItem(name: "sort", value: "random"),
            URLQueryItem(name: "addRecipeInformation", value: "true")
        ]
        
        guard let url = urlComponents.url else {
            completion(.failure(.invalidURL))
            return
        }
        
        // Print the full URL for debugging (with API key masked)
        let maskedURL = url.absoluteString.replacingOccurrences(of: apiKey, with: "API_KEY")
        print("🌐 Making featured recipes API request to: \(maskedURL)")
        
        let request = createRequest(url: url)
        
        session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(.networkError(error)))
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                DispatchQueue.main.async {
                    completion(.failure(.networkError(NSError(domain: "RecipeAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"]))))
                }
                return
            }
            
            print("📡 Featured Recipes API Response status code: \(httpResponse.statusCode)")
            
            // Check for HTTP error status codes
            if httpResponse.statusCode < 200 || httpResponse.statusCode >= 300 {
                var errorMessage = "Server returned error status"
                if let data = data, let errorResponse = String(data: data, encoding: .utf8) {
                    errorMessage = errorResponse
                    print("❌ Error response: \(errorResponse)")
                }
                
                DispatchQueue.main.async {
                    completion(.failure(.serverError(httpResponse.statusCode, errorMessage)))
                }
                return
            }
            
            guard let data = data else {
                print("❌ No data received")
                DispatchQueue.main.async {
                    completion(.failure(.noData))
                }
                return
            }
            
            // Log the JSON response for debugging
            self.logJSONResponse(data: data, endpoint: "FeaturedRecipes")
            
            do {
                let decoder = JSONDecoder()
                let decoded = try decoder.decode(FeaturedRecipeResponse.self, from: data)
                print("✅ Successfully decoded \(decoded.recipes.count) featured recipes")
                
                // Update cache on successful fetch
                self.cachedFeaturedRecipes = decoded.recipes
                self.featuredRecipesCacheTimestamp = Date()
                
                DispatchQueue.main.async {
                    completion(.success(decoded.recipes))
                }
            } catch {
                print("❌ Decoding error: \(error.localizedDescription)")
                
                // More detailed error logging for decoding errors
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("❌ Key '\(key.stringValue)' not found: \(context.debugDescription)")
                        print("❌ CodingPath: \(context.codingPath)")
                    case .valueNotFound(let type, let context):
                        print("❌ Value of type '\(type)' not found: \(context.debugDescription)")
                        print("❌ CodingPath: \(context.codingPath)")
                    case .typeMismatch(let type, let context):
                        print("❌ Type '\(type)' mismatch: \(context.debugDescription)")
                        print("❌ CodingPath: \(context.codingPath)")
                    case .dataCorrupted(let context):
                        print("❌ Data corrupted: \(context.debugDescription)")
                        print("❌ CodingPath: \(context.codingPath)")
                    @unknown default:
                        print("❌ Unknown decoding error: \(error)")
                    }
                }
                
                DispatchQueue.main.async {
                    completion(.failure(.decodingError(error)))
                }
            }
        }.resume()
    }

    /// Get featured recipes using the complexSearch endpoint instead of random
    /// This is an alternative implementation that might work better
    /// - Parameters:
    ///   - forceRefresh: Whether to force a refresh or use cached data
    ///   - completion: Callback with featured recipes or error
    func fetchFeaturedRecipesAlternative(forceRefresh: Bool = false, completion: @escaping (Result<[Recipe], RecipeAPIError>) -> Void) {
        // Return cached data if available and not expired
        if !forceRefresh, 
           let cached = cachedFeaturedRecipes, 
           let timestamp = featuredRecipesCacheTimestamp,
           Date().timeIntervalSince(timestamp) < cacheValidityDuration {
            print("📋 Returning cached featured recipes (cached \(Int(Date().timeIntervalSince(timestamp))) seconds ago)")
            completion(.success(cached))
            return
        }
        
        // Use complexSearch with sort=random instead of the random endpoint
        guard var urlComponents = URLComponents(string: baseSearchURL) else {
            completion(.failure(.invalidURL))
            return
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "apiKey", value: apiKey),
            URLQueryItem(name: "number", value: "5"),
            URLQueryItem(name: "sort", value: "random"),
            URLQueryItem(name: "addRecipeInformation", value: "true")
        ]

        guard let url = urlComponents.url else {
            completion(.failure(.invalidURL))
            return
        }
        
        let maskedURL = url.absoluteString.replacingOccurrences(of: apiKey, with: "API_KEY")
        print("🌐 Making alternative featured recipes API request to: \(maskedURL)")
        
        let request = createRequest(url: url)
        
        session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(.networkError(error)))
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                DispatchQueue.main.async {
                    completion(.failure(.networkError(NSError(domain: "RecipeAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"]))))
                }
                return
            }
            
            print("📡 Alternative Featured Recipes API Response status code: \(httpResponse.statusCode)")
            
            // Check for HTTP error status codes
            if httpResponse.statusCode < 200 || httpResponse.statusCode >= 300 {
                var errorMessage = "Server returned error status"
                if let data = data, let errorResponse = String(data: data, encoding: .utf8) {
                    errorMessage = errorResponse
                    print("❌ Error response: \(errorResponse)")
                }
                
                DispatchQueue.main.async {
                    completion(.failure(.serverError(httpResponse.statusCode, errorMessage)))
                }
                return
            }

            guard let data = data else {
                print("❌ No data received")
                DispatchQueue.main.async {
                    completion(.failure(.noData))
                }
                return
            }
            
            // Log the JSON response for debugging
            self.logJSONResponse(data: data, endpoint: "AlternativeFeaturedRecipes")

            do {
                let decoder = JSONDecoder()
                let decoded = try decoder.decode(RecipeSearchResponse.self, from: data)
                print("✅ Successfully decoded \(decoded.results.count) featured recipes")
                
                // Update cache on successful fetch
                self.cachedFeaturedRecipes = decoded.results
                self.featuredRecipesCacheTimestamp = Date()
                
                DispatchQueue.main.async {
                    completion(.success(decoded.results))
                }
            } catch {
                print("❌ Decoding error: \(error.localizedDescription)")
                
                // More detailed error logging for decoding errors
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("❌ Key '\(key.stringValue)' not found: \(context.debugDescription)")
                        print("❌ CodingPath: \(context.codingPath)")
                    case .valueNotFound(let type, let context):
                        print("❌ Value of type '\(type)' not found: \(context.debugDescription)")
                        print("❌ CodingPath: \(context.codingPath)")
                    case .typeMismatch(let type, let context):
                        print("❌ Type '\(type)' mismatch: \(context.debugDescription)")
                        print("❌ CodingPath: \(context.codingPath)")
                    case .dataCorrupted(let context):
                        print("❌ Data corrupted: \(context.debugDescription)")
                        print("❌ CodingPath: \(context.codingPath)")
                    @unknown default:
                        print("❌ Unknown decoding error: \(error)")
                    }
                }
                
                DispatchQueue.main.async {
                    completion(.failure(.decodingError(error)))
                }
            }
        }.resume()
    }

    /// Test different Spoonacular API endpoints to find one that works
    /// - Parameter completion: Callback with results of each test
    func testSpoonacularEndpoints(completion: @escaping (String) -> Void) {
        var results = "Testing Spoonacular API endpoints:\n"
        let dispatchGroup = DispatchGroup()
        
        // Test 1: Random recipes endpoint
        dispatchGroup.enter()
        let randomURL = "https://api.spoonacular.com/recipes/random?number=1&apiKey=\(apiKey)"
        testEndpoint(name: "Random Recipes", url: randomURL) { result in
            results += result + "\n\n"
            dispatchGroup.leave()
        }
        
        // Test 2: Complex search endpoint
        dispatchGroup.enter()
        let searchURL = "https://api.spoonacular.com/recipes/complexSearch?query=pasta&number=1&apiKey=\(apiKey)"
        testEndpoint(name: "Complex Search", url: searchURL) { result in
            results += result + "\n\n"
            dispatchGroup.leave()
        }
        
        // Test 3: Recipe information endpoint
        dispatchGroup.enter()
        let infoURL = "https://api.spoonacular.com/recipes/716429/information?apiKey=\(apiKey)"
        testEndpoint(name: "Recipe Information", url: infoURL) { result in
            results += result + "\n\n"
            dispatchGroup.leave()
        }
        
        // Test 4: Ingredients search endpoint
        dispatchGroup.enter()
        let ingredientsURL = "https://api.spoonacular.com/recipes/findByIngredients?ingredients=apples,flour,sugar&number=1&apiKey=\(apiKey)"
        testEndpoint(name: "Find By Ingredients", url: ingredientsURL) { result in
            results += result + "\n\n"
            dispatchGroup.leave()
        }
        
        // Test 5: Direct API key validation
        dispatchGroup.enter()
        testApiKey { isValid, message in
            results += "API Key Test: \(isValid ? "✅ Valid" : "❌ Invalid") - \(message)\n\n"
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(results)
        }
    }
    
    /// Helper method to test a specific endpoint
    private func testEndpoint(name: String, url urlString: String, completion: @escaping (String) -> Void) {
        guard let url = URL(string: urlString) else {
            completion("❌ \(name): Invalid URL")
            return
        }
        
        let maskedURL = urlString.replacingOccurrences(of: apiKey, with: "API_KEY")
        print("🧪 Testing \(name) endpoint: \(maskedURL)")
        
        let request = createRequest(url: url)
        
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion("❌ \(name): Network error - \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion("❌ \(name): Invalid response")
                return
            }
            
            if httpResponse.statusCode == 200 {
                var result = "✅ \(name): Success (200 OK)"
                if let data = data, let json = try? JSONSerialization.jsonObject(with: data) {
                    result += " - Valid JSON response"
                }
                completion(result)
            } else {
                var errorMessage = "Status code: \(httpResponse.statusCode)"
                if let data = data, let errorString = String(data: data, encoding: .utf8) {
                    errorMessage += " - \(errorString)"
                }
                completion("❌ \(name): \(errorMessage)")
            }
        }.resume()
    }

    /// Get recipes by ingredients - uses the working Postman endpoint
    /// - Parameters:
    ///   - ingredients: Comma-separated list of ingredients
    ///   - number: Number of results to return
    ///   - limitLicense: Whether to limit to recipes with open licenses
    ///   - ranking: Whether to maximize used ingredients (1) or minimize missing ingredients (2)
    ///   - ignorePantry: Whether to ignore pantry items
    ///   - completion: Callback with recipes or error
    func findRecipesByIngredients(
        ingredients: String,
        number: Int = 10,
        limitLicense: Bool = true,
        ranking: Int = 1,
        ignorePantry: Bool = false,
        completion: @escaping (Result<[Recipe], RecipeAPIError>) -> Void
    ) {
        guard var urlComponents = URLComponents(string: findByIngredientsURL) else {
            completion(.failure(.invalidURL))
            return
        }
        
        // Add query parameters exactly as they appear in the working Postman request
        urlComponents.queryItems = [
            URLQueryItem(name: "apiKey", value: apiKey),
            URLQueryItem(name: "ingredients", value: ingredients),
            URLQueryItem(name: "number", value: String(number)),
            URLQueryItem(name: "limitLicense", value: limitLicense ? "true" : "false"),
            URLQueryItem(name: "ranking", value: String(ranking)),
            URLQueryItem(name: "ignorePantry", value: ignorePantry ? "true" : "false")
        ]
        
        guard let url = urlComponents.url else {
            completion(.failure(.invalidURL))
            return
        }
        
        // Print the full URL for debugging (with API key masked)
        let maskedURL = url.absoluteString.replacingOccurrences(of: apiKey, with: "API_KEY")
        print("🌐 Making findByIngredients API request to: \(maskedURL)")
        
        // For debugging: Print the URL components
        print("🔍 findByIngredients URL Components:")
        print("  - Scheme: \(urlComponents.scheme ?? "nil")")
        print("  - Host: \(urlComponents.host ?? "nil")")
        print("  - Path: \(urlComponents.path)")
        print("  - Query Items:")
        for item in urlComponents.queryItems ?? [] {
            let value = item.name == "apiKey" ? "API_KEY" : (item.value ?? "nil")
            print("    - \(item.name): \(value)")
        }
        
        let request = createRequest(url: url)
        
        // Print request headers for debugging
        print("📋 findByIngredients Request Headers:")
        request.allHTTPHeaderFields?.forEach { key, value in
            print("  - \(key): \(key.lowercased() == "x-api-key" ? "API_KEY" : value)")
        }
        
        session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(.networkError(error)))
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                DispatchQueue.main.async {
                    completion(.failure(.networkError(NSError(domain: "RecipeAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"]))))
                }
                return
            }
            
            print("📡 findByIngredients API Response status code: \(httpResponse.statusCode)")
            
            // Check for HTTP error status codes
            if httpResponse.statusCode < 200 || httpResponse.statusCode >= 300 {
                var errorMessage = "Server returned error status"
                if let data = data, let errorResponse = String(data: data, encoding: .utf8) {
                    errorMessage = errorResponse
                    print("❌ Error response: \(errorResponse)")
                }
                
                DispatchQueue.main.async {
                    completion(.failure(.serverError(httpResponse.statusCode, errorMessage)))
                }
                return
            }
            
            guard let data = data else {
                print("❌ No data received")
                DispatchQueue.main.async {
                    completion(.failure(.noData))
                }
                return
            }
            
            // Log the JSON response for debugging
            self.logJSONResponse(data: data, endpoint: "findByIngredients")
            
            do {
                // The findByIngredients endpoint returns an array directly, not wrapped in an object
                let decoder = JSONDecoder()
                let recipes = try decoder.decode([Recipe].self, from: data)
                print("✅ Successfully decoded \(recipes.count) recipes from findByIngredients")
                
                DispatchQueue.main.async {
                    completion(.success(recipes))
                }
            } catch {
                print("❌ Decoding error: \(error.localizedDescription)")
                
                // More detailed error logging for decoding errors
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("❌ Key '\(key.stringValue)' not found: \(context.debugDescription)")
                        print("❌ CodingPath: \(context.codingPath)")
                    case .valueNotFound(let type, let context):
                        print("❌ Value of type '\(type)' not found: \(context.debugDescription)")
                        print("❌ CodingPath: \(context.codingPath)")
                    case .typeMismatch(let type, let context):
                        print("❌ Type '\(type)' mismatch: \(context.debugDescription)")
                        print("❌ CodingPath: \(context.codingPath)")
                    case .dataCorrupted(let context):
                        print("❌ Data corrupted: \(context.debugDescription)")
                        print("❌ CodingPath: \(context.codingPath)")
                    @unknown default:
                        print("❌ Unknown decoding error: \(error)")
                    }
                }
                
                DispatchQueue.main.async {
                    completion(.failure(.decodingError(error)))
                }
            }
        }.resume()
    }
}

// MARK: - Response Wrappers

/// Wrapper for recipe search API responses
struct RecipeSearchResponse: Codable {
    let results: [Recipe]
}

/// Wrapper for featured recipes API responses
struct FeaturedRecipeResponse: Codable {
    let recipes: [Recipe]
}
