//
//  OnboardingView.swift
//  Your Ai Wallpaper
//
//  Created by Jan Kubeš on 05.06.2025.
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel: OnboardingVM
    let dismissOnboarding: () -> Void
    
    init(dismissOnboarding: @escaping () -> Void, onboardingScreen: OnboardingScreen = .generatingImage) {
        self._viewModel = StateObject(wrappedValue: OnboardingVM(onboardingScreen: onboardingScreen))
        self.dismissOnboarding = dismissOnboarding
    }
    
    var body: some View {
        NavigationView {
            VStack (alignment: .leading) {
                switch viewModel.state.onboardingScreen {
                case .generatingImage:
                    Text("Welcome, generating your first wallpaper!")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.bottom, 20)
                    
                    WallpaperComponent(
                        wallpaperState: .loading,
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                    Spacer()
                    
                    VStack (alignment: .center) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5)
                            .tint(.white)
                            .padding(.bottom)
                        Text("Generating Beatiful Ocean Sunset")
                            .opacity(0.8)
                            .italic()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                case .imageScreen:
                    // Display the generated image
                    if let image = viewModel.state.generatedImage {
                        Text("Your wallpaper is ready!")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.bottom, 20)
                        
                        WallpaperComponent(wallpaperState: .success(.image(image)), text: "Beatiful Ocean Sunset")
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Spacer()
                        
                        MainButtonAction(text: "Animate!", tinted: true, action: {
                            viewModel.handle(.startAnimatingImage)
                        })
                    } else {
                        // Fallback or error state if image is unexpectedly nil
                        Text("Error: Image not found.")
                    }
                case .animatingImage:
                    Text("Animating!")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.bottom, 20)
                    
                    WallpaperComponent(
                        wallpaperState: .loading,
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                    Spacer()
                    
                    VStack (alignment: .center) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5)
                            .tint(.white)
                            .padding(.bottom)
                        Text("Animating the Landscape...")
                            .opacity(0.8)
                            .italic()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                case .liveWallpaperGenerated:
                    // Display the generated image
                    if let livePhoto = viewModel.state.animatedLivePhoto {
                        Text("Your wallpaper is alive!")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.bottom, 20)
                        
                        WallpaperComponent(wallpaperState: .success(.livePhoto(livePhoto)), text: "Beatiful Ocean Sunset")
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Spacer()
                        VStack {
                            Text("Press and Hold the image!")
                                .font(.caption)
                                .foregroundColor(.white)
                            MainButtonAction(text: "How do you set live wallpaper?", tinted: true, action: {
                                viewModel.handle(.wallpaperTutorial)
                            })
                        }
                    } else {
                        // Fallback or error state if image is unexpectedly nil
                        Text("Error: Image not found.")
                    }
                case .liveWallpaperTutorial:
                    Text("Your alive wallpaper!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Image("livewallpaperTutorial")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 500)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Spacer()
                    VStack {
                        Text("Simply click the live photo icon!")
                            .font(.caption)
                            .foregroundColor(.white)
                        MainButtonAction(text: "Wow - I want to generate!", tinted: true, action: {
                            viewModel.handle(.goBeforePaywall)
                        })
                    }
                    // TODO: Probably remove this page... 
                case .beforePayWall:
                    Text("Stay free - only 5 wallpapers per month, no animation, or...")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                case .paywall(_):
                    CreditPurchaseView()
                    
                }
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: viewModel.state.onboardingScreen)
            .padding(.horizontal)
            .padding(.bottom)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    let isVisible: Bool = {
                        if case .paywall(let paywallState) = viewModel.state.onboardingScreen {
                            return paywallState.closeVisible
                        }
                        return false
                    }()
                    
                    Button(action: {
                        if (isVisible) {
                            dismissOnboarding()
                        }
                    }) {
                        Text("Continue in free version")
                            .foregroundStyle(.white)
                            .opacity(isVisible ? 1 : 0) // Apply dynamic opacity
                    }
                    .zIndex(1)
                    .animation(.easeInOut(duration: 0.3), value: isVisible)
                }
            }
        }
        
    }
}

#Preview {
    OnboardingView(dismissOnboarding: {}, onboardingScreen: .paywall(PaywallState()),)
}
