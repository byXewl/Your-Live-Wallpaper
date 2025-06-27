//
//  StylesRow.swift
//  Your Ai Wallpaper
//
//  Created by Jan Kubeš on 10.05.2025.
//
//
//  StylesRow.swift
//  Your Ai Wallpaper
//
//  Created by Jan Kubeš on 10.05.2025.
//
import SwiftUI

struct StylesRow: View {
    // Functions to add or remove styles, provided by the view model
    let styleClicked: (String) -> Void
    
    // State to track the selected styles
    var selectedStyles: Set<String>
    
    // State to store the tap location (optional, for demonstration)
    @State private var tapLocation: CGPoint? = nil
    
    // List of available styles
    private let styles = ["Fantasy", "Anime", "Nature", "Mountains"]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Text("Styles:")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                ForEach(styles, id: \.self) { style in
                    Button(action: {
                        // Toggle selection
                        withAnimation {
                            styleClicked(style)
                        }
                    }) {
                        Text(style)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 10)
                            .background(
                                selectedStyles.contains(style) ? Color.blue : Color(hex: 0x878787).opacity(0.4)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.blue, lineWidth: 4)
                            )
                            .clipShape(Capsule())
                        
                            
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct InsetCapsule: Shape {
    let inset: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: inset, dy: inset)
        return Capsule().path(in: insetRect)
    }
}
