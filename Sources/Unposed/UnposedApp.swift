import SwiftUI

@main
struct UnposedApp: App {
    @StateObject private var boothSettings = BoothSettings()
    @StateObject private var captureSession = CaptureSession()
    @StateObject private var propStore = PropStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(boothSettings)
                .environmentObject(captureSession)
                .environmentObject(propStore)
                .preferredColorScheme(.dark)
        }
    }
}
