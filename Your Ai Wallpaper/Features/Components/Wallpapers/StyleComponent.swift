//
//  StyleComponent.swift
//  Your Ai Wallpaper
//
//  Created by Jan Kubeš on 10.05.2025.
//

import SwiftUI

struct StyleComponent: View {
    let style: String
    @State var clicked: Bool = false
    
    
    var body: some View {
        WallpaperComponent(
            wallpaperState: .success(.image(UIImage(imageLiteralResourceName: style))),
            wallpaperComponentType: .style,
            height: 301,
            width: 175,
            fontSize: 15.0,
            text: style,
        )
        .onTapGesture {
            Haptics.play(.medium)
            clicked = true
        }
        .padding(.leading, 5)
        .fullScreenCover(isPresented: Binding(
            get: { clicked },
            set: { _ in clicked=false }
        )) {
            NewWallpaperView(style: style)
                .presentationBackground(.clear)
        }
    }
}
