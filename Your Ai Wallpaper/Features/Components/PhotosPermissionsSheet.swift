//
//  PhotosPermissionsSheet.swift
//  Your Ai Wallpaper
//
//  Created by Jan Kubeš on 17.05.2025.
//

import SwiftUI

struct PhotosPermissionSheet: View {
    let showAlertButtonText: String
    let onConfirm: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Photos Permission")
                .font(.title)
                .fontWeight(.bold)
            
            Text("To save your wallpaper to the Photos app for use, please allow this app to access your Photos library. We will only add the wallpaper and won’t access your existing photos.")
            
            Spacer()
            
            HStack {
                Spacer()
                Button(action: onConfirm) {
                    Text(showAlertButtonText)
                }
                Spacer()
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
        .padding(.vertical, 20)
        .presentationDetents([.medium])
        .interactiveDismissDisabled()
    }
}
