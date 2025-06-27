//
//  animateWallpaperUseCase.swift
//  Your Ai Wallpaper
//
//  Created by Jan Kubeš on 31.05.2025.
//


import UIKit
import Foundation
import Photos

func animateWallpaperUseCase(
    image: URL,
    descriptionOfImage: String,
    completion: @escaping (Result<AnimateWallpaperResult, Error>) -> Void
) {
    print("ANIMATING WALLPAPER USECASE")
    Task {
        // Generate Video
        generateVideo(from: image.absoluteString, prompt: "Make things in this picture slightly move. Here is the description of the image: " + descriptionOfImage) { result in
            switch result {
            case .success(let videoURL):
                print("Video saved at: \(videoURL)")
                
                // Generate Live Photo From Video
                Task {
                    do {
                        // Generate Live Photo From Video
                        await LivePhotoManager.processLivePhoto(mp4URL: videoURL) { livePhoto in
                            if (livePhoto != nil) {
                                completion(.success(AnimateWallpaperResult(livePhoto: livePhoto!, savedToPhotos: true, vidURL: videoURL)))
                            } else {
                                let error = NSError(domain: "WallpaperError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create or save the live photo."])
                                completion(.failure(error))
                            }
                        }
                        
                    }
                }
            case .failure(let error):
                print("Error: \(error.localizedDescription)")
            }
        }
    }
}

func animateWallpaperTestCase(
    image: URL,
    descriptionOfImage: String,
    completion: @escaping (Result<AnimateWallpaperResult, Error>) -> Void
) {
    print("ANIMATING WALLPAPER USECASE")

    // Testing errors
//    let error = NSError(domain: "WallpaperError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Generating Test Error"])
//    return completion(.failure(error))
    
    Task {
        
        // Generate Video
        try await Task.sleep(nanoseconds: 3_000_000_000)
        
        
        animateWallpaperFromAssetsUseCase(imageName: "troll_vid", fileExtension: "mov", descriptionOfImage: "", completion: {result in print("\(result)");
            completion(result)
        })
    }
}

func animateWallpaperFromAssetsUseCase(
    imageName: String,
    fileExtension: String,
    descriptionOfImage: String,
    completion: @escaping (Result<AnimateWallpaperResult, Error>) -> Void
) {

    Task {
        // Generate Video
        guard let mp4URL = LivePhotoManager.saveAssetToStorage(assetName: imageName, fileExtension: fileExtension) else {
            print("Failed to save MP4 from assets")
            let error = NSError(domain: "WallpaperError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Err while saving mp4 test file"])
            completion(.failure(error))
            return
        }
        
        // Generate Live Photo From Video
        await LivePhotoManager.processLivePhoto(mp4URL: mp4URL) { livePhoto in
            if (livePhoto != nil) {
                completion(.success(AnimateWallpaperResult(livePhoto: livePhoto!, savedToPhotos: true, vidURL: mp4URL)))
            } else {
                let error = NSError(domain: "WallpaperError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create or save the live photo."])
                completion(.failure(error))
            }
        }
    }
}

class AnimateWallpaperResult {
    let livePhoto: PHLivePhoto
    let savedToPhotos: Bool
    let vidURL: URL
    
    init(livePhoto: PHLivePhoto, savedToPhotos: Bool, vidURL: URL) {
        self.livePhoto = livePhoto
        self.savedToPhotos = savedToPhotos
        self.vidURL = vidURL
    }
}
