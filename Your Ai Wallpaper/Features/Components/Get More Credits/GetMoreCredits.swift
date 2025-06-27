//
//  GetMoreCredits.swift
//  Your Ai Wallpaper
//
//  Created by Jan Kubeš on 26.06.2025.
//

import SwiftUI

struct CreditPurchaseView: View {
var body: some View {
    ZStack {
        // Your background animation
        AnimatedBlobView()

        VStack(alignment: .leading) {
            Text("Your iPhone, Your Masterpiece.")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 5)

            Text("Gain credits to unleash powerful AI tools:")
                .font(.title3)
                .padding(.bottom, 15)

            // Feature list highlighting AI capabilities
            FeatureBenefitRow(
                text: "Generate stunning wallpapers from text with AI.",
                icon: "sparkles"
            )
            FeatureBenefitRow(
                text: "Bring your images to life by animating them with AI.",
                icon: "play.circle.fill" // Icon for animation/video
            )
            FeatureBenefitRow(
                text: "Effortlessly set animated creations as Live Wallpapers.",
                icon: "photo.fill" // Icon for setting live wallpaper
            )
            FeatureBenefitRow(
                text: "No recurring payments, just pure creative freedom!",
                icon: "dollarsign.circle.fill"
            )

            Spacer()

            VStack {
                MainButtonAction(text: "Buy 10 Credits - $4.99", tinted: false, action: {
                    print("Buy 10 credits tapped!")
                })

                MainButtonAction(text: "Buy 50 Credits - $19.99", tinted: true, action: {
                    print("Buy 50 credits tapped!")
                }, text2: "Best Value!")

                MainButtonAction(text: "Buy 100 Credits - $34.99", tinted: false, action: {
                    print("Buy 100 credits tapped!")
                })
            }
            .padding(.bottom)
        }
        .padding()
        .foregroundColor(.white)
    }
}
}

// Renamed helper view for clarity: from CreditFeatureRow to FeatureBenefitRow
struct FeatureBenefitRow: View {
let text: String
let icon: String

var body: some View {
    HStack(alignment: .top) {
        Image(systemName: icon)
            .font(.body)
            .foregroundColor(.green)
            .frame(width: 25)
        Text(text)
            .font(.body)
            .fontWeight(.medium)
        Spacer()
    }
    .padding(.vertical, 5)
}
}

struct CreditPurchaseView_Previews: PreviewProvider {
static var previews: some View {
    CreditPurchaseView()
        .background(Color.black.edgesIgnoringSafeArea(.all))
}
}
