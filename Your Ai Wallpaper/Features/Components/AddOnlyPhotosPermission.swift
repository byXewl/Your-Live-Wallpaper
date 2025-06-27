//
//  AddOnlyPhotosPermission.swift
//  Your Ai Wallpaper
//
//  Created by Jan Kubeš on 13.05.2025.
//
import SwiftUI

struct AddOnlyPhotosPermission: View {
    var allowAction: () -> Void
    
    @State var glowOpacity = 0.0
    
    
    var body: some View {
        VStack(spacing: 0) {
            // Title and description
            VStack(spacing: 8) {
                Text("“Your AI Wallpaper” Would Like to Add to Your Photos")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text("In order to save photos, we need your permission.")
                    .font(.system(size: 13))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            // Divider between text and buttons
            Divider()
                .background(Color.gray.opacity(0.3))

            // Buttons
            HStack(spacing: 0) {
                // Don't Allow button
                Button(action: {
                    // No action for "Don't Allow" as per requirement
                }) {
                    Text("Don't Allow")
                        .font(.system(size: 17))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity, maxHeight: 48)
                        .contentShape(Rectangle())
                }

                // Vertical divider between buttons
                Divider()
                    .background(Color.gray.opacity(0.3))

                // Allow button with glow
                Button(action: allowAction) {
                    Text("Allow")
                        .font(.system(size: 17))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity, maxHeight: 48)
                        .contentShape(Rectangle())
                        .shadow(color: .blue.opacity(glowOpacity), radius: 1, x: 1, y: 1) // Glow effect
                }
                .onAppear {
                    // Animate the glow effect
                    withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                        glowOpacity = 1.0
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 17)
                        .stroke(.blue.opacity(glowOpacity), lineWidth: 2)
                )
            }
            .frame(height: 48)
        }
        .frame(width: 270) // Set fixed width and height
        .background(Color(UIColor.systemBackground)) // iOS background color
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(radius: 10) // Subtle shadow for depth
    }
    
}

#Preview {
    AddOnlyPhotosPermission {
        
    }
}
