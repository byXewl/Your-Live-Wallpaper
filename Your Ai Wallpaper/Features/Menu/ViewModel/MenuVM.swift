//
//  MenuVM.swift
//  Your Ai Wallpaper
//
//  Created by Jan Kubeš on 09.05.2025.
//
import Combine
import SwiftUI
import SwiftData
import Photos

class MenuVM: ObservableObject {
    @Published private(set) var state: MenuModel
    private let databaseManager: DatabaseManager
    
    let livePhotoProcessor = LivePhotoProcessor(maxConcurrentTasks: 1)
    let downloadUseCase = DownloadAssetFromFirebaseUseCase()
    
    init(initialState: MenuModel = MenuModel(sheetIsShown: false, showOnboarding: false, pregeneratedWallpaperItems: [], recentWallpapers: []), databaseManager: DatabaseManager) {
        self.state = initialState
        self.databaseManager = databaseManager
        
        shouldOpenOnboarding()
    }
    
    
    func handle(_ intent: MenuIntent) {
        switch intent {
        case .newWallpaper:
            Haptics.play(.medium)
            state = MenuModel(sheetIsShown: true, showOnboarding: false, pregeneratedWallpaperItems: state.pregeneratedWallpaperItems, recentWallpapers: state.recentWallpapers)
        case .dismissSheet:
            state = MenuModel(sheetIsShown: false, showOnboarding: false, pregeneratedWallpaperItems: state.pregeneratedWallpaperItems, recentWallpapers: state.recentWallpapers)
        case .dismissOnboarding:
            state = MenuModel(sheetIsShown: false, showOnboarding: false, pregeneratedWallpaperItems: state.pregeneratedWallpaperItems, recentWallpapers: state.recentWallpapers)
        }
    }
    
    private func shouldOpenOnboarding() {
        state = MenuModel(sheetIsShown: false, showOnboarding: true, pregeneratedWallpaperItems: state.pregeneratedWallpaperItems, recentWallpapers: state.recentWallpapers)
    }
    
    func getRecentWallpapers() async {
        let recentWallpapers = await databaseManager.fetchRecentWallpapers()
        
        print("Fetched recent wallpaper: ")
        print(recentWallpapers)
        
        var recentWallapersWithState: [RecentWallpaperItem] = []
        
        for wallpaper in recentWallpapers {
            recentWallapersWithState.append(RecentWallpaperItem(state: await getWallpaperState(for: wallpaper.getSavedWallpaper(), livePhotoProcessor: livePhotoProcessor), savedWallpaper: wallpaper.getSavedWallpaper()))
        }
        
        print("Recent wallpapers: ")
        print(recentWallapersWithState)
        
        await self.updateRecentWallpapers(newRecentWallpapers: recentWallapersWithState)
        
    }
    
    func handleWallpaperItemState(item: PregeneratedWallpaperItem) {
           switch item.state {
           case .loading:
               print("VM: Loading... \(item.name)")
               Task {
                   // This task is now owned by the ViewModel, not the View.
                   // It will continue even if the WallpaperCell disappears.
                   let wallpaperState = await getWallpaperState(
                       for: SavedWallpaper(name: item.name, filepath: item.filepath ?? "", dateAdded: item.dateAdded, filePathVideo: item.filePathVideo ?? "", isLivePhoto: item.isLivePhoto),
                       livePhotoProcessor: livePhotoProcessor
                   )
                   // Update the item's state on the main actor
                   await MainActor.run {
                       item.state = wallpaperState
                   }
               }

           case .needsDownload:
               print("VM: Needs download... \(item.name)")
               // Your existing downloadAndSave already handles this well within the VM.
               Task {
                   await downloadAndSave(item: item)
               }
               
           default:
               print("VM: No action needed for state: \(item.state)")
           }
       }

    
    func syncWallpapers() async {
        // --- PHASE 1: Initial load from database for instant UI ---
        let cachedWallpapers = await databaseManager.fetchCachedFirebaseWallpapers()
        let wallpaperItems = cachedWallpapers.map { PregeneratedWallpaperItem(from: $0) }
        
        print("Cached wallpapers: ")
        print(wallpaperItems)
        
        await MainActor.run {
            updateWallpapers(pregeneratedWallpapers: wallpaperItems)
        }
        
        // --- PHASE 2: Check for new wallpapers from Firebase ---
        let cachedUrls = Set(cachedWallpapers.compactMap { $0.firebaseFileURL })
        
        guard let allFirebaseUrls = try? await fetchAllImageURLs(from: "") else {
            print("Could not fetch remote URLs. Finishing.")
            return
        }
        
        let newFirebaseItems = allFirebaseUrls
            .filter { !cachedUrls.contains($0.absoluteString) }
            .map { PregeneratedWallpaperItem(from: $0) }
        
        var updatedWallpapers = state.pregeneratedWallpaperItems
        updatedWallpapers.append(contentsOf: newFirebaseItems)
        
        let finalWallpapers = updatedWallpapers
        print("All wallpapers: ")
        print(finalWallpapers)
        
        await MainActor.run {
            updateWallpapers(pregeneratedWallpapers: finalWallpapers)
        }
    }
    
    /// This function is called by the cell when it needs to download its content.
    func downloadAndSave(item: PregeneratedWallpaperItem) async {
        print("Item state: \(item.state)")
        
        // Update state to prevent multiple downloads and show a spinner
        await MainActor.run {
            item.state = .downloading
        }
        
        do {
            let result = try await downloadUseCase.execute(from: item.firebaseFileURL)
            
            // Create the SwiftData model object
            let newWallpaperToSave: SavedWallpaperNotManagedByModel
            switch result.type {
            case .photo:
                newWallpaperToSave = SavedWallpaperNotManagedByModel(name: "", filepath: result.localURL.absoluteString, dateAdded: Date(), filePathVideo: "", isLivePhoto: false, source: 0, firebaseFileURL: item.firebaseFileURL)
            case .video:
                newWallpaperToSave = SavedWallpaperNotManagedByModel(name: "", filepath: "", dateAdded: Date(), filePathVideo: result.localURL.absoluteString, isLivePhoto: true, source: 0, firebaseFileURL: item.firebaseFileURL)
            case .unknown:
                throw URLError(.cannotParseResponse) // Or a custom error
            }
            
            
            await MainActor.run {
                databaseManager.save(wallpaper: newWallpaperToSave.getSavedWallpaper())
            }
            
            let state = await getWallpaperState(for: newWallpaperToSave.getSavedWallpaper(), livePhotoProcessor: livePhotoProcessor)
            
            await MainActor.run {
                // Update the item's properties and state so the cell can now load it
                item.filepath = newWallpaperToSave.filepath
                item.filePathVideo = newWallpaperToSave.filePathToVideo
                item.isLivePhoto = newWallpaperToSave.isLivePhoto
                item.state = state
                print("Updated sucessfully")
            }
            
        } catch(let error) {
            await MainActor.run {
                item.state = .failure(error)
            }
            print("Failure: ")
            print(error)
        }
    }
    
    @MainActor
    private func updateWallpapers(pregeneratedWallpapers: [PregeneratedWallpaperItem]) {
        state = .init(sheetIsShown: state.sheetIsShown, showOnboarding: state.showOnboarding, pregeneratedWallpaperItems: pregeneratedWallpapers, recentWallpapers: state.recentWallpapers)
    }
    
    @MainActor
    private func updateRecentWallpapers(newRecentWallpapers: [RecentWallpaperItem]) {
        withAnimation {
            state = .init(sheetIsShown: state.sheetIsShown, showOnboarding: state.showOnboarding, pregeneratedWallpaperItems: state.pregeneratedWallpaperItems, recentWallpapers: newRecentWallpapers)
        }
    }
    
    private func fetchAllImageURLs(from folderPath: String) async throws -> [URL] {
        return try await withCheckedThrowingContinuation { continuation in
            // Call the original function with the escaping closure
            StorageManager.shared.fetchAllImageURLs(from: "") { result in
                // The closure has been called. Now, resume the async function.
                switch result {
                case .success(let urls):
                    // On success, resume by returning the value.
                    continuation.resume(returning: urls)
                case .failure(let error):
                    // On failure, resume by throwing the error.
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

enum MenuIntent {
    case newWallpaper
    case dismissSheet
    case dismissOnboarding
}

struct MenuModel {
    let sheetIsShown: Bool
    let showOnboarding: Bool
    
    let pregeneratedWallpaperItems: [PregeneratedWallpaperItem]
    let recentWallpapers: [RecentWallpaperItem]
}

class RecentWallpaperItem: Identifiable {
    let state: WallpaperState
    let savedWallpaper: SavedWallpaper
    
    init(state: WallpaperState, savedWallpaper: SavedWallpaper) {
        self.state = state
        self.savedWallpaper = savedWallpaper
    }
}

class PregeneratedWallpaperItem: ObservableObject, Identifiable, Equatable, Hashable {
    
    // The firebaseURL is a perfect unique identifier across both local and remote items.
    let id: String
    
    // Published properties will automatically update the cell's UI when they change.
    @Published var state: WallpaperState
    
    // Stored properties from the database or for a future download
    let name: String
    var filepath: String?
    let dateAdded: Date
    var filePathVideo: String?
    var isLivePhoto: Bool
    let source: Int
    let firebaseFileURL: String
    
    // Initializer for an item that is ALREADY in the database
    init(from savedWallpaper: SavedWallpaperNotManagedByModel) {
        self.id = savedWallpaper.firebaseFileURL! // Assume cached items always have this
        self.state = .loading
        self.name = savedWallpaper.name
        self.filepath = savedWallpaper.filepath
        self.dateAdded = savedWallpaper.dateAdded
        self.filePathVideo = savedWallpaper.filePathToVideo
        self.isLivePhoto = savedWallpaper.isLivePhoto
        self.source = savedWallpaper.source
        self.firebaseFileURL = savedWallpaper.firebaseFileURL!
    }
    
    // Initializer for an item that ONLY exists on Firebase so far
    init(from firebaseURL: URL) {
        self.id = firebaseURL.absoluteString
        self.state = .needsDownload
        self.name = ""
        self.filepath = nil
        self.dateAdded = Date() // Placeholder date
        self.filePathVideo = nil
        self.isLivePhoto = false // Assume we don't know yet
        self.source = 1
        self.firebaseFileURL = firebaseURL.absoluteString
    }
    
    static func == (lhs: PregeneratedWallpaperItem, rhs: PregeneratedWallpaperItem) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    var canClick: Bool {
        if case .success = self.state {
            return true
        }
        return false
    }
}

func getWallpaperState(for wallpaper: SavedWallpaper, livePhotoProcessor: LivePhotoProcessor) async -> WallpaperState {
    // Check if the wallpaper is a Live Photo and attempt to load the video
    if wallpaper.isLivePhoto {
        print("WALLPAPER STATE CHECK IS LIVE PHOTO")
        let videoPath = wallpaper.filePathToVideo
        let videoURL: URL
        
        // Check if the path is an absolute URL string (starts with "file://")
        if videoPath.hasPrefix("file://") {
            guard let url = URL(string: videoPath) else {
                print("Error: Could not convert absolute string to URL: \(videoPath)")
                return .failure(WallpaperError.filePathError)
            }
            videoURL = url
        } else {
            videoURL = URL(fileURLWithPath: videoPath)
        }
        
        // Check if the video file exists
        if FileManager.default.fileExists(atPath: videoURL.path) {
            do {
                print("Attempting to load video from: \(videoURL.absoluteString)")
                
                let phLivePhoto = try await livePhotoProcessor.processLivePhoto(mp4URL: videoURL)
                print("Successfully processed live photo for \(wallpaper.id)")
                return .success(.livePhoto(phLivePhoto))
            } catch {
                print("Error processing live photo: \(error.localizedDescription)")
                return getWallpaperImage(for: wallpaper) // Await here
            }
        } else {
            return getWallpaperImage(for: wallpaper)
        }
    }
    else {
        return getWallpaperImage(for: wallpaper)
    }
}

func getWallpaperImage(for wallpaper: SavedWallpaper) -> WallpaperState {
    let path = wallpaper.filepath
    
    let fileURL: URL
    
    // Check if the path is an absolute URL string (starts with "file://")
    if path.hasPrefix("file://") {
        // Try to create a URL from the absolute string
        guard let url = URL(string: path) else {
            print("Error: Could not convert absolute string to URL: \(path)")
            return .failure(WallpaperError.filePathError)
        }
        fileURL = url
    } else {
        // Treat it as a file path and create a file URL
        fileURL = URL(fileURLWithPath: path)
    }
    
    // Check if the image file exists
    guard FileManager.default.fileExists(atPath: fileURL.path) else {
        print("Error: File does not exist at \(fileURL.absoluteString)")
        return .failure(WallpaperError.filePathError)
    }
    
    // Attempt to load the image data
    do {
        let imageData = try Data(contentsOf: fileURL)
        guard let image = UIImage(data: imageData) else {
            print("Error: Could not convert data to UIImage")
            return .failure(WallpaperError.filePathError)
        }
        print("Successfully loaded image from: \(fileURL.absoluteString)")
        
        
        return .success(.image(image))
    } catch {
        print("Error loading image: \(error.localizedDescription)")
        return .failure(WallpaperError.filePathError)
    }
}
