import SwiftUI

struct ContentView: View {
    @EnvironmentObject var boothSettings: BoothSettings
    @EnvironmentObject var captureSession: CaptureSession
    
    @State private var currentScreen: AppScreen = .intro
    @State private var curtainOpen: Bool = true       // true = curtains off-screen
    @State private var showCurtain: Bool = false       // whether curtain overlay is visible at all
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            switch currentScreen {
            case .intro:
                IntroScreen(onStart: {
                    // 1. Show curtains closed
                    curtainOpen = false
                    showCurtain = true
                    
                    // 2. Switch screen behind curtains WITHOUT any transition animation
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        currentScreen = .boothSetup
                    }
                    
                    // 3. After a brief beat, animate curtains open
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
                        withAnimation(.easeInOut(duration: 1.10)) {
                            curtainOpen = true
                        }
                        // Remove curtain overlay after animation finishes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            showCurtain = false
                        }
                    }
                })
                .transition(.opacity)
                
            case .boothSetup:
                BoothSetupScreen(onEnterBooth: {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        currentScreen = .camera
                    }
                }, onBack: {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        currentScreen = .intro
                    }
                })
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                
            case .camera:
                CameraScreen(
                    onCaptureComplete: {
                        withAnimation(.easeInOut(duration: 0.6)) {
                            currentScreen = .result
                        }
                    },
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            currentScreen = .boothSetup
                        }
                    }
                )
                .transition(.opacity)
                
            case .result:
                ResultScreen(
                    onCustomize: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            currentScreen = .customization
                        }
                    },
                    onRetake: {
                        captureSession.reset()
                        withAnimation(.easeInOut(duration: 0.5)) {
                            currentScreen = .camera
                        }
                    }
                )
                .transition(.move(edge: .bottom))
                
            case .customization:
                CustomizationScreen(
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            currentScreen = .result
                        }
                    },
                    onStartOver: {
                        captureSession.reset()
                        withAnimation(.easeInOut(duration: 0.5)) {
                            currentScreen = .intro
                        }
                    }
                )
                .transition(.move(edge: .trailing))
            }
            // Curtain overlay — renders above all screens
            if showCurtain {
                CurtainOverlay(isOpen: curtainOpen)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: currentScreen)
    }
}

enum AppScreen {
    case intro
    case boothSetup
    case camera
    case result
    case customization
}

#Preview {
    ContentView()
        .environmentObject(BoothSettings())
        .environmentObject(CaptureSession())
        .environmentObject(PropStore())
}
