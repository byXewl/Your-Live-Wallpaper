//
//  WallpaperComponent.swift
//  Your Ai Wallpaper
//
//  Created by Jan Kubeš on 09.05.2025.
//

import SwiftUI
import PhotosUI
import Photos

struct WallpaperComponent: View {
    let wallpaperState: WallpaperState
    var wallpaperComponentType: WallpaperComponentType = .generic
    
    var height = 444.0
    var width = 258.0
    var fontSize = 30.0
    var text = "Your Ai \nWallpaper"

    var isWallpaperComponent = false
    
    
    // Reference offsets at referenceWidth = 258, referenceHeight = 444
    private let offsets: [[CGFloat]] = [
        [0, 180],
        [-10, -10],
        [-100, -90],
    ]
    
    
    @State var gradient1Index = 0
    @State var gradient2Index = 1
    @State var gradient3Index = 2
    
    @State private var timer: Timer? = nil
    
    @State private var opacity: Double = 0.9
    
    var body: some View {
        ZStack (alignment: .topLeading) {
            // Gradient 1: Top Left (#1600B9)
            switch self.wallpaperState {
            case .success(let displayable):
                switch displayable {
                case .image(let image):
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill() // Fill the frame, may crop
                        .frame(width: width, height: height)
                        .clipped() // Clip to frame bounds
                case .livePhoto(let livePhoto):
                    LivePhotoViewRepresentable(livePhoto: livePhoto)
                        .frame(width: width, height: height)
                        .scaledToFill()
                }
            case .loading, .failure, .initial, .downloading, .needsDownload:
                ZStack {
                    // Gradient 1: Top Left (#1600B9)
                    Circle()
                        .frame(width: width, height: height)
                        .foregroundColor(Color(hex: 0x1600B9))
                        .blur(radius: 30)
                        .offset(x: offsets[gradient1Index][0], y: offsets[gradient1Index][1])
                    
                    // Gradient 2: Middle Right (#0B57D1)
                    Circle()
                        .frame(width: width, height: height)
                        .foregroundColor(Color(hex: 0x0B57D1))
                        .blur(radius: 50)
                        .offset(x: offsets[gradient2Index][0], y: offsets[gradient2Index][1],)
                    
                    // Gradient 3: Bottom Left (#8E008B)
                    Circle()
                        .frame(width: width, height: height)
                        .foregroundColor(Color(hex: 0x8E008B))
                        .blur(radius: 70)
                        .offset(x: offsets[gradient3Index][0], y: offsets[gradient3Index][1],)
                }
                .opacity(opacity)
                
            }
            
            // Blurred Black Shadow at the Top
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.8), Color.clear]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(.all)
            .frame(width: width , height: height, alignment: .center)
            .offset(y: -10)
            .allowsHitTesting(false)
            
            HStack(alignment: .top) {
                // White Condensed Bold Text in Top Left
                switch wallpaperState {
                case .loading, .needsDownload, .downloading:
                    ProgressView()
                default:
                    Text(text)
                        .font(.system(size: fontSize, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .allowsHitTesting(false)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                switch wallpaperComponentType {
                case .style:
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.blue)
                        .frame(width: 18, height: 18)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .shadow(radius: 5)
                case .livePhoto:
                    Text("LIVE") // The text to display
                        .font(.caption2) // Smaller font size, typically seen for indicators
                        .fontWeight(.bold) // Bold text for prominence
                        .foregroundColor(.gray) // Gray text color
                        .padding(.horizontal, 6) // Horizontal padding inside the rectangle
                        .padding(.vertical, 3) // Vertical padding inside the rectangle
                        .background(
                            Rectangle() // Use Capsule for a pill-shaped background
                                .fill(Color.white) // White background color
                                .cornerRadius(3)
                        )
                        .overlay(
                            Rectangle() // Add a subtle gray border
                                .stroke(Color.gray.opacity(0.5), lineWidth: 0.5)
                                .cornerRadius(3)
                        )
                case .generic:
                    EmptyView()
                }
            }
            .padding()
        }
        .background(Color(hex: 0x0C4CB3))
        .frame(width: width, height: height)
        .cornerRadius(10) // Rounded corners
        .onChange(of: wallpaperState, initial: true) { oldState, newState  in
            print("State changed: " + String(describing: newState))
            switch newState {
            case .loading:
                withAnimation {
                    opacity = 0.9
                }
                
                timer?.invalidate() // Clear any existing timer
                timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
                    withAnimation(.easeInOut(duration: 2)) {
                        // don't vibrate if it is in menu
                        if (!isWallpaperComponent) {
                            Haptics.play(.light)
                        }
                        
                        gradient1Index = (gradient1Index + 1) % 3
                        gradient2Index = (gradient2Index + 1) % 3
                        gradient3Index = (gradient3Index + 1) % 3
                    }
                }
            case .success(_):
                timer?.invalidate()
                withAnimation {
                    opacity = 0
                }
            case .failure(_):
                withAnimation(.easeInOut(duration: 2)) {
                    gradient1Index = (gradient1Index + 1) % 3
                    gradient2Index = (gradient2Index + 1) % 3
                    gradient3Index = (gradient3Index + 1) % 3
                }
            case .initial:
                print("Initial")
                
            case .needsDownload:
                print("Needs to download")
                
            case .downloading:
                print("Downloading!!!")
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
        
    }
}

struct LivePhotoViewRepresentable: UIViewControllerRepresentable {
    let livePhoto: PHLivePhoto
    
    class ViewController: UIViewController {
        let livePhotoView = PHLivePhotoView()
        let livePhoto: PHLivePhoto
        
        init(livePhoto: PHLivePhoto) {
            self.livePhoto = livePhoto
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLivePhotoView()
            
            livePhotoView.startPlayback(with: .hint)
        }
        
        private func setupLivePhotoView() {
            livePhotoView.livePhoto = livePhoto
            livePhotoView.contentMode = .scaleAspectFill
            livePhotoView.isUserInteractionEnabled = true
            livePhotoView.clipsToBounds = true
            view.addSubview(livePhotoView)
            
            livePhotoView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                livePhotoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                livePhotoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                livePhotoView.topAnchor.constraint(equalTo: view.topAnchor),
                livePhotoView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            
        }
        
        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            print("PHLivePhotoView Bounds: \(livePhotoView.bounds.size)")
        }
        
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            livePhotoView.startPlayback(with: .hint)
        }
    }
    
    func makeUIViewController(context: Context) -> ViewController {
        ViewController(livePhoto: livePhoto)
    }
    
    func updateUIViewController(_ uiViewController: ViewController, context: Context) {
        uiViewController.livePhotoView.livePhoto = livePhoto
        
        uiViewController.livePhotoView.startPlayback(with: .hint)
    }
}

extension Color {
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}

enum WallpaperState: Equatable {
    case initial
    case loading
    case needsDownload
    case downloading
    case success(Displayable)
    case failure(Error)
    
    static func == (lhs: WallpaperState, rhs: WallpaperState) -> Bool {
        switch (lhs, rhs) {
        case (.needsDownload, .downloading):
            return true
        case (.success, .success):
            return true
        case (.failure, .failure):
            return true
        default:
            return false
        }
    }
    
    enum Displayable {
        case image(UIImage)
        case livePhoto(PHLivePhoto)
    }
}

enum TitleState {
    case initial(String)
    case loaded(String)
    
    var value: String {
        switch self {
        case .initial(let string):
            return string
        case .loaded(let string):
            return string
        }
    }
}

enum WallpaperComponentType {
    case generic
    case livePhoto
    case style
}

#Preview {
    VStack {
        WallpaperComponent(wallpaperState: .success(.image(UIImage())), wallpaperComponentType: .livePhoto)
    }
}
