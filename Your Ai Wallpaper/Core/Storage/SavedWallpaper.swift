//
//  Image.swift
//  Your Ai Wallpaper
//
//  Created by Jan Kubeš on 10.05.2025.
//

import SwiftData
import UIKit

@Model
class SavedWallpaper {
    var id: UUID
    var name: String
    var filepath: String
    var filePathToVideo: String
    var isLivePhoto: Bool
    
    var dateAdded: Date
    
    // MARK: Source: 0 == firebase, 1 == userGenerated
    var source: Int
    var firebaseFileURL: String?
    
    init(name: String, filepath: String, dateAdded: Date, filePathVideo: String, isLivePhoto: Bool, source: Int = 1, firebaseFileURL: String? = nil) {
        self.id = UUID()
        self.name = name
        self.filepath = filepath
        self.dateAdded = dateAdded
        self.filePathToVideo = filePathVideo
        self.isLivePhoto = isLivePhoto
        self.source = source
        self.firebaseFileURL = firebaseFileURL
    }
    
    func returnId() -> UUID {
        return self.id
    }
    
    var isFirebaseSource: Bool {
        if source == 0 {
            return true
        } else {
            return false
        }
    }
    
    func getSavedWallpaperNotManagedByDatabase() -> SavedWallpaperNotManagedByModel {
        let savedWallpaper = SavedWallpaperNotManagedByModel(name: self.name, filepath: self.filepath, dateAdded: self.dateAdded, filePathVideo: self.filePathToVideo, isLivePhoto: self.isLivePhoto, source: self.source, firebaseFileURL: self.firebaseFileURL)
        
        return savedWallpaper
    }
}

class SavedWallpaperNotManagedByModel {
    var id: UUID
    var name: String
    var filepath: String
    var filePathToVideo: String
    var isLivePhoto: Bool
    
    var dateAdded: Date
    
    // MARK: Source: 0 == firebase, 1 == userGenerated
    var source: Int
    var firebaseFileURL: String?
    
    init(name: String, filepath: String, dateAdded: Date, filePathVideo: String, isLivePhoto: Bool, source: Int = 1, firebaseFileURL: String? = nil) {
        self.id = UUID()
        self.name = name
        self.filepath = filepath
        self.dateAdded = dateAdded
        self.filePathToVideo = filePathVideo
        self.isLivePhoto = isLivePhoto
        self.source = source
        self.firebaseFileURL = firebaseFileURL
    }
    
    func returnId() -> UUID {
        return self.id
    }
    
    func getSavedWallpaper() -> SavedWallpaper {
        let savedWallpaper = SavedWallpaper(name: self.name, filepath: self.filepath, dateAdded: self.dateAdded, filePathVideo: self.filePathToVideo, isLivePhoto: self.isLivePhoto, source: self.source, firebaseFileURL: self.firebaseFileURL)
        
        return savedWallpaper
    }
}




func savePNGToStorage(image: UIImage, fileName: String = "image_\(UUID().uuidString).png") -> URL? {
    // Get the documents directory URL
    guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
        print("Error: Could not access documents directory")
        return nil
    }
    
    // Ensure the file name has a .png extension
    let validFileName = fileName.lowercased().hasSuffix(".png") ? fileName : "\(fileName).png"
    
    // Create the file URL by appending the file name
    let fileURL = documentsDirectory.appendingPathComponent(validFileName)
    
    // Convert the image to PNG data
    guard let imageData = image.pngData() else {
        print("Error: Could not convert image to PNG data")
        return nil
    }
    
    // Write the PNG data to the file URL
    do {
        try imageData.write(to: fileURL)
        print("Saved image to: \(fileURL.absoluteString)")
        return fileURL
    } catch {
        print("Error saving PNG: \(error.localizedDescription)")
        return nil
    }
}
