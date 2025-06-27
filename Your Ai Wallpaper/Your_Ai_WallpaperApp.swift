//
//  Your_Ai_WallpaperApp.swift
//  Your Ai Wallpaper
//
//  Created by Jan Kubeš on 09.05.2025.
//

import SwiftUI
import FirebaseCore


class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}

@main
struct Your_Ai_WallpaperApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            MenuViewContainer()
                .modelContainer(for: SavedWallpaper.self)
        }
    }
}

struct MenuViewContainer: View {
    @Environment(\.modelContext) private var modelContext // Access modelContext from the environment

    var body: some View {
        MenuView(modelContext: modelContext)
    }
}
