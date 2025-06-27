//
//  downloadWallpaperFromFirebase.swift
//  Your Ai Wallpaper
//
//  Created by Jan Kubeš on 07.06.2025.
//

import Foundation
import FirebaseStorage

class DownloadAssetFromFirebaseUseCase {
    
    private let photoExtensions: Set<String> = ["jpg", "jpeg", "png", "gif", "heic"]
    private let videoExtensions: Set<String> = ["mov", "mp4", "m4v", "avi"]

    /// Downloads a file from a Firebase Storage URL to a permanent local cache directory.
    /// - Parameter urlString: The `gs://` or `https://` URL of the file in Firebase Storage.
    /// - Returns: A `DownloadedAsset` containing the permanent local URL and the determined asset type.
    /// - Throws: An error if the download or file move fails.
    func execute(from urlString: String) async throws -> DownloadedAsset {
        
        // 1. Get a reference to the file in Firebase Storage.
        let storageRef = Storage.storage().reference(forURL: urlString)
        
        // 2. Download the file to a temporary location on disk.
        let (tempLocalURL, _) = try await URLSession.shared.download(from: try await storageRef.downloadURL())
        
        // 3. Determine the permanent destination for the file.
        // We will save it in the app's Caches directory, which is appropriate for
        // data that can be redownloaded.
        let fileManager = FileManager.default
        let cachesDirectory = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        
        // Use the original filename from Firebase Storage.
        let destinationURL = cachesDirectory.appendingPathComponent(storageRef.name)
        
        // If a file already exists at the destination, remove it to ensure a clean overwrite.
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        
        // 4. Move the downloaded file from its temporary location to the permanent destination.
        // This is a very fast file system operation.
        try fileManager.moveItem(at: tempLocalURL, to: destinationURL)
        
        // 5. Determine if the asset is a photo or video based on its file extension.
        // This logic correctly handles both types.
        let fileExtension = destinationURL.pathExtension.lowercased()
        let assetType: AssetType
        if photoExtensions.contains(fileExtension) {
            assetType = .photo
        } else if videoExtensions.contains(fileExtension) {
            assetType = .video
        } else {
            assetType = .unknown
        }
        
        print("✅ Asset downloaded and saved to: \(destinationURL.path)")
        
        // 6. Return the result, containing the permanent URL and the asset type.
        return DownloadedAsset(localURL: destinationURL, type: assetType)
    }

}

enum AssetType: String {
    case photo
    case video
    case unknown
}

/// A struct to hold the result of the download operation.
struct DownloadedAsset {
    /// The URL to the file stored locally on the device.
    let localURL: URL
    
    /// The determined type of the asset.
    let type: AssetType
}
