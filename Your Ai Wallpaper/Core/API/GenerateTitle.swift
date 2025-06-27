//
//  GenerateTitle.swift
//  Your Ai Wallpaper
//
//  Created by Jan Kubeš on 17.05.2025.
//

import Foundation

class WallpaperAPIClient {
    private let apiKey = "Bearer 9084a526808152ccd5058573c899c82d52fc9ee4da4788e4d6dca5126d772754"
    private let baseURL = "https://api.together.xyz/v1/chat/completions"
    
    func getWallpaperTitle(description: String) async -> Result<String, Error> {
        // Prepare request body
        let requestBody = WallpaperRequestBody(
            model: "meta-llama/Meta-Llama-3.1-405B-Instruct-Turbo",
            messages: [
                Message(
                    role: "system",
                    content: "Here is a description of wallpaper: '\(description)' Generate max 5 word title for the wallpaper, aim to have minimum of words in your title. Return only title, nothing else."
                )
            ]
        )
        
        // Encode request body to JSON
        let encoder = JSONEncoder()
        guard let requestData = try? encoder.encode(requestBody) else {
            return .failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode request body"]))
        }
        
        // Prepare URL and request
        guard let url = URL(string: baseURL) else {
            return .failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")
        request.httpBody = requestData
        
        // Perform network request
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check HTTP response status
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                return .failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response from server"]))
            }
            
            // Decode response
            let decoder = JSONDecoder()
            do {
                let topLevelResponse = try decoder.decode(TopLevelResponse.self, from: data)
                
                // Extract content from the first choice's message
                let content = topLevelResponse.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                
                // Validate content
                if content.isEmpty || content.lowercased() == "error" {
                    return .failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid wallpaper description"]))
                }
                
                return .success(content)
            } catch {
                print("Decoding error: \(error)")
                return .failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode response"]))
            }
        } catch {
            print("Network error: \(error)")
            return .failure(error)
        }
    }
}

struct WallpaperRequestBody: Codable {
    let model: String
    let messages: [Message]
}

struct TopLevelResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: Message
}

struct Message: Codable {
    let role: String
    let content: String
}
