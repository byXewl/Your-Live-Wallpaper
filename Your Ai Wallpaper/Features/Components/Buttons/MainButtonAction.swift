//
//  SaveToPhotosButton.swift
//  Your Ai Wallpaper
//
//  Created by Jan Kubeš on 17.05.2025.
//

import SwiftUI

struct MainButtonAction: View {
    let text: String
    let tinted: Bool
    let action: () -> Void
    
    var text2: String? = nil
    
    var body: some View {
        Button(action: {
            Haptics.play(.medium)
            
            action()
            
        }) {
            VStack {
                Text(text)
                    .font(.system(size: 17, weight: .medium))
                
                if text2 != nil {
                    Text(text2!)
                        .font(.system(size: 13, weight: .light))
                        .foregroundColor(.white)
                }
            }
            .foregroundColor(.white)
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(
                tinted ? Color.blue : Color.gray.opacity(0.3)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .background(Color.black.opacity(0))
    }
}
