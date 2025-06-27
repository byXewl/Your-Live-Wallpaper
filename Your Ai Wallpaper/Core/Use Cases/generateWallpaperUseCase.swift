//
//  generateWallpaperUseCase.swift
//  Your Ai Wallpaper
//
//  Created by Jan Kubeš on 10.05.2025.
//

import UIKit
import Foundation

func generateWallpaperUseCase(
    userDescription: String,
    styles: String,
    useTestData: Bool = false,
    completion: @escaping (Result<GenerateWallpaperResult, Error>) -> Void
) {
    print(styles)
    
    let apiClient = WallpaperAPIClient()
  
    // For simulation of error
//    let error = NSError(domain: "WallpaperError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Generating Test Error"])
//    return completion(.failure(error))
    
    
    Task {
        do {
            // Generate image first
            let image: UIImage
            if useTestData {
                // Test data: Simulate image generation
                try await Task.sleep(nanoseconds: 3_000_000_000)
                image = UIImage(imageLiteralResourceName: "troll")
                
                completion(.success(GenerateWallpaperResult(image: image, title: "Troll")))
            } else {
                // Real data: Fetch image URL and download image
                let imageResult = await withCheckedContinuation { continuation in
                    fetchImageURL(userDescription: userDescription, styles: styles) { result in
                        switch result {
                        case .success(let urlString):
                            downloadImage(from: urlString) { imageResult in
                                continuation.resume(returning: imageResult)
                            }
                        case .failure(let error):
                            continuation.resume(returning: .failure(error))
                            return
                        }
                    }
                }
                
                switch imageResult {
                case .success(let downloadedImage):
                    image = downloadedImage
                case .failure(let error):
                    return completion(.failure(error))
                }
                
                // Generate title after image is successfully generated
                let titleResult = await apiClient.getWallpaperTitle(description: "\(userDescription) \(styles)")
                
                switch titleResult {
                case .success(let title):
                    print("Generated title: \(title)")
                    completion(.success(GenerateWallpaperResult(image: image, title: title)))
                case .failure:
                    // On title failure, return success with default title
                    completion(.success(GenerateWallpaperResult(image: image, title: "Your Wallpaper")))
                }
            }
        } catch {
            // Return failure if image generation fails (e.g., test data sleep throws)
            completion(.failure(error))
        }
    }
}


func fetchImageURLTest(userDescription: String, completion: @escaping (Result<String, Error>) -> Void) {
    DispatchQueue.global().asyncAfter(deadline: .now()) {
        completion(.success("https://oaidalleapiprodscus.blob.core.windows.net/private/org-NnqcpQYmbRhn5dah27W05gR1/user-AVIv9iGijaWnnThU7Jrca2X1/img-X7vnvE8H0JhK33TApw88Vtwx.png?st=2025-05-11T10%3A49%3A25Z&se=2025-05-11T12%3A49%3A25Z&sp=r&sv=2024-08-04&sr=b&rscd=inline&rsct=image/png&skoid=475fd488-6c59-44a5-9aa9-31c4db451bea&sktid=a48cca56-e6da-484e-a814-9c849652bcb3&skt=2025-05-10T22%3A44%3A07Z&ske=2025-05-11T22%3A44%3A07Z&sks=b&skv=2024-08-04&sig=CfszyzQYk6Kc6I/Gy5HlZvZNcGhJp8ohG7sif5Tcd3Q%3D"))
    }
}

enum GenerateWallpaperResultEnum {
    case success(GenerateWallpaperResult)
    case failure(Error)
}

class GenerateWallpaperResult {
    let image: UIImage
    let title: String
    
    init(image: UIImage, title: String) {
        self.image = image
        self.title = title
    }
}
