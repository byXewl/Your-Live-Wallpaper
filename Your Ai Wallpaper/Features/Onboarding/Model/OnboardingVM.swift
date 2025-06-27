//
//  OnboardingVM.swift
//  Your Ai Wallpaper
//
//  Created by Jan Kubeš on 06.06.2025.
//

import SwiftUI
import Combine
import Photos // Still needed for PHLivePhoto
import AVKit  // Still needed for PHLivePhoto

class OnboardingVM: ObservableObject {
    @Published private(set) var state: OnboardingModel

    init(onboardingScreen: OnboardingScreen = .generatingImage,) {
        self.state = OnboardingModel(
            onboardingScreen: onboardingScreen,
            generatedImage: nil,
            animatedLivePhoto: nil,
            animatedLivePhotoVideoURL: nil,
            isLoading: false // Initial state might be true if it starts generating immediately
        )
        // Start the onboarding process automatically or via a user intent
        handle(.startGeneratingImage)
    }

    func handle(_ intent: OnboardingIntent) {
        switch intent {
        case .startGeneratingImage:
            updateState(onboardingScreen: .generatingImage, isLoading: true)

            // Simulate image generation delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                guard let self = self else { return }
                // Use a placeholder/test image
                if let testImage = UIImage(named: "onboardingImage") {
                    self.handle(.imageGenerated(testImage))
                } else {
                    // Fallback if test image is missing (though in a no-fail scenario, it should exist)
                    print("Error: testWallpaperImage not found in assets.")
                    // If no failure is allowed, this might transition to the next screen anyway
                    self.handle(.imageGenerated(UIImage())) // Provide an empty UIImage or default
                }
            }

        case .imageGenerated(let image):
            updateState(onboardingScreen: .imageScreen, generatedImage: image, isLoading: false)

        case .startAnimatingImage:
            updateState(onboardingScreen: .animatingImage, isLoading: true)
            
            animateWallpaperFromAssetsUseCase(
                imageName: "onboardingVideo",
                fileExtension: "mp4",
                descriptionOfImage: "Onboarding Live Wallpaper Example"
            ) { [weak self] result in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    switch result {
                    case .success(let animationResult):
                        self.handle(.animationEnded(animationResult.livePhoto, animationResult.vidURL))
                    case .failure(let error):
                        print("Onboarding Error: animateWallpaperFromAssetsUseCase failed locally: \(error.localizedDescription)")
                        self.handle(.wallpaperTutorial) // Skip the live photo step
                    }
                }
            }


        case .animationEnded(let livePhoto, let videoURL):
            updateState(onboardingScreen: .liveWallpaperGenerated, animatedLivePhoto: livePhoto, animatedLivePhotoVideoURL: videoURL, isLoading: false)

        case .wallpaperTutorial:
            updateState(onboardingScreen: .liveWallpaperTutorial, isLoading: false) // Ensure isLoading is false here
            
        case .goBeforePaywall:
            updateState(onboardingScreen: .beforePayWall, isLoading: false)
            
            // Simulate image generation delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                guard let self = self else { return }

                self.handle(.goPaywall)
            }
            
        case .goPaywall:
            updateState(onboardingScreen: .paywall(PaywallState()))
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                guard let self = self else { return }

                updateState(onboardingScreen: .paywall(PaywallState(closeVisible: true)))
            }
        }
    }

    private func updateState(
        onboardingScreen: OnboardingScreen? = nil,
        generatedImage: UIImage? = nil,
        animatedLivePhoto: PHLivePhoto? = nil,
        animatedLivePhotoVideoURL: URL? = nil,
        isLoading: Bool? = nil
    ) {
        state = OnboardingModel(
            onboardingScreen: onboardingScreen ?? state.onboardingScreen,
            generatedImage: generatedImage ?? state.generatedImage,
            animatedLivePhoto: animatedLivePhoto ?? state.animatedLivePhoto,
            animatedLivePhotoVideoURL: animatedLivePhotoVideoURL ?? state.animatedLivePhotoVideoURL,
            isLoading: isLoading ?? state.isLoading
            // errorState is removed
        )
    }

    // MARK: - Cancellables (still good practice for Combine usage if any, though less critical now)
    private var cancellables = Set<AnyCancellable>()
}

// MARK: - Onboarding Intent
enum OnboardingIntent {
    case startGeneratingImage
    case imageGenerated(UIImage)
    case startAnimatingImage
    case animationEnded(PHLivePhoto, URL) // Now includes live photo data
    case wallpaperTutorial
    case goBeforePaywall
    case goPaywall
}

// MARK: - Onboarding Model
struct OnboardingModel {
    let onboardingScreen: OnboardingScreen
    let generatedImage: UIImage?
    let animatedLivePhoto: PHLivePhoto?
    let animatedLivePhotoVideoURL: URL? // Store the video URL for Live Photo export/display
    let isLoading: Bool
    // Removed: let errorState: ErrorState
}

// MARK: - Onboarding Screen States
enum OnboardingScreen: Equatable {
    
    case generatingImage
    case imageScreen
    case animatingImage
    case liveWallpaperGenerated
    case liveWallpaperTutorial
    case beforePayWall
    case paywall(PaywallState)
}

// MARK: - Paywall State Class
class PaywallState: Equatable {
    var closeVisible: Bool = false

    static func == (lhs: PaywallState, rhs: PaywallState) -> Bool {
        return lhs.closeVisible == rhs.closeVisible
    }

    init(closeVisible: Bool = false) {
        self.closeVisible = closeVisible
    }
}
