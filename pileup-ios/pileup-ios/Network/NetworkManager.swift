import Foundation

actor NetworkManager {
    static let shared = NetworkManager()
    
    // The base URL checks UserDefaults for a custom server first, then falls back to Info.plist
    private var baseURL: String {
        if let customURL = UserDefaults.standard.string(forKey: "customServerURL"), !customURL.isEmpty {
            return customURL
        }
        
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String else {
            fatalError("API_BASE_URL not found in Info.plist. Did you configure the .xcconfig files?")
        }
        return urlString
    }
    
    private var refreshTask: Task<Bool, Error>?
    
    private init() {}
    
    func request<T: Decodable & Sendable>(
        endpoint: String,
        method: String = "GET",
        queryItems: [URLQueryItem]? = nil,
        body: Data? = nil
    ) async throws -> T {
        let fullURL = try buildURL(endpoint: endpoint, queryItems: queryItems)
        
        var request = URLRequest(url: fullURL)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            // If token expired, try to refresh
            if httpResponse.statusCode == 401 && endpoint != "auth/jwt/refresh/" && endpoint != "auth/jwt/create/" && endpoint != "auth/register/" {
                let refreshSuccess = try await refreshAccessToken()
                if refreshSuccess {
                    // Retry original request
                    return try await self.request(endpoint: endpoint, method: method, queryItems: queryItems, body: body)
                } else {
                    // Logout if refresh fails
                    await MainActor.run {
                        NotificationCenter.default.post(name: NSNotification.Name("SessionExpired"), object: nil)
                    }
                    throw NSError(domain: "Network", code: 401, userInfo: [NSLocalizedDescriptionKey: "Session expired."])
                }
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                let serverMessage = String(data: data, encoding: .utf8) ?? "Server error"
                throw NSError(domain: "Network", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "\(serverMessage) (\(httpResponse.statusCode))"])
            }
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    func request(
        endpoint: String,
        method: String = "GET",
        queryItems: [URLQueryItem]? = nil,
        body: Data? = nil
    ) async throws {
        let fullURL = try buildURL(endpoint: endpoint, queryItems: queryItems)
        
        var request = URLRequest(url: fullURL)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 401 && endpoint != "auth/jwt/refresh/" && endpoint != "auth/jwt/create/" && endpoint != "auth/register/" {
                let refreshSuccess = try await refreshAccessToken()
                if refreshSuccess {
                    return try await self.request(endpoint: endpoint, method: method, queryItems: queryItems, body: body)
                } else {
                    await MainActor.run {
                        NotificationCenter.default.post(name: NSNotification.Name("SessionExpired"), object: nil)
                    }
                    throw NSError(domain: "Network", code: 401, userInfo: [NSLocalizedDescriptionKey: "Session expired."])
                }
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                let serverMessage = String(data: data, encoding: .utf8) ?? "Server error"
                throw NSError(domain: "Network", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "\(serverMessage) (\(httpResponse.statusCode))"])
            }
        }
    }
    
    private func buildURL(endpoint: String, queryItems: [URLQueryItem]?) throws -> URL {
        let baseString = baseURL.hasSuffix("/") || endpoint.hasPrefix("/") ? baseURL + endpoint : baseURL + "/" + endpoint
        
        guard var components = URLComponents(string: baseString) else {
            throw NSError(domain: "Network", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL: \(baseString)"])
        }
        
        if let queryItems = queryItems, !queryItems.isEmpty {
            var existingItems = components.queryItems ?? []
            existingItems.append(contentsOf: queryItems)
            components.queryItems = existingItems
        }
        
        guard let url = components.url else {
            throw NSError(domain: "Network", code: 400, userInfo: [NSLocalizedDescriptionKey: "Cannot create URL from components: \(baseString)"])
        }
        
        return url
    }
    
    private func refreshAccessToken() async throws -> Bool {
        if let existingTask = refreshTask {
            return try await existingTask.value
        }
        
        let task = Task<Bool, Error> {
            guard let refreshToken = UserDefaults.standard.string(forKey: "refreshToken") else {
                return false
            }
            
            let parameters = ["refresh": refreshToken]
            guard let body = try? JSONSerialization.data(withJSONObject: parameters) else {
                return false
            }
            
            guard let url = URL(string: baseURL + "auth/jwt/refresh/") else {
                return false
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                return false
            }
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let access = json["access"] as? String {
                UserDefaults.standard.set(access, forKey: "authToken")
                return true
            }
            return false
        }
        
        refreshTask = task
        
        do {
            let result = try await task.value
            refreshTask = nil
            return result
        } catch {
            refreshTask = nil
            throw error
        }
    }
}
