//
//  AnimatedBackground.swift
//  Your Ai Wallpaper
//
//  Created by Jan Kubeš on 06.06.2025.
//
import SwiftUI

// The core view that creates the animated blob effect.
// This view is now self-contained and can be used as a background for any other view.
struct AnimatedBlobView: View {
    // State variables to hold the position of each blob.
    // SwiftUI will automatically animate changes to these values.
    @State private var blob1Pos: CGPoint = .zero
    @State private var blob2Pos: CGPoint = .zero
    @State private var blob3Pos: CGPoint = .zero
    
    // A timer that fires every 10 seconds to trigger a new animation cycle.
    // The long interval ensures the movement is infrequent and subtle.
    let timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            
            // Canvas for the blobs
            ZStack {
                // Blob 1: Magenta
                Circle()
                    .fill(Color(hex: 0xFF00FF))
                // The frame is now significantly larger than the screen to ensure full coverage.
                    .frame(width: geometry.size.width * 2.1, height: geometry.size.width * 2.2)
                    .position(blob1Pos)
                
                // Blob 2: Cyan
                Circle()
                    .fill(Color(hex: 0x00FFFF))
                    .frame(width: geometry.size.width * 2.0, height: geometry.size.width * 2.1)
                    .position(blob2Pos)
                
                // Blob 3: Indigo
                Circle()
                    .fill(Color(hex: 0x4D00FF))
                    .frame(width: geometry.size.width * 2.5, height: geometry.size.width * 2.4)
                    .position(blob3Pos)
            }
            // A very strong blur is applied to merge the circles into a soft, fluid gradient.
            .blur(radius: 120)
            .onAppear {
                // Set initial random positions for the blobs when the view first appears.
                let initialRect = geometry.frame(in: .local)
                blob1Pos = randomPoint(in: initialRect)
                blob2Pos = randomPoint(in: initialRect)
                blob3Pos = randomPoint(in: initialRect)
                // Start the continuous animation.
                animateBlobs(in: initialRect)
            }
            .onReceive(timer) { _ in
                // On each timer tick, calculate new positions and animate to them.
                animateBlobs(in: geometry.frame(in: .local))
            }
        }
    }
    
    // Function to update the blob positions to new random locations.
    private func animateBlobs(in rect: CGRect) {
        // The animation duration is long, creating a slow, graceful movement.
        withAnimation(.easeInOut(duration: 12.0)) {
            blob1Pos = randomPoint(in: rect)
            blob2Pos = randomPoint(in: rect)
            blob3Pos = randomPoint(in: rect)
        }
    }
    
    // Helper function to generate a random CGPoint.
    private func randomPoint(in rect: CGRect) -> CGPoint {
        // Define a larger rectangle for the blob centers to roam in.
        // This ensures that even if a blob's center is off-screen, its body still covers the view.
        // We extend the area by 30% on each side.
        let extendedRect = rect.insetBy(dx: -rect.width * 0.3, dy: -rect.height * 0.3)
        
        let newX = CGFloat.random(in: extendedRect.minX...extendedRect.maxX)
        let newY = CGFloat.random(in: extendedRect.minY...extendedRect.maxY)
        return CGPoint(x: newX, y: newY)
    }
}


struct AnimatedBlobView_Previews : PreviewProvider {
    static var previews: some View {
        AnimatedBlobView()
    }
}
