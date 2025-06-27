//
//  Live Photo.swift
//  Your Ai Wallpaper
//
//  Created by Jan Kubeš on 20.05.2025.
//
import Foundation
import UIKit
import Photos
import AVFoundation
import AVKit

// MARK: - LivePhotoProcessor (The Actor that Manages Concurrency)

actor LivePhotoProcessor {
    private var activeTasks = 0
    private let maxConcurrentTasks: Int
    private var pendingContinuations: [() -> Void] = []

    init(maxConcurrentTasks: Int = 1) {
        self.maxConcurrentTasks = maxConcurrentTasks
    }

    func processLivePhoto(mp4URL: URL) async throws -> PHLivePhoto {
        if activeTasks >= maxConcurrentTasks {
            print("LivePhotoProcessor: Max concurrent tasks reached. Suspending for \(mp4URL.lastPathComponent)")
            await withCheckedContinuation { continuation in
                pendingContinuations.append {
                    continuation.resume()
                }
            }
            print("LivePhotoProcessor: Resumed processing for \(mp4URL.lastPathComponent)")
        }

        activeTasks += 1
        print("LivePhotoProcessor: Starting task for \(mp4URL.lastPathComponent). Active tasks: \(activeTasks)")

        defer {
            self.decrementAndResumeNext()
        }
        
        let livePhoto = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<PHLivePhoto, Error>) in
            
            Task {
                await LivePhotoManager.processLivePhoto(mp4URL: mp4URL) { _livePhoto in
                    // This completion handler is provided by `LivePhotoManager.processLivePhoto`.
                    // It gets called once the *entire* Live Photo generation is done (including `LivePhoto.generate`).
                    // This is the point where we resume the `withCheckedThrowingContinuation`.
                    if let livePhoto = _livePhoto {
                        continuation.resume(returning: livePhoto)
                    } else {
                        // The original `LivePhotoManager` function provides `nil` on failure.
                        // We translate this to throwing a specific error.
                        continuation.resume(throwing: WallpaperError.processingLivePhotoFailed)
                    }
                }
            }
        }
        return livePhoto
    }

    private func decrementAndResumeNext() {
        activeTasks -= 1
        print("LivePhotoProcessor: Task finished. Active tasks: \(activeTasks). Pending: \(pendingContinuations.count)")
        if !pendingContinuations.isEmpty {
            let next = pendingContinuations.removeFirst()
            next() // Resume the next pending task
        }
    }
}

class LivePhotoManager {
    // MARK: Only for testing with images from asssets
    static func saveAssetToStorage(assetName: String, fileExtension: String) -> URL? {
        print("Attempting to load asset: \(assetName)")
        
        // Create destination URL in the documents directory
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Error: Could not access documents directory")
            return nil
        }
        let destinationURL = documentsDirectory.appendingPathComponent("\(assetName).\(fileExtension)")
        
        // Check if file already exists
        if fileManager.fileExists(atPath: destinationURL.path) {
            print("File already exists at destination: \(destinationURL.path)")
            return destinationURL
        }
        
        // Try to load as a data asset from .xcassets
        if let dataAsset = NSDataAsset(name: assetName) {
            let data = dataAsset.data
            print("Found asset in .xcassets as data set, size: \(data.count) bytes")
            
            // Write the data to storage
            do {
                try data.write(to: destinationURL)
                print("Successfully saved file to: \(destinationURL.path)")
                return destinationURL
            } catch {
                print("Error writing data asset: \(error.localizedDescription)")
                return nil
            }
        }
        
        // Try to load as an image from .xcassets
        if let image = UIImage(named: assetName) {
            print("Found asset in .xcassets as image")
            
            // Convert the image to data based on the file extension
            let data: Data?
            if fileExtension.lowercased() == "png" {
                data = image.pngData()
            } else if fileExtension.lowercased() == "jpg" || fileExtension.lowercased() == "jpeg" {
                data = image.jpegData(compressionQuality: 1.0)
            } else {
                print("Error: Unsupported image format for extension \(fileExtension)")
                return nil
            }
            
            guard let imageData = data else {
                print("Error: Could not convert image to data")
                return nil
            }
            
            // Write the image data to storage
            do {
                try imageData.write(to: destinationURL)
                print("Successfully saved image to: \(destinationURL.path)")
                return destinationURL
            } catch {
                print("Error writing image data: \(error.localizedDescription)")
                return nil
            }
        }
        
        // Fallback to loading as a regular bundle resource
        var assetURL: URL?
        if let url = Bundle.main.url(forResource: assetName, withExtension: fileExtension) {
            assetURL = url
        } else if let url = Bundle.main.url(forResource: "Assets/\(assetName)", withExtension: fileExtension) {
            assetURL = url
        }
        
        if let foundURL = assetURL {
            print("Found asset in bundle at: \(foundURL.path)")
            
            // Copy the file from bundle to storage
            do {
                try fileManager.copyItem(at: foundURL, to: destinationURL)
                print("Successfully saved file to: \(destinationURL.path)")
                return destinationURL
            } catch {
                print("Error saving file: \(error.localizedDescription)")
                return nil
            }
        }
        
        print("Error: Could not find \(assetName) in .xcassets or bundle")
        return nil
    }
    
    // MARK: - Main Function to Process and Create Live Photo
    static func processLivePhoto(mp4URL: URL, livePhotoCompletion: @escaping (PHLivePhoto?) -> Void) async {
        do {
            let movURL = try await MediaConverter.convertMP4ToMOV(mp4URL: mp4URL)
            deleteFile(atPath: mp4URL.absoluteString)
            print("MOV URL saved successfully: \(movURL)")
            
            
            if let movURL_correctRatio = await MediaConverter.convertVideoToLivePhotoSize(inputURL: movURL) {
                deleteFile(atPath: movURL.absoluteString)
                
                LivePhoto.generate(from: nil, videoURL: movURL_correctRatio, progress: { (percent) in
                }) { (livePhoto, resources) in
                    if let _livePhoto: PHLivePhoto = livePhoto {
                        livePhotoCompletion(_livePhoto)
                    } else {
                        livePhotoCompletion(nil)
                    }
                }
                
                
            }
            else {
                print("Failed converting movie to correct ratio")
                livePhotoCompletion(nil)
            }
            
        } catch {
            print("Failed to convert MP4 to MOV: \(error)")
            deleteFile(atPath: mp4URL.absoluteString)
            livePhotoCompletion(nil)
        }
    }
    
    static func saveLiveVideo(mp4URL: URL, saveLivePhotoCompletion: @escaping (Bool) -> Void) async {
        do {
            let movURL = try await MediaConverter.convertMP4ToMOV(mp4URL: mp4URL)
            deleteFile(atPath: mp4URL.absoluteString)
            print("MOV URL saved successfully: \(movURL)")
            
            if let movURL_correctRatio = await MediaConverter.convertVideoToLivePhotoSize(inputURL: movURL) {
                deleteFile(atPath: movURL.absoluteString)
                print("Converted video to correct live photo size")
                
                LivePhotoUtil.convertVideo(movURL_correctRatio.absoluteString, complete: {result, msg in
                    print("Result: " + String(result))
                    print("Message: " + (msg ?? "No message"))
                    deleteFile(atPath: movURL_correctRatio.absoluteString)
                    
                    saveLivePhotoCompletion(result)
                })
            } else {
                saveLivePhotoCompletion(false)
            }
            
        } catch {
            print("Failed converting movie to correct ratio")
            saveLivePhotoCompletion(false)
        }
    }
}

func deleteFile(atPath path: String) {
    let fileManager = FileManager.default
    if fileManager.fileExists(atPath: path) {
        do {
            try fileManager.removeItem(atPath: path)
            print("File deleted successfully")
        } catch {
            print("Error: \(error)")
        }
    } else {
        print("Could not init")
    }
}
