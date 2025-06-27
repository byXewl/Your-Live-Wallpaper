//
//  MenuView.swift
//  Your Ai Wallpaper
//
//  Created by Jan Kubeš on 09.05.2025.
//
import SwiftUI
import SwiftData
import Photos

struct MenuView: View {
    @StateObject private var viewModel: MenuVM
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var creditManager = CreditManager()
    
    @State var showCredits: Bool = false
    
    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: MenuVM(databaseManager: DatabaseManager(modelContext: modelContext)))
        UIToolbar.changeAppearance(clear: true)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                
                VStack(alignment: .leading) {
                    
                    if !viewModel.state.recentWallpapers.isEmpty {
                        Text("Recent")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false)  {
                            LazyHStack (spacing: 10) {
                                ForEach(viewModel.state.recentWallpapers) {wallpaper in
                                    NavigationLink(destination: DetailView(wallpaper: wallpaper.savedWallpaper)){
                                        WallpaperComponent(
                                            wallpaperState: wallpaper.state,
                                            wallpaperComponentType: wallpaper.savedWallpaper.isLivePhoto ? .livePhoto : .generic,
                                            height: 301,
                                            width: 175,
                                            fontSize: 15.0,
                                            text: wallpaper.savedWallpaper.name,
                                            isWallpaperComponent: true
                                        )
                                        // If is first, add leading padding
                                        .padding(.leading, viewModel.state.recentWallpapers.first?.id == wallpaper.id ? 5 : 0)
                                    }
                                }
                            }
                        }
                        .animation(.easeInOut(duration: 0.5), value: viewModel.state.recentWallpapers.count)
                        .padding(.bottom, 10)
                    }
                    
                    Text("Generate from styles! 💡")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    // Scrollable HStack
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            StyleComponent(style: "Fantasy")
                                .padding(.leading, 5)
                            StyleComponent(style: "Anime")
                            StyleComponent(style: "Nature")
                            StyleComponent(style: "Mountains")
                        }
                    }.padding(.bottom, 10)
                    
                    Text("Wallpapers")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [
                        GridItem(.fixed(175), spacing: 10), // Fixed width, minimal spacing
                        GridItem(.fixed(175), spacing: 10)
                    ], spacing: 16) {
                        ForEach(viewModel.state.pregeneratedWallpaperItems) { item in
                            NavigationLink(value: item) {
                                WallpaperCell(item: item, viewModel: viewModel)
                            }
                            .disabled(item.canClick)
                        }
                    }
                    .padding(.vertical)
                    .navigationDestination(for: PregeneratedWallpaperItem.self) { item in
                        DetailView(wallpaper: SavedWallpaper(name: item.name, filepath: item.filepath ?? "", dateAdded: item.dateAdded, filePathVideo: item.filePathVideo ?? "", isLivePhoto: item.isLivePhoto))
                    }
                    
                    Spacer()
                }
                
            }
            .background(Color.black)
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button(action: { viewModel.handle(.newWallpaper) }) {
                        VStack {
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                            Text("New Wallpaper")
                                .foregroundStyle(.white)
                                .font(.caption)
                                .padding(.top, 3)
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: Binding(
                get: { viewModel.state.sheetIsShown },
                set: { _ in viewModel.handle(.dismissSheet) }
            )) {
                NewWallpaperView()
                    .presentationBackground(.clear)
            }
            .fullScreenCover(isPresented: $showCredits, content: {
                CreditPurchaseView()
            })
            .navigationTitle("Ai Wallpapers!")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // Wrap the Hstack in a Button
                    Button {
                        Haptics.play(.medium)
                        
                        showCredits = true
                    } label: {
                        HStack {
                            Image(systemName: "bag.fill")
                                .foregroundColor(.primary)
                                .scaleEffect(0.6)
                            Text("\(creditManager.getCredits())")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.gray.opacity(0.2)))
                        .contentShape(Capsule()) // Make the whole capsule tappable area
                    }
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { viewModel.state.showOnboarding },
            set: { _ in viewModel.handle(.dismissOnboarding) }
        )) {
            OnboardingView(dismissOnboarding: {
                viewModel.handle(.dismissOnboarding)
            })
            .interactiveDismissDisabled(true)
            .onAppear {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first
                {
                    window.backgroundColor = .black
                }
            }
        }
        .task {
            await viewModel.syncWallpapers()
        }
        .task {
            await viewModel.getRecentWallpapers()
        }
    }
}

struct WallpaperCell: View {
    @ObservedObject var item: PregeneratedWallpaperItem // Observe the item for state changes
    var viewModel: MenuVM
    
    var body: some View {
        WallpaperComponent(
            wallpaperState: item.state,
            wallpaperComponentType: item.isLivePhoto ? .livePhoto : .generic,
            height: 301,
            width: 175,
            fontSize: 15.0,
            text: item.name,
            isWallpaperComponent: true
        )
        .onAppear {
            viewModel.handleWallpaperItemState(item: item)
        }
    }
}

extension UIToolbar {
    static func changeAppearance(clear: Bool) {
        let appearance = UIToolbarAppearance()
        
        if clear {
            appearance.configureWithOpaqueBackground()
        } else {
            appearance.configureWithDefaultBackground()
        }
        
        // customize appearance for your needs here
        appearance.shadowColor = .clear
        appearance.backgroundColor = .gray.withAlphaComponent(0.4)
        
        UIToolbar.appearance().standardAppearance = appearance
        UIToolbar.appearance().compactAppearance = appearance
        UIToolbar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    @Previewable @Environment(\.modelContext) var modelContext
    
    MenuView(modelContext: modelContext)
}

