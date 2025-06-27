//
//  DetailVM.swift
//  Your Ai Wallpaper
//
//  Created by Jan Kubeš on 17.05.2025.
//
import UIKit
import Combine
import Photos
import SwiftData

class DetailWallpaperVM: ObservableObject {
    @Published private(set) var state: DetailWallpaperModel
    private let wallpaperDatabaseInstance: SavedWallpaper
    var context: ModelContext? = nil
    let livePhotoProcessor = LivePhotoProcessor(maxConcurrentTasks: 1)
    
    init(wallpaperDatabaseInstance: SavedWallpaper, showSaveToPhotosSheet: Bool = false, showAlertPhotoSaved: SavePhotosAlertInfo = .notVisible, savedWallpaper: SavedWallpaper) {
        self.wallpaperDatabaseInstance = wallpaperDatabaseInstance
        self.state = DetailWallpaperModel(
            showSaveToPhotosSheet: showSaveToPhotosSheet,
            showAlertButtonText: "Understood! Ask for Permission!",
            showAlertPhotoSaved: showAlertPhotoSaved,
            wallpaperState: .loading,
            savedWallpaper: savedWallpaper
        )
        Task {
            await loadWallpaperState()
        }
    }
    
    private func loadWallpaperState() async {
        let wallpaperState = await getWallpaperState(for: state.savedWallpaper, livePhotoProcessor: livePhotoProcessor)
        print("Wallpaper State Loaded: \(wallpaperState)")
        await MainActor.run {
            self.updateState(wallpaperState: wallpaperState)
        }
    }
    
    private func updateState(
        showSaveToPhotosSheet: Bool? = nil,
        showAlertButtonText: String? = nil,
        showAlertPhotoSaved: SavePhotosAlertInfo? = nil,
        wallpaperState: WallpaperState? = nil,
        savedWallpaper: SavedWallpaper? = nil
    ) {
        state = DetailWallpaperModel(
            showSaveToPhotosSheet: showSaveToPhotosSheet ?? state.showSaveToPhotosSheet,
            showAlertButtonText: showAlertButtonText ?? state.showAlertButtonText,
            showAlertPhotoSaved: showAlertPhotoSaved ?? state.showAlertPhotoSaved,
            wallpaperState: wallpaperState ?? state.wallpaperState,
            savedWallpaper: savedWallpaper ?? state.savedWallpaper
        )
    }
    
    func handle(_ intent: DetailWallpaperIntent) {
        switch intent {
        case .saveToPhotosLibrary:
            let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
            switch status {
            case .authorized, .restricted, .limited:
                switch state.wallpaperState {
                case .success(let displayable):
                    switch displayable {
                    case .image(let image):
                        PHPhotoLibrary.shared().performChanges({
                            PHAssetChangeRequest.creationRequestForAsset(from: image)
                        }) { success, error in
                            DispatchQueue.main.async {
                                if success {
                                    self.updateState(
                                        showAlertPhotoSaved: .visible("Photo Saved!", "Saving photo was successful!")
                                    )
                                } else if let error = error {
                                    print("Error " + error.localizedDescription)
                                    self.updateState(
                                        showAlertPhotoSaved: .visible("Error", "For some reason, app was not able to save the photo. Try Again!")
                                    )
                                }
                            }
                        }
                    case .livePhoto(let livePhoto):
                        let videoPath = wallpaperDatabaseInstance.filePathToVideo
                        let videoURL: URL
                        if videoPath.hasPrefix("file://") {
                            if let url = URL(string: videoPath) {
                                videoURL = url
                            } else {
                                self.updateState(
                                    showAlertPhotoSaved: .visible("Error", "For some reason, app was not able to save the photo. Try Again!")
                                )
                                return
                            }
                        } else {
                            videoURL = URL(fileURLWithPath: videoPath)
                        }
                        if FileManager.default.fileExists(atPath: videoURL.path) {
                            saveLivePhotoUseCase(mp4URL: videoURL) { result in
                                switch result {
                                case .success:
                                    self.updateState(
                                        showAlertPhotoSaved: .visible("Success", "Saved live photo to your photos library!")
                                    )
                                case .failure:
                                    self.updateState(
                                        showAlertPhotoSaved: .visible("Error", "For some reason, app was not able to save the photo. Try Again!")
                                    )
                                }
                            }
                        }
                    }
                    
                case .loading, .initial, .failure(_), .downloading, .needsDownload:
                    self.updateState(
                        showAlertPhotoSaved: .visible("Error", "Can not save wallpaper.")
                    )
                }
            case .notDetermined:
                updateState(
                    showSaveToPhotosSheet: true,
                    showAlertButtonText: "Understood! Ask for Permission!",
                    showAlertPhotoSaved: .notVisible
                )
            case .denied:
                updateState(
                    showSaveToPhotosSheet: true,
                    showAlertButtonText: "Understood! Open App Settings!",
                    showAlertPhotoSaved: .notVisible
                )
            @unknown default:
                updateState(
                    showSaveToPhotosSheet: true,
                    showAlertButtonText: "Understood! Open App Settings!",
                    showAlertPhotoSaved: .notVisible
                )
            }
            
        case .showSaveToPhotosAlert:
            let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
            switch status {
            case .authorized, .restricted, .limited:
                print("Authorized")
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                    DispatchQueue.main.async {
                        self.updateState(
                            showSaveToPhotosSheet: false,
                            showAlertPhotoSaved: .notVisible
                        )
                    }
                }
            case .denied:
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
                self.updateState(
                    showSaveToPhotosSheet: false,
                    showAlertPhotoSaved: .notVisible
                )
            @unknown default:
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
                self.updateState(
                    showSaveToPhotosSheet: false,
                    showAlertPhotoSaved: .notVisible
                )
            }
            
        case .alertPhotoSavedDismissed:
            self.updateState(
                showAlertPhotoSaved: .notVisible
            )
            
        case .dismissSheet:
            self.updateState(
                showSaveToPhotosSheet: false,
                showAlertPhotoSaved: .notVisible
            )
            
        case .animate:
            if case .success(let image) = state.wallpaperState {
                let originalImage = image
                updateState(wallpaperState: .loading)
                if let imageURL = URL(string: wallpaperDatabaseInstance.filepath) {
                    animateWallpaperTestCase(image: imageURL, descriptionOfImage: wallpaperDatabaseInstance.name) { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let livePhoto):
                                self.wallpaperDatabaseInstance.filePathToVideo = livePhoto.vidURL.absoluteString
                                self.wallpaperDatabaseInstance.isLivePhoto = true
                                try? self.context?.save()
                                self.updateState(
                                    wallpaperState: .success(.livePhoto(livePhoto.livePhoto)),
                                    savedWallpaper: self.wallpaperDatabaseInstance
                                )
                            case .failure(let error):
                                self.updateState(
                                    showAlertPhotoSaved: .visible("Animation Failed", "Failed to animate the wallpaper: \(error.localizedDescription)"),
                                    wallpaperState: .success(originalImage)
                                )
                            }
                        }
                    }
                } else {
                    updateState(
                        showAlertPhotoSaved: .visible("Error", "Invalid wallpaper file path."),
                        wallpaperState: .success(originalImage)
                    )
                }
            } else {
                updateState(
                    showAlertPhotoSaved: .visible("Cannot Animate", "The wallpaper is not in a state to be animated.")
                )
            }
        }
    }
}

enum DetailWallpaperIntent {
    case saveToPhotosLibrary
    case showSaveToPhotosAlert
    case alertPhotoSavedDismissed
    case dismissSheet
    case animate
}

struct DetailWallpaperModel {
    let showSaveToPhotosSheet: Bool
    let showAlertButtonText: String
    let showAlertPhotoSaved: SavePhotosAlertInfo
    let wallpaperState: WallpaperState
    let savedWallpaper: SavedWallpaper
}
