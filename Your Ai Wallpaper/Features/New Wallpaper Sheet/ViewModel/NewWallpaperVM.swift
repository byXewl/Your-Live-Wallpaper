//
//  NewWallpaperVM.swift
//  Your Ai Wallpaper
//
//  Created by Jan Kubeš on 09.05.2025.
//
import UIKit
import Combine
import SwiftData
import Photos
import SwiftUI

class NewWallpaperVM: ObservableObject {
    @Published private(set) var state: NewWallpaperModel
    var context: ModelContext? = nil
    
    private var creditManager: CreditManager
    
    var wallpaperImage: UIImage? = nil
    var wallpaperDatabaseID: UUID? = nil
    
    init(style: String = "", showSaveToPhotosSheet: Bool = false, creditManager: CreditManager) {
        self.creditManager = creditManager
        
        self.state = NewWallpaperModel(
            newWallpaperDescription: "",
            wallpaperState: .initial,
            titleState: .initial("Your Ai Wallpaper"),
            selectedStyles: style.isEmpty ? [] : [style],
            showSaveToPhotosSheet: showSaveToPhotosSheet,
            showAlertButtonText: "Understood! Ask for Permission!",
            showAlertPhotoSaved: .notVisible,
            wallpaperURL: nil,
            savingLivePhoto: false,
            animatedWallpaperVideoURL: nil,
            errorState: .noError,
            showGetMoreCreditsScreen: false
        )
    }
    
    func handle(_ intent: NewWallpaperIntent) {
        switch intent {
        case .updateWallpaperDescription(let wallpaperDesc):
            updateState(newWallpaperDescription: wallpaperDesc)
            
        case .dismissSheet:
            updateState(showSaveToPhotosSheet: false)
            
        case .generate:
            let result = creditManager.purchaseImageGeneration()
            
            if result {
                print("Generating!!!")
                updateState(wallpaperState: .loading, showAlertPhotoSaved: .notVisible)
                
                generateWallpaperUseCase (userDescription: state.newWallpaperDescription, styles: state.selectedStyles.sorted().joined(separator: ", "), useTestData: true) { [weak self] result in
                    guard let self = self else { return }
                    
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let generatedWallpaperResult):
                            self.handle(.generatingEnded(.success(generatedWallpaperResult)))
                        case .failure(let error):
                            self.handle(.generatingEnded(.failure(error)))
                        }
                    }
                }
            } else {
                updateState(showGetMoreCreditsScreen: true)
            }
            
            
        case .styleClicked(let clickedStyle):
            Haptics.selection()
            
            var newStyles = state.selectedStyles
            
            if state.selectedStyles.contains(clickedStyle) {
                newStyles.remove(clickedStyle)
            } else {
                newStyles.insert(clickedStyle)
            }
            
            updateState(selectedStyles: newStyles)
            
        case .generatingEnded(let result):
            switch result {
            case .success(let wallpaperResult):
                
                wallpaperImage = wallpaperResult.image
                updateState(wallpaperState: .success(.image(wallpaperImage!)), titleState: .loaded(wallpaperResult.title))
                
                let fileURL = savePNGToStorage(image: wallpaperResult.image)
                if (fileURL != nil) {
                    print("Wallpaper Saved")
                    updateState(wallpaperURL: fileURL)
                    
                    if let context = context {
                        let savedWallpaper = SavedWallpaper(name: wallpaperResult.title, filepath: fileURL!.absoluteString, dateAdded: Date(), filePathVideo: "", isLivePhoto: false)
                        wallpaperDatabaseID = savedWallpaper.returnId()
                        
                        context.insert(savedWallpaper)
                        print("Wallpaper Saved to Database")
                    }
                } else {
                    print("Error while saving wallpaper to app's storage sandbox")
                }
            case .failure(let error):
                print(error)
                updateState(wallpaperState: .initial, titleState: .initial("Your Ai Wallpaper"), errorState: .generic(ErrorInfo(title: "Failed Generating Wallpaper", description: "Generating wallpaper failed... 😞 Check your internet connection and try again later.")))
            }
            
        case .saveToPhotosLibrary:
            // Check permission
            let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
            print(status)
            switch status {
            case .authorized, .restricted, .limited:
                if case let .success(.image(image)) = state.wallpaperState {
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAsset(from: image)
                    }) { success, error in
                        DispatchQueue.main.async {
                            if success {
                                self.updateState(showAlertPhotoSaved: .visible("Photo Saved!", "Saving photo was sucessful!"))
                            } else if let error = error {
                                print("Error " + error.localizedDescription)
                                self.updateState(showAlertPhotoSaved: .visible("Error", "For some reason, app was not able to save the photo. Try Again!"))
                            }
                        }
                    }
                }
            case .notDetermined:
                updateState(showSaveToPhotosSheet: true, showAlertButtonText: "Understood! Ask for Permission!", showAlertPhotoSaved: .notVisible, )
            case .denied:
                updateState(showSaveToPhotosSheet: true, showAlertButtonText: "Understood! Open App Settings!", showAlertPhotoSaved: .notVisible, )
            @unknown default:
                updateState(showSaveToPhotosSheet: true, showAlertButtonText: "Understood! Open App Settings!", showAlertPhotoSaved: .notVisible, )
            }
        case .showSaveToPhotosAlert:
            let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
            
            switch status {
                // Never happens Here
            case .authorized, .restricted, .limited:
                print("Authorized")
            case .notDetermined:
                print("Denied")
                PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                    DispatchQueue.main.async {
                        self.updateState(showSaveToPhotosSheet: false, showAlertPhotoSaved: .notVisible)
                    }
                }
            case .denied:
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
                updateState(showSaveToPhotosSheet: false, showAlertPhotoSaved: .notVisible)
            @unknown default:
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
                updateState(showSaveToPhotosSheet: false, showAlertPhotoSaved: .notVisible)
            }
            
        case .alertPhotoSavedDissmised:
            updateState(showAlertPhotoSaved: .notVisible)
        case .animate:
            print("Animating: " + (state.wallpaperURL?.absoluteString ?? "nil"))
            updateState(wallpaperState: .loading)
            if (state.wallpaperURL != nil) {
                
                // Using test case for dev purposes
                animateWallpaperTestCase(image: state.wallpaperURL!, descriptionOfImage: state.newWallpaperDescription, completion: {livePhotoResult in
                    switch livePhotoResult {
                    case .success(let livePhoto):
                        self.updateState(wallpaperState: .success(.livePhoto(livePhoto.livePhoto)), animatedWallpaperVideoURL: livePhoto.vidURL)
                        
                        if let wallpaperID = self.wallpaperDatabaseID, let context = self.context {
                            do {
                                let predicate = #Predicate<SavedWallpaper> { $0.id == wallpaperID }
                                let fetchDescriptor = FetchDescriptor<SavedWallpaper>(predicate: predicate)
                                
                                if let savedWallpaper = try context.fetch(fetchDescriptor).first {
                                    // Update the properties
                                    savedWallpaper.filePathToVideo = livePhoto.vidURL.absoluteString
                                    savedWallpaper.isLivePhoto = true
                                    
                                    
                                    try context.save()
                                    print("Updated SavedWallpaper with video path and isLivePhoto set to true")
                                } else {
                                    print("No SavedWallpaper found with ID: \(wallpaperID)")
                                }
                            } catch {
                                print("Failed to update SavedWallpaper: \(error.localizedDescription)")
                            }
                        } else {
                            print("wallpaperDatabaseID or context is nil")
                        }
                        
                        print("success")
                        
                    case .failure(let error):
                        print(error)
                        let errorState: ErrorState = .generic(ErrorInfo(title: "Failed Animating Wallpaper", description: "Error animating wallpaper... 😞 Check your internet connection and try again later."))
                        
                        // if the image is acessible (it should), return user to the sucess stage with the image. In all cases show error
                        if (self.wallpaperImage != nil) {
                            self.updateState(wallpaperState: .success(.image(self.wallpaperImage!)), errorState: errorState)
                        } else {
                            self.updateState(wallpaperState: .initial, errorState: errorState)
                        }
                    }
                })
            }
        case .dismissError:
            updateState(errorState: ErrorState.noError)
        case .saveLivePhotoToPhotosLibrary:
            // Check permission
            let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
            print(status.rawValue)
            switch status {
            case .authorized, .restricted, .limited:
                updateState(savingLivePhoto: true)
                
                if (state.animatedWallpaperVideoURL != nil) {
                    saveLivePhotoUseCase(mp4URL: state.animatedWallpaperVideoURL!, completion: {success in
                        switch success {
                        case .success:
                            self.updateState(showAlertPhotoSaved: .visible("Photo Saved!", "Saving photo was sucessful!"), savingLivePhoto: false)
                        case .failure(let err):
                            print("Error " + err.localizedDescription)
                            self.updateState(showAlertPhotoSaved: .visible("Error", "For some reason, app was not able to save the photo. Try Again!"), savingLivePhoto: false)
                        }
                    })
                } else {
                    print("The Video URL is nil")
                }
                
            case .notDetermined:
                updateState(showSaveToPhotosSheet: true, showAlertButtonText: "Understood! Ask for Permission!", showAlertPhotoSaved: .notVisible, )
            case .denied:
                updateState(showSaveToPhotosSheet: true, showAlertButtonText: "Understood! Open App Settings!", showAlertPhotoSaved: .notVisible, )
            @unknown default:
                updateState(showSaveToPhotosSheet: true, showAlertButtonText: "Understood! Open App Settings!", showAlertPhotoSaved: .notVisible, )
            }
            
        }
    }
    
    func setContext(context: ModelContext) {
        self.context = context
    }
    
    private func updateState(
        newWallpaperDescription: String? = nil,
        wallpaperState: WallpaperState? = nil,
        selectedStyles: Set<String>? = nil,
        showSaveToPhotosSheet: Bool? = nil,
        showAlertButtonText: String? = nil,
        showAlertPhotoSaved: SavePhotosAlertInfo? = nil,
        titleState: TitleState? = nil,
        wallpaperURL: URL? = nil,
        savingLivePhoto: Bool? = nil,
        animatedWallpaperVideoURL: URL? = nil,
        errorState: ErrorState? = nil,
        showGetMoreCreditsScreen: Bool? = nil
    ) {
        state = NewWallpaperModel(
            newWallpaperDescription: newWallpaperDescription ?? state.newWallpaperDescription,
            wallpaperState: wallpaperState ?? state.wallpaperState,
            titleState: titleState ?? state.titleState,
            selectedStyles: selectedStyles ?? state.selectedStyles,
            showSaveToPhotosSheet: showSaveToPhotosSheet ?? state.showSaveToPhotosSheet,
            showAlertButtonText: showAlertButtonText ?? state.showAlertButtonText,
            showAlertPhotoSaved: showAlertPhotoSaved ?? state.showAlertPhotoSaved,
            wallpaperURL: wallpaperURL ?? state.wallpaperURL,
            savingLivePhoto: savingLivePhoto ?? state.savingLivePhoto,
            animatedWallpaperVideoURL: animatedWallpaperVideoURL ?? state.animatedWallpaperVideoURL,
            errorState: errorState ?? state.errorState,
            showGetMoreCreditsScreen: showGetMoreCreditsScreen ?? state.showGetMoreCreditsScreen
        )
    }
}

enum NewWallpaperIntent {
    case updateWallpaperDescription(String)
    case dismissSheet
    case generate
    case styleClicked(String)
    case generatingEnded(GenerateWallpaperResultEnum)
    
    case saveToPhotosLibrary
    
    case showSaveToPhotosAlert
    case alertPhotoSavedDissmised
    
    case animate
    case saveLivePhotoToPhotosLibrary
    
    case dismissError
}

struct NewWallpaperModel {
    let newWallpaperDescription: String
    
    let wallpaperState: WallpaperState
    let titleState: TitleState
    
    let selectedStyles: Set<String>
    
    let showSaveToPhotosSheet: Bool
    let showAlertButtonText: String
    
    let showAlertPhotoSaved: SavePhotosAlertInfo
    
    let wallpaperURL: URL?
    let savingLivePhoto: Bool
    let animatedWallpaperVideoURL: URL?
    
    let errorState: ErrorState
    
    let showGetMoreCreditsScreen: Bool
}

enum SavePhotosAlertInfo {
    case visible(String, String)
    case notVisible
}

extension UIViewController{
    
    public func showAlertMessage(title: String, message: String){
        
        let alertMessagePopUpBox = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okButton = UIAlertAction(title: "OK", style: .default)
        
        alertMessagePopUpBox.addAction(okButton)
        self.present(alertMessagePopUpBox, animated: true)
    }
}

enum ErrorState {
    case noError
    case generic(ErrorInfo)
}

class ErrorInfo {
    let title: String
    let description: String
    
    init(title: String, description: String) {
        self.title = title
        self.description = description
    }
}
