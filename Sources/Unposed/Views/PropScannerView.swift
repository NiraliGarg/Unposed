import SwiftUI

// scan an object with the camera to create a custom prop
struct PropScannerView: View {
    @ObservedObject var propStore: PropStore
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var cameraManager = CameraManager()
    
    @State private var capturedImage: UIImage? = nil
    @State private var liftedImage: UIImage? = nil
    @State private var isProcessing = false
    @State private var propName: String = ""
    @State private var selectedAnchor: PropAnchor = .forehead
    @State private var scanPhase: ScanPhase = .capture
    
    enum ScanPhase {
        case capture      // Taking the photo
        case processing   // Removing background
        case preview      // Showing cutout, picking name + anchor
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                switch scanPhase {
                case .capture:
                    capturePhaseView
                case .processing:
                    processingPhaseView
                case .preview:
                    previewPhaseView
                }
            }
            .navigationTitle("Scan a Prop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    
    // Capture Phase
    
    private var capturePhaseView: some View {
        VStack(spacing: 24) {
            Text("Point your camera at an object\nyou want to use as a prop")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.top, 20)
            
            if cameraManager.isCameraReady {
                CameraPreviewView(cameraManager: cameraManager)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(white: 0.15))
                    .overlay(
                        ProgressView()
                            .tint(.white)
                    )
                    .padding(.horizontal, 24)
            }
            
            HStack(spacing: 40) {
                Button(action: {
                    cameraManager.switchCamera()
                }) {
                    Image(systemName: "arrow.triangle.2.circlepath.camera")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 50, height: 50)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.12))
                        )
                }
                
                Button(action: captureForScanning) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 70, height: 70)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.5), lineWidth: 4)
                                .frame(width: 80, height: 80)
                        )
                }
                
                Color.clear
                    .frame(width: 50, height: 50)
            }
            .padding(.bottom, 30)
        }
        .onAppear {
            cameraManager.startSession()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }
    
    // Processing Phase
    
    private var processingPhaseView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.5)
                .tint(.pink)
            
            Text("Removing background...")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Text("Using Vision AI to isolate the subject")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
            
            Spacer()
        }
    }
    
    // Preview Phase
    
    private var previewPhaseView: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let liftedImage = liftedImage {
                    Image(uiImage: liftedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 250)
                        .background(
                            // Checkerboard pattern to show transparency
                            CheckerboardBackground()
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 40)
                        .padding(.top, 20)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("PROP NAME")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(1.5)
                    
                    TextField("Name your prop", text: $propName)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.1))
                        )
                }
                .padding(.horizontal, 24)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("ATTACH TO")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(1.5)
                    
                    HStack(spacing: 10) {
                        ForEach(PropAnchor.allCases.filter { $0 != .hand }, id: \.self) { anchor in
                            Button(action: {
                                withAnimation(.spring(response: 0.2)) {
                                    selectedAnchor = anchor
                                }
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: anchor.icon)
                                        .font(.system(size: 20))
                                    Text(anchor.displayName)
                                        .font(.system(size: 10, weight: .medium))
                                }
                                .foregroundColor(selectedAnchor == anchor ? .white : .white.opacity(0.5))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedAnchor == anchor ? Color.pink.opacity(0.6) : Color.white.opacity(0.08))
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                HStack(spacing: 16) {
                    Button(action: {
                        withAnimation {
                            scanPhase = .capture
                            capturedImage = nil
                            liftedImage = nil
                        }
                    }) {
                        Text("Retake")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.15))
                            )
                    }
                    
                    // Save
                    Button(action: saveProp) {
                        Text("Add Prop")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.pink)
                            )
                    }
                    .disabled(propName.isEmpty)
                    .opacity(propName.isEmpty ? 0.5 : 1.0)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
        }
    }
    
    // Actions
    
    private func captureForScanning() {
        cameraManager.capturePhoto { image in
            guard let image = image else { return }
            capturedImage = image
            
            withAnimation {
                scanPhase = .processing
            }
            
            // Run subject lifting
            Task {
                let lifted = await SubjectLifter.liftSubject(from: image)
                
                await MainActor.run {
                    if let lifted = lifted {
                        liftedImage = lifted
                        withAnimation {
                            scanPhase = .preview
                        }
                    } else {
                        // Failed — go back to capture
                        withAnimation {
                            scanPhase = .capture
                        }
                    }
                }
            }
        }
    }
    
    private func saveProp() {
        guard let liftedImage = liftedImage, !propName.isEmpty else { return }
        propStore.addCustomProp(name: propName, image: liftedImage, anchor: selectedAnchor)
        dismiss()
    }
}

// Checkerboard Background (shows transparency)

struct CheckerboardBackground: View {
    let size: CGFloat = 12
    
    var body: some View {
        Canvas { context, canvasSize in
            let rows = Int(canvasSize.height / size) + 1
            let cols = Int(canvasSize.width / size) + 1
            
            for row in 0..<rows {
                for col in 0..<cols {
                    let isGray = (row + col) % 2 == 0
                    let rect = CGRect(x: CGFloat(col) * size, y: CGFloat(row) * size, width: size, height: size)
                    context.fill(Path(rect), with: .color(isGray ? Color(white: 0.25) : Color(white: 0.2)))
                }
            }
        }
    }
}
