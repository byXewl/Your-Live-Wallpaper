//
//  GenerateWallpaper.swift
//  Your Ai Wallpaper
//
//  Created by Jan Kubeš on 10.05.2025.
//
import UIKit
import Foundation

enum WallpaperError: LocalizedError {
    case invalidURL
    case noData
    case invalidResponse
    case httpError(Int)
    case imageDownloadFailed
    case apiError(String)
    case invalidContentType(String)
    case processingLivePhotoFailed
    
    case filePathError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .noData: return "No data received"
        case .invalidResponse: return "Invalid response format"
        case .httpError(let code): return "HTTP error \(code)"
        case .imageDownloadFailed: return "Failed to load image"
        case .apiError(let message): return message
        case .invalidContentType(let type): return "Invalid content type: \(type)"
        case .filePathError: return "File path does not exist"
        case .processingLivePhotoFailed:
            return "Processing live photo failed."
        }
    }
}

// Fetches the image URL from OpenAI API
func fetchImageURL(userDescription: String, styles: String, completion: @escaping (Result<String, Error>) -> Void) {
    // Custom URLSession configuration
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 120 // 2 minutes for slow API
    config.timeoutIntervalForResource = 120
    let session = URLSession(configuration: config)
    
    let maxRetries = 3
    let retryDelay: TimeInterval = 2.0
    
    func attemptRequest(attempt: Int) {
        guard let url = URL(string: "https://api.openai.com/v1/images/generations") else {
            completion(.failure(WallpaperError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(getApiKey())", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var stylesPrompt = ""
        if (!styles.isEmpty) {
            stylesPrompt = " Those are some styles user chose for the images: " + styles
        }
        
        let body: [String: Any] = [
            "model": "dall-e-3",
            "prompt": userDescription + stylesPrompt + " Never generate images from close distance. Always use a distance of at least 3 meter.",
            "size": "1024x1792",
            "n": 1,
            "response_format": "url"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = session.dataTask(with: request) { data, response, error in
            // Handle network errors with retry logic
            if let error = error as NSError?,
               [NSURLErrorNetworkConnectionLost, NSURLErrorCannotParseResponse].contains(error.code),
               attempt < maxRetries {
                print("Network error (code \(error.code)), retrying (\(attempt + 1)/\(maxRetries))...")
                DispatchQueue.global().asyncAfter(deadline: .now() + retryDelay) {
                    attemptRequest(attempt: attempt + 1)
                }
                return
            }
            
            if let error = error {
                print("Network error: \(error.localizedDescription), Code: \(error._code)")
                completion(.failure(error))
                return
            }
            
            // Log response details
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status: \(httpResponse.statusCode)")
                print("Headers: \(httpResponse.allHeaderFields)")
                if let contentType = httpResponse.allHeaderFields["Content-Type"] as? String {
                    print("Content-Type: \(contentType)")
                    if !contentType.lowercased().contains("application/json") {
                        completion(.failure(WallpaperError.invalidContentType(contentType)))
                        return
                    }
                }
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                completion(.failure(WallpaperError.httpError(statusCode)))
                return
            }
            
            guard let data = data else {
                completion(.failure(WallpaperError.noData))
                return
            }
            
            // Log raw response for debugging
            if let rawResponse = String(data: data, encoding: .utf8) {
                print("Raw Response: \(rawResponse)")
            } else {
                print("Raw Response: (non-UTF8 data, \(data.count) bytes)")
            }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    completion(.failure(WallpaperError.invalidResponse))
                    return
                }
                
                print("Parsed JSON: \(json)")
                
                if let error = json["error"] as? [String: Any], let message = error["message"] as? String {
                    completion(.failure(WallpaperError.apiError(message)))
                    return
                }
                
                guard let dataArray = json["data"] as? [[String: Any]],
                      let urlString = dataArray.first?["url"] as? String else {
                    completion(.failure(WallpaperError.invalidResponse))
                    return
                }
                
                print("Fetched image URL: \(urlString)")
                completion(.success(urlString))
                
            } catch {
                print("JSON parsing error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    attemptRequest(attempt: 1)
}

// Downloads a UIImage from a given URL
func downloadImage(from urlString: String, completion: @escaping (Result<UIImage, Error>) -> Void) {
    // Custom URLSession configuration
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 60 // 1 minute for image download
    config.timeoutIntervalForResource = 60
    let session = URLSession(configuration: config)
    
    guard let url = URL(string: urlString) else {
        completion(.failure(WallpaperError.invalidURL))
        return
    }
    
    let task = session.dataTask(with: url) { data, response, error in
        if let error = error {
            print("Image download error: \(error.localizedDescription), Code: \((error as NSError).code)")
            completion(.failure(error))
            return
        }
        
        // Log response details
        if let httpResponse = response as? HTTPURLResponse {
            print("Image HTTP Status: \(httpResponse.statusCode), Headers: \(httpResponse.allHeaderFields)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            completion(.failure(WallpaperError.httpError(statusCode)))
            return
        }
        
        guard let data = data, let image = UIImage(data: data) else {
            completion(.failure(WallpaperError.imageDownloadFailed))
            return
        }
        
        print("Image downloaded successfully from \(urlString)")
        completion(.success(image))
    }
    
    task.resume()
}
