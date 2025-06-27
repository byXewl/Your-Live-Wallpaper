//
//  DetailView.swift
//  Your Ai Wallpaper
//
//  Created by Jan Kubeš on 17.05.2025.
//
import SwiftUI

struct DetailView: View {
    @StateObject private var viewModel: DetailWallpaperVM
    
    init(wallpaper: SavedWallpaper) {
        _viewModel = StateObject(wrappedValue: DetailWallpaperVM(wallpaperDatabaseInstance: wallpaper, savedWallpaper: wallpaper))
    }
    
    var body: some View {
        VStack {
            // Wallpaper display
            WallpaperComponent(
                wallpaperState: viewModel.state.wallpaperState,
                wallpaperComponentType: viewModel.state.savedWallpaper.isLivePhoto ? .livePhoto : .generic,
                height: 600,
                width: 350,
                fontSize: 40.0,
                text: viewModel.state.savedWallpaper.name
            )
            .padding(.bottom, 20)
            
            switch viewModel.state.wallpaperState {
            case .loading, .initial, .failure(_), .needsDownload, .downloading:
                Spacer()
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                        .tint(.white) // Set ProgressView color to white
                    Spacer()
                }
                .transition(.scale.combined(with: .opacity))
                Spacer()
            case .success(let displayable):
                switch displayable {
                case .image(let image):
                    
                    Spacer()
                    
                    HStack {
                        MainButtonAction(text: "Save To Photos", tinted: false) {
                            viewModel.handle(.saveToPhotosLibrary)
                        }
                        MainButtonAction(text: "Animate", tinted: true) {
                            viewModel.handle(.animate)
                        }
                    }
                    
                    Spacer()
                    
                case .livePhoto(let livePhoto):
                    VStack {
                        Text("Press and Hold the image!")
                            .font(.caption)
                            .foregroundColor(.white)
                        HStack {
                            MainButtonAction(text: "Save To Photos", tinted: false, action: {
                                viewModel.handle(.saveToPhotosLibrary)
                            })
                        }
                    }
                }
                
            }
        }
        .padding()
        .sheet(isPresented: Binding(get: { viewModel.state.showSaveToPhotosSheet }, set: { _ in viewModel.handle(.dismissSheet) })) {
            PhotosPermissionSheet(showAlertButtonText: viewModel.state.showAlertButtonText, onConfirm: {
                viewModel.handle(.showSaveToPhotosAlert)
            })
        }
        .alert(isPresented: Binding(get: {
            if case .visible = viewModel.state.showAlertPhotoSaved {
                return true
            } else {
                return false
            }
        }, set: { _ in viewModel.handle(.alertPhotoSavedDismissed) })) {
            if case let .visible(title, description) = viewModel.state.showAlertPhotoSaved {
                return Alert(
                    title: Text(title),
                    message: Text(description),
                    dismissButton: .default(Text("OK"))
                )
            } else {
                return Alert(
                    title: Text("Error"),
                    message: Text("Unable to show alert"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .background(Color.black)
        .animation(.easeInOut(duration: 0.3), value: viewModel.state.wallpaperState)
    }
}
