//
//  AppStorageManager.swift
//  Your Ai Wallpaper
//
//  Created by Jan Kubeš on 26.06.2025.
//

import SwiftUI

class CreditManager: ObservableObject {
    @AppStorage("userCredits") var credits: Int = 0 {
        didSet {
            print("Credits changed to: \(credits)")
        }
    }

    /// Checks credits and in case of enough credits it substracts them.
    /// Returns true if there is enough credits
    func purchaseImageGeneration() -> Bool {
        if credits >= 10 {
            credits -= 10
            print("Image generated. Remaining credits: \(credits)")
            return true
        } else {
            print("Not enough credits for image.")
            return false
        }
    }

    func purchaseVideoGeneration() -> Bool {
        if credits >= 20 {
            credits -= 20
            print("Video generated. Remaining credits: \(credits)")
            return true
        } else {
            print("Not enough credits for video.")
            return false
        }
    }

    func addCredits(amount: Int) {
        credits += amount
        print("Credits added. New balance: \(credits)")
    }
    
    func getCredits() -> Int {
        return credits
    }
}
