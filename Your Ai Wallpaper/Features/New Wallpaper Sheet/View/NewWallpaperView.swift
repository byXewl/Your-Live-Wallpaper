//
//  NewWallpaperView.swift
//  Your Ai Wallpaper
//
//  Created by Jan Kubeš on 09.05.2025.
//
import SwiftUI

public struct NewWallpaperView: View {
    @StateObject private var viewModel: NewWallpaperVM
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    let style: String
    
    init(style: String = "", saveToPhotosSheet: Bool = false) {
        self._viewModel = StateObject(wrappedValue: NewWallpaperVM(style: style, showSaveToPhotosSheet: saveToPhotosSheet, creditManager: CreditManager()))
        
        self.style = style
    }
    
    public var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .leading) {
                        Text("Generate Your \nWallpaper")
                            .foregroundStyle(.white)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                            .padding(.bottom, 30)
                        
                        
                        WallpaperComponent(wallpaperState: viewModel.state.wallpaperState, text: viewModel.state.titleState.value)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.bottom, 30)
                        
                        Spacer()
                        
                        
                        switch viewModel.state.wallpaperState {
                        case .initial:
                            VStack {
                                StylesRow(styleClicked: {clickedStyle in
                                    viewModel.handle(.styleClicked(clickedStyle))
                                }, selectedStyles: viewModel.state.selectedStyles)
                                TextField(
                                    "",
                                    text: Binding(
                                        get: { viewModel.state.newWallpaperDescription },
                                        set: { viewModel.handle(.updateWallpaperDescription($0)) }
                                    ),
                                    prompt: Text("Description of your future wallpaper").foregroundColor(.white),
                                )
                                .foregroundStyle(.white)
                                .padding(.horizontal, 15)
                                .padding(.vertical, 15)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(10)
                                .controlSize(.large)
                                .padding(.horizontal, 16)
                                .submitLabel(.go)
                                .onSubmit {
                                    viewModel.handle(.generate)
                                }
                            }
                        case .loading, .downloading, .needsDownload:
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
                        case .failure(_):
                            Text("Failure")
                        case .success(let displayable):
                            switch displayable {
                            case .image:
                                HStack {
                                    MainButtonAction(text: "Save To Photos", tinted: false, action: {
                                        viewModel.handle(.saveToPhotosLibrary)
                                    })
                                    
                                    MainButtonAction(text: "Animate!", tinted: true, action: {
                                        viewModel.handle(.animate)
                                    })
                                }
                            case .livePhoto:
                                if (viewModel.state.savingLivePhoto) {
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
                                } else {
                                    VStack {
                                        Text("Press and Hold the image!")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                        HStack {
                                            MainButtonAction(text: "Save To Photos", tinted: true, action: {
                                                viewModel.handle(.saveLivePhotoToPhotosLibrary)
                                            })
                                        }
                                    }
                                }
                            }
                            
                        }
                        
                        
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 15)
                    .ignoresSafeArea(.keyboard)
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.state.wallpaperState)
                    
                }
                .defaultScrollAnchor(.bottom)
                .scrollDisabled(true)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        if (viewModel.state.wallpaperState != .loading) {
                            dismiss()
                        }
                    }) {
                        Text("Cancel")
                            .foregroundStyle(.white)
                            .opacity(viewModel.state.wallpaperState != .loading ? 1.0 : 0.0)
                    }
                    .animation(.easeInOut(duration: 0.3), value: viewModel.state.wallpaperState != .loading)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .background(Color.black.opacity(0.9))
            .onAppear {
                viewModel.setContext(context: context)
            }
            .sheet(isPresented: Binding(get: {viewModel.state.showSaveToPhotosSheet}, set: {_ in viewModel.handle(.dismissSheet)})) {
                PhotosPermissionSheet(showAlertButtonText: viewModel.state.showAlertButtonText, onConfirm: {
                    viewModel.handle(.showSaveToPhotosAlert)
                })
            }
        }
        .alert(isPresented: Binding(get: {
            if case .visible(_, _) = viewModel.state.showAlertPhotoSaved {
                return true
            } else {
                return false
            }
        }, set: {
            _ in viewModel.handle(.alertPhotoSavedDissmised)
        })) {
            // Extract title and description from the .visible case
            if case let .visible(title, description) = viewModel.state.showAlertPhotoSaved {
                return Alert(
                    title: Text(title),
                    message: Text(description),
                    dismissButton: .default(Text("OK"))
                )
            } else {
                // Fallback in case the state isn't .visible (shouldn't happen due to isPresented binding)
                return Alert(
                    title: Text("Error"),
                    message: Text("Unable to show alert"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .alert(isPresented: Binding(get: {
            if case .generic(_) = viewModel.state.errorState {
                return true
            } else {
                return false
            }
        },
            set: {
                _ in viewModel.handle(.dismissError)
            }
        )) {
            if case let .generic(errorInfo) = viewModel.state.errorState {
                return Alert(
                    title: Text(errorInfo.title),
                    message: Text(errorInfo.description)
                )
            } else {
                // Fallback in case the state isn't .visible (shouldn't happen due to isPresented binding)
                return Alert(
                    title: Text("Error"),
                    message: Text("Unable to show alert"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        
        .sheet(isPresented: Binding(
            get: { viewModel.state.showGetMoreCreditsScreen }, set: {_ in print("Closed")}
        )) {
            CreditPurchaseView()
        }
    }
    
}
