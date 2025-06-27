//
//  GenerateVideo.swift
//  Your Ai Wallpaper
//
//  Created by Jan Kubeš on 01.06.2025.
//

import UIKit

func generateVideo(from imageURL: String, prompt: String, completion: @escaping (Result<URL, Error>) -> Void) {
    convertImageToDataUri(from: imageURL) { result in
        switch result {
        case .success(let dataURI):
            submitVideoGenerationTask(with: dataURI, promptText: prompt) { taskResult in
                switch taskResult {
                case .success(let taskID):
                    pollTaskStatus(taskID: taskID) { pollResult in
                        switch pollResult {
                        case .success(let outputURL):
                            downloadVideo(from: outputURL) { downloadResult in
                                switch downloadResult {
                                case .success(let videoData):
                                    saveVideoLocally(videoData) { saveResult in
                                        completion(saveResult)
                                    }
                                case .failure(let error):
                                    completion(.failure(error))
                                }
                            }
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        case .failure(let error):
            completion(.failure(error))
        }
    }
}

func submitVideoGenerationTask(with dataURI: String, promptText: String, completion: @escaping (Result<String, Error>) -> Void) {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 120
    config.timeoutIntervalForResource = 120
    let session = URLSession(configuration: config)
    
    guard let url = URL(string: "https://api.dev.runwayml.com/v1/image_to_video") else {
        completion(.failure(VideoGenerationError.invalidURL))
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(getRunwayApiKey())", forHTTPHeaderField: "Authorization")
    request.setValue("2024-11-06", forHTTPHeaderField: "X-Runway-Version")
    
    let body: [String: Any] = [
        "promptImage": dataURI,
        "model": "gen4_turbo",
        "promptText": promptText,
        "duration": 5,
        "ratio": "720:1280"
    ]
    
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
    } catch {
        completion(.failure(error))
        return
    }
    
    let task = session.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            completion(.failure(VideoGenerationError.httpError(statusCode)))
            return
        }
        
        guard let data = data else {
            completion(.failure(VideoGenerationError.noData))
            return
        }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let taskID = json["id"] as? String {
                completion(.success(taskID))
            } else {
                completion(.failure(VideoGenerationError.invalidResponse))
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    task.resume()
}

func convertImageToDataUri(from fileURL: String, compressionQuality: CGFloat = 0.8, maxDimension: CGFloat? = 1024, completion: @escaping (Result<String, Error>) -> Void) {
    // Ensure the URL is a valid file URL
    guard let url = URL(string: fileURL), url.isFileURL else {
        completion(.failure(VideoGenerationError.invalidURL))
        return
    }
    
    do {
        // Read the image data from the local file
        let data = try Data(contentsOf: url)
        
        // Convert data to UIImage
        guard let image = UIImage(data: data) else {
            completion(.failure(VideoGenerationError.imageConversionFailed))
            return
        }
        
        // Resize image for PNG if maxDimension is specified
        let targetImage: UIImage
        if let maxDimension = maxDimension, url.pathExtension.lowercased() == "png", image.size.width > maxDimension || image.size.height > maxDimension {
            let aspectRatio = image.size.width / image.size.height
            let newSize: CGSize
            if aspectRatio > 1 {
                // Wider than tall
                newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
            } else {
                // Taller than wide or square
                newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
            }
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            if let resizedImage = UIGraphicsGetImageFromCurrentImageContext() {
                targetImage = resizedImage
            } else {
                UIGraphicsEndImageContext()
                completion(.failure(VideoGenerationError.imageConversionFailed))
                return
            }
            UIGraphicsEndImageContext()
        } else {
            targetImage = image
        }
        
        // Determine the MIME type based on the file extension
        let pathExtension = url.pathExtension.lowercased()
        let mimeType: String
        var imageData: Data
        
        switch pathExtension {
        case "png":
            mimeType = "image/png"
            // Use PNG data for resized image
            guard let pngData = targetImage.pngData() else {
                completion(.failure(VideoGenerationError.imageConversionFailed))
                return
            }
            imageData = pngData
        case "jpg", "jpeg":
            mimeType = "image/jpeg"
            // Use JPEG compression with specified quality
            guard let jpegData = targetImage.jpegData(compressionQuality: compressionQuality) else {
                completion(.failure(VideoGenerationError.imageConversionFailed))
                return
            }
            imageData = jpegData
        case "gif":
            mimeType = "image/gif"
            // GIFs are not easily compressed in UIKit; pass through original data
            imageData = data
        case "bmp":
            mimeType = "image/bmp"
            // Convert to PNG as BMP is not commonly used in data URIs
            guard let bmpData = targetImage.pngData() else {
                completion(.failure(VideoGenerationError.imageConversionFailed))
                return
            }
            imageData = bmpData
        default:
            completion(.failure(VideoGenerationError.invalidResponse))
            return
        }
        
        // Log the size of the compressed data for debugging
        print("Compressed image data size: \(imageData.count) bytes")
        
        // Convert data to base64 and create data URI
        let base64String = imageData.base64EncodedString()
        let dataURI = "data:\(mimeType);base64,\(base64String)"
        
        // Verify the data URI size (optional, for debugging)
        print("Data URI length: \(dataURI.count) characters")
        
        completion(.success(dataURI))
    } catch {
        completion(.failure(error))
    }
}


func pollTaskStatus(taskID: String, attempts: Int = 0, completion: @escaping (Result<String, Error>) -> Void) {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 60
    config.timeoutIntervalForResource = 60
    let session = URLSession(configuration: config)
    
    if attempts >= 120 { // 10 minutes
        completion(.failure(VideoGenerationError.timeout))
        return
    }
    
    guard let url = URL(string: "https://api.dev.runwayml.com/v1/tasks/\(taskID)") else {
        completion(.failure(VideoGenerationError.invalidURL))
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(getRunwayApiKey())", forHTTPHeaderField: "Authorization")
    request.setValue("2024-11-06", forHTTPHeaderField: "X-Runway-Version")
    
    let task = session.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            completion(.failure(VideoGenerationError.httpError(statusCode)))
            return
        }
        
        guard let data = data else {
            completion(.failure(VideoGenerationError.noData))
            return
        }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let status = json["status"] as? String {
                if status == "SUCCEEDED" {
                    if let output = json["output"] as? [String], let outputURL = output.first {
                        completion(.success(outputURL))
                    } else {
                        completion(.failure(VideoGenerationError.missingOutputURL))
                    }
                } else if status == "FAILED" || status == "CANCELLED" {
                    let failureReason = json["failure"] as? String
                    completion(.failure(VideoGenerationError.taskFailed(failureReason)))
                } else {
                    DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
                        pollTaskStatus(taskID: taskID, attempts: attempts + 1, completion: completion)
                    }
                }
            } else {
                completion(.failure(VideoGenerationError.invalidResponse))
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    task.resume()
}

func downloadVideo(from urlString: String, completion: @escaping (Result<Data, Error>) -> Void) {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 60
    config.timeoutIntervalForResource = 60
    let session = URLSession(configuration: config)
    
    guard let url = URL(string: urlString) else {
        completion(.failure(VideoGenerationError.invalidURL))
        return
    }
    
    let task = session.dataTask(with: url) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            completion(.failure(VideoGenerationError.httpError(statusCode)))
            return
        }
        
        guard let data = data else {
            completion(.failure(VideoGenerationError.noData))
            return
        }
        
        completion(.success(data))
    }
    
    task.resume()
}

func saveVideoLocally(_ data: Data, completion: @escaping (Result<URL, Error>) -> Void) {
    let tempDirectory = FileManager.default.temporaryDirectory
    let fileURL = tempDirectory.appendingPathComponent("generated_video.mp4")
    
    do {
        try data.write(to: fileURL)
        completion(.success(fileURL))
    } catch {
        completion(.failure(VideoGenerationError.fileSaveError))
    }
}

enum VideoGenerationError: LocalizedError {
    case invalidURL
    case noData
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    case taskFailed(String?)
    case timeout
    case missingOutputURL
    case fileSaveError
    case imageConversionFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .noData: return "No data received"
        case .invalidResponse: return "Invalid response format"
        case .httpError(let code): return "HTTP error \(code)"
        case .apiError(let message): return "API error: \(message)"
        case .taskFailed(let reason): return "Task failed\(reason.map { ": \($0)" } ?? "")"
        case .timeout: return "Video generation timed out"
        case .missingOutputURL: return "No output URL provided in successful task"
        case .fileSaveError: return "Failed to save video file locally"
        case .imageConversionFailed: return "Failed to convert images to video with compression"
        }
    }
}

