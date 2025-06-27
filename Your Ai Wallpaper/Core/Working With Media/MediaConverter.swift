//
//  MediaConverter.swift
//  Your Ai Wallpaper
//
//  Created by Jan Kubeš on 24.05.2025.
//

import UIKit
import AVFoundation
import MobileCoreServices

class MediaConverter {

    
    /// Converts a video to 1080x1920 resolution, exactly 1 second at 60 fps, suitable for Live Photo wallpaper.
    /// Pads with the last frame if the source is shorter than 1 second.
    /// - Parameter inputURL: URL of the input video (e.g., MOV, MP4).
    /// - Returns: URL of the processed video (MOV) or nil if conversion fails.
    static func convertVideoToLivePhotoSize(inputURL: URL) async -> URL? {
        let asset = AVURLAsset(url: inputURL)
        
        // Get video duration
        guard let duration = try? await asset.load(.duration) else {
            print("Cannot load video duration")
            return nil
        }
        
        // Get video track
        guard let videoTrack = try? await asset.loadTracks(withMediaType: .video).first else {
            print("No video track found")
            return nil
        }
        
        let videoSize = try? await videoTrack.load(.naturalSize)
        guard let sourceSize = videoSize else {
            print("Failed to load video size")
            return nil
        }
        
        // Get source frame rate
        let frameRate = try? await videoTrack.load(.nominalFrameRate)
        guard let sourceFrameRate = frameRate, sourceFrameRate > 0 else {
            print("Failed to load source frame rate")
            return nil
        }
        
        // Set target duration to exactly 1 second
        let targetDurationSeconds = 2.0
        let targetDuration = CMTime(seconds: targetDurationSeconds, preferredTimescale: 600)
        
        // Log source duration
        print("Source duration: \(duration.seconds)s, Source frame rate: \(sourceFrameRate)")
        if duration.seconds < targetDurationSeconds {
            print("Source video is \(duration.seconds)s, padding with last frame to reach 1 second.")
        }
        
        // Create composition
        let composition = AVMutableComposition()
        guard let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            print("Failed to create composition video track")
            return nil
        }
        
        // Insert the full source video
        let sourceTimeRange = CMTimeRange(start: .zero, duration: duration)
        do {
            try compositionVideoTrack.insertTimeRange(sourceTimeRange, of: videoTrack, at: .zero)
        } catch {
            print("Failed to insert video track: \(error)")
            return nil
        }
        
        // Pad with the last frame if duration is less than 1 second
        if duration < targetDuration {
            let remainingDuration = targetDuration - duration
            let frameDuration = CMTime(value: 1, timescale: Int32(sourceFrameRate))
            let lastFrameTime = CMTimeRange(start: duration - frameDuration, duration: frameDuration)
            
            // Calculate how many times to insert the last frame
            let remainingSeconds = remainingDuration.seconds
            let frameSeconds = frameDuration.seconds
            let framesNeeded = Int(ceil(remainingSeconds / frameSeconds))
            
            print("Padding \(framesNeeded) frames for \(remainingSeconds)s")
            
            // Insert last frame repeatedly to fill remaining duration
            var currentTime = duration
            for _ in 0..<framesNeeded {
                do {
                    try compositionVideoTrack.insertTimeRange(lastFrameTime, of: videoTrack, at: currentTime)
                    currentTime = currentTime + frameDuration
                } catch {
                    print("Failed to pad frame: \(error)")
                    return nil
                }
            }
            
            // Trim composition to exactly 1 second if overextended
            if currentTime > targetDuration {
                compositionVideoTrack.removeTimeRange(CMTimeRange(start: targetDuration, end: currentTime))
            }
        }
        
        // Verify composition duration
        let compositionDuration = composition.duration
        print("Composition duration: \(compositionDuration.seconds)s")
        if compositionDuration != targetDuration {
            print("Warning: Composition duration is not exactly 1 second (\(compositionDuration.seconds)s)")
        }
        
        let targetSize = CGSize(width: 1080, height: 1920)
        let sourceAspect = sourceSize.width / sourceSize.height
        let targetAspect = targetSize.width / targetSize.height
        
        // Log sizes for debugging
        print("Source size: \(sourceSize), Target size: \(targetSize), Target duration: \(targetDurationSeconds)s")
        
        // Calculate scaling and cropping
        var transform = CGAffineTransform.identity
        let renderSize = targetSize
        
        if sourceAspect > targetAspect {
            // Source is wider: scale height to match, crop width
            let scale = targetSize.height / sourceSize.height
            transform = CGAffineTransform(scaleX: scale, y: scale)
            let scaledWidth = sourceSize.width * scale
            let excessWidth = scaledWidth - targetSize.width
            transform = transform.translatedBy(x: -excessWidth / (2 * scale), y: 0)
        } else {
            // Source is taller: scale width to match, crop height
            let scale = targetSize.width / sourceSize.width
            transform = CGAffineTransform(scaleX: scale, y: scale)
            let scaledHeight = sourceSize.height * scale
            let excessHeight = scaledHeight - targetSize.height
            transform = transform.translatedBy(x: 0, y: -excessHeight / (2 * scale))
        }
        
        print("Render size: \(renderSize), Transform: \(transform)")
        
        // Create video composition with 60 fps
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = targetSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 60) // 60 fps
        
        let instructionLayer = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
        instructionLayer.setTransform(transform, at: .zero)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: targetDuration)
        instruction.layerInstructions = [instructionLayer]
        videoComposition.instructions = [instruction]
        
        let presets = AVAssetExportSession.exportPresets(compatibleWith: asset)
        if !presets.contains(AVAssetExportPresetHEVCHighestQuality) {
            print("HEVC preset not supported for this asset or device")
            return nil
        } else {
            print("HEVC Compatible")
        }
        
        // Create export session with HEVC
        guard let export = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHEVCHighestQuality) else {
            print("Unable to create AVAssetExportSession")
            return nil
        }
        
        // Create output URL
        guard let outputURL = createOutputURL(for: "converted_video", extension: "mov") else {
            print("Failed to create output URL")
            return nil
        }
        
        // Configure export session
        export.videoComposition = videoComposition
        export.shouldOptimizeForNetworkUse = true
        export.canPerformMultiplePassesOverSourceMediaData = true
        export.outputFileType = .mov
        export.outputURL = outputURL
        export.timeRange = CMTimeRange(start: .zero, duration: targetDuration)
        
        // Remove existing output file if it exists
        try? FileManager.default.removeItem(at: outputURL)
        
        print("Preset Name: \(export.presetName)")
        
        // Export the video
        do {
            try await export.export(to: outputURL, as: .mov)
            // Verify output frame count (approximate)
            let expectedFrames = Int(targetDurationSeconds * 60.0) // 60 frames at 60 fps
            print("Video exported successfully, expected \(expectedFrames) frames at 60 fps for 1 second")
            return outputURL
        } catch {
            print("Error while exporting: \(error)")
            return nil
        }
    }
    
    /// Extracts the middle frame of a video and saves it as a HEIF image at 1080x1920 resolution.
    /// - Parameter videoURL: URL of the input video (e.g., MOV, MP4).
    /// - Returns: URL of the processed image (HEIF) or nil if extraction fails.
    static func extractMiddleFrameAsImage(videoURL: URL) async -> URL? {
        let asset = AVURLAsset(url: videoURL)
        
        // Get video duration
        guard let duration = try? await asset.load(.duration) else {
            print("Cannot load video duration")
            return nil
        }
        
        // Calculate middle time
        let middleTimeSeconds = duration.seconds / 2
        let time = CMTime(seconds: middleTimeSeconds, preferredTimescale: 600)
        
        // Create image generator
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        
        // Extract the middle frame
        do {
            let cgImage = try await generator.copyCGImage(at: time, actualTime: nil)
            let sourceImage = UIImage(cgImage: cgImage)
            
            // Resize and crop to 1080x1920
            let targetSize = CGSize(width: 1080, height: 1920)
            let sourceSize = sourceImage.size
            let sourceAspect = sourceSize.width / sourceSize.height
            let targetAspect = targetSize.width / targetSize.height
            
            var scaledSize: CGSize
            var cropRect: CGRect
            
            if sourceAspect > targetAspect {
                // Source is wider: scale height to match, crop width
                let scale = targetSize.height / sourceSize.height
                scaledSize = CGSize(width: sourceSize.width * scale, height: targetSize.height)
                let excessWidth = scaledSize.width - targetSize.width
                cropRect = CGRect(x: excessWidth / 2, y: 0, width: targetSize.width, height: targetSize.height)
            } else {
                // Source is taller: scale width to match, crop height
                let scale = targetSize.width / sourceSize.width
                scaledSize = CGSize(width: targetSize.width, height: sourceSize.height * scale)
                let excessHeight = scaledSize.height - targetSize.height
                cropRect = CGRect(x: 0, y: excessHeight / 2, width: targetSize.width, height: targetSize.height)
            }
            
            // Create a renderer for scaling
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1.0
            let renderer = UIGraphicsImageRenderer(size: scaledSize, format: format)
            
            let scaledImage = renderer.image { _ in
                sourceImage.draw(in: CGRect(origin: .zero, size: scaledSize))
            }
            
            guard let outputURL = createOutputURL(for: "middle_frame", extension: "jpg") else {
                print("Failed to create output URL")
                return nil
            }
            
            do {
                let ctx = CIContext()
                guard let ciImage = CIImage(image: scaledImage) else {
                    print("Failed to create CIImage")
                    return nil
                }
                try ctx.writeJPEGRepresentation(of: ciImage, to: outputURL, colorSpace: ciImage.colorSpace!, options: [:])
                print("Saved JPG Image: \(outputURL.path)")
                return outputURL
            } catch {
                print("Could not save JPG Image, error: \(error)")
                return nil
            }
        } catch {
            print("Failed to extract middle frame: \(error)")
            return nil
        }
    }
    
    static func convertMP4ToMOV(mp4URL: URL, outputFileName: String = "troll_vid_converted") async throws -> URL {
        // Load the asset
        let asset = AVAsset(url: mp4URL)
        
        // Create the output URL in the documents directory
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "ConvertError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not access documents directory"])
        }
        let outputURL = documentsDirectory.appendingPathComponent("\(outputFileName).mov")
        
        // Remove the output file if it exists
        try? fileManager.removeItem(at: outputURL)
        
        // Create an export session
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            throw NSError(domain: "ConvertError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to create export session"])
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        
        // Set up a video composition to ensure proper rendering
        let videoComposition = AVMutableVideoComposition()
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            throw NSError(domain: "ConvertError", code: -3, userInfo: [NSLocalizedDescriptionKey: "No video track found in asset"])
        }
        
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30) // 30 fps
        videoComposition.renderSize = videoTrack.naturalSize
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: asset.duration)
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]
        
        exportSession.videoComposition = videoComposition
        
        // Export asynchronously using async/await
        await exportSession.export()
        
        // Check the export status
        switch exportSession.status {
        case .completed:
            print("Successfully converted MP4 to MOV: \(outputURL.path)")
            return outputURL
        case .failed:
            let errorMessage = exportSession.error?.localizedDescription ?? "Unknown error"
            print("Failed to convert: \(errorMessage)")
            throw NSError(domain: "ConvertError", code: -4, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        case .cancelled:
            print("Conversion cancelled")
            throw NSError(domain: "ConvertError", code: -5, userInfo: [NSLocalizedDescriptionKey: "Conversion cancelled"])
        default:
            print("Unknown export status")
            throw NSError(domain: "ConvertError", code: -6, userInfo: [NSLocalizedDescriptionKey: "Unknown export status"])
        }
    }
    
    /// Helper function to create a unique output URL in the temporary directory.
    private static func createOutputURL(for name: String, extension ext: String) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let uniqueName = "\(name)_\(UUID().uuidString).\(ext)"
        return tempDir.appendingPathComponent(uniqueName)
    }
}
