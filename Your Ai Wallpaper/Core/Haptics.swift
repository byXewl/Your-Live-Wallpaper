//
//  Haptics.swift
//  Your Ai Wallpaper
//
//  Created by Jan Kubeš on 10.05.2025.
//

import UIKit

struct Haptics {
    static func play(_ feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: feedbackStyle)
        generator.prepare()
        generator.impactOccurred()
    }
    
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
//        generator.selectionChanged(at: <#T##CGPoint#>)
    }
}
