//
//  saveLivePhotoUseCase.swift
//  Your Ai Wallpaper
//
//  Created by Jan Kubeš on 01.06.2025.
//


func saveLivePhotoUseCase(
    mp4URL: URL,
    completion: @escaping (Result<Bool, Error>) -> Void
) {
    
    Task {
        
        // Generate Live Photo From Video
        await LivePhotoManager.saveLiveVideo(mp4URL: mp4URL, saveLivePhotoCompletion: {result in
            if (result) {
                completion(.success(result))
            } else {
                let error = NSError(domain: "WallpaperError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Err while saving live photo to storage"])
                completion(.failure(error))
            }
        })
    }
}
